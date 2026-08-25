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
import PhotosUI
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

    private func makeAccessoryButton(title: String, imageName: String) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(named: imageName)
        config.imagePlacement = .leading
        config.imagePadding = 2
        config.baseForegroundColor = .gray2
        config.contentInsets = NSDirectionalEdgeInsets(top: 9, leading: 0, bottom: 9, trailing: 0)

        var titleAttr = AttributedString(title)
        titleAttr.font = Typography.b5.uiFont
        config.attributedTitle = titleAttr

        return UIButton(configuration: config)
    }

    private lazy var receiptButton: UIButton = {
        let button = makeAccessoryButton(title: "영수증", imageName: "image icon")
        button.addAction(UIAction { [weak self] _ in
            self?.presentReceiptPicker()
        }, for: .touchUpInside)
        return button
    }()

    private lazy var pasteButton: UIButton = {
        let button = makeAccessoryButton(title: "붙여넣기", imageName: "paste icon")
        button.addAction(UIAction { [weak self] _ in
            self?.pasteFromClipboard()
        }, for: .touchUpInside)
        return button
    }()

    // 키보드 위에 붙는 액션바. inputAccessoryView로 달면 iOS가 키보드 바로 위에 배치하고
    // 키보드 프레임 높이에 이 바가 합산되어 보고되므로, 기존 캡슐 위치 로직이 그대로
    // 캡슐을 액션바 위로 띄워준다. 키보드가 내려가면 함께 사라져 도킹 상태에선 안 보인다.
    private lazy var inputAccessoryBar: KeyboardAccessoryBar = {
        let bar = KeyboardAccessoryBar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 48))
        bar.autoresizingMask = .flexibleWidth
        bar.fillColor = .gray10

        bar.addSubview(receiptButton)
        bar.addSubview(pasteButton)

        receiptButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
        }

        pasteButton.snp.makeConstraints {
            $0.leading.equalTo(receiptButton.snp.trailing).offset(16)
            $0.centerY.equalToSuperview()
        }

        return bar
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

        inputTextField.inputAccessoryView = inputAccessoryBar

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

        inputTextField.text = ""
        sendButton.isEnabled = false
        inputTextField.resignFirstResponder()

        (tabBarController as? CustomTabBarViewController)?
            .routeToChatTab(message: text, interstitialAd: preloadedInterstitialAd)
        preloadedInterstitialAd = nil
    }

    private func pasteFromClipboard() {
        guard let text = UIPasteboard.general.string, !text.isEmpty else { return }
        // insertText로 넣으면 editingChanged가 발생해 전송 버튼 활성화 바인딩이 갱신됨
        inputTextField.insertText(text)
    }

    private func presentReceiptPicker() {
        let picker = ReceiptPickerViewController()
        picker.onPickImage = { [weak self] image in
            self?.pushChatWithImage(image)
        }
        picker.modalPresentationStyle = .fullScreen
        present(picker, animated: true)
    }

    private func pushChatWithImage(_ image: UIImage) {
        inputTextField.text = ""
        sendButton.isEnabled = false
        inputTextField.resignFirstResponder()

        (tabBarController as? CustomTabBarViewController)?
            .routeToChatTab(image: image, interstitialAd: preloadedInterstitialAd)
        preloadedInterstitialAd = nil
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


// 키보드 액션바. iOS 26 liquid glass 키보드는 상단 좌우가 둥글게 깎여 있어, 흰 직사각형
// 바가 그대로 붙으면 깎인 부분에 배경이 비쳐 이음새가 생긴다. 카카오톡처럼 흰색을 키보드
// 뒤로 화면 바닥까지 채워, 깎인 둥근 영역에도 배경 대신 흰색이 비치도록 해 이음새를 없앤다.
final class KeyboardAccessoryBar: UIView {
    var fillColor: UIColor = .white {
        didSet { backgroundView.backgroundColor = fillColor }
    }

    private let backgroundView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        // bounds 아래(키보드 뒤)로 뻗은 흰색이 잘리지 않도록 클립 해제.
        clipsToBounds = false
        backgroundColor = .clear
        backgroundView.backgroundColor = fillColor
        insertSubview(backgroundView, at: 0)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // 바 영역 + 아래로 화면 높이만큼 더 뻗어 키보드 전체 뒤를 흰색으로 덮는다.
        backgroundView.frame = CGRect(x: 0, y: 0,
                                      width: bounds.width,
                                      height: bounds.height + UIScreen.main.bounds.height)
    }
}
