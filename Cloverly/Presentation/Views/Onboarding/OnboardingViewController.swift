//
//  OnboardingViewController.swift
//  Cloverly
//
//  Created by 이인호 on 12/18/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

class OnboardingViewController: UIPageViewController {
    
    private var pages: [UIViewController] = []
    private var currentIndex = 0
    private let disposeBag = DisposeBag()
    
    private let pagecontrol = CustomPageControl()
    
    private lazy var button: UIButton = {
        let button = BouncyButton()
        
        button.setTitle("다음", for: .normal)
        button.setTitleColor(.gray10, for: .normal)
        button.titleLabel?.font = Typography.b1.uiFont
        button.backgroundColor = .green5
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        
        button.addAction(UIAction { [weak self] _ in
            self?.moveToNextPage()
        }, for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPages()
        configureUI()
        pagecontrol.configure(numberOfPages: pages.count)
    }
    
    private func setupPages() {
        let page1 = OnboardingPageController(model: OnboardingModel(title: "대화로 쓰는 가계부", subtitle: "채팅하듯 간편하게 내역을 입력하고\n소비할 때의 기분도 함께 남겨요", imageName: "onboarding 1"))
        let page2 = OnboardingPageController(model: OnboardingModel(title: "입력은 더 간편하게", subtitle: "영수증을 찍거나 복사한 텍스트를\n붙여넣으면 자동으로 분류돼요", imageName: "onboarding 2"))
        let page3 = OnboardingPageController(model: OnboardingModel(title: "영수증 속 세부 품목 등록", subtitle: "AI가 영수증 속 품목과 금액을 하나씩 정리해요\n품목별로 기록하고, 총액은 자동으로 계산돼요", imageName: "onboarding 3"))
        let page4 = OnboardingPageController(model: OnboardingModel(title: "소비 통계로 돌아보기", subtitle: "기록한 내역부터 카테고리별 지출 통계까지\n어디에 얼마나 썼는지 쉽게 살펴봐요", imageName: "onboarding 4"))
        
        
        pages = [page1, page2, page3, page4]
    }
    
    private func configureUI() {
        self.dataSource = self
        self.delegate = self
        self.setViewControllers([pages[currentIndex]], direction: .forward, animated: true)
        
        view.addSubview(pagecontrol)
        view.addSubview(button)
        
        pagecontrol.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(button.snp.top).offset(-36)
            $0.height.equalTo(10)
        }
        
        
        button.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().offset(-34)
            $0.height.equalTo(56)
        }
        
        // 맨 앞으로 가져오기 (혹시 가려질까봐)
        view.bringSubviewToFront(button)
        view.bringSubviewToFront(pagecontrol)
    }
    
    private func moveToNextPage() {
        guard let currentVC = viewControllers?.first,
              let currentIndex = pages.firstIndex(of: currentVC) else { return }
        
        let nextIndex = currentIndex + 1

        if nextIndex < pages.count {
            let nextPage = pages[nextIndex]
            self.setViewControllers([nextPage], direction: .forward, animated: true)
            pagecontrol.setCurrentPage(nextIndex)
        } else {
            UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let sceneDelegate = windowScene.delegate as? SceneDelegate {
                sceneDelegate.checkAndUpdateRootViewController()
            }
        }
    }
}

extension OnboardingViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let currentIndex = pages.firstIndex(of: viewController) else { return nil }
        guard currentIndex > 0 else { return nil }
        return pages[currentIndex - 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let currentIndex = pages.firstIndex(of: viewController) else { return nil }
        guard currentIndex < (pages.count - 1) else { return nil }
        return pages[currentIndex + 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        guard let targetVC = pendingViewControllers.first,
              let targetIndex = pages.firstIndex(of: targetVC) else { return }
        
        pagecontrol.setCurrentPage(targetIndex)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if !completed {
            guard let currentVC = pageViewController.viewControllers?.first,
                  let index = pages.firstIndex(of: currentVC) else { return }
            
            pagecontrol.setCurrentPage(index)
        }
    }
}
