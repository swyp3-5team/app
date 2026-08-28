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
    private let calendarViewModel: CalendarViewModel
    private let disposeBag = DisposeBag()
    
    private let titleLabel: AppLabel = {
        let label = AppLabel()
        label.text = "아래와 같이 저장할까요?"
        label.textColor = .gray1
        label.typography = .t1
        return label
    }()
    
    private let subtitleLabel: AppLabel = {
        let label = AppLabel()
        label.text = "*하단 [내역]탭에서 수정이 가능합니다."
        label.textColor = .gray5
        label.typography = .l1
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
    
    private let amountValueLabel = AppLabel()
    private let dateValueLabel = AppLabel()
    private let emotionValueLabel = AppLabel()
    private let contentValueLabel = AppLabel()
    private let paymentMethodValueLabel = AppLabel()
    private let categoryValueLabel = AppLabel()

    // 수입 등으로 값이 없을 때 행 자체를 숨기기 위한 참조
    private var emotionRow: UIStackView?
    private var paymentRow: UIStackView?
    
    private lazy var saveButton: UIButton = {
        let button = UIButton()
        button.setTitle("저장", for: .normal)
        button.setTitleColor(.gray10, for: .normal)
        button.titleLabel?.font = Typography.b1.uiFont
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        button.backgroundColor = .green5
        button.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }
            let parentVC = self.presentingViewController
            
            Task {
                do {
                    try await self.viewModel.saveTransaction()
                    self.calendarViewModel.refreshTrigger.accept(())
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
                            userInfo: ["index": 2]
                        )
                    }
                } catch {
                    self.showErrorToast(error)
                }
            }
        }, for: .touchUpInside)

        return button
    }()
    
    init(viewModel: ChatViewModel, calendarViewModel: CalendarViewModel) {
        self.viewModel = viewModel
        self.calendarViewModel = calendarViewModel
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard let navBar = navigationController?.navigationBar else { return }
        let navBarFrameInView = navBar.convert(navBar.bounds, to: view)

        titleLabel.snp.remakeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.centerY.equalTo(navBarFrameInView.midY)
        }

        updateSheetDetent()
    }

    private var appliedDetentHeight: CGFloat = 0

    // 콘텐츠(저장 버튼 하단 + 여백)에 맞춰 시트 높이를 재조정. 수입처럼 행이 숨겨지면 그만큼 짧아진다.
    private func updateSheetDetent() {
        guard let nav = navigationController,
              let sheet = nav.sheetPresentationController else { return }

        let buttonMaxY = saveButton.convert(saveButton.bounds, to: nav.view).maxY
        let height = buttonMaxY + 34
        guard height > 0, abs(height - appliedDetentHeight) > 0.5 else { return }
        appliedDetentHeight = height

        sheet.animateChanges {
            sheet.detents = [.custom(identifier: .init("saveModalFit")) { context in
                min(height, context.maximumDetentValue)
            }]
        }
    }
    
    func configureUI() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: xButton)
        
        view.backgroundColor = .gray10
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(contentStackView)
        view.addSubview(saveButton)
        
        addInfoRow(title: "날짜", valueLabel: dateValueLabel)
        addInfoRow(title: "금액", valueLabel: amountValueLabel)
        addInfoRow(title: "내용", valueLabel: contentValueLabel)
        addInfoRow(title: "카테고리", valueLabel: categoryValueLabel)
        emotionRow = addInfoRow(title: "감정", valueLabel: emotionValueLabel)
        paymentRow = addInfoRow(title: "결제수단", valueLabel: paymentMethodValueLabel)
        
        subtitleLabel.snp.makeConstraints {
            $0.leading.equalTo(titleLabel.snp.leading)
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
        }
        
        // 콘텐츠(행)와 저장 버튼을 위에서 아래로 흐르게 배치해, 시트 높이를 콘텐츠에 맞출 수 있게 한다.
        contentStackView.snp.makeConstraints {
            $0.top.equalTo(subtitleLabel.snp.bottom).offset(24)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().offset(-20)
        }

        saveButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.top.equalTo(contentStackView.snp.bottom).offset(30)
            $0.height.equalTo(56)
        }
    }
    
    @discardableResult
    private func addInfoRow(title: String, valueLabel: AppLabel) -> UIStackView {
        let rowStack = UIStackView()
        rowStack.axis = .horizontal
        rowStack.spacing = 20
        rowStack.alignment = .firstBaseline

        let keyLabel = AppLabel()
        keyLabel.text = title
        keyLabel.typography = .b3
        keyLabel.textColor = .gray4

        keyLabel.snp.makeConstraints {
            $0.width.equalTo(70)
        }

        valueLabel.typography = .b2
        valueLabel.textColor = .gray1
        valueLabel.numberOfLines = 0
        valueLabel.textAlignment = .left

        rowStack.addArrangedSubview(keyLabel)
        rowStack.addArrangedSubview(valueLabel)

        contentStackView.addArrangedSubview(rowStack)
        return rowStack
    }
    
    func bind() {
        viewModel.chatResponse
            .observe(on: MainScheduler.instance)
            .compactMap { $0 }
            .subscribe(onNext: { [weak self] info in
                guard let self = self, let transactionInfo = info.transactionInfo else { return }

                let items = transactionInfo.transactions
                dateValueLabel.text = transactionInfo.transactionDate
                amountValueLabel.text = "\(transactionInfo.totalAmount.withComma)원"
                contentValueLabel.text = items.isEmpty ? "미입력" : items.map { $0.name }.joined(separator: ", ")
                categoryValueLabel.text = Array(Set(items.map { $0.categoryName })).joined(separator: ", ")
                // 수입 등으로 감정/결제수단이 없으면 해당 행 자체를 숨긴다 (시트 높이는 프레젠트 시 반영)
                emotionValueLabel.text = transactionInfo.emotion?.displayName ?? "-"
                paymentMethodValueLabel.text = transactionInfo.payment?.displayName ?? "-"
                emotionRow?.isHidden = (transactionInfo.emotion == nil)
                paymentRow?.isHidden = (transactionInfo.payment == nil)
            })
            .disposed(by: disposeBag)
    }
}
