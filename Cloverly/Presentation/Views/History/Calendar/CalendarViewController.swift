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
    private let viewModel = CalendarViewModel()
    private let disposeBag = DisposeBag()
    
    private lazy var headerLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 18)
        label.textColor = .black
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy년 MM월"
        dateFormatter.locale = Locale(identifier: "ko_KR")
        label.text = dateFormatter.string(from: calendar.currentPage)
        return label
    }()
    
    private lazy var prevButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = .black
        button.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }
            let currentPage = calendar.currentPage
                guard let prevPage = Calendar.current.date(byAdding: .month, value: -1, to: currentPage) else { return }
                calendar.setCurrentPage(prevPage, animated: true)
        }, for: .touchUpInside)
        return button
    }()

    private lazy var nextButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        button.tintColor = .black
        button.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }
            let currentPage = calendar.currentPage
                guard let prevPage = Calendar.current.date(byAdding: .month, value: 1, to: currentPage) else { return }
                calendar.setCurrentPage(prevPage, animated: true)
        }, for: .touchUpInside)
        return button
    }()
    
    private lazy var statsButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "통계"
        config.baseBackgroundColor = .gray6
        config.baseForegroundColor = .black
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        
        let button = UIButton(configuration: config)
        button.layer.cornerRadius = 12
        button.clipsToBounds = true
        return button
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
    
    let expenses: [String: String] = [
            "2025-12-25": "-50,000",
            "2025-12-30": "-12,000"
        ]
    
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
        view.addSubview(calendar)
        
        prevButton.snp.makeConstraints {
            $0.centerY.equalTo(headerLabel)
            $0.leading.equalToSuperview().offset(16)
        }
        
        headerLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            $0.leading.equalTo(prevButton.snp.trailing).offset(20)
        }
        
        nextButton.snp.makeConstraints {
            $0.centerY.equalTo(headerLabel)
            $0.leading.equalTo(headerLabel.snp.trailing).offset(20)
        }
        
        statsButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalTo(headerLabel)
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
    }

    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        self.viewModel.isSheetPresent.accept(true)
    }
    
    func configureCell(_ cell: FSCalendarCell?, for date: Date?, at position: FSCalendarMonthPosition) {
        
    }
    
    func calendar(_ calendar: FSCalendar, cellFor date: Date, at position: FSCalendarMonthPosition) -> FSCalendarCell {
        let cell = calendar.dequeueReusableCell(withIdentifier: CalendarCell.identifier, for: date, at: position) as! CalendarCell
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        // 데이터가 있다면 라벨에 표시
        if let expense = expenses[dateString] {
            cell.configure(with: expense)
        }
        
        return cell
    }
    
    func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
        let currentPage = calendar.currentPage
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy년 MM월"
        dateFormatter.locale = Locale(identifier: "ko_KR")
        
        self.headerLabel.text = dateFormatter.string(from: currentPage)
    }
}
