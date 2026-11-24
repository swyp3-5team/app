//
//  TapmanViewController.swift
//  Cloverly
//
//  Created by 이인호 on 12/31/25.
//

import UIKit
import Tabman
import Pageboy
import SnapKit
import FirebaseAnalytics

class HistoryTabViewController: TabmanViewController {
    private let viewModel: CalendarViewModel
    private var viewControllers: [UIViewController] = []
    // 현재 화면 방문 ID (history_feature_clicked의 screen_visit_id 연결용)
    private var screenVisitId = ""
    var statusBarHeight: CGFloat {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            return windowScene.statusBarManager?.statusBarFrame.height ?? 0
        }
        return 0
    }
    
    private let titleLabel: AppLabel = {
        let label = AppLabel()
        label.text = "내역"
        label.textColor = .gray1
        label.typography = .t1
        return label
    }()
    
    init(viewModel: CalendarViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
//        self.isScrollEnabled = false // 탭바 스와이프 비활성화
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        screenVisitId = UUID().uuidString
        AnalyticsManager.shared.logScreenView(screenName: "history_tab", screenVisitId: screenVisitId)
    }

    // 달력 서브탭(index 1)으로 전환 시 history_feature_clicked(calendar). super 호출로 Tabman 바 동기화 보존.
    override func pageboyViewController(_ pageboyViewController: PageboyViewController,
                                        didScrollToPageAt index: PageboyViewController.PageIndex,
                                        direction: PageboyViewController.NavigationDirection,
                                        animated: Bool) {
        super.pageboyViewController(pageboyViewController, didScrollToPageAt: index, direction: direction, animated: animated)
        if index == 1 {
            AnalyticsManager.shared.logHistoryFeatureClicked(featureName: .calendar, screenVisitId: screenVisitId)
        }
    }

    func configureUI() {
        view.addSubview(titleLabel)
        
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.snp.top).offset(statusBarHeight + 15.5)
            $0.centerX.equalToSuperview()
        }

        let transactionViewModel = TransactionViewModel()
        viewControllers.append(RecordViewController(viewModel: viewModel, transactionViewModel: transactionViewModel))
        viewControllers.append(CalendarViewController(viewModel: viewModel, transactionViewModel: transactionViewModel))
        
        self.dataSource = self
        
        let bar = TMBar.ButtonBar()
        
        bar.backgroundView.style = .blur(style: .regular)
        bar.layout.transitionStyle = .snap
        bar.layout.contentMode = .fit
        
        bar.buttons.customize { button in
            button.tintColor = .gray6
            button.selectedTintColor = .label
        }
        bar.indicator.weight = .custom(value: 2)
        bar.indicator.tintColor = .label
        
        addBar(bar, dataSource: self, at: .top)
    }
}

extension HistoryTabViewController: PageboyViewControllerDataSource, TMBarDataSource {
    func numberOfViewControllers(in pageboyViewController: PageboyViewController) -> Int {
        return viewControllers.count
    }
    
    func viewController(for pageboyViewController: PageboyViewController,
                        at index: PageboyViewController.PageIndex) -> UIViewController? {
        return viewControllers[index]
    }
    
    func defaultPage(for pageboyViewController: PageboyViewController) -> PageboyViewController.Page? {
        return nil // nil이면 첫 번째 페이지
    }
    
    func barItem(for bar: TMBar, at index: Int) -> TMBarItemable {
        let title = index == 0 ? "기록" : "달력"
        return TMBarItem(title: title)
    }
}
