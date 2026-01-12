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
    
    private lazy var headerLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 18)
        label.textColor = .black
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
    
    private let expenseLabel: UILabel = {
        let label = UILabel()
        label.font = .customFont(.pretendardSemiBold, size: 18)
        label.textColor = .gray1
        return label
    }()
    
    private let incomeLabel: UILabel = {
        let label = UILabel()
        label.font = .customFont(.pretendardSemiBold, size: 18)
        label.textColor = .green5
        label.text = "수입 0원"
        return label
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
        view.addSubview(expenseLabel)
        //        view.addSubview(incomeLabel)
        view.addSubview(dividerView)
        view.addSubview(calendar)
        
        prevButton.snp.makeConstraints {
            $0.centerY.equalTo(headerLabel)
            $0.leading.equalToSuperview().offset(16)
        }
        
        headerLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(20)
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
        
        expenseLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.top.equalTo(statsButton.snp.bottom).offset(12)
        }
        
        // 수입 일단 제거
        //        incomeLabel.snp.makeConstraints {
        //            $0.leading.equalToSuperview().offset(16)
        //            $0.top.equalTo(expenseLabel.snp.bottom).offset(8)
        //        }
        
        dividerView.snp.makeConstraints {
            $0.top.equalTo(expenseLabel.snp.bottom).offset(20)
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
        
        viewModel.dailyTotalAmounts
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] amounts in
                let total = amounts.values.reduce(0, +)
                self?.expenseLabel.text = total > 0 ? "지출 -\(total.withComma)원" : "지출 0원"
                self?.calendar.reloadData()
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
        
        // 데이터가 있다면 라벨에 표시
        if let totalAmount = viewModel.dailyTotalAmounts.value[dateString] {
            // 세자리 콤마 포맷팅
            cell.configure(with: "-\(totalAmount.withComma)")
        } else {
            cell.configure(with: "")
        }
        
        return cell
    }
    
    func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
        viewModel.updateDate(calendar.currentPage)
    }
}
