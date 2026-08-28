//
//  ChatViewController.swift
//  Cloverly
//
//  Created by 이인호 on 12/11/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import PhotosUI
import Lottie
import GoogleMobileAds

extension UINavigationController {
    open override func viewWillLayoutSubviews() {
        navigationBar.topItem?.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
}

class ChatViewController: UIViewController {
    private let calendarViewModel: CalendarViewModel
    private let disposeBag = DisposeBag()
    private let viewModel = ChatViewModel()
    private let sizingCell = ChatCollectionViewCell()
    private lazy var inputBar = InputBar(viewModel: viewModel)
    private var inputBarBottomConstraint: Constraint?

    // 이전 페이지 prepend 시 스크롤 위치 보정용
    private var isPrependingHistory = false
    private var contentHeightBeforePrepend: CGFloat = 0

    // 최초 진입 시 프레임 확정 후 1회 하단 고정용
    private var didInitialScrollToBottom = false

    // 히스토리 최초 조회 동안 스켈레톤 표시
    private var isInitialLoading = false
    private let skeletonView = ChatSkeletonView()
    
    lazy var segmented = CustomSegmentedControl(selectedIndex: viewModel.selectedIndex, items: ["가계부", "대화"], cornerRadius: 17)

    private let titleLabel: AppLabel = {
        let label = AppLabel()
        label.text = "가계부 입력"
        label.textColor = .gray1
        label.typography = .t1
        return label
    }()

    var statusBarHeight: CGFloat {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            return windowScene.statusBarManager?.statusBarFrame.height ?? 0
        }
        return 0
    }

