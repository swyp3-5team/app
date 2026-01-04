//
//  StatsViewController.swift
//  Cloverly
//
//  Created by wayblemac02 on 1/2/26.
//

import UIKit
import DGCharts
import SnapKit
import RxSwift
import RxCocoa

class StatsViewController: UIViewController {
    private let viewModel: CalendarViewModel
    private let disposeBag = DisposeBag()
    
    // ✨ 차트와 리스트가 공유할 색상 목록 (이미지 느낌의 파스텔톤)
    private let chartColors: [UIColor] = [
        UIColor(red: 0.2, green: 0.8, blue: 0.6, alpha: 1.0),  // 민트/초록 (식비)
        UIColor(red: 1.0, green: 0.8, blue: 0.4, alpha: 1.0),  // 노랑 (쇼핑)
        UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0),  // 파랑
        UIColor(red: 0.2, green: 0.8, blue: 0.8, alpha: 1.0),  // 청록
        UIColor(red: 1.0, green: 0.4, blue: 0.5, alpha: 1.0),  // 핑크/빨강
        UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)   // 회색
    ]
    
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "내역이 없습니다."
        label.font = .customFont(.pretendardMedium, size: 16)
        label.textColor = .gray
        label.textAlignment = .center
        label.isHidden = true // 처음엔 숨겨둠
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .customFont(.pretendardMedium, size: 14)
        label.textColor = .gray3
        return label
    }()
    
    private let totalAmount: UILabel = {
        let label = UILabel()
        label.font = .customFont(.pretendardSemiBold, size: 24)
        label.textColor = .gray1
        return label
    }()
    
    private let dividerView: UIView = {
        let view = UIView()
        view.backgroundColor = .gray9
        return view
    }()
    
    private lazy var pieChartView: PieChartView = {
        let chart = PieChartView()
        chart.usePercentValuesEnabled = true
        chart.drawEntryLabelsEnabled = true
        chart.holeColor = .white
        chart.transparentCircleColor = .clear
        chart.holeRadiusPercent = 0.4
        chart.transparentCircleRadiusPercent = 0.45
        
        chart.chartDescription.enabled = false
        chart.drawEntryLabelsEnabled = false
        chart.rotationEnabled = false
        chart.legend.enabled = false
        
        chart.animate(yAxisDuration: 1.0, easingOption: .easeInOutQuad)
        
        return chart
    }()
    
    private lazy var categoryTableView: UITableView = {
        let tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.rowHeight = 60 // 셀 높이를 넉넉하게
        tableView.register(CategoryTableViewCell.self, forCellReuseIdentifier: CategoryTableViewCell.identifier)
        return tableView
    }()
    
    lazy var segmented = CustomSegmentedControl(selectedIndex: viewModel.selectedIndex, items: ["수입", "지출"], cornerRadius: 17)
    
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
        navigationItem.title = "통계"
        
        viewModel.getCategoryStatistics(yearMonth: viewModel.currentDate.value)
    }
    
    func configureUI() {
        view.addSubview(dateLabel)
        view.addSubview(totalAmount)
        view.addSubview(dividerView)
        view.addSubview(pieChartView)
        view.addSubview(categoryTableView)
        view.addSubview(emptyStateLabel)
        
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
        
        pieChartView.snp.makeConstraints {
            $0.top.equalTo(dividerView.snp.bottom).offset(40)
            $0.centerX.equalToSuperview()
            $0.width.height.equalTo(200) // 차트 크기 적당히 조절
        }
        
        categoryTableView.snp.makeConstraints {
            $0.top.equalTo(pieChartView.snp.bottom).offset(40)
            $0.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        
        segmented.snp.makeConstraints {
            $0.width.equalTo(120)
            $0.height.equalTo(34)
        }
        
        emptyStateLabel.snp.makeConstraints {
            $0.center.equalTo(pieChartView)
        }
        
        let marker = CircleMarkerView()
        marker.chartView = pieChartView // 필수 연결
        pieChartView.marker = marker
    }
    
    func bind() {
        viewModel.categoryStatistics
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] stats in
                self?.updateHeader(stats: stats) // 총액 업데이트
                self?.setChartData(data: stats)
                self?.categoryTableView.reloadData()
            })
            .disposed(by: disposeBag)
    }
    
    private func updateHeader(stats: [CategoryStatistic]) {
        let total = stats.reduce(0) { $0 + $1.totalAmount }
        
        totalAmount.text = "\(total.withComma)원"
        
        // 날짜 라벨도 업데이트 (viewModel 날짜 가져와서)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M월 지출"
        dateLabel.text = dateFormatter.string(from: viewModel.currentDate.value)
    }
    
    func setChartData(data: [CategoryStatistic]) {
        if data.isEmpty {
            pieChartView.isHidden = true
            emptyStateLabel.isHidden = false
            
            pieChartView.data = nil
            return
        } else {
            pieChartView.isHidden = false
            emptyStateLabel.isHidden = true
        }
        
        let entries = data.map { PieChartDataEntry(value: $0.totalAmount, label: $0.categoryName) }
        let dataSet = PieChartDataSet(entries: entries, label: "")
        
        let colors = data.map { stat in
            return ExpenseCategory.from(id: stat.categoryId).color
        }
        
        dataSet.colors = colors
        dataSet.sliceSpace = 0 // 이미지처럼 딱 붙이려면 0, 살짝 떼려면 2
        dataSet.selectionShift = 10
        dataSet.drawValuesEnabled = false
        
        let chartData = PieChartData(dataSet: dataSet)
        pieChartView.data = chartData
        
//        if !data.isEmpty {
//            pieChartView.highlightValue(x: 0, dataSetIndex: 0)
//        }
    }
}

extension StatsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.categoryStatistics.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CategoryTableViewCell.identifier, for: indexPath) as? CategoryTableViewCell else {
            return UITableViewCell()
        }
        
        let stats = viewModel.categoryStatistics.value
        let item = stats[indexPath.row]
        
        // 퍼센트 계산
        let totalSum = stats.reduce(0.0) { $0 + $1.totalAmount }
        let percentage = totalSum == 0 ? 0 : (item.totalAmount / totalSum) * 100
        
        let color = ExpenseCategory.from(id: item.categoryId).color
        
        cell.configure(color: color, name: item.categoryName, amount: item.totalAmount, percent: percentage, categoryId: item.categoryId)
        
        return cell
    }
}
