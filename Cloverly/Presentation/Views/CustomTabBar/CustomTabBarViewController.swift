//
//  CustomTabBarViewController.swift
//  Cloverly
//
//  Created by 이인호 on 12/20/25.
//

import UIKit
import SnapKit
import RxSwift
import GoogleMobileAds

class CustomTabBarViewController: UITabBarController {
    
    private let customTabBar = CustomTabBar()
    private let disposeBag = DisposeBag()
    private let calendarViewModel = CalendarViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewControllers()
        configureUI()
        bindError()
        applyTabBarStyle(for: selectedIndex)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTabChange(_:)),
            name: .changeTab,
            object: nil
        )
    }

    private func bindError() {
        calendarViewModel.errorRelay
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] error in
                self?.topmostViewController()?.showErrorToast(error)
            })
            .disposed(by: disposeBag)
    }

    private func topmostViewController() -> UIViewController? {
        var top: UIViewController = self
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
    
    func setupViewControllers() {
        let homeVC = HomeViewController(calendarViewModel: calendarViewModel)
        let chatVC = ChatViewController(calendarViewModel: calendarViewModel)
        let historyVC = HistoryTabViewController(viewModel: calendarViewModel)
        let myVC = MyPageViewController()

        viewControllers = [homeVC, chatVC, historyVC, myVC]

        customTabBar.itemTapped
            .subscribe(onNext: { [weak self] index in
                self?.selectedIndex = index
                self?.applyTabBarStyle(for: index)
            })
            .disposed(by: disposeBag)
    }

    private func applyTabBarStyle(for index: Int) {
        // 홈(0)·채팅(1)에서는 입력바가 탭바와 자연스럽게 이어지도록 상단 shadow 제거
        customTabBar.setShadowHidden(index == 0 || index == 1)
    }

    // 홈에서 입력한 내용을 채팅 탭으로 전달하며 이동. 채팅 VC를 새로 만들어 교체해
    // 기존 initialMessage/initialImage 전송 흐름을 그대로 재사용한다.
    func routeToChatTab(message: String? = nil, image: UIImage? = nil, interstitialAd: InterstitialAd? = nil) {
        let chatVC = ChatViewController(
            calendarViewModel: calendarViewModel,
            interstitialAd: interstitialAd,
            initialMessage: message,
            initialImage: image
        )

        if var vcs = viewControllers, vcs.count > 1 {
            vcs[1] = chatVC
            viewControllers = vcs
        }

        selectedIndex = 1
        customTabBar.updateButtonState(selectedIndex: 1)
        applyTabBarStyle(for: 1)
    }
    
    func configureUI() {
        tabBar.isHidden = true
        
        view.addSubview(customTabBar)
        additionalSafeAreaInsets.bottom = 90 - 34
        
        customTabBar.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(90)
        }
    }
    
    @objc private func handleTabChange(_ notification: Notification) {
        guard let index = notification.userInfo?["index"] as? Int else { return }
        
        // 메인 스레드에서 안전하게 이동
        DispatchQueue.main.async { [weak self] in
            self?.selectedIndex = index
            self?.customTabBar.updateButtonState(selectedIndex: index)
            self?.applyTabBarStyle(for: index)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