    private lazy var questionButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(named: "questionmark icon")
        let button = UIButton(configuration: config)
        button.addAction(UIAction { [weak self] _ in
            self?.setGuide(visible: true)
        }, for: .touchUpInside)
        return button
    }()

    // 가이드 바깥 영역 탭 시 닫기용 전체 화면 backdrop
    private lazy var guideBackdrop: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.isHidden = true
        v.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(hideGuide)))
        return v
    }()

    private lazy var guideView: ChatGuideView = {
        let view = ChatGuideView()
        view.isHidden = true
        view.onClose = { [weak self] in
            self?.setGuide(visible: false)
        }
        return view
    }()
    
    var overlayWindow: UIWindow?

    private var interstitialAd: InterstitialAd?
    private let initialMessage: String?
    private let initialImage: UIImage?
    private var pendingAdAfterSave = false

    private lazy var imagePicker: UIImagePickerController = {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        return imagePicker
    }()
    
    var isAtBottom: Bool {
        let offsetY = collectionView.contentOffset.y
        let contentHeight = collectionView.contentSize.height
        let frameHeight = collectionView.frame.size.height
        return offsetY >= contentHeight - frameHeight - 10
    }

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        // sizeForItemAt에서 정확한 크기를 주므로 셀프사이징을 끔.
        // (셀프사이징이면 초기 로드 시 추정 크기로 스크롤돼 하단 고정이 어긋남)
        layout.minimumLineSpacing = 24
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.register(ChatCollectionViewCell.self, forCellWithReuseIdentifier: ChatCollectionViewCell.identifier)
        cv.delegate = self
        cv.dataSource = self
        cv.keyboardDismissMode = .interactive
        
        return cv
    }()
    
    private lazy var lottieView: LottieAnimationView = {
        let animationView = LottieAnimationView(name: "loadingSpinner")
        
        animationView.loopMode = .loop
        animationView.contentMode = .scaleAspectFit
        animationView.animationSpeed = 1.0
        
        return animationView
    }()
    
    private let statusLabel: AppLabel = {
        let label = AppLabel()
        label.text = "내용 인식중"
        label.textColor = .gray10
        label.typography = .b6
        label.textAlignment = .center
        return label
    }()
    
    private lazy var loadingStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [lottieView, statusLabel])
        stack.axis = .vertical
        stack.spacing = 0
        stack.alignment = .center
        stack.distribution = .fill
        stack.backgroundColor = .gray1.withAlphaComponent(0.2)
        stack.layer.cornerRadius = 16
        stack.clipsToBounds = true
        
        stack.layoutMargins = UIEdgeInsets(top: 6, left: 25, bottom: 14, right: 25)
        stack.isLayoutMarginsRelativeArrangement = true
        
        stack.isHidden = true
        return stack
    }()
    
    init(calendarViewModel: CalendarViewModel, interstitialAd: InterstitialAd? = nil, initialMessage: String? = nil, initialImage: UIImage? = nil) {
        self.calendarViewModel = calendarViewModel
        self.interstitialAd = interstitialAd
        self.initialMessage = initialMessage
        self.initialImage = initialImage
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()

        let trimmed = initialMessage?.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasInitialSend = (trimmed?.isEmpty == false) || initialImage != nil

        if hasInitialSend {
            // 홈에서 넘어온 전송: 스켈레톤 없이 내 메시지를 즉시 노출.
            // bind() 전에 보내 두면 BehaviorRelay 최신값이 비어있지 않아 빈 화면/스켈레톤 깜빡임이 없다.
            isInitialLoading = false
            viewModel.selectedIndex.accept(0)
            if let message = trimmed, !message.isEmpty {
                viewModel.sendChat(message: message)
            } else if let initialImage {
                viewModel.sendChat(image: initialImage)
            }
        } else {
            // 일반 진입: 히스토리 로딩 동안 스켈레톤 표시
            isInitialLoading = true
        }

        bind()
        textBind()

        Task {
            if hasInitialSend {
                // 이미 보낸 메시지는 하단에 유지하고, 이전 히스토리를 백그라운드로 불러와 위에 붙인다
                await viewModel.loadInitialHistory(keepingCurrent: true)
            } else {
                await viewModel.loadInitialHistory()
                isInitialLoading = false
                updateBackground(isEmpty: viewModel.messages.value.isEmpty)
            }
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        view.addGestureRecognizer(tap)
        
        let backImage = UIImage(named: "Chevron left")
        navigationController?.navigationBar.backIndicatorImage = backImage
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = backImage
        navigationController?.navigationBar.tintColor = .gray1
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    
        if !UserDefaults.standard.bool(forKey: "hasSeenCoachMark") {
            showCoachMark()
            UserDefaults.standard.set(true, forKey: "hasSeenCoachMark")
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // 최초 진입 시엔 히스토리 로딩(async)으로 reloadData가 늦게 오므로
        // bind의 scrollToBottom이 프레임 확정 전에 실행돼 하단 고정이 어긋난다.
        // 콘텐츠가 실제로 채워진 뒤 프레임이 확정되는 이 시점에 1회만 하단 고정.
        if !didInitialScrollToBottom,
           collectionView.numberOfSections > 0,
           collectionView.contentSize.height > 0 {
            didInitialScrollToBottom = true
            scrollToBottom(animated: false)
        }
    }

    // 가계부 저장 완료 후, 저장 모달이 완전히 닫힌 뒤에 전면광고 노출 (하루 1회는 홈 preload 단계에서 이미 보장됨)
    private func presentAdAfterSaveIfNeeded() {
        guard pendingAdAfterSave else { return }
        pendingAdAfterSave = false

        guard let ad = interstitialAd else { return }
        ad.present(from: self)
        UserDefaults.standard.set(Date(), forKey: "chatInterstitialLastShownDate")
        interstitialAd = nil
    }


    func showCoachMark() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        
        let newWindow = NoFocusWindow(windowScene: windowScene)
        newWindow.frame = windowScene.coordinateSpace.bounds
        newWindow.backgroundColor = .clear
        newWindow.windowLevel = .statusBar + 1
        
        let coachView = CoachMarkView(frame: newWindow.bounds)
        
        var cutouts: [(CGRect, CGFloat)] = []
        
        // 상단 Segmented Control
        if let segFrame = self.segmented.superview?.convert(self.segmented.frame, to: nil) {
            let finalSegRect = segFrame.insetBy(dx: -10, dy: -11)
            cutouts.append((finalSegRect, finalSegRect.height / 2))
        }
        
        // 버튼들이 포함된 배열
        let targetButtons = [self.inputBar.receiptButton, self.inputBar.pasteButton]
        var combinedFrame: CGRect = .null
        
        for button in targetButtons {
            guard let frame = button.superview?.convert(button.frame, to: nil) else { continue }
            
            if combinedFrame.isNull {
                combinedFrame = frame
            } else {
                combinedFrame = combinedFrame.union(frame)
            }
        }
        
        let fixedFrame = CGRect(
            x: combinedFrame.origin.x,
            y: UIScreen.main.bounds.height - 78,
            width: combinedFrame.width,
            height: combinedFrame.height
        )
        
        let finalBtnRect = fixedFrame.insetBy(dx: -6, dy: -6)
        
        cutouts.append((finalBtnRect, finalBtnRect.height / 2))

        coachView.setCutouts(cutouts)
        
        coachView.onDismiss = { [weak self] in
            self?.overlayWindow = nil
        }
        
        newWindow.addSubview(coachView)
        newWindow.isHidden = false
        self.overlayWindow = newWindow
    }
    
    private func setGuide(visible: Bool) {
        guideBackdrop.isHidden = !visible
        guideView.isHidden = !visible
    }

    @objc private func hideGuide() {
        setGuide(visible: false)
    }

    @objc func dismissKeyboard() {
        //        view.window?.endEditing(true)
        inputBar.textView.resignFirstResponder()
    }
    
    func configure() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        view.addSubview(inputBar)
        view.addSubview(titleLabel)
        view.addSubview(questionButton)
        view.addSubview(loadingStackView)
        view.addSubview(guideBackdrop)
        view.addSubview(guideView)
        view.backgroundColor = .systemBackground

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.snp.top).offset(statusBarHeight + 15.5)
            $0.centerX.equalToSuperview()
        }

        questionButton.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel.snp.centerY)
            $0.trailing.equalToSuperview().offset(-16)
        }

        guideBackdrop.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        guideView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(10)
            $0.trailing.equalToSuperview().offset(-20)
            $0.leading.greaterThanOrEqualToSuperview().offset(20)
        }

        // 입력바를 탭바 위(safeArea 하단)에 고정. 키보드가 올라오면 keyboardWillChangeFrame에서 위로 이동.
        inputBar.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            inputBarBottomConstraint = $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).constraint
        }

        collectionView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(inputBar.snp.top)
        }
        // 마지막 메시지가 입력바에 붙지 않도록 하단 여백
        collectionView.contentInset.bottom = 12
        collectionView.verticalScrollIndicatorInsets.bottom = 12

        loadingStackView.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        collectionView.register(
            DateHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: DateHeaderView.id
        )
    }
    
    func textBind() {
        inputBar.heightUpdateNeeded
            .asDriver(onErrorJustReturn: ())
            .drive(onNext: { [weak self] _ in
                self?.updateInputBarHeight()
            })
            .disposed(by: disposeBag)
    }
    
    func bind() {
        viewModel.currentSectionsStream
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] sections in
                guard let self = self else { return }

                let allMessages = sections.flatMap { $0.messages }
                self.updateBackground(isEmpty: allMessages.isEmpty)

                let currentTotal = (0..<self.collectionView.numberOfSections).reduce(0) { $0 + self.collectionView.numberOfItems(inSection: $1) }
                let newTotal = allMessages.count

                if newTotal == currentTotal + 1 && viewModel.currentSections.count == self.collectionView.numberOfSections {
                    // 동일 섹션에 메시지 1개 추가
                    let lastSection = viewModel.currentSections.count - 1
                    let lastItem = viewModel.currentSections[lastSection].messages.count - 1
                    let indexPath = IndexPath(item: lastItem, section: lastSection)

                    self.collectionView.performBatchUpdates({
                        self.collectionView.insertItems(at: [indexPath])
                    }) { _ in
                        self.scrollToBottom(animated: true)
                    }
                } else {
                    // 모드 변경, 대량 로딩, 섹션 추가 등 -> 전체 갱신
                    self.collectionView.reloadData()
                    self.collectionView.layoutIfNeeded()

                    if self.isPrependingHistory {
                        // 이전 페이지가 앞에 붙어 콘텐츠가 위로 늘어난 만큼 오프셋을 더해 보던 위치 유지
                        self.isPrependingHistory = false
                        let diff = self.collectionView.contentSize.height - self.contentHeightBeforePrepend
                        self.collectionView.contentOffset.y += diff
                    } else if newTotal > 0 {
                        self.scrollToBottom(animated: false)
                        // 셀프사이징으로 셀 크기가 나중에 확정되며 오프셋이 어긋나는 것 보정
                        DispatchQueue.main.async {
                            self.scrollToBottom(animated: false)
                        }
                    }
                }
            })
            .disposed(by: disposeBag)
        
        inputBar.rx.receiptButtonTap
            .subscribe(onNext: { [weak self] in
                self?.presentReceiptPicker()
            })
            .disposed(by: disposeBag)
        
        viewModel.isSheetPresent
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isPresent in
                guard let self = self else { return }
                
                if isPresent {
                    let vc = SaveModalViewController(viewModel: viewModel, calendarViewModel: calendarViewModel)
                    let nav = UINavigationController(rootViewController: vc)
                    
                    if let sheet = nav.sheetPresentationController {
                        sheet.detents = [
                            .custom(identifier: .init("threeFifths")) { context in
                                let screenWidth = UIScreen.main.bounds.width
                                let ratio: CGFloat = screenWidth <= 375 ? 0.55 : 0.5
                                return context.maximumDetentValue * ratio
                            }
                        ]
                    }
                    present(nav, animated: true)
                } else {
                    dismiss(animated: true) { [weak self] in
                        self?.presentAdAfterSaveIfNeeded()
                    }
                }
            })
            .disposed(by: disposeBag)

        viewModel.didSaveTransaction
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.pendingAdAfterSave = true
            })
            .disposed(by: disposeBag)
        
        viewModel.isLoading
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isLoading in
                guard let self = self else { return }

                if isLoading {
                    self.loadingStackView.isHidden = false
                    self.lottieView.play()

                    // 로딩 중엔 다른 버튼 못 누르게 막기
                    self.view.isUserInteractionEnabled = false
                } else {
                    self.lottieView.stop() // 배터리 절약을 위해 stop
                    self.loadingStackView.isHidden = true
                    self.view.isUserInteractionEnabled = true
                }
            })
            .disposed(by: disposeBag)

        viewModel.errorRelay
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] error in
                guard let self else { return }
                let appError = AppError.from(error)
                self.showToast(message: appError.errorDescription ?? AppError.unknown.errorDescription!)
            })
            .disposed(by: disposeBag)
    }

    // 배경 상태 결정: 메시지 있음 → 없음, 최초 로딩 중 → 스켈레톤, 그 외 빈 상태 → 안내 뷰
    private func updateBackground(isEmpty: Bool) {
        // 스켈레톤이 떠 있는 최초 로딩 중에는 입력/상호작용 차단
        inputBar.isUserInteractionEnabled = !isInitialLoading

        if !isEmpty {
            skeletonView.stopShimmer()
            collectionView.backgroundView = nil
            return
        }

        if isInitialLoading {
            collectionView.backgroundView = skeletonView
            skeletonView.startShimmer()
            return
        }

        skeletonView.stopShimmer()

        let mode = ChatMode(index: viewModel.selectedIndex.value)
        let emptyStateView = EmptyStateView()
        if mode == .receipt {
            emptyStateView.messageLabel.text = "가계부를 입력해 주세요!"
            emptyStateView.descriptionLabel.isHidden = false
            emptyStateView.exampleBox.isHidden = false
        } else {
            emptyStateView.messageLabel.text = "오늘 하루 어땠어요?"
            emptyStateView.descriptionLabel.isHidden = true
            emptyStateView.exampleBox.isHidden = true
        }
        collectionView.backgroundView = emptyStateView
    }

    @objc func keyboardWillChangeFrame(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let frame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        else { return }
        
        // 레이아웃이 줄어들기 전에 바닥 여부를 캡처 (줄어든 뒤엔 항상 false로 판정됨)
        let wasAtBottom = isAtBottom

        let keyboardFrameInView = view.convert(frame, from: nil)
        let overlap = max(view.bounds.maxY - keyboardFrameInView.origin.y, 0)
        // 키보드가 없으면 탭바 위(offset 0)에 도킹, 있으면 키보드 위로 올림.
        let offset = overlap > 0 ? -(overlap - view.safeAreaInsets.bottom) : 0
        inputBarBottomConstraint?.update(offset: offset)

        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()

            if wasAtBottom {
                self.scrollToBottom(animated: false)
            }
        }
    }
    
    func scrollToBottom(animated: Bool = true) {
        let sectionCount = collectionView.numberOfSections
        guard sectionCount > 0 else { return }
        let lastSection = sectionCount - 1
        let itemCount = collectionView.numberOfItems(inSection: lastSection)
        guard itemCount > 0 else { return }

        let indexPath = IndexPath(item: itemCount - 1, section: lastSection)

        collectionView.layoutIfNeeded()
        collectionView.scrollToItem(at: indexPath, at: .bottom, animated: animated)
    }
    
    func updateInputBarHeight() {
        // 입력바 높이가 바뀌면 collectionView(입력바 top에 붙어있음)가 자동으로 축소/확장된다.
        inputBar.invalidateIntrinsicContentSize()

        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()

            if self.isAtBottom {
                self.scrollToBottom(animated: false)
            }
        }
    }
}

