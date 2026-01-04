//
//  RecordViewController.swift
//  Cloverly
//
//  Created by 이인호 on 12/31/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

class RecordViewController: UIViewController {
    private let viewModel: CalendarViewModel
    private let disposeBag = DisposeBag()
    
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
            guard let prevDate = Calendar.current.date(byAdding: .month, value: -1, to: current) else { return }
            self.viewModel.updateDate(prevDate)
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
            guard let nextDate = Calendar.current.date(byAdding: .month, value: 1, to: current) else { return }
            self.viewModel.updateDate(nextDate)
        }, for: .touchUpInside)
        return button
    }()
    
    private lazy var statsButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "통계"
        config.baseForegroundColor = .gray2
        config.baseBackgroundColor = .gray9
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        
        config.image = UIImage(named: "Analytics Icon")
        
        config.imagePlacement = .leading
        config.imagePadding = 4
        
        let button = UIButton(configuration: config)
        button.layer.cornerRadius = 32
        button.clipsToBounds = true
        
        button.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }
            let vc = StatsViewController(viewModel: viewModel)
            self.navigationController?.pushViewController(vc, animated: true)
        }, for: .touchUpInside)
        
        return button
    }()
    
    private lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "recordBackground"))
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    private lazy var greetingLabel: UILabel = {
        let label = UILabel()
        let nickname = AuthViewModel.shared.currentUser.value?.nickName ?? "사용자"
        label.text = "\(nickname)님, 만나서 반가워요!\n이번 달 지출 내역을 확인해보세요"
        label.font = .customFont(.pretendardSemiBold, size: 16)
        label.textColor = .gray1
        label.numberOfLines = 0
        return label
    }()
    
    private let expenseTextLabel: UILabel = {
        let label = UILabel()
        label.text = "지출"
        label.font = .customFont(.pretendardMedium, size: 14)
        label.textColor = .gray4
        return label
    }()
    
    private let expenseLabel: UILabel = {
        let label = UILabel()
        label.font = .customFont(.pretendardSemiBold, size: 22)
        label.textColor = .gray1
        return label
    }()
    
    private lazy var filterButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "전체 내역"
        config.baseForegroundColor = .gray2
        config.baseBackgroundColor = .clear
        config.contentInsets = .zero
        
        config.image = UIImage(named: "filter")
        
        let attributes: AttributeContainer = {
            var container = AttributeContainer()
            container.font = .customFont(.pretendardSemiBold, size: 14)
            return container
        }()

        config.attributedTitle = AttributedString("전체 내역", attributes: attributes)
        
        config.imagePlacement = .leading
        config.imagePadding = 4
        
        let button = UIButton(configuration: config)
        button.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }
            let vc = FilterViewController(viewModel: viewModel)
            let nav = UINavigationController(rootViewController: vc)
            
            if let sheet = nav.sheetPresentationController {
                sheet.detents = [.medium()]
            }
            present(nav, animated: true)
        }, for: .touchUpInside)
        return button
    }()
    
    private lazy var addButton: UIButton = {
        let button = UIButton()
        button.setTitle("내역 추가", for: .normal)
        button.setTitleColor(.blueConfirm, for: .normal)
        button.titleLabel?.font = .customFont(.pretendardSemiBold, size: 14)
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
        let tableView = UITableView(frame: .zero, style: .grouped) // ✨ 헤더를 쓰려면 .grouped 추천
        tableView.backgroundColor = .white
        tableView.separatorStyle = .none // 구분선 제거 (이미지처럼 깔끔하게)
        tableView.register(ExpenseListViewCell.self, forCellReuseIdentifier: ExpenseListViewCell.identifier)
        tableView.sectionHeaderTopPadding = 0 // 헤더 위 여백 제거
        
        tableView.delegate = self
        tableView.dataSource = self
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
    }
    
    func configureUI() {
        view.addSubview(prevButton)
        view.addSubview(headerLabel)
        view.addSubview(nextButton)
        view.addSubview(statsButton)
        view.addSubview(backgroundImageView)
        view.addSubview(greetingLabel)
        view.addSubview(expenseTextLabel)
        view.addSubview(expenseLabel)
        view.addSubview(filterButton)
        view.addSubview(addButton)
        view.addSubview(tableView)
        
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
        
        backgroundImageView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.top.equalTo(statsButton.snp.bottom).offset(24)
        }
        
        greetingLabel.snp.makeConstraints {
            $0.top.equalTo(backgroundImageView.snp.top).offset(20)
            $0.leading.equalTo(backgroundImageView.snp.leading).offset(16)
        }
        
        expenseTextLabel.snp.makeConstraints {
            $0.bottom.equalTo(expenseLabel.snp.top).offset(-4)
            $0.leading.equalTo(backgroundImageView.snp.leading).offset(16)
        }
        
        expenseLabel.snp.makeConstraints {
            $0.bottom.equalTo(backgroundImageView.snp.bottom).offset(-20)
            $0.leading.equalTo(backgroundImageView.snp.leading).offset(16)
        }
        
        filterButton.snp.makeConstraints {
            $0.top.equalTo(backgroundImageView.snp.bottom).offset(30)
            $0.leading.equalToSuperview().offset(16)
        }
        
        addButton.snp.makeConstraints {
            $0.centerY.equalTo(filterButton.snp.centerY)
            $0.trailing.equalToSuperview().offset(-16)
        }
        
        tableView.snp.makeConstraints {
            $0.top.equalTo(addButton.snp.bottom).offset(14)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    private func bind() {
        // ✨ ViewModel의 날짜가 바뀌면 -> 헤더 라벨도 자동으로 바뀜
        viewModel.currentDate
            .observe(on: MainScheduler.instance) // UI 업데이트니까 메인 스레드 보장
            .subscribe(onNext: { [weak self] date in
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "M월" // "01월"이 싫으면 "M월"로
                dateFormatter.locale = Locale(identifier: "ko_KR")
                
                self?.headerLabel.text = dateFormatter.string(from: date)
                
                // 만약 이 화면에 데이터를 불러오는 API 호출이 필요하다면 여기서 호출!
                // self?.viewModel.getStatistics(yearMonth: date)
            })
            .disposed(by: disposeBag)
        
        viewModel.dailyTotalAmounts
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] amounts in
                let total = amounts.values.reduce(0, +)
                self?.expenseLabel.text = total > 0 ? "지출 -\(total.withComma)원" : "지출 0원"
            })
            .disposed(by: disposeBag)
        
        viewModel.filteredTransactions
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.tableView.reloadData()
            })
            .disposed(by: disposeBag)
        
        viewModel.selectedCategories
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] categories in
                self?.updateFilterButtonText(categories: categories)
            })
            .disposed(by: disposeBag)
    }
    
    private func updateFilterButtonText(categories: Set<ExpenseCategory>) {
        // 1. 표시할 텍스트 결정
        let titleText: String
        let isFilterActive = !categories.isEmpty
        
        if categories.isEmpty {
            titleText = "전체 내역"
        } else {
            titleText = "필터 \(categories.count)"
        }
        
        guard var config = filterButton.configuration else { return }
        
        var container = AttributeContainer()
        container.font = .customFont(.pretendardSemiBold, size: 14)
        container.foregroundColor = isFilterActive ? .green5 : .gray2
        
        config.attributedTitle = AttributedString(titleText, attributes: container)
        
        filterButton.configuration = config
    }
}

