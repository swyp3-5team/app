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
        textView.font = .systemFont(ofSize: 14)
        textView.isScrollEnabled = false
        textView.delegate = self
        textView.pasteDelegate = self
        return textView
    }()
    
    lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = "텍스트를 입력하세요"
        label.font = .systemFont(ofSize: 14)
        label.textColor = UIColor.lightGray
        label.sizeToFit()
        label.isHidden = !textView.text.isEmpty
        return label
    }()
    
    fileprivate lazy var cameraButton: UIButton = {
        let button = UIButton()
        button.setTitle("카메라", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.gray.cgColor
        return button
    }()
    
    fileprivate lazy var galleryButton: UIButton = {
        let button = UIButton()
        button.setTitle("사진", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.gray.cgColor
        return button
    }()
    
    fileprivate lazy var pasteButton: UIButton = {
        let button = UIButton()
        button.setTitle("붙여넣기", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.gray.cgColor
        button.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }
            
            textView.becomeFirstResponder()
            textView.paste(nil)
        }, for: .touchUpInside)
        return button
    }()
    
    lazy var sendButton: UIButton = {
        let sendButton = UIButton(type: .system)
        sendButton.setTitle("전송", for: .normal)
        return sendButton
    }()
    
    init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        backgroundColor = .white
        autoresizingMask = .flexibleHeight
        configureUI()
        setupBinding()
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
        addSubview(cameraButton)
        addSubview(galleryButton)
        addSubview(pasteButton)
        addSubview(sendButton)
        
        textView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.trailing.equalTo(sendButton.snp.leading).offset(-8)
            $0.top.equalToSuperview().offset(8)
            textViewHeightConstraint = $0.height.equalTo(minTextViewHeight).constraint
        }
        
        placeholderLabel.snp.makeConstraints {
            $0.leading.equalTo(textView.snp.leading).offset(textView.textContainerInset.left + textView.textContainer.lineFragmentPadding)
            $0.top.equalTo(textView.snp.top).offset(textView.textContainerInset.top)
        }
        
        cameraButton.snp.makeConstraints {
            $0.leading.equalTo(textView.snp.leading)
            $0.top.equalTo(textView.snp.bottom).offset(8)
            $0.height.equalTo(36)
            $0.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).offset(-8)
        }
        
        galleryButton.snp.makeConstraints {
            $0.leading.equalTo(cameraButton.snp.trailing).offset(8)
            $0.centerY.equalTo(cameraButton.snp.centerY)
        }
        
        pasteButton.snp.makeConstraints {
            $0.leading.equalTo(galleryButton.snp.trailing).offset(8)
            $0.centerY.equalTo(cameraButton.snp.centerY)
        }
        
        sendButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-12)
            $0.centerY.equalTo(cameraButton.snp.centerY)
            $0.width.equalTo(48)
        }
        
        updateTextViewHeight()
    }
    
    private func setupBinding() {
        textView.rx.didChange
            .do(onNext: { [weak self] in
                self?.updateTextViewHeight()
            })
            .map { _ in Void() }
            .bind(to: heightUpdateNeeded)
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
