//
//  PaymentDropDown.swift
//  Cloverly
//
//  Created by 이인호 on 1/3/26.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

class PaymentDropDown: UIView {
    
    let selectedPayment = BehaviorRelay<Payment>(value: .card)
    private let disposeBag = DisposeBag()
    
    // 상태 (열림/닫힘)
    private var isExpanded = false
    private let headerHeight: CGFloat = 48
    private let rowHeight: CGFloat = 44
    
    // UI 요소
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 8
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.systemGray5.cgColor
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "카드"
        label.font = .systemFont(ofSize: 14)
        label.textColor = .black
        return label
    }()
    
    private let arrowIcon: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(named: "text field arrow down")
        return view
    }()
    
    private lazy var tableView: UITableView = {
        let view = UITableView()
        view.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.delegate = self
        view.dataSource = self
        view.separatorStyle = .none
        view.isScrollEnabled = false
        view.backgroundColor = .clear
        view.layer.borderColor = UIColor.gray8.cgColor
        view.layer.borderWidth = 1
        view.layer.cornerRadius = 8
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        bind()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(arrowIcon)
        addSubview(tableView)
        
        // 1. 헤더 (박스)
        containerView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(headerHeight)
        }
        
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
        }
        
        arrowIcon.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(16)
        }
        
        // 2. 테이블뷰 (헤더 바로 아래)
        tableView.snp.makeConstraints {
            $0.top.equalTo(containerView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(0) // 처음엔 높이 0 (숨김)
            $0.bottom.equalToSuperview() // ✨ 중요: 뷰의 전체 높이를 결정함
        }
    }
    
    private func bind() {
        // 헤더 탭 -> 토글
        let tap = UITapGestureRecognizer(target: self, action: #selector(toggleDropdown))
        containerView.addGestureRecognizer(tap)
    }
    
    @objc private func toggleDropdown() {
        isExpanded.toggle()
        
        // 1. 테이블뷰 높이 계산 (펼치면 목록만큼, 닫으면 0)
        let newHeight = isExpanded ? CGFloat(Payment.allCases.count) * rowHeight : 0
        self.arrowIcon.transform = self.isExpanded ? CGAffineTransform(rotationAngle: .pi) : .identity
        
        self.tableView.snp.updateConstraints {
            $0.height.equalTo(newHeight)
        }
        
        self.superview?.layoutIfNeeded()
    }
}

// MARK: - TableView Delegate
extension PaymentDropDown: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Payment.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = Payment.allCases[indexPath.row].displayName
        cell.textLabel?.font = .systemFont(ofSize: 14)
        cell.textLabel?.textColor = .darkGray
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selected = Payment.allCases[indexPath.row]
        
        // 1. UI 업데이트
        titleLabel.text = selected.displayName
        selectedPayment.accept(selected) // 값 방출
        
        // 2. 닫기
        toggleDropdown()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return rowHeight
    }
}
