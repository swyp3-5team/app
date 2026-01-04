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

class HistoryTabViewController: TabmanViewController {
    private let viewModel: CalendarViewModel
    private var viewControllers: [UIViewController] = []
    var statusBarHeight: CGFloat {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            return windowScene.statusBarManager?.statusBarFrame.height ?? 0
        }
        return 0
    }
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "내역"
        label.font = .customFont(.pretendardSemiBold, size: 18)
        label.textColor = .gray1
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
    
    func configureUI() {
        view.addSubview(titleLabel)
        
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.snp.top).offset(statusBarHeight + 15.5)
            $0.centerX.equalToSuperview()
        }

        viewControllers.append(RecordViewController(viewModel: viewModel))
        viewControllers.append(CalendarViewController(viewModel: viewModel))
        
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
