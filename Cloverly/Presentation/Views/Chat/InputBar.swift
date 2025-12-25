//
//  InputBar.swift
//  Cloverly
//
//  Created by 이인호 on 12/11/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

class InputBar: UIView {
    private let viewModel: ChatViewModel
    private let disposeBag = DisposeBag()
    private var textViewHeightConstraint: Constraint?
    
    private let minTextViewHeight: CGFloat = 36
    private let maxTextViewHeight: CGFloat = 120
    
    let heightUpdateNeeded = PublishRelay<Void>()
    
    lazy var textView: UITextView = {
        let textView = UITextView()
        textView.font = .customFont(.pretendardMedium, size: 16)
        textView.isScrollEnabled = false
        textView.delegate = self
        textView.pasteDelegate = self
        return textView
    }()
    
    lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = "오늘의 소비 내역을 알려주세요!"
        label.font = .customFont(.pretendardMedium, size: 16)
        label.textColor = .gray7
        label.sizeToFit()
        label.isHidden = !textView.text.isEmpty
        return label
    }()
    
    fileprivate lazy var galleryButton: UIButton = {
        var config = UIButton.Configuration.plain()
        
        config.title = "사진"
        config.baseForegroundColor = .gray3
        
        config.image = UIImage(named: "image icon")
        config.imagePlacement = .leading
        config.imagePadding = 4
        
//        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        
        config.background.strokeColor = .gray8
        config.background.strokeWidth = 1
        config.cornerStyle = .capsule
        
        var titleAttr = AttributedString.init("사진")
        titleAttr.font = .customFont(.pretendardMedium, size: 14)
        config.attributedTitle = titleAttr
        
        let button = UIButton(configuration: config)
        return button
    }()
    
    fileprivate lazy var cameraButton: UIButton = {
        var config = UIButton.Configuration.plain()
        
        config.title = "카메라"
        config.baseForegroundColor = .gray3
        
        config.image = UIImage(named: "camera icon")
        config.imagePlacement = .leading
        config.imagePadding = 4
        
        config.background.strokeColor = .gray8
        config.background.strokeWidth = 1
        config.cornerStyle = .capsule
        
        var titleAttr = AttributedString.init("카메라")
        titleAttr.font = .customFont(.pretendardMedium, size: 14)
        config.attributedTitle = titleAttr
        
        let button = UIButton(configuration: config)
        
        return button
    }()
    
    fileprivate lazy var pasteButton: UIButton = {
        var config = UIButton.Configuration.plain()
        
        config.title = "붙여넣기"
        config.baseForegroundColor = .gray3
        
        config.image = UIImage(named: "paste icon")
        config.imagePlacement = .leading
        config.imagePadding = 4
        
        config.background.strokeColor = .gray8
        config.background.strokeWidth = 1
        config.cornerStyle = .capsule
        
        var titleAttr = AttributedString.init("붙여넣기")
        titleAttr.font = .customFont(.pretendardMedium, size: 14)
        config.attributedTitle = titleAttr
        
        let button = UIButton(configuration: config)
        button.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }
            
            textView.becomeFirstResponder()
            textView.paste(nil)
        }, for: .touchUpInside)
        return button
    }()
    
    lazy var sendButton: UIButton = {
        let sendButton = UIButton()
        sendButton.setImage(UIImage(named: "send button enabled"), for: .normal)
        sendButton.setImage(UIImage(named: "Send Button disabled"), for: .disabled)
        sendButton.isEnabled = false
        return sendButton
    }()
    
    init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        backgroundColor = .white
        autoresizingMask = .flexibleHeight
        configureUI()
        bind()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        applyTopShadow()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureUI() {
        textView.addSubview(placeholderLabel)
        addSubview(textView)
        addSubview(galleryButton)
        addSubview(cameraButton)
        addSubview(pasteButton)
        addSubview(sendButton)
        
        textView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalTo(sendButton.snp.leading).offset(-8).priority(999)
            $0.top.equalToSuperview().offset(22)
            textViewHeightConstraint = $0.height.equalTo(minTextViewHeight).constraint
        }
        
        placeholderLabel.snp.makeConstraints {
            $0.leading.equalTo(textView.snp.leading).offset(textView.textContainerInset.left + textView.textContainer.lineFragmentPadding)
            $0.top.equalTo(textView.snp.top).offset(textView.textContainerInset.top)
        }
        
        galleryButton.snp.makeConstraints {
            $0.leading.equalTo(textView.snp.leading)
            $0.top.equalTo(textView.snp.bottom).offset(15)
            $0.height.equalTo(30)
            $0.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).offset(-14).priority(999)
        }
        
        cameraButton.snp.makeConstraints {
            $0.leading.equalTo(galleryButton.snp.trailing).offset(8)
            $0.centerY.equalTo(galleryButton.snp.centerY)
            $0.height.equalTo(30)
        }
        
        pasteButton.snp.makeConstraints {
            $0.leading.equalTo(cameraButton.snp.trailing).offset(8)
            $0.centerY.equalTo(galleryButton.snp.centerY)
            $0.height.equalTo(30)
        }
        
        sendButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalTo(galleryButton.snp.centerY)
            $0.width.equalTo(48)
        }
        
        updateTextViewHeight()
    }
    
    private func bind() {
        textView.rx.didChange
            .do(onNext: { [weak self] in
                self?.updateTextViewHeight()
            })
            .map { _ in Void() }
            .bind(to: heightUpdateNeeded)
            .disposed(by: disposeBag)
        
        textView.rx.text.orEmpty
            .map { text in
                return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            .distinctUntilChanged()
            .bind(to: sendButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        sendButton.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }
            
            let inputText = self.textView.text ?? ""
            let message = Message(kind: .text(inputText), chatType: .send)
            self.viewModel.messages.accept(self.viewModel.messages.value + [message])
            
            textView.text = ""
            placeholderLabel.isHidden = false
            updateTextViewHeight()
            
            heightUpdateNeeded.accept(())
            print("\(message) 전송!")
        }, for: .touchUpInside)
    }
    
    override var intrinsicContentSize: CGSize {
        let size = textView.sizeThatFits(CGSize(width: textView.bounds.width, height: .infinity))
        
        // 여백(Padding) 더하기 (위아래 여백 합쳐서 16이라고 가정)
        let totalHeight = size.height + 16
        
        // 최대 높이 제한 로직 (이걸 해야 무한정 안 늘어남)
        return CGSize(width: bounds.width, height: min(totalHeight, maxTextViewHeight))
    }
    
    private func updateTextViewHeight() {
        let fittingSize = CGSize(width: textView.bounds.width, height: .greatestFiniteMagnitude)
        let calculatedHeight = textView.sizeThatFits(fittingSize).height
        let clampedHeight = min(max(calculatedHeight, minTextViewHeight), maxTextViewHeight)
        
        textView.isScrollEnabled = calculatedHeight > maxTextViewHeight
        textViewHeightConstraint?.update(offset: clampedHeight)
        invalidateIntrinsicContentSize()
        layoutIfNeeded()
    }
}

extension InputBar: UITextViewDelegate {
    func textViewDidEndEditing(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }
    
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }
}

extension InputBar: UITextPasteDelegate {
    func textPasteConfigurationSupporting(_ textPasteConfigurationSupporting: any UITextPasteConfigurationSupporting, combineItemAttributedStrings itemStrings: [NSAttributedString], for textRange: UITextRange) -> NSAttributedString {
        let text = itemStrings.first?.string ?? ""
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return NSAttributedString(string: trimmed)
    }
}

extension Reactive where Base: InputBar {
    var cameraButtonTap: ControlEvent<Void> {
        return base.cameraButton.rx.tap
    }
    
    var gallaryButtonTap: ControlEvent<Void> {
        return base.galleryButton.rx.tap
    }
}
