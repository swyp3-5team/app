//
//  CoachMarkView.swift
//  Cloverly
//
//  Created by 이인호 on 12/25/25.
//

import UIKit
import SnapKit

class NoFocusWindow: UIWindow {
    override var canBecomeKey: Bool {
        return false
    }
}

class CoachMarkView: UIView {
    var onDismiss: (() -> Void)?
    
    private let topGuideLabel: AppLabel = {
        let label = AppLabel()
        label.text = "캐릭터와 대화하듯\n가계부를 작성해보세요"
        label.textColor = .gray10
        label.typography = .b6
        label.numberOfLines = 0
        label.textAlignment = .left
        return label
    }()
    
    private let topArrowImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "short arrow")
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    lazy var closeButton: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(named: "coachmark close button"), for: .normal)
        
        btn.addAction(UIAction { [weak self] _ in
            self?.onDismiss?()
        }, for: .touchUpInside)
        return btn
    }()
    
    private let leftBottomGuideLabel: AppLabel = {
        let label = AppLabel()
        label.text = "사진/카메라로\n영수증을 촬영해보세요"
        label.textColor = .gray10
        label.typography = .b6
        label.numberOfLines = 0
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let rightBottomGuideLabel: AppLabel = {
        let label = AppLabel()
        label.text = "텍스트를 붙여넣으면\n자동으로 분류돼요"
        label.textColor = .gray10
        label.typography = .b6
        label.numberOfLines = 0
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let leftBottomArrowImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "short reverse arrow")
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let rightBottomArrowImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "long arrow")
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.8)
        
        addSubview(topArrowImageView)
        addSubview(topGuideLabel)
        addSubview(closeButton)
        addSubview(leftBottomArrowImageView)
        addSubview(leftBottomGuideLabel)
        addSubview(rightBottomArrowImageView)
        addSubview(rightBottomGuideLabel)
        
        topArrowImageView.snp.makeConstraints {
            $0.centerX.equalToSuperview().offset(-30)
            $0.top.equalToSuperview().offset(103)
        }
        
        topGuideLabel.snp.makeConstraints {
            $0.leading.equalTo(topArrowImageView)
            $0.top.equalTo(topArrowImageView.snp.bottom).offset(12)
        }
        
        closeButton.snp.makeConstraints {
            $0.centerX.centerY.equalToSuperview()
        }
    }

    /// 하단 가이드(영수증/붙여넣기)를 배치. 라벨과 화살표는 한 쌍으로 묶여 함께 이동한다.
    /// 코치뷰가 윈도우 전체를 덮으므로 snp.top 기준 offset = 절대 y 좌표.
    /// 좌 여백(leftMargin)/우 여백(rightMargin)만 조정하면 각 쌍이 통째로 이동.
    func positionBottomGuides(receiptFrame: CGRect, pasteFrame: CGRect) {
        let leftMargin: CGFloat = 24    // 영수증 쌍: 왼쪽 여백

        // 좌: 영수증 — 화살표(왼쪽 여백 기준) + 그 위 라벨(화살표에 맞춰 함께 이동)
        leftBottomArrowImageView.snp.remakeConstraints {
            $0.leading.equalToSuperview().offset(leftMargin)
            $0.bottom.equalTo(snp.top).offset(receiptFrame.minY - 12)
        }
        leftBottomGuideLabel.snp.remakeConstraints {
            $0.leading.equalTo(leftBottomArrowImageView)
            $0.bottom.equalTo(leftBottomArrowImageView.snp.top).offset(-15)
        }

        // 우: 붙여넣기 — 화살표를 붙여넣기 버튼 위(살짝 오른쪽)에, 라벨은 화살표에 맞춰 함께 이동
        rightBottomArrowImageView.snp.remakeConstraints {
            $0.centerX.equalTo(snp.leading).offset(pasteFrame.midX + 12)
            $0.bottom.equalTo(snp.top).offset(pasteFrame.minY - 12)
        }
        rightBottomGuideLabel.snp.remakeConstraints {
            $0.leading.equalTo(rightBottomArrowImageView)
            $0.bottom.equalTo(rightBottomArrowImageView.snp.top).offset(-15)
        }
    }

    func setCutouts(_ shapes: [(rect: CGRect, radius: CGFloat)]) {
        let path = UIBezierPath(rect: self.bounds)
        
        for shape in shapes {
            let holePath = UIBezierPath(roundedRect: shape.rect, cornerRadius: shape.radius)
            path.append(holePath)
        }
        
        // 마스크 적용
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        maskLayer.fillRule = .evenOdd // 겹친 부분 뚫기
        
        self.layer.mask = maskLayer
    }
}
