//
//  ExpenseListViewController.swift
//  Cloverly
//
//  Created by wayblemac02 on 1/2/26.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

class ExpenseListViewController: UIViewController {
    private let viewModel: CalendarViewModel
    private let disposeBag = DisposeBag()
    
    var statusBarHeight: CGFloat {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            return windowScene.statusBarManager?.statusBarFrame.height ?? 0
        }
        return 0
    }
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .gray1
        label.font = .customFont(.pretendardSemiBold, size: 18)
        return label
    }()
    
    private lazy var xButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "Modal Close Button"), for: .normal)
        button.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }
            self.viewModel.isSheetPresent.accept(false)
        }, for: .touchUpInside)
        
        return button
    }()
    
    private lazy var addButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.filled()

        config.title = "내역 추가"
        config.image = UIImage(named: "add icon")

        config.imagePlacement = .leading
        config.imagePadding = 4

        config.baseForegroundColor = .gray1
        config.baseBackgroundColor = .gray9
        config.contentInsets = NSDirectionalEdgeInsets(top: 9, leading: 16, bottom: 9, trailing: 16)
        
        var titleAttr = AttributedString.init("내역 추가")
        titleAttr.font = .customFont(.pretendardSemiBold, size: 16)
        config.attributedTitle = titleAttr
        
        config.cornerStyle = .capsule
        
        button.configuration = config
        
        button.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }
            viewModel.clearCurrentTransaction()
            let vc = ExpenseHistoryViewController(viewModel: viewModel)
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        }, for: .touchUpInside)
        
        return button
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .systemBackground
        tableView.register(ExpenseListViewCell.self, forCellReuseIdentifier: ExpenseListViewCell.identifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        return tableView
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
        bind()
        
        if let sheet = self.sheetPresentationController {
            sheet.delegate = self
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard let navBar = navigationController?.navigationBar else { return }
        let navBarFrameInView = navBar.convert(navBar.bounds, to: view)

        // navBar에 맞추기
        titleLabel.snp.remakeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalTo(navBarFrameInView.midY)
        }
    }
    
    func configureUI() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: xButton)
        view.backgroundColor = .gray10
        view.addSubview(titleLabel)
        view.addSubview(tableView)
        
        tableView.snp.makeConstraints {
            $0.top.equalTo(titleLabel).offset(20)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 60))
        footerView.addSubview(addButton)
        
        addButton.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        
        tableView.tableFooterView = footerView
    }
    
    func bind() {
        viewModel.selectedDate
            .map { date -> String in
                let formatter = DateFormatter()
                formatter.dateFormat = "MM월 dd일"
                formatter.locale = Locale(identifier: "ko_KR")
                return formatter.string(from: date)
            }
            .bind(to: titleLabel.rx.text) // 라벨 텍스트로 바로 연결
            .disposed(by: disposeBag)
        
        viewModel.groupedTransactions
            .observe(on: MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    self?.tableView.reloadData()
                })
                .disposed(by: disposeBag)
    }
}

extension ExpenseListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.currentDayTransactions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ExpenseListViewCell.identifier, for: indexPath) as? ExpenseListViewCell else {
            return UITableViewCell()
        }
        
        let transaction = viewModel.currentDayTransactions[indexPath.row]
        cell.configure(with: transaction)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.currentTransaction.accept(viewModel.currentDayTransactions[indexPath.row])
        let vc = ExpenseHistoryViewController(viewModel: viewModel)
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
}

extension ExpenseListViewController: UISheetPresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        viewModel.isSheetPresent.accept(false)
    }
}
