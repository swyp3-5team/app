//
//  ProfileTableViewCell.swift
//  Cloverly
//
//  Created by 이인호 on 12/27/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

class ProfileTableViewCell: UITableViewCell {
    static let identifier = "ProfileTableViewCell"
    private let disposeBag = DisposeBag()
    
    private lazy var profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "character profile")
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let nicknameLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        return label
    }()
    
    private let chevronImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "chevron.right")
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureUI()
        bind()
        selectionStyle = .none
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureUI() {
        contentView.addSubview(profileImageView)
        contentView.addSubview(nicknameLabel)
        contentView.addSubview(chevronImageView)
        
        profileImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(48)
        }
        
        nicknameLabel.snp.makeConstraints {
            $0.leading.equalTo(profileImageView.snp.trailing).offset(12)
            $0.centerY.equalTo(profileImageView.snp.centerY)
        }
        
        chevronImageView.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalTo(profileImageView.snp.centerY)
        }
    }
    
    private func bind() {
        AuthViewModel.shared.currentUser
            .observe(on: MainScheduler.instance)
            .map { user -> String in
                return user?.nickName ?? "게스트"
            }
            .bind(to: nicknameLabel.rx.text)
            .disposed(by: disposeBag)
    }
}
