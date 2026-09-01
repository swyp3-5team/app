//
//  HomeViewController.swift
//  Cloverly
//
//  Created by 이인호 on 12/20/25.
//

import UIKit
import SnapKit
import AVFoundation
import GoogleMobileAds
import RxSwift
import RxCocoa

class HomeViewController: UIViewController {
    private let calendarViewModel: CalendarViewModel
    private let disposeBag = DisposeBag()
    private var preloadedInterstitialAd: InterstitialAd?
    private var inputContainerBottomConstraint: Constraint?
    private var inputCapsuleBottomConstraint: Constraint?
    private let inputContainerBaseOffset: CGFloat = 20
    private let capsuleDockedBottomInset: CGFloat = -30
    private let capsuleKeyboardBottomInset: CGFloat = -10
    private var isInputDocked = true
    
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
        case 12..<15:
            return "점심 먹었어? 🍛"
        case 15..<18:
            return "커피 한 잔 마셨어? ☕️"
        case 18..<22:
            return "오늘도 고생했어 🌟"
        default:
            return "아직 안 잤어? 💤"
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
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let month = calendar.component(.month, from: now)
        let isSummer = (6...9).contains(month)

        let baseName: String
        switch hour {
        case 6..<12:  baseName = "morning"
        case 12..<18: baseName = "afternoon"
        case 18..<22: baseName = "evening"
        default:      baseName = "night"
        }

        return isSummer ? "\(baseName)_summer" : baseName
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
    
    private lazy var inputContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .gray10
        view.layer.cornerRadius = 20
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return view
    }()

    private lazy var inputCapsule: UIView = {
        let view = UIView()
        view.backgroundColor = .gray9
        view.layer.cornerRadius = 24
        view.clipsToBounds = true
        return view
    }()

    private lazy var inputTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "오늘의 소비 내역을 알려주세요!"
        tf.font = Typography.b2.uiFont
        tf.textColor = .gray1
        tf.returnKeyType = .send
        return tf
    }()

    private lazy var sendButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "send button enabled"), for: .normal)
        button.setImage(UIImage(named: "Send Button disabled"), for: .disabled)
        button.isEnabled = false
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
        bind()
        setupVideoBackground()
        AuthViewModel.shared.getProfile()

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        preloadChatInterstitialAd()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    private func preloadChatInterstitialAd() {
        guard !hasShownAdToday else { return }
        guard preloadedInterstitialAd == nil else { return }
        let adUnitID = "ca-app-pub-8889421922972515/5880985432"
//        let adUnitID = "ca-app-pub-3940256099942544/4411468910" // test
        InterstitialAd.load(with: adUnitID, request: Request()) { [weak self] ad, _ in
            self?.preloadedInterstitialAd = ad
        }
    }

    private var hasShownAdToday: Bool {
        guard let lastDate = UserDefaults.standard.object(forKey: "chatInterstitialLastShownDate") as? Date else { return false }
        return Calendar.current.isDateInToday(lastDate)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        playerLayer?.frame = CGRect(
            x: 0,
            y: 0,
            width: backgroundVideoView.bounds.width,
            height: backgroundVideoView.bounds.height + timeBasedVideoShift
        )

        if isInputDocked {
            inputContainer.applyTopShadow(color: .shadow2, yOffset: -6)
        } else {
            inputContainer.layer.shadowOpacity = 0
        }
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
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)

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
        view.addSubview(inputContainer)
        inputContainer.addSubview(inputCapsule)
        inputCapsule.addSubview(inputTextField)
        inputCapsule.addSubview(sendButton)

        backgroundVideoView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        typeLogoImageView.snp.makeConstraints {
            $0.top.equalTo(view.snp.top).offset(statusBarHeight + 15)
            $0.leading.equalToSuperview().offset(20)
        }

        bubbleImageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(typeLogoImageView.snp.bottom).offset(42)
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

        inputContainer.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            inputContainerBottomConstraint = $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(inputContainerBaseOffset).constraint
        }

        inputCapsule.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.top.equalToSuperview().offset(10)
            inputCapsuleBottomConstraint = $0.bottom.equalToSuperview().offset(capsuleDockedBottomInset).constraint
            $0.height.equalTo(48)
        }

        sendButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-8)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(32)
        }

        inputTextField.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalTo(sendButton.snp.leading).offset(-8)
            $0.centerY.equalToSuperview()
        }
    }

    private func bind() {
        inputTextField.rx.text.orEmpty
            .map { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .distinctUntilChanged()
            .bind(to: sendButton.rx.isEnabled)
            .disposed(by: disposeBag)

        sendButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.sendAndPushChat()
            })
            .disposed(by: disposeBag)

        inputTextField.delegate = self
    }

    private func sendAndPushChat() {
        let text = inputTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !text.isEmpty else { return }

        let vc = ChatViewController(
            calendarViewModel: calendarViewModel,
            interstitialAd: preloadedInterstitialAd,
            initialMessage: text
        )
        preloadedInterstitialAd = nil

        inputTextField.text = ""
        sendButton.isEnabled = false
        inputTextField.resignFirstResponder()

        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let frame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        else { return }

        let screenHeight = UIScreen.main.bounds.height
        let overlap = max(screenHeight - frame.origin.y - view.safeAreaInsets.bottom, 0)
        let isKeyboardUp = overlap > 0

        let bottomOffset: CGFloat = isKeyboardUp ? -overlap : inputContainerBaseOffset
        let capsuleInset: CGFloat = isKeyboardUp ? capsuleKeyboardBottomInset : capsuleDockedBottomInset

        isInputDocked = !isKeyboardUp
        inputContainer.layer.shadowOpacity = isKeyboardUp ? 0 : 0.05

        inputContainerBottomConstraint?.update(offset: bottomOffset)
        inputCapsuleBottomConstraint?.update(offset: capsuleInset)

        UIView.animate(withDuration: duration) {
            self.inputContainer.backgroundColor = isKeyboardUp ? .clear : .gray10
            self.view.layoutIfNeeded()
        }
    }
}

extension HomeViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendAndPushChat()
        return false
    }
}

extension HomeViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // 인풋 캡슐(전송 버튼 포함) 터치는 dismiss 제스처가 가로채지 않도록
        if let touched = touch.view, touched.isDescendant(of: inputCapsule) {
            return false
        }
        return true
    }
}
