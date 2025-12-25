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

extension UINavigationController {
    open override func viewWillLayoutSubviews() {
        navigationBar.topItem?.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
}

class ChatViewController: UIViewController {
    private let disposeBag = DisposeBag()
    private let viewModel = ChatViewModel()
    private let sizingCell = ChatCollectionViewCell()
    private lazy var inputBar = InputBar(viewModel: viewModel)
    
    lazy var segmented = CustomSegmentedControl(viewModel: viewModel, items: ["가계부", "대화"], cornerRadius: 17)
    
    var overlayWindow: UIWindow?
    
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
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        layout.minimumLineSpacing = 20
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.register(ChatCollectionViewCell.self, forCellWithReuseIdentifier: ChatCollectionViewCell.identifier)
        cv.delegate = self
        cv.dataSource = self
        cv.keyboardDismissMode = .interactive
        
        return cv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
        bind()
        textBind()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
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

    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    
        if !UserDefaults.standard.bool(forKey: "hasSeenCoachMark") {
            showCoachMark()
            UserDefaults.standard.set(true, forKey: "hasSeenCoachMark")
        }
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
        let targetButtons = [self.inputBar.galleryButton, self.inputBar.cameraButton, self.inputBar.pasteButton]
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
    
    override var inputAccessoryView: UIView? {
        return inputBar
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    @objc func dismissKeyboard() {
        //        view.window?.endEditing(true)
        inputBar.textView.resignFirstResponder()
    }
    
    func configure() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        view.backgroundColor = .systemBackground
        
        collectionView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        
        segmented.snp.makeConstraints {
            $0.width.equalTo(120)
            $0.height.equalTo(34)
        }
        
        collectionView.register(
            DateHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: DateHeaderView.id
        )
        
        navigationItem.titleView = segmented
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
        viewModel.messages
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] newMessages in
                guard let self = self else { return }
                
                if newMessages.isEmpty {
                    self.collectionView.backgroundView = EmptyStateView() // 아까 만든 뷰 클래스
                } else {
                    self.collectionView.backgroundView = nil
                }
                
                let currentCount = self.collectionView.numberOfSections > 0 ? self.collectionView.numberOfItems(inSection: 0) : 0
                let newCount = newMessages.count
                
                if currentCount == 0 || newCount <= currentCount {
                    self.collectionView.reloadData()
                    self.scrollToBottom(animated: false)
                    return
                }
                
                var indexPaths: [IndexPath] = []
                for i in currentCount..<newCount {
                    indexPaths.append(IndexPath(item: i, section: 0))
                }
                
                self.collectionView.performBatchUpdates({
                    self.collectionView.insertItems(at: indexPaths)
                }) { _ in
                    self.scrollToBottom(animated: true)
                }
                // 버벅임 이슈 수정 필요
                //                self.collectionView.reloadData()
                //                self.scrollToBottom(animated: false)
                
            })
            .disposed(by: disposeBag)
        
        inputBar.rx.cameraButtonTap
            .subscribe(onNext: { [weak self] in
                self?.openCamera()
            })
            .disposed(by: disposeBag)
        
        inputBar.rx.gallaryButtonTap
            .subscribe(onNext: { [weak self] in
                self?.openPicker()
            })
            .disposed(by: disposeBag)
        
        viewModel.isSheetPresent
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isPresent in
                guard let self = self else { return }
                
                if isPresent {
                    let vc = ExpenseHistoryViewController()
                    let nav = UINavigationController(rootViewController: vc)
                    nav.modalPresentationStyle = .fullScreen
                    
                    present(nav, animated: true)
                }
            })
            .disposed(by: disposeBag)
    }
    
    @objc func keyboardWillChangeFrame(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let frame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        else { return }
        
        let keyboardHeight = frame.height
        
        let bottomInset: CGFloat
        
        if keyboardHeight > 0 {
            bottomInset = keyboardHeight /*- 간격 없이 딱 view.safeAreaInsets.bottom*/
        } else {
            bottomInset = inputBar.frame.height
        }
        
        UIView.animate(withDuration: duration) {
            self.collectionView.contentInset.bottom = bottomInset
            self.collectionView.verticalScrollIndicatorInsets.bottom = bottomInset
            
            if self.isAtBottom {
                self.scrollToBottom(animated: false)
            }
        }
    }
    
    func scrollToBottom(animated: Bool = true) {
        let section = 0
        let itemCount = collectionView.numberOfItems(inSection: section)
        guard itemCount > 0 else { return }
        
        let indexPath = IndexPath(item: itemCount - 1, section: section)
        
        collectionView.layoutIfNeeded()
        collectionView.scrollToItem(at: indexPath, at: .bottom, animated: animated)
    }
    
    func updateInputBarHeight() {
        let oldHeight = inputBar.frame.height
        
        // 높이 갱신 요청
        inputBar.invalidateIntrinsicContentSize()
        inputBar.layoutIfNeeded() // 즉시 반영
        
        let newHeight = inputBar.frame.height
        
        // 변화량 계산 (예: 50 -> 70이면 +20)
        let diff = newHeight - oldHeight
        
        guard diff != 0 else { return }
        
        UIView.animate(withDuration: 0.2) {
            self.collectionView.contentInset.bottom += diff
            self.collectionView.verticalScrollIndicatorInsets.bottom += diff
            
            if self.isAtBottom {
                self.scrollToBottom(animated: false)
            }
            
            self.view.layoutIfNeeded()
        }
    }
}

extension ChatViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.messages.value.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ChatCollectionViewCell.identifier, for: indexPath) as? ChatCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        let message = viewModel.messages.value[indexPath.row]
        UIView.performWithoutAnimation {
            cell.bind(with: message)
            cell.layoutIfNeeded()
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let message = viewModel.messages.value[indexPath.item]
        
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
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy년 MM월 dd일 EEEE"
            formatter.locale = Locale(identifier: "ko_KR")
            let todayString = formatter.string(from: Date())
            
            header.dateLabel.text = "\(todayString)"
            
            return header
        }
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        if viewModel.messages.value.isEmpty {
            return .zero
        }
        
        return CGSize(width: collectionView.frame.width, height: 50)
    }
}

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate {
    func openCamera() {
        imagePicker.sourceType = .camera
        present(imagePicker, animated: false, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true)
        
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage{
            let message = Message(kind: .photo(image), chatType: .send)
            self.viewModel.messages.accept(self.viewModel.messages.value + [message])
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
                        let message = Message(kind: .photo(image), chatType: .send)
                        self.viewModel.messages.accept(self.viewModel.messages.value + [message])
                        self.viewModel.sendChat(message: "ㅇㅇ", image: image)
                    }
                }
            }
        }
    }
}
