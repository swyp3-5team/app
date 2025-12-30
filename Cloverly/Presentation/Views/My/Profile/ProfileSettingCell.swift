//
//  ProfileSettingCell.swift
//  Cloverly
//
//  Created by 이인호 on 12/28/25.
//

import UIKit
import SnapKit

class ProfileSettingCell: UITableViewCell {
    static let identifier = "ProfileSettingCell"
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .customFont(.pretendardMedium, size: 16)
        label.textColor = .gray2
        return label
    }()
    
    // 우측 콘텐츠 컨테이너
    private let rightStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 6
        sv.alignment = .center
        return sv
    }()
    
    // 타입 1: 텍스트 (이름/이메일 등)
    private let infoLabel: UILabel = {
        let label = UILabel()
        label.font = .customFont(.pretendardMedium, size: 16)
        label.textColor = .gray1
        label.isHidden = true
        label.numberOfLines = 1
        return label
    }()
    
    // 타입 2: 아이콘 (네이버 아이콘 등)
    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.isHidden = true
        return iv
    }()
    
    // 타입 3: 쉐브론
    private let chevronImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "Chevron right gray")
        iv.tintColor = .gray
        iv.isHidden = true
        return iv
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureUI()
        selectionStyle = .none
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    func configureUI() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(rightStackView)
        
        rightStackView.addArrangedSubview(iconImageView)
        rightStackView.addArrangedSubview(infoLabel)
        rightStackView.addArrangedSubview(chevronImageView)
        
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.centerY.equalToSuperview()
        }
        
        rightStackView.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-20)
            $0.centerY.equalToSuperview()
        }
        
        iconImageView.snp.makeConstraints {
            $0.width.height.equalTo(20)
        }
        
        chevronImageView.snp.makeConstraints {
            $0.width.height.equalTo(16)
        }
    }
    
    func configure(menu: ProfileMenu, user: User?) {
        titleLabel.text = menu.rawValue
        
        // 초기화
        infoLabel.isHidden = true
        iconImageView.isHidden = true
        chevronImageView.isHidden = true
        
        switch menu {
        case .profile:
            infoLabel.text = user?.nickName
            infoLabel.isHidden = false
            chevronImageView.isHidden = false
            
        case .account:
            infoLabel.text = user?.userEmail
            infoLabel.isHidden = false
            
            if user?.provider == .apple {
                iconImageView.image = UIImage(systemName: "apple.logo")
                iconImageView.tintColor = .black
            } else {
                iconImageView.image = UIImage(named: "kakao icon")
            }
            iconImageView.isHidden = false
            
        case .logout, .withdraw:
            // 우측에 아무것도 표시하지 않음
            break
        }
    }
    
    
}

