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
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .systemBackground
        tableView.register(ExpenseListViewCell.self, forCellReuseIdentifier: ExpenseListViewCell.identifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
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
        isModalInPresentation = true
    }
    
    func configureUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(titleLabel)
        view.addSubview(xButton)
        view.addSubview(tableView)
        
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.top.equalToSuperview().offset(24)
        }
        
        xButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalTo(titleLabel)
        }
        
        tableView.snp.makeConstraints {
            $0.top.equalTo(titleLabel).offset(20)
            $0.leading.trailing.bottom.equalToSuperview()
        }
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
}
