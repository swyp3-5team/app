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
    private var timeLeadingConstraint: NSLayoutConstraint!
    private var timeTrailingConstraint: NSLayoutConstraint!
    
    lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [messageImageView, messageTextView])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 0
        stackView.backgroundColor = .clear
        return stackView
    }()
    
    let messageImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 16
        imageView.clipsToBounds = true
        return imageView
    }()
    
    let messageTextView: UITextView = {
        let textView = UITextView()
        textView.text = "Sample"
        textView.textColor = .gray1
        textView.backgroundColor = .white
        textView.layer.cornerRadius = 16
        textView.layer.masksToBounds = false
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        textView.textContainer.lineFragmentPadding = 0
        textView.font = .customFont(.pretendardRegular, size: 16)
        
        return textView
    }()
    
    let profileImageView: UIImageView = {
        let view = UIImageView(image: UIImage(named: "character chat profile"))
        view.layer.cornerRadius = view.bounds.width / 2
        return view
    }()
    
    let timeLabel: UILabel = {
        let label = UILabel()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "a h:mm"

        let timeString = formatter.string(from: Date())
        
        label.textColor = .gray2
        label.font = .customFont(.pretendardRegular, size: 12)
        label.text = "\(timeString)"
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        messageTextView.text = nil
        messageImageView.image = nil
        
        messageTextView.isHidden = true
        messageImageView.isHidden = true
        
        messageTextView.backgroundColor = .clear
    }
    
    func configure() {
        contentView.addSubview(profileImageView)
        contentView.addSubview(stackView)
        contentView.addSubview(timeLabel)
        
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.widthAnchor.constraint(lessThanOrEqualToConstant: 250).isActive = true
        
        //        profileImageView.snp.makeConstraints {
        //            $0.top.equalToSuperview()
        //            $0.leading.equalToSuperview().offset(12)
        //        }
        //
        //        stackView.snp.makeConstraints {
        //            $0.top.bottom.equalToSuperview()
        //        }
        
        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            profileImageView.centerYAnchor.constraint(equalTo: stackView.centerYAnchor),
            
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            timeLabel.bottomAnchor.constraint(equalTo: stackView.bottomAnchor),
            
            messageImageView.heightAnchor.constraint(lessThanOrEqualToConstant: 300)
        ])
        
        leadingConstraint = stackView.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 8)
        trailingConstraint = stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        timeLeadingConstraint = timeLabel.leadingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: 6)
        timeTrailingConstraint = timeLabel.trailingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: -6)
        
        trailingConstraint.priority = UILayoutPriority(999)
        
        leadingConstraint.isActive = false
        trailingConstraint.isActive = false
        timeLeadingConstraint.isActive = false
        timeTrailingConstraint.isActive = false
    }
    
    func bind(with message: Message) {
        switch message.kind {
        case .text(let text):
            messageTextView.text = text
            messageTextView.isHidden = false
            messageImageView.isHidden = true
        case .photo(let image):
            messageImageView.image = image
            messageTextView.isHidden = true
            messageImageView.isHidden = false
        }
        
        if message.chatType == .receive {
            profileImageView.isHidden = false
            leadingConstraint.isActive = true
            trailingConstraint.isActive = false
            timeLeadingConstraint.isActive = true
            timeTrailingConstraint.isActive = false
            messageTextView.backgroundColor = .green10
            messageTextView.font = .customFont(.pretendardRegular, size: 16)
            
            messageTextView.layer.maskedCorners = [
                .layerMinXMinYCorner,
                .layerMaxXMinYCorner,
                .layerMaxXMaxYCorner
            ]
        } else {
            profileImageView.isHidden = true
            leadingConstraint.isActive = false
            trailingConstraint.isActive = true
            timeLeadingConstraint.isActive = false
            timeTrailingConstraint.isActive = true
            messageTextView.backgroundColor = .gray9
            messageTextView.font = .customFont(.pretendardMedium, size: 16)
            
            messageTextView.layer.maskedCorners = [
                .layerMinXMinYCorner,
                .layerMaxXMinYCorner,
                .layerMinXMaxYCorner
            ]
        }
    }
}
