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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewControllers()
        configureUI()
    }
    
    func setupViewControllers() {
        let homeVC = HomeViewController()
        let recordVC = ViewController()
        let myVC = ViewController()
        
        viewControllers = [homeVC, recordVC, myVC]
        
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
}
