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
    
    private let topGuideLabel: UILabel = {
        let label = UILabel()
        label.text = "캐릭터와 대화하듯\n가계부를 작성해보세요\nex)"
        label.textColor = .gray10
        label.font = .customFont(.pretendardSemiBold, size: 14)
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
    
    private let leftBottomGuideLabel: UILabel = {
        let label = UILabel()
        label.text = "사진/카메라로\n영수증을 촬영해보세요"
        label.textColor = .gray10
        label.font = .customFont(.pretendardSemiBold, size: 14)
        label.numberOfLines = 0
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let rightBottomGuideLabel: UILabel = {
        let label = UILabel()
        label.text = "텍스트를 붙여넣으면\n자동으로 분류돼요"
        label.textColor = .gray10
        label.font = .customFont(.pretendardSemiBold, size: 14)
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
        
        leftBottomArrowImageView.snp.makeConstraints {
            $0.bottom.equalToSuperview().offset(-84)
            $0.leading.equalToSuperview().offset(44)
        }
        
        leftBottomGuideLabel.snp.makeConstraints {
            $0.leading.equalTo(leftBottomArrowImageView)
            $0.bottom.equalTo(leftBottomArrowImageView.snp.top).offset(-15)
        }
        
        rightBottomArrowImageView.snp.makeConstraints {
            $0.top.equalTo(rightBottomGuideLabel.snp.bottom).offset(15)
            $0.leading.equalTo(rightBottomGuideLabel.snp.leading)
        }
        
        rightBottomGuideLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-44)
            $0.bottom.equalToSuperview().offset(-159)
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
