//
//  CircleMarkerView.swift
//  Cloverly
//
//  Created by 이인호 on 1/3/26.
//

import UIKit
import DGCharts
import SnapKit

class CircleMarkerView: MarkerView {
    
    // 1. 하얀색 배경 원
    private let bgView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 35 // width(70)의 절반
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowOpacity = 0.15
        view.layer.shadowRadius = 4
        return view
    }()
    
    // 2. 카테고리 이름 (예: 식비)
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .customFont(.pretendardSemiBold, size: 12)
        label.textColor = .gray1
        label.textAlignment = .center
        return label
    }()
    
    // 3. 퍼센트 (예: 21%)
    private let percentLabel: UILabel = {
        let label = UILabel()
        label.font = .customFont(.pretendardSemiBold, size: 16)
        label.textAlignment = .center
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // 마커의 크기 지정 (70x70 정원)
        self.frame = CGRect(x: 0, y: 0, width: 70, height: 70)
        
        addSubview(bgView)
        bgView.addSubview(nameLabel)
        bgView.addSubview(percentLabel)
        
        bgView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        // 텍스트 위치 잡기 (수직 스택 느낌)
        nameLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(16)
        }
        
        percentLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(nameLabel.snp.bottom).offset(2)
        }
    }
    
    // ✨ 핵심: 차트 데이터가 눌릴 때마다 호출되어 내용을 갱신함
    override func refreshContent(entry: ChartDataEntry, highlight: Highlight) {
        guard let pieEntry = entry as? PieChartDataEntry else { return }
        
        nameLabel.text = pieEntry.label
        
        if let chart = chartView as? PieChartView,
           let data = chart.data,
           // ✨ [핵심] 여기서 PieChartDataSet으로 형변환을 해야 .entries가 보입니다!
           let dataSet = data.dataSets.first as? PieChartDataSet {
            
            // 이제 entries를 쓸 수 있습니다.
            let total = dataSet.entries.reduce(0) { $0 + $1.y }
            let percent = total == 0 ? 0 : (entry.y / total) * 100
            
            percentLabel.text = String(format: "%.0f%%", percent)
            let index = Int(highlight.x)
            
            // 색상 배열에서 해당 인덱스의 색을 꺼냅니다. (안전을 위해 % 연산 사용)
            if !dataSet.colors.isEmpty {
                let color = dataSet.colors[index % dataSet.colors.count]
                percentLabel.textColor = color
            }
        }
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    // ✨ 마커 위치 조정 (터치한 곳의 정중앙에 오도록)
    override func offsetForDrawing(atPoint point: CGPoint) -> CGPoint {
        return CGPoint(x: -self.bounds.width / 2 + 10, y: -self.bounds.height / 2 - 10)
    }
}

