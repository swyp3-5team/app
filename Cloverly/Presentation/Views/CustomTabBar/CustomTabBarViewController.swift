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
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTabChange(_:)),
            name: .changeTab,
            object: nil
        )
    }
    
    func setupViewControllers() {
        let homeVC = HomeViewController(calendarViewModel: calendarViewModel)
        let historyVC = HistoryTabViewController(viewModel: calendarViewModel)
        let myVC = MyPageViewController()
        
        viewControllers = [homeVC, historyVC, myVC]
        
        customTabBar.itemTapped
            .subscribe(onNext: { [weak self] index in
                self?.selectedIndex = index
            })
            .disposed(by: disposeBag)
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
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
