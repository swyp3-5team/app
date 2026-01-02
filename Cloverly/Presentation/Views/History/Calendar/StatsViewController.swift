//
//  StatsViewController.swift
//  Cloverly
//
//  Created by wayblemac02 on 1/2/26.
//

import UIKit
import DGCharts
import SnapKit

class StatsViewController: UIViewController {
    private let viewModel: CalendarViewModel
    
    private lazy var pieChartView: PieChartView = {
        let chart = PieChartView()
        chart.usePercentValuesEnabled = true
        chart.drawEntryLabelsEnabled = true
        chart.holeColor = .white
        chart.transparentCircleColor = .clear
        chart.holeRadiusPercent = 0.4
        chart.transparentCircleRadiusPercent = 0.45
        
        chart.chartDescription.enabled = false
        
        chart.legend.enabled = false
//        chart.legend.horizontalAlignment = .center
//        chart.legend.verticalAlignment = .bottom
//        chart.legend.orientation = .horizontal
//        chart.legend.drawInside = false
//        chart.legend.font = .systemFont(ofSize: 17)
        
        chart.animate(yAxisDuration: 1.0, easingOption: .easeInOutQuad)
        
        return chart
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
        setChartData()
        navigationItem.titleView = segmented
    }
    
    func configureUI() {
        view.addSubview(pieChartView)
        
        pieChartView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(20)
            $0.centerX.equalToSuperview()
            $0.width.height.equalTo(300)
        }
        
        segmented.snp.makeConstraints {
            $0.width.equalTo(120)
            $0.height.equalTo(34)
        }
    }
    
    func setChartData() {
        let entries: [PieChartDataEntry] = [
            PieChartDataEntry(value: 40, label: "식비"),
            PieChartDataEntry(value: 30, label: "쇼핑"),
            PieChartDataEntry(value: 20, label: "교통"),
            PieChartDataEntry(value: 10, label: "기타")
        ]
        
        let dataSet = PieChartDataSet(entries: entries, label: "")
        
        // 색상 지정 (순서대로 적용됨)
        dataSet.colors = [
            .systemRed,
            .systemBlue,
            .systemGreen,
            .systemGray
        ]
        
        // 조각(Slice) 간의 간격
//        dataSet.sliceSpace = 0
        
        // 선택 시 커지는 효과
        dataSet.selectionShift = 10
        
        // 데이터 값 텍스트 스타일
        dataSet.valueFont = .boldSystemFont(ofSize: 12)
        dataSet.valueTextColor = .white
        
        // 4. 최종 데이터 주입
        let data = PieChartData(dataSet: dataSet)
        
        // (선택) 숫자를 소수점 없이 깔끔하게 보여주기 포맷터
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        formatter.multiplier = 1.0
        data.setValueFormatter(DefaultValueFormatter(formatter: formatter))
        
        pieChartView.data = data
        
        // 가장 많은 비율에 커져보이게
  
    }
}
