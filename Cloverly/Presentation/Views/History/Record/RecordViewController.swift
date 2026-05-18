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
import GoogleMobileAds

class RecordViewController: UIViewController {
    private let viewModel: CalendarViewModel
    private let disposeBag = DisposeBag()
    private var isMenuOpen = false
    
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

    private lazy var filterButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = "전체 내역"
        config.baseForegroundColor = .gray2
        config.baseBackgroundColor = .clear
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0)
        
        config.image = UIImage(named: "filter")
        
        let attributes: AttributeContainer = {
            var container = AttributeContainer()
            container.font = Typography.b5.uiFont
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
        button.titleLabel?.font = Typography.b5.uiFont
        button.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }
            viewModel.clearCurrentTransaction()
            let vc = TransactionContainerViewController(viewModel: viewModel)
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        }, for: .touchUpInside)
        return button
    }()
    
    private lazy var bannerView: BannerView = {
        let bannerWidth = UIScreen.main.bounds.width - 32
        let adSize = portraitAnchoredAdaptiveBanner(width: bannerWidth)
        let banner = BannerView(adSize: adSize, origin: .zero)
        banner.adUnitID = "ca-app-pub-8889421922972515/2490079929"
//        banner.adUnitID = "ca-app-pub-3940256099942544/2934735716" // test
        banner.rootViewController = self
        banner.layer.cornerRadius = 8
        banner.clipsToBounds = true
        return banner
    }()
    
    private lazy var floatingButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "plus icon"), for: .normal)
        button.backgroundColor = .green5
        button.layer.cornerRadius = 28 // half
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.2
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.layer.shadowRadius = 4
        
        button.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }
            isMenuOpen.toggle()
            updateMenuState()
        }, for: .touchUpInside)
        return button
    }()
    
    private lazy var menuCardView: MenuCardView = {
        let card = MenuCardView(items: [
//            MenuItem(title: "단일 품목") { [weak self] in
//                print("단일 품목 선택")
//            },
            MenuItem(title: "내역 추가") { [weak self] in
                guard let self = self else { return }
                viewModel.clearCurrentTransaction()
                let vc = TransactionContainerViewController(viewModel: viewModel)
                let nav = UINavigationController(rootViewController: vc)
                nav.modalPresentationStyle = .fullScreen
                present(nav, animated: true)
            }
        ])
        return card
    }()

    private let dimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        return view
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.backgroundColor = .white
        tableView.separatorStyle = .none
        tableView.register(ExpenseListViewCell.self, forCellReuseIdentifier: ExpenseListViewCell.identifier)
        tableView.sectionHeaderTopPadding = 0
        
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
        
        bannerView.load(Request())
        
        print("banner adSize: \(bannerView.adSize)")
        print("banner frame: \(bannerView.frame)")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        closeMenu()
    }
    
    func configureUI() {
        view.addSubview(tableView)
        view.addSubview(floatingButton)

        tableView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        // 헤더 추가
        let headerContainer = UIView()
        headerContainer.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 400)
        
        [prevButton, headerLabel, nextButton, statsButton,
         incomeRowStack, expenseRowStack, balanceRowStack, filterButton, bannerView].forEach {
            headerContainer.addSubview($0)
        }
        
        headerLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(24)
            $0.leading.equalTo(prevButton.snp.trailing).offset(8)
        }
        
        prevButton.snp.makeConstraints {
            $0.centerY.equalTo(headerLabel)
            $0.leading.equalToSuperview().offset(16)
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
            $0.top.equalTo(statsButton.snp.bottom).offset(20)
        }

        expenseRowStack.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.top.equalTo(incomeRowStack.snp.bottom).offset(8)
        }

        balanceRowStack.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalTo(expenseRowStack)
        }

        let bannerWidth = UIScreen.main.bounds.width - 32
        let adSize = portraitAnchoredAdaptiveBanner(width: bannerWidth)
        bannerView.snp.makeConstraints {
            $0.top.equalTo(expenseRowStack.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(adSize.size.height)
        }
        
        filterButton.snp.makeConstraints {
            $0.top.equalTo(bannerView.snp.bottom).offset(20)
            $0.leading.equalToSuperview().offset(16)
            $0.bottom.equalToSuperview().inset(22)
        }
        
        floatingButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-16)
            $0.width.height.equalTo(56)
        }

        headerContainer.layoutIfNeeded()
        let size = headerContainer.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        headerContainer.frame.size.height = size.height
        
        tableView.tableHeaderView = headerContainer
    }
    
    private func bind() {
        // ✨ ViewModel의 날짜가 바뀌면 -> 헤더 라벨도 자동으로 바뀜
        viewModel.currentDate
            .observe(on: MainScheduler.instance) // UI 업데이트니까 메인 스레드 보장
            .subscribe(onNext: { [weak self] date in
                let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale(identifier: "ko_KR")
                
                let currentYear = Calendar.current.component(.year, from: Date())
                let targetYear = Calendar.current.component(.year, from: date)
                
                if currentYear == targetYear {
                    dateFormatter.dateFormat = "M월"
                } else {
                    dateFormatter.dateFormat = "yy년 M월"
                }
                
                self?.headerLabel.text = dateFormatter.string(from: date)
                
                // 만약 이 화면에 데이터를 불러오는 API 호출이 필요하다면 여기서 호출!
                // self?.viewModel.getStatistics(yearMonth: date)
            })
            .disposed(by: disposeBag)
        
        viewModel.monthlyExpenseAmounts
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] amounts in
                let total = amounts.values.reduce(0, +)
                self?.expenseLabel.text = total > 0 ? "-\(total.withComma)원" : "0원"
            })
            .disposed(by: disposeBag)

        viewModel.monthlyIncomeAmounts
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] amounts in
                let total = amounts.values.reduce(0, +)
                self?.incomeLabel.text = total > 0 ? "+\(total.withComma)원" : "0원"
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

        viewModel.filteredTransactions
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.tableView.reloadData()
                self.updateFilterButtonText()
            })
            .disposed(by: disposeBag)
    }
    
    private func updateFilterButtonText() {
        let totalCount = viewModel.selectedCategories.value.count + viewModel.selectedIncomeCategories.value.count
        let isFilterActive = totalCount > 0
        let titleText = isFilterActive ? "필터 \(totalCount)" : "전체 내역"
        
        guard var config = filterButton.configuration else { return }
        
        var container = AttributeContainer()
        container.font = Typography.b5.uiFont
        container.foregroundColor = isFilterActive ? .green5 : .gray2
        
        config.attributedTitle = AttributedString(titleText, attributes: container)
        config.image = UIImage(named: "filter")?.withTintColor(isFilterActive ? .green5 : .gray2, renderingMode: .alwaysOriginal)
        
        filterButton.configuration = config
    }
    
    private func updateMenuState() {
        if isMenuOpen {
            showMenu()
        } else {
            hideMenu()
        }
    }

    private func showMenu() {
        guard let window = view.window else { return }
        let fabFrame = floatingButton.convert(floatingButton.bounds, to: window)

        floatingButton.setImage(UIImage(named: "x icon"), for: .normal)
        floatingButton.backgroundColor = .white

        floatingButton.removeFromSuperview()
        floatingButton.translatesAutoresizingMaskIntoConstraints = true
        floatingButton.frame = fabFrame

        let cardWidth: CGFloat = 92
        let cardHeight: CGFloat = 76
        menuCardView.frame = CGRect(
            x: fabFrame.maxX - cardWidth,
            y: fabFrame.minY - cardHeight - 12,
            width: cardWidth,
            height: cardHeight
        )

        dimmingView.frame = window.bounds
        dimmingView.alpha = 0
        menuCardView.alpha = 0
        menuCardView.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
            .concatenating(CGAffineTransform(translationX: 0, y: 12))

        window.addSubview(dimmingView)
        window.addSubview(menuCardView)
        window.addSubview(floatingButton)

        let tap = UITapGestureRecognizer(target: self, action: #selector(closeMenu))
        dimmingView.addGestureRecognizer(tap)

        UIView.animate(withDuration: 0.25) {
            self.dimmingView.alpha = 1
        }
        UIView.animate(withDuration: 0.4, delay: 0,
                       usingSpringWithDamping: 0.65, initialSpringVelocity: 0.8,
                       options: [], animations: {
            self.menuCardView.alpha = 1
            self.menuCardView.transform = .identity
        })
    }

    private func hideMenu() {
        UIView.animate(withDuration: 0.2, animations: {
            self.dimmingView.alpha = 0
            self.menuCardView.alpha = 0
            self.menuCardView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
                .concatenating(CGAffineTransform(translationX: 0, y: 8))
        }, completion: { _ in
            self.dimmingView.gestureRecognizers?.forEach { self.dimmingView.removeGestureRecognizer($0) }
            self.dimmingView.removeFromSuperview()
            self.menuCardView.removeFromSuperview()
            self.menuCardView.transform = .identity

            self.floatingButton.setImage(UIImage(named: "plus icon"), for: .normal)
            self.floatingButton.backgroundColor = .green5

            self.floatingButton.removeFromSuperview()
            self.floatingButton.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(self.floatingButton)
            self.floatingButton.snp.makeConstraints {
                $0.trailing.equalToSuperview().offset(-16)
                $0.bottom.equalTo(self.view.safeAreaLayoutGuide).offset(-16)
                $0.width.height.equalTo(56)
            }
        })
    }

    @objc private func closeMenu() {
        isMenuOpen = false
        updateMenuState()
    }
}

