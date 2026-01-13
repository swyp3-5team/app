//
//  ExpandableListView.swift
//  Cloverly
//
//  Created by 이인호 on 1/4/26.
//

import UIKit
import SnapKit

class ExpandableListView: UIView {
    
    var onEditItem: ((Int) -> Void)?
    var onDeleteItem: ((Int) -> Void)?
    
    // MARK: - UI Components
    
    // ✨ 1. 전체를 감싸는 메인 스택뷰 (이게 핵심!)
    // 이 안에 넣어야 isHidden 처리가 될 때 공간도 같이 사라집니다.
    private let mainStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.alignment = .fill
        stack.distribution = .fill
        return stack
    }()
    
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "지출내역이 없습니다"
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()
    
    // 2. 헤더 영역
    private let headerContainer = UIView()
    
    private let listLabel: UILabel = {
        let label = UILabel()
        label.font = .customFont(.pretendardSemiBold, size: 16)
        label.textColor = .gray1
        return label
    }()
    
    private let listOpenImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "Chevron down"))
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        return imageView
    }()
    
    // 3. 내용물 리스트 스택뷰
    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.isHidden = true // 처음엔 숨김 (공간 차지 X)
        stack.alpha = 0
        
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 0, left: 10, bottom: 16, right: 10)
        
        return stack
    }()
    
    private let dividerView: UIView = {
        let view = UIView()
        view.backgroundColor = .gray9
        view.isHidden = true
        return view
    }()
    
    // MARK: - Properties
    private var isExpanded: Bool = false {
        didSet {
            // 상태 변경 시 애니메이션 실행
            toggleAnimation()
        }
    }
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupGesture()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        // 1. 메인 스택뷰를 뷰에 꽉 차게 넣음
        addSubview(mainStackView)
        addSubview(emptyStateLabel)
        mainStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        // 2. 메인 스택뷰에 순서대로 쌓음 (헤더 -> 내용 -> 구분선)
        mainStackView.addArrangedSubview(headerContainer)
        mainStackView.addArrangedSubview(contentStackView)
        mainStackView.addArrangedSubview(dividerView)
        
        // 3. 헤더 내부 레이아웃
        headerContainer.addSubview(listLabel)
        headerContainer.addSubview(listOpenImageView)
        
        headerContainer.snp.makeConstraints {
            $0.height.equalTo(48) // 헤더 높이 고정
        }
        
        listLabel.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.centerY.equalToSuperview()
        }
        
        listOpenImageView.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(24)
        }
        
        // 4. 구분선 높이 설정
        dividerView.snp.makeConstraints {
            $0.height.equalTo(1)
        }
        
        emptyStateLabel.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.equalToSuperview().offset(16)
        }
    }
    
    private func setupGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        headerContainer.addGestureRecognizer(tap)
        headerContainer.isUserInteractionEnabled = true // 터치 가능하도록 설정
    }
    
    // MARK: - Logic
    
    @objc private func handleTap() {
        isExpanded.toggle()
    }
    
    private func toggleAnimation() {
        // ✨ 핵심: isHidden을 바꾸면 StackView가 알아서 공간을 계산함
        // 애니메이션 블록 안에서 layoutIfNeeded를 호출해야 부드럽게 펼쳐짐
        UIView.animate(withDuration: 0.3, animations: {
            self.contentStackView.isHidden = !self.isExpanded
            self.contentStackView.alpha = self.isExpanded ? 1.0 : 0.0
            
            // 쉐브론 회전
            let angle = self.isExpanded ? CGFloat.pi : 0
            self.listOpenImageView.transform = CGAffineTransform(rotationAngle: angle)
            
            // 레이아웃 갱신
            self.layoutIfNeeded()
            
            // (중요) 이 뷰를 포함하고 있는 부모 뷰도 같이 갱신해줘야 자연스러움
            // 테이블뷰 셀 안에 있다면 beginUpdates/endUpdates 필요할 수 있음
            // 일반 뷰컨트롤러라면 아래 코드로 충분
            self.superview?.layoutIfNeeded()
        })
    }
    
    // MARK: - Data Binding
    func configure(with transaction: Transaction) {
        // 기존 뷰 제거 (초기화)
        contentStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let items = transaction.transactionInfoList
        
        if items.isEmpty {
            emptyStateLabel.isHidden = false
            listLabel.text = ""
            listOpenImageView.isHidden = true
            dividerView.isHidden = true
            contentStackView.isHidden = true
            
            // 비어있을때는 바로 접히게
            UIView.performWithoutAnimation {
                isExpanded = false
            }
            
            headerContainer.snp.updateConstraints {
                $0.height.equalTo(24)
            }
            
            headerContainer.isUserInteractionEnabled = false
            
            return
        }
        
        emptyStateLabel.isHidden = true
        listOpenImageView.isHidden = false
        dividerView.isHidden = false
        
        headerContainer.snp.updateConstraints {
            $0.height.equalTo(48)
        }
        
        headerContainer.isUserInteractionEnabled = true
        
        // 헤더 텍스트
        if items.count == 1 {
            listLabel.text = items[0].name
        } else {
            listLabel.text = "\(items[0].name) 외 \(items.count - 1)개"
        }
        
        // 상세 항목 추가
        for (index, item) in items.enumerated() {
            // createRowView에 index를 같이 넘겨줌
            let rowView = createRowView(name: item.name, amount: item.amount, index: index)
            contentStackView.addArrangedSubview(rowView)
        }
    }
    
    private func createRowView(name: String, amount: Int, index: Int) -> UIView {
        let view = UIView()
        
        let nameLabel = UILabel()
        nameLabel.text = name
        nameLabel.font = .customFont(.pretendardRegular, size: 14)
        nameLabel.textColor = .gray1
        
        let amountLabel = UILabel()
        amountLabel.text = "\(amount.withComma)원"
        amountLabel.font = .customFont(.pretendardMedium, size: 14)
        amountLabel.textColor = .gray4
        
        // (참고: 라벨이 정의된 후에 스택뷰를 만들어야 에러가 안 납니다)
        let contentStackView = UIStackView(arrangedSubviews: [nameLabel, amountLabel])
        contentStackView.axis = .vertical
        contentStackView.spacing = 4
        
        let editButton = UIButton()
        editButton.setImage(UIImage(named: "edit icon"), for: .normal)
        editButton.addAction(UIAction { [weak self] _ in
            self?.onEditItem?(index)
        }, for: .touchUpInside)
        
        let deleteButton = UIButton()
        deleteButton.setImage(UIImage(named: "delete icon"), for: .normal)
        
        // ✨ [추가 4] 삭제 버튼에 액션 추가 (핵심!)
        deleteButton.addAction(UIAction { [weak self] _ in
            // 삭제되는 애니메이션
            UIView.animate(withDuration: 0.2, animations: {
                view.alpha = 0
                view.isHidden = true
                self?.contentStackView.layoutIfNeeded()
                
            }, completion: { _ in
                self?.onDeleteItem?(index)
            })
        }, for: .touchUpInside)
        
        view.addSubview(contentStackView)
        view.addSubview(editButton)
        view.addSubview(deleteButton)
        
        contentStackView.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview()
        }
        
        editButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.trailing.equalTo(deleteButton.snp.leading).offset(-16)
        }
        
        deleteButton.snp.makeConstraints {
            $0.trailing.centerY.equalToSuperview()
        }
        
        return view
    }
}
