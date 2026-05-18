//
//  CategoryExpenseViewController.swift
//  Cloverly
//
//  Created by 이인호 on 3/19/26.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

class CategoryExpenseViewController: UIViewController {
    private let viewModel: CalendarViewModel
    private let categoryId: Int
    private let categoryName: String
    private let disposeBag = DisposeBag()
    private var groupedTransactions: [(date: String, transactions: [TransactionRecord])] = []

    private lazy var dateLabel: AppLabel = {
        let label = AppLabel()
        let icon = ExpenseCategory(rawValue: categoryId)?.icon ?? "💸"
        label.text = "\(icon) \(categoryName)"
        label.textColor = .gray3
        label.typography = .b6
        return label
    }()

    private let totalAmount: AppLabel = {
        let label = AppLabel()
        label.textColor = .gray1
        label.typography = .h1
        return label
    }()

    private let dividerView: UIView = {
        let view = UIView()
        view.backgroundColor = .gray9
        return view
    }()

    private let countLabel: AppLabel = {
        let label = AppLabel()
        label.typography = .b5
        return label
    }()

    private let cardLabel: AppLabel = {
        let label = AppLabel()
        label.typography = .b5
        return label
    }()

    private let cashLabel: AppLabel = {
        let label = AppLabel()
        label.typography = .b5
        return label
    }()

    private lazy var paymentStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [cardLabel, cashLabel])
        stack.axis = .horizontal
        stack.spacing = 8
        return stack
    }()

    private lazy var summaryRowView: UIView = {
        let view = UIView()
        return view
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.backgroundColor = .systemBackground
        tableView.register(ExpenseListViewCell.self, forCellReuseIdentifier: ExpenseListViewCell.identifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        tableView.sectionHeaderTopPadding = 0
        return tableView
    }()

    init(viewModel: CalendarViewModel, categoryId: Int, categoryName: String) {
        self.viewModel = viewModel
        self.categoryId = categoryId
        self.categoryName = categoryName
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bind()
        viewModel.getCategoryTransactions(yearMonth: viewModel.currentDate.value, categoryId: categoryId)
    }

    private func configureUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(dateLabel)
        view.addSubview(totalAmount)
        view.addSubview(dividerView)
        view.addSubview(summaryRowView)
        view.addSubview(tableView)

        summaryRowView.addSubview(countLabel)
        summaryRowView.addSubview(paymentStackView)

        dateLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            $0.leading.equalToSuperview().offset(16)
        }

        totalAmount.snp.makeConstraints {
            $0.top.equalTo(dateLabel.snp.bottom).offset(8)
            $0.leading.equalToSuperview().offset(16)
        }

        dividerView.snp.makeConstraints {
            $0.top.equalTo(totalAmount.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(6)
        }

        summaryRowView.snp.makeConstraints {
            $0.top.equalTo(dividerView.snp.bottom)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(44)
        }

        countLabel.snp.makeConstraints {
            $0.leading.centerY.equalToSuperview()
        }

        paymentStackView.snp.makeConstraints {
            $0.trailing.centerY.equalToSuperview()
        }

        tableView.snp.makeConstraints {
            $0.top.equalTo(summaryRowView.snp.bottom)
            $0.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }

    private func bind() {
        viewModel.categoryTransactions
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] transactions in
                guard let self else { return }
                let total = transactions.reduce(0) { $0 + $1.amount }
                self.totalAmount.text = "\(total.withComma)원"

                self.countLabel.attributedText = Self.makeSummaryText(prefix: "총 ", value: "\(transactions.count)건")

                let cardTotal = transactions.filter { $0.payment == .card }.reduce(0) { $0 + $1.amount }
                let cashTotal = transactions.filter { $0.payment == .cash }.reduce(0) { $0 + $1.amount }
                self.cardLabel.attributedText = Self.makeSummaryText(prefix: "카드 ", value: "\(cardTotal.withComma)원")
                self.cashLabel.attributedText = Self.makeSummaryText(prefix: "현금 ", value: "\(cashTotal.withComma)원")

                self.groupedTransactions = Self.group(transactions: transactions)
                self.tableView.reloadData()
            })
            .disposed(by: disposeBag)
    }

    private static func makeSummaryText(prefix: String, value: String) -> NSAttributedString {
        let attributed = NSMutableAttributedString(string: prefix, attributes: [.foregroundColor: UIColor.gray5, .font: Typography.b7.uiFont])
        attributed.append(NSAttributedString(string: value, attributes: [.foregroundColor: UIColor.gray1, .font: Typography.b5.uiFont]))
        return attributed
    }

    private static func group(transactions: [TransactionRecord]) -> [(date: String, transactions: [TransactionRecord])] {
        var dict: [String: [TransactionRecord]] = [:]
        for transaction in transactions {
            dict[transaction.date, default: []].append(transaction)
        }
        return dict.keys.sorted(by: >).map { (date: $0, transactions: dict[$0]!) }
    }
}

extension CategoryExpenseViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        groupedTransactions.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        groupedTransactions[section].transactions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ExpenseListViewCell.identifier, for: indexPath) as? ExpenseListViewCell else {
            return UITableViewCell()
        }
        let transaction = groupedTransactions[indexPath.section].transactions[indexPath.row]
        let isIncome = IncomeCategory(rawValue: categoryId) != nil
        let color = isIncome ? IncomeCategory.from(id: categoryId).color : ExpenseCategory.from(id: categoryId).color
        cell.configure(with: transaction, color: color, isIncome: isIncome)
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .systemBackground

        let label = UILabel()
        label.font = Typography.b7.uiFont
        label.textColor = .gray5
        label.text = formatDateForHeader(groupedTransactions[section].date)

        headerView.addSubview(label)
        label.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.bottom.equalToSuperview().offset(-8)
        }

        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }

    private func formatDateForHeader(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"

        guard let date = inputFormatter.date(from: dateString) else { return dateString }

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "yy년 MM월 dd일 EEEE"
        outputFormatter.locale = Locale(identifier: "ko_KR")

        return outputFormatter.string(from: date)
    }
}
