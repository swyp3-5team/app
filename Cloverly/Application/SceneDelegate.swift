//
//  SceneDelegate.swift
//  Cloverly
//
//  Created by 이인호 on 12/11/25.
//

import UIKit
import KakaoSDKAuth
import AppTrackingTransparency

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    // 업데이트 알림 중복 표시 방지
    private var isShowingUpdateAlert = false


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        window?.backgroundColor = .systemBackground
        
        checkAndUpdateRootViewController()
    }
    
    private func showOnboarding() {
        let onboardingVC = OnboardingViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        changeRootViewController(onboardingVC)
    }

    func showMain() {
        let mainVC = UINavigationController(rootViewController: CustomTabBarViewController())
        changeRootViewController(mainVC)
    }

    private func showLogin() {
        let loginVC = UINavigationController(rootViewController: LoginViewController())
        changeRootViewController(loginVC)
    }
    
    private func changeRootViewController(_ vc: UIViewController, animated: Bool = true) {
        guard let window = self.window else { return }
        
        window.rootViewController = vc
        
        if animated {
            UIView.transition(with: window,
                              duration: 0.3,
                              options: .transitionCrossDissolve,
                              animations: nil,
                              completion: nil)
        }
        window.makeKeyAndVisible()
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url {
            if (AuthApi.isKakaoTalkLoginUrl(url)) {
                _ = AuthController.handleOpenUrl(url: url)
            }
        }
    }
    
    func checkAndUpdateRootViewController() {
        if !UserDefaults.standard.bool(forKey: "hasSeenOnboarding") {
            showOnboarding()
        } else {
            if KeychainManager.shared.refreshToken != nil {
                showMain()
            } else {
                showLogin()
            }
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            ATTrackingManager.requestTrackingAuthorization { _ in }
        }

        checkAppUpdate()
    }

    // MARK: - 앱 업데이트 체크

    private func checkAppUpdate() {
        guard !isShowingUpdateAlert else { return }

        Task { @MainActor in
            let result = await AppUpdateManager.shared.check()
            switch result.status {
            case .forced:
                presentForcedUpdateAlert(storeURL: result.storeURL)
            case .optional:
                presentOptionalUpdateAlert(storeVersion: result.storeVersion, storeURL: result.storeURL)
            case .none:
                break
            }
        }
    }

    private func presentForcedUpdateAlert(storeURL: URL?) {
        guard !isShowingUpdateAlert, let top = topViewController() else { return }

        let alert = UIAlertController(
            title: "업데이트 안내",
            message: "원활한 앱 사용을 위해 최신 버전으로 업데이트가 필요합니다.",
            preferredStyle: .alert
        )
        // 강제: 취소 없이 업데이트만. 스토어에서 돌아와도 sceneDidBecomeActive가 다시 검사해 재노출한다.
        alert.addAction(UIAlertAction(title: "업데이트", style: .default) { [weak self] _ in
            self?.isShowingUpdateAlert = false
            if let storeURL { UIApplication.shared.open(storeURL) }
        })

        isShowingUpdateAlert = true
        top.present(alert, animated: true)
    }

    private func presentOptionalUpdateAlert(storeVersion: String?, storeURL: URL?) {
        guard !isShowingUpdateAlert, let top = topViewController() else { return }

        let alert = UIAlertController(
            title: "업데이트 안내",
            message: "새로운 버전이 출시되었어요. 지금 바로 업데이트 해보세요!",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "다음", style: .cancel) { [weak self] _ in
            self?.isShowingUpdateAlert = false
            if let storeVersion { AppUpdateManager.shared.skipOptional(storeVersion: storeVersion) }
        })
        alert.addAction(UIAlertAction(title: "업데이트", style: .default) { [weak self] _ in
            self?.isShowingUpdateAlert = false
            if let storeURL { UIApplication.shared.open(storeURL) }
        })

        isShowingUpdateAlert = true
        top.present(alert, animated: true)
    }

    private func topViewController() -> UIViewController? {
        var top = window?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