extension RecordViewController: UITableViewDataSource, UITableViewDelegate {
    // 1. 섹션 개수
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.filteredTransactions.value.keys.count
    }
    
    // 2. 섹션당 행 개수
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sortedKeys = getSortedDateKeys() // 정렬된 키 목록 가져오기
        let dateKey = sortedKeys[section]    // 현재 섹션의 날짜 키
        
        // 필터링된 데이터에서 해당 날짜의 리스트 꺼내기
        return viewModel.filteredTransactions.value[dateKey]?.count ?? 0
    }
    
    // 3. 셀 구성
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ExpenseListViewCell.identifier, for: indexPath) as? ExpenseListViewCell else {
            return UITableViewCell()
        }
        
        let sortedKeys = getSortedDateKeys()
        let dateKey = sortedKeys[indexPath.section] // ① 섹션 날짜 키 찾기
        
        // ② 해당 날짜의 데이터 리스트 가져오기
        if let transactions = viewModel.filteredTransactions.value[dateKey] {
            let transaction = transactions[indexPath.row] // ③ 행(Row)에 맞는 데이터 찾기
            cell.configure(with: transaction)
        }
        
        return cell
    }
    
    // 4. 헤더 뷰
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .white
        
        let label = UILabel()
        label.font = .customFont(.pretendardRegular, size: 14)
        label.textColor = .gray3
        
        // ① 정렬된 키 목록에서 현재 섹션의 날짜 가져오기
        let sortedKeys = getSortedDateKeys()
        let dateString = sortedKeys[section]
        
        // ② 포맷팅
        label.text = formatDateForHeader(dateString)
        
        headerView.addSubview(label)
        label.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.bottom.equalToSuperview().offset(-8)
        }
        
        return headerView
    }
    
    private func getSortedDateKeys() -> [String] {
        return viewModel.filteredTransactions.value.keys.sorted(by: >)
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
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
}
