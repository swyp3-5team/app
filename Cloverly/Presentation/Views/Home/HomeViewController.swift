//
//  HomeViewController.swift
//  Cloverly
//
//  Created by 이인호 on 12/20/25.
//

import UIKit
import SnapKit

class HomeViewController: UIViewController {
    private let calendarViewModel: CalendarViewModel
    
    var statusBarHeight: CGFloat {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            return windowScene.statusBarManager?.statusBarFrame.height ?? 0
        }
        return 0
    }
    
    private var timeBasedMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 6..<12:
            return "좋은 아침이에요! 🌼"
        case 12..<18:
            return "맛있는 점심 드셨나요? 🍛"
        case 18..<22:
            return "오늘 하루 수고했어요 🌟"
        default:
            return "아직 안 주무셨군요? 💤"
        }
    }
    
    private var timeBasedBackgroundImageName: String {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 6..<12:
            return "background_morning"
        case 12..<18:
            return "background_afternoon"
        case 18..<22:
            return "background_evening"
        default:
            return "background_night"
        }
    }
    
    private lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: timeBasedBackgroundImageName))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let typeLogoImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "typeLogo"))
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let bubbleImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "speech_bubble"))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private lazy var greetingLabel: UILabel = {
        let label = UILabel()
        label.text = timeBasedMessage
        label.font = .customFont(.pretendardSemiBold, size: 24)
        label.textColor = .gray10
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var characterImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "character+shadow"))
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private lazy var chatButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.filled()

        config.title = "채팅 시작"
        config.image = UIImage(named: "chatting icon")

        config.imagePlacement = .leading
        config.imagePadding = 4

        config.baseForegroundColor = .gray1
        config.baseBackgroundColor = .gray10
        
        var titleAttr = AttributedString.init("채팅 시작")
        titleAttr.font = .customFont(.pretendardSemiBold, size: 16)
        config.attributedTitle = titleAttr
        
        config.cornerStyle = .capsule
        
        button.configuration = config
        
        button.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }
            let vc = ChatViewController(calendarViewModel: calendarViewModel)
            self.navigationController?.pushViewController(vc, animated: true)
        }, for: .touchUpInside)
        return button
    }()
    
    init(calendarViewModel: CalendarViewModel) {
        self.calendarViewModel = calendarViewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        AuthViewModel.shared.getProfile()
    }
    
    func configureUI() {
        view.backgroundColor = .clear
        
        view.addSubview(backgroundImageView)
        view.sendSubviewToBack(backgroundImageView)
        view.addSubview(typeLogoImageView)
        view.addSubview(bubbleImageView)
        view.addSubview(greetingLabel)
        view.addSubview(characterImageView)
        view.addSubview(chatButton)
        
        backgroundImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        typeLogoImageView.snp.makeConstraints {
            $0.top.equalTo(view.snp.top).offset(statusBarHeight + 15)
            $0.leading.equalToSuperview().offset(16)
        }
        
        bubbleImageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(typeLogoImageView.snp.bottom).offset(100)
        }
        
        greetingLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(bubbleImageView.snp.top).offset(22)
        }
        
        characterImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(105)
            $0.trailing.equalToSuperview().offset(-104)
            $0.bottom.equalTo(chatButton.snp.top).offset(-60)
        }
        
        chatButton.snp.makeConstraints {
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-16)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(40)
        }
    }
}
