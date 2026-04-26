//
//  CalendarViewController.swift
//  Cloverly
//
//  Created by 이인호 on 12/31/25.
//

import UIKit
import SnapKit
import FSCalendar
import RxSwift
import RxCocoa

class CalendarViewController: UIViewController, FSCalendarDataSource, FSCalendarDelegate {
    private let viewModel: CalendarViewModel
    private let disposeBag = DisposeBag()
    
    init(viewModel: CalendarViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    private lazy var headerLabel: AppLabel = {
        let label = AppLabel()
        label.textColor = .gray1
        label.typography = .h2
        return label
    }()
    
    private lazy var prevButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "Calendar Navigation Arrow left"), for: .normal)
        button.tintColor = .black
        button.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }
            let current = self.viewModel.currentDate.value
            guard let prevPage = Calendar.current.date(byAdding: .month, value: -1, to: current) else { return }
            self.viewModel.updateDate(prevPage)
        }, for: .touchUpInside)
        return button
    }()
    
    private lazy var nextButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "Calendar Navigation Arrow right"), for: .normal)
        button.tintColor = .black
        button.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }
            let current = self.viewModel.currentDate.value
            guard let nextPage = Calendar.current.date(byAdding: .month, value: 1, to: current) else { return }
            self.viewModel.updateDate(nextPage)
        }, for: .touchUpInside)
        return button
    }()
    
    private lazy var statsButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "통계"
        config.baseForegroundColor = .gray2
        config.baseBackgroundColor = .gray9
        config.baseForegroundColor = .black
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        
        config.image = UIImage(named: "Analytics Icon")
        
        config.imagePlacement = .leading
        config.imagePadding = 4
        config.cornerStyle = .capsule
        let button = UIButton(configuration: config)
        
        button.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }
            let vc = StatsViewController(viewModel: viewModel)
            self.navigationController?.pushViewController(vc, animated: true)
        }, for: .touchUpInside)
        
        return button
    }()
    
    private let expenseTextLabel: AppLabel = {
        let label = AppLabel()
        label.text = "지출"
        label.textColor = .gray4
        label.typography = .b6
        return label
    }()

    private let expenseLabel: AppLabel = {
        let label = AppLabel()
        label.textColor = .gray1
        label.typography = .t1
        return label
    }()

    private lazy var expenseRowStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [expenseTextLabel, expenseLabel])
        stack.axis = .horizontal
        stack.alignment = .bottom
        stack.spacing = 8
        return stack
    }()

    private let incomeTextLabel: AppLabel = {
        let label = AppLabel()
        label.text = "수입"
        label.textColor = .gray4
        label.typography = .b6
        return label
    }()

    private let incomeLabel: AppLabel = {
        let label = AppLabel()
        label.textColor = .green5
        label.typography = .t1
        return label
    }()

    private lazy var incomeRowStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [incomeTextLabel, incomeLabel])
        stack.axis = .horizontal
        stack.alignment = .bottom
        stack.spacing = 8
        return stack
    }()

    private let balanceTextLabel: AppLabel = {
        let label = AppLabel()
        label.text = "잔액"
        label.textColor = .gray4
        label.typography = .b6
        return label
    }()

    private let balanceLabel: AppLabel = {
        let label = AppLabel()
        label.textColor = .gray1
        label.typography = .t1
        return label
    }()

    private lazy var balanceRowStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [balanceTextLabel, balanceLabel])
        stack.axis = .horizontal
        stack.alignment = .bottom
        stack.spacing = 8
        return stack
    }()

    private let dividerView: UIView = {
        let view = UIView()
        view.backgroundColor = .gray9
        return view
    }()
    
    private lazy var calendar: FSCalendar = {
        let calendar = FSCalendar()
        calendar.locale = Locale(identifier: "ko_KR")
        calendar.today = nil
        calendar.placeholderType = .none
        calendar.headerHeight = 0
        calendar.appearance.weekdayTextColor = .gray6
        calendar.appearance.selectionColor = .green5
        calendar.scrollEnabled = false
        calendar.dataSource = self
        calendar.delegate = self
        calendar.register(CalendarCell.self, forCellReuseIdentifier: CalendarCell.identifier)
        calendar.select(Date())
        return calendar
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bind()
    }
    
    func configureUI() {
        view.addSubview(prevButton)
        view.addSubview(headerLabel)
        view.addSubview(nextButton)
        view.addSubview(statsButton)
        view.addSubview(incomeRowStack)
        view.addSubview(expenseRowStack)
        view.addSubview(balanceRowStack)
        view.addSubview(dividerView)
        view.addSubview(calendar)

        prevButton.snp.makeConstraints {
            $0.centerY.equalTo(headerLabel)
            $0.leading.equalToSuperview().offset(16)
        }

        headerLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(24)
            $0.leading.equalTo(prevButton.snp.trailing).offset(8)
        }

        nextButton.snp.makeConstraints {
            $0.centerY.equalTo(headerLabel)
            $0.leading.equalTo(headerLabel.snp.trailing).offset(8)
        }

        statsButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalTo(headerLabel)
        }

        incomeRowStack.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.top.equalTo(statsButton.snp.bottom).offset(12)
        }

        expenseRowStack.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.top.equalTo(incomeRowStack.snp.bottom).offset(8)
        }

        balanceRowStack.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalTo(expenseRowStack)
        }

        dividerView.snp.makeConstraints {
            $0.top.equalTo(expenseRowStack.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(6)
        }

        calendar.snp.makeConstraints {
            $0.top.equalTo(headerLabel.snp.bottom).offset(100)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-16)
        }
    }
    
    func bind() {
        viewModel.isSheetPresent
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isPresent in
                guard let self = self else { return }
                
                if isPresent {
                    let vc = ExpenseListViewController(viewModel: viewModel)
                    let nav = UINavigationController(rootViewController: vc)
                    
                    if let sheet = nav.sheetPresentationController {
                        sheet.detents = [.medium()]
                    }
                    present(nav, animated: true)
                } else {
                    self.becomeFirstResponder()
                    dismiss(animated: true)
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.currentDate
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] date in
                guard let self = self else { return }
                let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale(identifier: "ko_KR")
                
                let currentYear = Calendar.current.component(.year, from: Date())
                let targetYear = Calendar.current.component(.year, from: date)
                
                if currentYear == targetYear {
                    dateFormatter.dateFormat = "M월"
                } else {
                    dateFormatter.dateFormat = "yy년 M월"
                }
                
                self.headerLabel.text = dateFormatter.string(from: date)
                
                if !Calendar.current.isDate(self.calendar.currentPage, equalTo: date, toGranularity: .month) {
                    self.calendar.setCurrentPage(date, animated: true)
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.monthlyExpenseAmounts
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] amounts in
                let total = amounts.values.reduce(0, +)
                self?.expenseLabel.text = total > 0 ? "-\(total.withComma)원" : "0원"
                self?.calendar.reloadData()
            })
            .disposed(by: disposeBag)
        
        viewModel.monthlyIncomeAmounts
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] amounts in
                let total = amounts.values.reduce(0, +)
                self?.incomeLabel.text = total > 0 ? "+\(total.withComma)원": "0원"
                self?.calendar.reloadData()
            })
            .disposed(by: disposeBag)

        Observable.combineLatest(viewModel.monthlyExpenseAmounts, viewModel.monthlyIncomeAmounts)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] expenseAmounts, incomeAmounts in
                let expenseTotal = expenseAmounts.values.reduce(0, +)
                let incomeTotal = incomeAmounts.values.reduce(0, +)
                let balance = incomeTotal - expenseTotal
                if balance > 0 {
                    self?.balanceLabel.text = "+\(balance.withComma)원"
                } else if balance < 0 {
                    self?.balanceLabel.text = "-\((-balance).withComma)원"
                } else {
                    self?.balanceLabel.text = "0원"
                }
            })
            .disposed(by: disposeBag)
    }
    
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        self.viewModel.selectedDate.accept(date)
        self.viewModel.isSheetPresent.accept(true)
    }
    
    // 내역 없는 날은 선택 안되게
//    func calendar(_ calendar: FSCalendar, shouldSelect date: Date, at monthPosition: FSCalendarMonthPosition) -> Bool {
//        let dateString = dateFormatter.string(from: date)
//
//        return viewModel.dailyTotalAmounts.value[dateString] != nil
//    }
    
    func calendar(_ calendar: FSCalendar, cellFor date: Date, at position: FSCalendarMonthPosition) -> FSCalendarCell {
        let cell = calendar.dequeueReusableCell(withIdentifier: CalendarCell.identifier, for: date, at: position) as! CalendarCell
        
        let dateString = dateFormatter.string(from: date)
        
        let expenseText = viewModel.monthlyExpenseAmounts.value[dateString].map { "-\($0.withComma)" } ?? ""
        let incomeText = viewModel.monthlyIncomeAmounts.value[dateString].map { "+\($0.withComma)" } ?? ""
        cell.configure(expense: expenseText, income: incomeText)
        
        return cell
    }
    
    func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
        viewModel.updateDate(calendar.currentPage)
    }
}
