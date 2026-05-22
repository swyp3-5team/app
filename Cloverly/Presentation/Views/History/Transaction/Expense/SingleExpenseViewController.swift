//
//  SingleExpenseViewController.swift
//  Cloverly
//
//  Created by 이인호 on 5/21/26.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

class SingleExpenseViewController: UIViewController {
    private let viewModel: TransactionViewModel
    private let disposeBag = DisposeBag()
    private var selectedDate: Date = Date()

    private var originalContentOffset: CGPoint = .zero
    private var isScrolledForKeyboard = false

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    let requestMultiMode = PublishRelay<Void>()

    var canSave: Observable<Bool> {
        Observable.combineLatest(
            viewModel.currentAmount,
            viewModel.selectedCategoryId,
            viewModel.selectedEmotion,
            viewModel.selectedPayment
        )
        .map { amount, categoryId, emotion, payment in
            amount > 0 && categoryId != nil && emotion != nil && payment != nil
        }
    }

    // MARK: - UI

    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        return sv
    }()

    private lazy var stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 40
        return sv
    }()

    private lazy var dateLabelView: AppLabel = {
        let label = AppLabel()
        label.textAlignment = .right
        label.typography = .b1
        label.textColor = .gray1
        label.isUserInteractionEnabled = true
        return label
    }()

    private lazy var amountTextField: UITextField = {
        let tf = UITextField()
        tf.attributedPlaceholder = NSAttributedString(
            string: "금액을 입력하세요",
            attributes: [.foregroundColor: UIColor.gray6, .font: Typography.b3.uiFont]
        )
        tf.textAlignment = .right
        tf.font = Typography.b3.uiFont
        tf.keyboardType = .numberPad
        tf.borderStyle = .none
        return tf
    }()

    private lazy var nameTextField: UITextField = {
        let tf = UITextField()
        tf.attributedPlaceholder = NSAttributedString(
            string: "내용을 입력하세요",
            attributes: [.foregroundColor: UIColor.gray6, .font: Typography.b3.uiFont]
        )
        tf.textAlignment = .right
        tf.font = Typography.b3.uiFont
        tf.borderStyle = .none
        return tf
    }()

    private lazy var categoryLabelView: AppLabel = {
        let label = AppLabel()
        label.text = "카테고리를 선택하세요"
        label.textAlignment = .right
        label.typography = .b3
        label.textColor = .gray6
        label.isUserInteractionEnabled = true
        return label
    }()

    private lazy var emotionLabelView: AppLabel = {
        let label = AppLabel()
        label.text = "소비감정을 선택하세요"
        label.textAlignment = .right
        label.typography = .b3
        label.textColor = .gray6
        label.isUserInteractionEnabled = true
        return label
    }()

    private lazy var paymentLabelView: AppLabel = {
        let label = AppLabel()
        label.text = "결제수단을 선택하세요"
        label.textAlignment = .right
        label.typography = .b3
        label.textColor = .gray6
        label.isUserInteractionEnabled = true
        return label
    }()

    private lazy var memoTextField: UITextField = {
        let tf = UITextField()
        tf.attributedPlaceholder = NSAttributedString(
            string: "메모를 입력하세요",
            attributes: [.foregroundColor: UIColor.gray6, .font: Typography.b3.uiFont]
        )
        tf.textAlignment = .right
        tf.font = Typography.b3.uiFont
        tf.borderStyle = .none
        return tf
    }()
    
    private lazy var changeExpenseMode: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "영수증∙여러 품목 입력"
        config.baseForegroundColor = .gray1
        config.baseBackgroundColor = .gray9
        config.contentInsets = NSDirectionalEdgeInsets(top: 9, leading: 16, bottom: 9, trailing: 16)
        config.image = UIImage(named: "Change Icon")
        
        config.imagePlacement = .leading
        config.imagePadding = 4
        config.cornerStyle = .capsule
        
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var attrs = attrs
            attrs.font = Typography.b1.uiFont
            return attrs
        }
        
        let btn = UIButton(configuration: config)
        
        btn.addAction(UIAction { [weak self] _ in
            self?.requestMultiMode.accept(())
        }, for: .touchUpInside)
        
        return btn
    }()

    // MARK: - Rows

    private lazy var dateRow: FormItemView = {
        let row = FormItemView(title: "날짜", content: dateLabelView)
        dateLabelView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(presentDatePicker)))
        return row
    }()

    private lazy var categoryRow: FormItemView = {
        let row = FormItemView(title: "카테고리", content: categoryLabelView)
        categoryLabelView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(presentCategoryPicker)))
        return row
    }()

    private lazy var emotionRow: FormItemView = {
        let row = FormItemView(title: "소비 감정", content: emotionLabelView)
        emotionLabelView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(presentEmotionPicker)))
        return row
    }()

    private lazy var paymentRow: FormItemView = {
        let row = FormItemView(title: "결제수단", content: paymentLabelView)
        paymentLabelView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(presentPaymentPicker)))
        return row
    }()

    // MARK: - Init

    init(viewModel: TransactionViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bind()

        amountTextField.delegate = self

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        view.addGestureRecognizer(tap)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    // MARK: - UI Setup

    private func configureUI() {
        view.backgroundColor = .systemBackground

        let amountRow = FormItemView(title: "금액", content: amountTextField)
        let nameRow = FormItemView(title: "내용", content: nameTextField)
        let memoRow = FormItemView(title: "메모", content: memoTextField)

        [dateRow, amountRow, nameRow, categoryRow, emotionRow, paymentRow, memoRow].forEach {
            stackView.addArrangedSubview($0)
        }

        scrollView.addSubview(stackView)
        scrollView.addSubview(changeExpenseMode)
        view.addSubview(scrollView)

        scrollView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        stackView.snp.makeConstraints {
            $0.top.leading.trailing.equalTo(scrollView.contentLayoutGuide).inset(UIEdgeInsets(top: 24, left: 0, bottom: 0, right: 0))
            $0.width.equalTo(scrollView.frameLayoutGuide)
        }

        changeExpenseMode.snp.makeConstraints {
            $0.top.equalTo(stackView.snp.bottom).offset(24)
            $0.centerX.bottom.equalTo(scrollView.contentLayoutGuide)
        }

        updateDateLabel(with: selectedDate)
    }
 
    // MARK: - Bind

    private func bind() {
        viewModel.currentTransaction
            .filter { $0 != nil }
            .map { $0! }
            .take(1)
            .subscribe(onNext: { [weak self] transaction in
                guard let self, transaction.trGroupId != -1 else { return }

                if let date = transaction.transactionDate.toDate {
                    self.selectedDate = date
                    self.updateDateLabel(with: date)
                }

                let amount = self.viewModel.currentAmount.value
                if amount > 0 {
                    self.amountTextField.text = "\(amount.withComma)원"
                    self.amountTextField.font = Typography.b1.uiFont
                }

                if let item = transaction.transactionInfoList.first {
                    self.nameTextField.text = item.name
                    self.nameTextField.font = item.name.isEmpty ? Typography.b3.uiFont : Typography.b1.uiFont

                    if let category = ExpenseCategory(rawValue: item.categoryId) {
                        self.categoryLabelView.text = category.fullDisplay
                        self.categoryLabelView.typography = .b1
                        self.categoryLabelView.textColor = .gray1
                    }
                }

                self.updateEmotionLabel(with: self.viewModel.selectedEmotion.value)
                self.updatePaymentLabel(with: self.viewModel.selectedPayment.value)

                let memo = transaction.paymentMemo ?? ""
                self.memoTextField.text = memo
                self.memoTextField.font = memo.isEmpty ? Typography.b3.uiFont : Typography.b1.uiFont
            })
            .disposed(by: disposeBag)

        amountTextField.rx.text.orEmpty
            .distinctUntilChanged()
            .map { Int($0.filter(\.isNumber)) ?? 0 }
            .bind(to: viewModel.currentAmount)
            .disposed(by: disposeBag)

        nameTextField.rx.text.orEmpty
            .distinctUntilChanged()
            .do(onNext: { [weak self] text in
                self?.nameTextField.font = text.isEmpty ? Typography.b3.uiFont : Typography.b1.uiFont
            })
            .bind(onNext: viewModel.editName)
            .disposed(by: disposeBag)

        memoTextField.rx.text.orEmpty
            .distinctUntilChanged()
            .do(onNext: { [weak self] text in
                self?.memoTextField.font = text.isEmpty ? Typography.b3.uiFont : Typography.b1.uiFont
            })
            .bind(onNext: viewModel.editMemo)
            .disposed(by: disposeBag)
    }

    // MARK: - Prepare Save

    func prepareSave() {
        guard var current = viewModel.currentTransaction.value else { return }
        let amount = viewModel.currentAmount.value
        let categoryId = viewModel.selectedCategoryId.value ?? 0
        let name = nameTextField.text ?? ""

        let item = TransactionInfo(
            transactionId: current.transactionInfoList.first?.transactionId,
            name: name,
            amount: amount,
            categoryId: categoryId,
            categoryName: ExpenseCategory(rawValue: categoryId)?.name ?? "기타"
        )
        current.transactionInfoList = [item]
        current.totalAmount = amount
        viewModel.currentTransaction.accept(current)
    }

    // MARK: - Actions

    @objc private func presentDatePicker() {
        view.endEditing(true)
        let pickerVC = DatePickerSheetViewController(date: selectedDate)
        pickerVC.onConfirm = { [weak self] date in
            guard let self else { return }
            self.selectedDate = date
            self.updateDateLabel(with: date)
            self.viewModel.editDate(date)
        }
        if let sheet = pickerVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        present(pickerVC, animated: true)
    }

    @objc private func presentCategoryPicker() {
        view.endEditing(true)
        let pickerVC = ExpenseCategoryPickerViewController(selectedId: viewModel.selectedCategoryId.value)
        pickerVC.onSelect = { [weak self] category in
            guard let self else { return }
            viewModel.selectedCategoryId.accept(category.rawValue)
            self.categoryLabelView.text = category.fullDisplay
            self.categoryLabelView.typography = .b1
            self.categoryLabelView.textColor = .gray1
        }
        if let sheet = pickerVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        present(pickerVC, animated: true)
    }

    @objc private func presentEmotionPicker() {
        view.endEditing(true)
        let pickerVC = EmotionPickerSheetViewController(emotion: viewModel.selectedEmotion.value ?? .neutral)
        pickerVC.onSelect = { [weak self] emotion in
            guard let self else { return }
            viewModel.editEmotion(emotion)
            self.updateEmotionLabel(with: emotion)
        }
        if let sheet = pickerVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        present(pickerVC, animated: true)
    }

    @objc private func presentPaymentPicker() {
        view.endEditing(true)
        let pickerVC = PaymentPickerSheetViewController(selectedPayment: viewModel.selectedPayment.value ?? .card)
        pickerVC.onSelect = { [weak self] payment in
            guard let self else { return }
            viewModel.editPaymentMethod(payment)
            self.updatePaymentLabel(with: payment)
        }
        if let sheet = pickerVC.sheetPresentationController {
            sheet.detents = [.custom { _ in 260 }]
            sheet.prefersGrabberVisible = true
        }
        present(pickerVC, animated: true)
    }

    // MARK: - Label Updates

    private func updateDateLabel(with date: Date) {
        dateLabelView.text = dateFormatter.string(from: date)
    }

    private func updateEmotionLabel(with emotion: Emotion?) {
        if let emotion {
            emotionLabelView.text = emotion.displayName
            emotionLabelView.typography = .b1
            emotionLabelView.textColor = .gray1
        } else {
            emotionLabelView.text = "소비감정을 선택하세요"
            emotionLabelView.typography = .b3
            emotionLabelView.textColor = .gray6
        }
    }

    private func updatePaymentLabel(with payment: Payment?) {
        if let payment {
            paymentLabelView.text = payment.displayName
            paymentLabelView.typography = .b1
            paymentLabelView.textColor = .gray1
        } else {
            paymentLabelView.text = "결제수단을 선택하세요"
            paymentLabelView.typography = .b3
            paymentLabelView.textColor = .gray6
        }
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - Keyboard

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard memoTextField.isFirstResponder else { return }
        guard let userInfo = notification.userInfo,
              let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        else { return }

        if !isScrolledForKeyboard {
            originalContentOffset = scrollView.contentOffset
            isScrolledForKeyboard = true
        }
        fitScrollingMinDistance(keyboardHeight: keyboardFrame.height)
    }

    private func fitScrollingMinDistance(keyboardHeight: CGFloat) {
        let superView = view.window ?? scrollView
        let textFieldBottomY = memoTextField.convert(memoTextField.bounds, to: superView).maxY
        let visibleAreaHeight = superView.frame.height - keyboardHeight
        let offsetY = textFieldBottomY + 24 - visibleAreaHeight
        guard offsetY > 0 else { return }
        scrollView.setContentOffset(
            CGPoint(x: scrollView.contentOffset.x, y: scrollView.contentOffset.y + offsetY),
            animated: true
        )
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard isScrolledForKeyboard else { return }
        isScrolledForKeyboard = false
        scrollView.setContentOffset(originalContentOffset, animated: true)
    }
}

// MARK: - UITextFieldDelegate

extension SingleExpenseViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard textField == amountTextField else { return true }
        guard string.isEmpty || string.allSatisfy({ $0.isNumber }) else { return false }

        let current = (textField.text ?? "") as NSString
        let proposed = current.replacingCharacters(in: range, with: string)
        let digits = proposed.filter { $0.isNumber }

        if digits.isEmpty {
            textField.text = ""
            textField.font = Typography.b3.uiFont
        } else {
            let amount = Int(digits) ?? 0
            textField.text = "\(amount.withComma)원"
            textField.font = Typography.b1.uiFont
            if let pos = textField.position(from: textField.endOfDocument, offset: -1) {
                textField.selectedTextRange = textField.textRange(from: pos, to: pos)
            }
        }

        textField.sendActions(for: .editingChanged)
        return false
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        guard textField == amountTextField,
              let text = textField.text, text.hasSuffix("원"),
              let pos = textField.position(from: textField.endOfDocument, offset: -1) else { return }
        textField.selectedTextRange = textField.textRange(from: pos, to: pos)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension SingleExpenseViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view is UIButton { return false }
        return true
    }
}