extension ChatViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    // 상단에서 3번째 이내(가장 오래된 섹션의 앞쪽) 아이템이 화면에 나타나면
    // 이전(더 오래된) 페이지를 이어서 로드한다.
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard viewModel.canLoadMoreHistory else { return }
        // 전체 타임라인의 맨 앞(가장 오래된) 3개 안에 드는 셀인지 확인
        guard indexPath.section == 0, indexPath.item <= 2 else { return }
        isPrependingHistory = true
        contentHeightBeforePrepend = collectionView.contentSize.height
        viewModel.loadMoreHistory()
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return viewModel.currentSections.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.currentSections[section].messages.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ChatCollectionViewCell.identifier, for: indexPath) as? ChatCollectionViewCell else {
            return UICollectionViewCell()
        }

        let message = viewModel.currentSections[indexPath.section].messages[indexPath.row]
        UIView.performWithoutAnimation {
            cell.bind(with: message)
            cell.layoutIfNeeded()
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let message = viewModel.currentSections[indexPath.section].messages[indexPath.item]

        sizingCell.bind(with: message)

        let targetSize = CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height)

        let exactSize = sizingCell.contentView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )

        return exactSize
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: DateHeaderView.id,
                for: indexPath
            ) as! DateHeaderView

            header.dateLabel.text = viewModel.currentSections[indexPath.section].dateString

            return header
        }
        return UICollectionReusableView()
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if viewModel.currentSections.isEmpty {
            return .zero
        }
        return CGSize(width: collectionView.frame.width, height: 50)
    }
}

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate {
    // 영수증 버튼 → 홈과 동일한 커스텀 갤러리 시트(카메라 셀 + 사진 그리드)
    func presentReceiptPicker() {
        dismissKeyboard()
        let picker = ReceiptPickerViewController()
        picker.onPickImage = { [weak self] image in
            self?.viewModel.sendChat(image: image)
        }
        picker.modalPresentationStyle = .fullScreen
        present(picker, animated: true)
    }

    func openCamera() {
        imagePicker.sourceType = .camera
        present(imagePicker, animated: false, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true)
        
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage{
            self.viewModel.sendChat(image: image)
        }
    }
    
    func openLibrary(){
        imagePicker.sourceType = .photoLibrary
        //        imagePicker.allowsEditing = true
        present(imagePicker, animated: false, completion: nil)
    }
    
    func openPicker() {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let phPicker = PHPickerViewController(configuration: config)
        phPicker.delegate = self
        dismissKeyboard()
        present(phPicker, animated: true, completion: nil)
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let result = results.first else { return }
        
        let provider = result.itemProvider
        if provider.canLoadObject(ofClass: UIImage.self) {
            provider.loadObject(ofClass: UIImage.self) { image, error in
                DispatchQueue.main.async {
                    if let image = image as? UIImage {
                        self.viewModel.sendChat(image: image)
                    }
                }
            }
        }
    }
}

extension ChatViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // 입력바(전송 버튼 등) 위 탭은 dismiss 제스처가 가로채지 않도록 → 버튼이 한 번에 동작
        if let touched = touch.view, touched.isDescendant(of: inputBar) {
            return false
        }
        return true
    }
}
