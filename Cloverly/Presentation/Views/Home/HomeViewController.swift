//
//  HomeViewController.swift
//  Cloverly
//
//  Created by 이인호 on 12/20/25.
//

import UIKit
import SnapKit
import AVFoundation

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
            return "좋은 아침! 🌼"
        case 12..<18:
            return "점심 먹었어? 🍛"
        case 18..<22:
            return "오늘도 고생했어 🌟"
        default:
            return "아직 안 잤어? 💤"
        }
    }
    
    private var timeBasedBubbleTopOffset: CGFloat {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 6..<12:  return 110
        case 12..<18: return 42
        case 18..<22: return 138
        default:      return 138
        }
    }

    private var timeBasedVideoShift: CGFloat {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12:  return -50
        case 12..<18: return -50
        case 18..<22: return -70
        default:      return -50
        }
    }

    private var timeBasedBackgroundVideoName: String {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 6..<12:
            return "morning"
        case 12..<18:
            return "afternoon"
        case 18..<22:
            return "evening"
        default:
            return "night"
        }
    }

    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?

    private lazy var backgroundVideoView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
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
    
    private lazy var greetingLabel: AppLabel = {
        let label = AppLabel()
        label.text = timeBasedMessage
        label.textColor = .gray1
        label.typography = .h1
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

        config.title = "가계부 입력하기"
        config.image = UIImage(named: "chatting icon")

        config.imagePlacement = .leading
        config.imagePadding = 4

        config.baseForegroundColor = .gray1
        config.baseBackgroundColor = .gray10
        
        var titleAttr = AttributedString.init("가계부 입력하기")
        titleAttr.font = Typography.b1.uiFont
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
        setupVideoBackground()
        AuthViewModel.shared.getProfile()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        playerLayer?.frame = CGRect(
            x: 0,
            y: 0,
            width: backgroundVideoView.bounds.width,
            height: backgroundVideoView.bounds.height + timeBasedVideoShift
        )
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        player?.play()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        player?.pause()
    }

    private func setupVideoBackground() {
        guard let url = Bundle.main.url(forResource: timeBasedBackgroundVideoName, withExtension: "mp4") else { return }

        let player = AVPlayer(url: url)
        player.isMuted = true

        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        backgroundVideoView.layer.addSublayer(playerLayer)

        self.player = player
        self.playerLayer = playerLayer

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidReachEnd),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )

        player.play()
    }

    @objc private func playerItemDidReachEnd(_ notification: Notification) {
        player?.seek(to: .zero)
        player?.play()
    }

    @objc private func appWillEnterForeground() {
        player?.play()
    }
    
    func configureUI() {
        view.backgroundColor = .clear
        
        view.addSubview(backgroundVideoView)
        view.sendSubviewToBack(backgroundVideoView)
        view.addSubview(typeLogoImageView)
        view.addSubview(bubbleImageView)
        view.addSubview(greetingLabel)
//        view.addSubview(characterImageView) // 미사용
        view.addSubview(chatButton)
        
        backgroundVideoView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        typeLogoImageView.snp.makeConstraints {
            $0.top.equalTo(view.snp.top).offset(statusBarHeight + 15)
            $0.leading.equalToSuperview().offset(16)
        }
        
        bubbleImageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(typeLogoImageView.snp.bottom).offset(timeBasedBubbleTopOffset)
        }
        
        greetingLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(bubbleImageView.snp.top).offset(22)
        }
        
//        characterImageView.snp.makeConstraints {
//            $0.leading.equalToSuperview().offset(105)
//            $0.trailing.equalToSuperview().offset(-104)
//            $0.bottom.equalTo(chatButton.snp.top).offset(-60)
//        }
        
        chatButton.snp.makeConstraints {
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-16)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(40)
        }
    }
}
