//
//  SaveModalViewController.swift
//  Cloverly
//
//  Created by 이인호 on 12/25/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

class SaveModalViewController: UIViewController {
    private let viewModel: ChatViewModel
    private let disposeBag = DisposeBag()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "아래와 같이 저장할까요?"
        label.textColor = .gray1
        label.font = .customFont(.pretendardSemiBold, size: 18)
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "*홈 > 내역탭에서 수정이 가능합니다"
        label.textColor = .gray5
        label.font = .customFont(.pretendardRegular, size: 13)
        return label
    }()
    
    private lazy var xButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "Modal Close Button"), for: .normal)
        button.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }
            
            var current = self.viewModel.messages.value
            guard !current.isEmpty else { return }
            current.removeLast()
            self.viewModel.messages.accept(current)
            
            self.viewModel.isSheetPresent.accept(false)
        }, for: .touchUpInside)
        
        return button
    }()
    
    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        stack.distribution = .fill
        return stack
    }()
    
    private let storeNameValueLabel = UILabel()
    private let amountValueLabel = UILabel()
    private let dateValueLabel = UILabel()
    private let emotionValueLabel = UILabel()
    private let contentValueLabel = UILabel()
    private let paymentMethodValueLabel = UILabel()
    private let categoryValueLabel = UILabel()
    
    private lazy var saveButton: UIButton = {
        let button = UIButton()
        button.setTitle("저장", for: .normal)
        button.setTitleColor(.gray10, for: .normal)
        button.titleLabel?.font = .customFont(.pretendardSemiBold, size: 16)
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        button.backgroundColor = .green5
        button.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }
            let parentVC = self.presentingViewController
            
            Task {
                do {
                    try await self.viewModel.saveTransaction()
                    
                    self.viewModel.isSheetPresent.accept(false)
                    
                    parentVC?.showToast(
                        message: "내역에 저장되었습니다.",
                        buttonTitle: "보기 >"
                    ) { [weak self] in
                        if let nav = parentVC as? UINavigationController {
                            nav.popViewController(animated: true)
                        } else {
                            parentVC?.navigationController?.popViewController(animated: true)
                        }
                        
                        NotificationCenter.default.post(
                            name: .changeTab,
                            object: nil,
                            userInfo: ["index": 1]
                        )
                    }
                } catch {
                    print("저장 실패: \(error)")
                }
            }
        }, for: .touchUpInside)
        
        return button
    }()
    
    init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        isModalInPresentation = true
        configureUI()
        bind()
    }
    
    func configureUI() {
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(xButton)
        view.addSubview(contentStackView)
        view.addSubview(saveButton)
        
        addInfoRow(title: "상호명", valueLabel: storeNameValueLabel)
        addInfoRow(title: "금액", valueLabel: amountValueLabel)
        addInfoRow(title: "결제일", valueLabel: dateValueLabel)
        addInfoRow(title: "감정", valueLabel: emotionValueLabel)
        addInfoRow(title: "지출내역", valueLabel: contentValueLabel)
        addInfoRow(title: "결제수단", valueLabel: paymentMethodValueLabel)
        addInfoRow(title: "카테고리", valueLabel: categoryValueLabel)
        
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.top.equalToSuperview().offset(24)
        }
        
        subtitleLabel.snp.makeConstraints {
            $0.leading.equalTo(titleLabel.snp.leading)
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
        }
        
        xButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalTo(titleLabel)
        }
        
        contentStackView.snp.makeConstraints {
            $0.top.equalTo(subtitleLabel.snp.bottom).offset(24)
            $0.leading.equalToSuperview().offset(16)
            $0.bottom.equalTo(saveButton.snp.top).offset(-33)
        }
        
        saveButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().offset(-34)
            $0.height.equalTo(56)
        }
    }
    
    private func addInfoRow(title: String, valueLabel: UILabel) {
        let rowStack = UIStackView()
        rowStack.axis = .horizontal
        rowStack.spacing = 20
        rowStack.alignment = .firstBaseline
        
        let keyLabel = UILabel()
        keyLabel.text = title
        keyLabel.font = .customFont(.pretendardRegular, size: 16)
        keyLabel.textColor = .gray4
        
        keyLabel.snp.makeConstraints {
            $0.width.equalTo(70)
        }
        
        valueLabel.font = .customFont(.pretendardMedium, size: 16)
        valueLabel.textColor = .gray1
        valueLabel.numberOfLines = 0
        valueLabel.textAlignment = .left
        
        rowStack.addArrangedSubview(keyLabel)
        rowStack.addArrangedSubview(valueLabel)
        
        contentStackView.addArrangedSubview(rowStack)
    }
    
    func bind() {
        viewModel.chatResponse
            .observe(on: MainScheduler.instance)
            .compactMap { $0 }
            .subscribe(onNext: { [weak self] info in
                guard let self = self else { return }

                let transactionInfo = info.transactionInfo
                storeNameValueLabel.text = transactionInfo.place
                amountValueLabel.text = "\(transactionInfo.totalAmount)"
                dateValueLabel.text = transactionInfo.transactionDate
                emotionValueLabel.text = transactionInfo.emotion.displayName
                contentValueLabel.text = transactionInfo.transactions.map { $0.name }.joined(separator: ", ")
                paymentMethodValueLabel.text = transactionInfo.payment.displayName
                categoryValueLabel.text = Array(Set(transactionInfo.transactions.map { $0.categoryName })).joined(separator: ", ")
            })
            .disposed(by: disposeBag)
    }
}