extension RecordViewController: UITableViewDataSource, UITableViewDelegate {
    // 1. 섹션 개수
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.filteredTransactions.value.keys.count
    }
    
    // 2. 섹션당 행 개수
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let dateKey = viewModel.sortedDateKeys[section]
        
        // 필터링된 데이터에서 해당 날짜의 리스트 꺼내기
        return viewModel.filteredTransactions.value[dateKey]?.count ?? 0
    }
    
    // 3. 셀 구성
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ExpenseListViewCell.identifier, for: indexPath) as? ExpenseListViewCell else {
            return UITableViewCell()
        }
        
        let dateKey = viewModel.sortedDateKeys[indexPath.section]
        
        // ② 해당 날짜의 데이터 리스트 가져오기
        if let transactions = viewModel.filteredTransactions.value[dateKey] {
            let transaction = transactions[indexPath.row] // ③ 행(Row)에 맞는 데이터 찾기
            cell.configure(with: transaction)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let dateKey = viewModel.sortedDateKeys[indexPath.section]
        
        if let transactions = viewModel.filteredTransactions.value[dateKey] {
            let transaction = transactions[indexPath.row]
            viewModel.currentTransaction.accept(transaction)
            let vc = TransactionContainerViewController(viewModel: viewModel)
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        }
    }
    
    // 4. 헤더 뷰
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .white
        
        let label = UILabel()
        label.font = Typography.b7.uiFont
        label.textColor = .gray5
        
        // ① 정렬된 키 목록에서 현재 섹션의 날짜 가져오기
        let dateKey = viewModel.sortedDateKeys[section]
        
        // ② 포맷팅
        label.text = formatDateForHeader(dateKey)
        
        headerView.addSubview(label)
        label.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.bottom.equalToSuperview().offset(-8)
        }
        
        return headerView
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
        return 22
    }
}
