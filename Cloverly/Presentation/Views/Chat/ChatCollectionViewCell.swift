//
//  ChatCollectionViewCell.swift
//  Cloverly
//
//  Created by 이인호 on 12/11/25.
//

import UIKit

class ChatCollectionViewCell: UICollectionViewCell {
    static let identifier = "ChatCollectionViewCell"
    
    private var leadingConstraint: NSLayoutConstraint!
    private var trailingConstraint: NSLayoutConstraint!
    
    let messageLabel: UITextView = {
        let view = UITextView()
        view.text = "Sample"
        view.textColor = .black
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = false
        view.isEditable = false
        return view
    }()
    
    let profileImageView: UIImageView = {
        let view = UIImageView(image: UIImage(systemName: "heart"))
        view.layer.cornerRadius = view.bounds.width / 2
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure() {
        contentView.addSubview(profileImageView)
        contentView.addSubview(messageLabel)
        
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        messageLabel.isScrollEnabled = false
        messageLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 250).isActive = true
        
        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            
            messageLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            messageLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        leadingConstraint = messageLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 4)
        trailingConstraint = messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12)
        
        leadingConstraint.isActive = false
        trailingConstraint.isActive = false
    }
    
    func bind(with message: Message) {
        messageLabel.text = message.textBody
        
        UIView.performWithoutAnimation {
            if message.chatType == .receive {
                profileImageView.isHidden = false
                leadingConstraint.isActive = true
                trailingConstraint.isActive = false
                messageLabel.backgroundColor = .gray
            } else {
                profileImageView.isHidden = true
                leadingConstraint.isActive = false
                trailingConstraint.isActive = true
                messageLabel.backgroundColor = .systemBlue
            }
            contentView.layoutIfNeeded()
        }
    }
}
