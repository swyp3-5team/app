//
//  CustomTabBarViewController.swift
//  Cloverly
//
//  Created by 이인호 on 12/20/25.
//

import UIKit
import SnapKit
import RxSwift

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
        let historyVC = HistoryTabViewController(viewModel: calendarViewModel)
        let myVC = MyPageViewController()

        viewControllers = [homeVC, historyVC, myVC]

        customTabBar.itemTapped
            .subscribe(onNext: { [weak self] index in
                self?.selectedIndex = index
                self?.applyTabBarStyle(for: index)
            })
            .disposed(by: disposeBag)
    }

    private func applyTabBarStyle(for index: Int) {
        // 홈(0)에서는 인풋바가 탭바 코너를 채우므로 shadow 제거
        customTabBar.setShadowHidden(index == 0)
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
