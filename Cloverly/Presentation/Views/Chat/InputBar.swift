//
//  InputBar.swift
//  Cloverly
//
//  Created by 이인호 on 12/11/25.
//

import UIKit

class InputBar: UIView {
    private let viewModel: ChatViewModel
    
    lazy var textView: UITextView = {
        let textView = UITextView()
        textView.isScrollEnabled = false
        textView.delegate = self
        return textView
    }()
    
    lazy var sendButton: UIButton = {
        let sendButton = UIButton(type: .system)
        sendButton.setTitle("전송", for: .normal)
        sendButton.addAction(UIAction { [weak self] _ in

        }, for: .touchUpInside)
        return sendButton
    }()
    
    init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        backgroundColor = .secondarySystemBackground
        autoresizingMask = .flexibleHeight
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureUI() {
        addSubview(textView)
        addSubview(sendButton)
        textView.translatesAutoresizingMaskIntoConstraints = false
        sendButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            textView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            textView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -8),
            
            sendButton.leadingAnchor.constraint(equalTo: textView.trailingAnchor, constant: 8),
            sendButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            sendButton.centerYAnchor.constraint(equalTo: textView.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 48)
        ])
    }
}

extension InputBar: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        
    }
}
