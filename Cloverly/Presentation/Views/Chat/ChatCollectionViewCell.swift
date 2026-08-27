//
//  ChatCollectionViewCell.swift
//  Cloverly
//
//  Created by 이인호 on 12/11/25.
//

import UIKit
import SnapKit
import Lottie

class ChatCollectionViewCell: UICollectionViewCell {
    static let identifier = "ChatCollectionViewCell"
    
    private var leadingConstraint: NSLayoutConstraint!
    private var trailingConstraint: NSLayoutConstraint!
    private var timeLeadingConstraint: NSLayoutConstraint!
    private var timeTrailingConstraint: NSLayoutConstraint!
    private var receiveWidthConstraint: NSLayoutConstraint!
    private var sendWidthConstraint: NSLayoutConstraint!
    
    lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [messageImageView, messageTextView, loadingRow])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 0
        stackView.backgroundColor = .clear
        return stackView
    }()

    private let loadingAnimationView: LottieAnimationView = {
        let view = LottieAnimationView(name: "loadingSpinner")
        view.loopMode = .loop
        view.contentMode = .scaleAspectFit
        return view
    }()

    // .loading 메시지용 어시스턴트 버블 (Lottie 인디케이터)
    private lazy var loadingBubbleView: UIView = {
        let view = UIView()
        view.backgroundColor = .green10
        view.layer.cornerRadius = 16
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        view.addSubview(loadingAnimationView)
        // 숨김 시 UIStackView가 0으로 접을 수 있도록 required(1000) 미만으로 둠 (셀 높이 오염 방지)
        loadingAnimationView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(14).priority(999)
            $0.leading.trailing.equalToSuperview().inset(16).priority(999)
            $0.width.equalTo(44).priority(999)
            $0.height.equalTo(16).priority(999)
        }
        return view
    }()

    // .fill 스택에서 로딩 버블이 말풍선(스택) 폭을 강제하지 않도록 감싸는 좌측 정렬 컨테이너
    private lazy var loadingRow: UIView = {
        let row = UIView()
        row.addSubview(loadingBubbleView)
        loadingBubbleView.snp.makeConstraints {
            $0.top.bottom.leading.equalToSuperview()
            $0.trailing.lessThanOrEqualToSuperview()
        }
        return row
    }()
    
    let messageImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 16
        imageView.clipsToBounds = true
        return imageView
    }()
    
    let messageTextView: AppTextView = {
        let textView = AppTextView()
        textView.text = "Sample"
        textView.textColor = .gray1
        textView.backgroundColor = .white
        textView.layer.cornerRadius = 16
        textView.layer.masksToBounds = false
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        textView.textContainer.lineFragmentPadding = 0
        textView.typography = .b2

        return textView
    }()
    
    let profileImageView: UIImageView = {
        let view = UIImageView(image: UIImage(named: "character chat profile"))
        view.layer.cornerRadius = view.bounds.width / 2
        return view
    }()
    
    let timeLabel: AppLabel = {
        let label = AppLabel()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "a h:mm"

        let timeString = formatter.string(from: Date())

        label.textColor = .gray2
        label.typography = .l3
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
        loadingRow.isHidden = true
        loadingAnimationView.stop()
        timeLabel.isHidden = false

        messageTextView.backgroundColor = .clear
    }
    
    func configure() {
        contentView.addSubview(profileImageView)
        contentView.addSubview(stackView)
        contentView.addSubview(timeLabel)
        
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let containerWidth = UIScreen.main.bounds.width - 32
        receiveWidthConstraint = stackView.widthAnchor.constraint(lessThanOrEqualToConstant: containerWidth * 0.67)
        sendWidthConstraint = stackView.widthAnchor.constraint(lessThanOrEqualToConstant: containerWidth * 0.82)
        
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
            profileImageView.bottomAnchor.constraint(equalTo: stackView.bottomAnchor),
            
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
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "a h:mm"
        timeLabel.text = formatter.string(from: message.date)

        switch message.kind {
        case .text(let text):
            messageTextView.text = text
            messageTextView.isHidden = false
            messageImageView.isHidden = true
            loadingRow.isHidden = true
            timeLabel.isHidden = false
        case .photo(let image):
            messageImageView.image = image
            messageTextView.isHidden = true
            messageImageView.isHidden = false
            loadingRow.isHidden = true
            timeLabel.isHidden = false
        case .loading:
            messageTextView.isHidden = true
            messageImageView.isHidden = true
            loadingRow.isHidden = false
            timeLabel.isHidden = true
            loadingAnimationView.play()
        }
        
        if message.chatType == .receive {
            profileImageView.isHidden = false
            leadingConstraint.isActive = true
            trailingConstraint.isActive = false
            timeLeadingConstraint.isActive = true
            timeTrailingConstraint.isActive = false
            sendWidthConstraint.isActive = false
            receiveWidthConstraint.isActive = true
            messageTextView.backgroundColor = .green10
            
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
            receiveWidthConstraint.isActive = false
            sendWidthConstraint.isActive = true
            messageTextView.backgroundColor = .gray9
            
            messageTextView.layer.maskedCorners = [
                .layerMinXMinYCorner,
                .layerMaxXMinYCorner,
                .layerMinXMaxYCorner
            ]
        }
    }
}
