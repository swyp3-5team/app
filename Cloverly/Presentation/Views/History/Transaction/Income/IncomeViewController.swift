//
//  IncomeViewController.swift
//  Cloverly
//
//  Created by 이인호 on 5/12/26.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

class IncomeViewController: UIViewController {
    private let viewModel: CalendarViewModel
    private let disposeBag = DisposeBag()
    private let selectedCategoryId = BehaviorRelay<Int?>(value: nil)
    private var selectedDate: Date = Date()

    var canSave: Observable<Bool> {
        Observable.combineLatest(
            viewModel.currentTransaction,
            selectedCategoryId.asObservable()
        )
        .map { transaction, categoryId in
            guard let t = transaction else { return false }
            return t.totalAmount > 0 && categoryId != nil
        }
    }

    // Keyboard handling
    private var originalContentOffset: CGPoint = .zero
    private var isScrolledForKeyboard = false

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

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

    // MARK: - Rows

    private lazy var dateRow: FormItemView = {
        let row = FormItemView(title: "날짜", content: dateLabelView)
        let tap = UITapGestureRecognizer(target: self, action: #selector(presentDatePicker))
        row.addGestureRecognizer(tap)
        return row
    }()

    private lazy var categoryRow: FormItemView = {
        let row = FormItemView(title: "카테고리", content: categoryLabelView)
        let tap = UITapGestureRecognizer(target: self, action: #selector(presentCategoryPicker))
        row.addGestureRecognizer(tap)
        return row
    }()

    // MARK: - Init

    init(viewModel: CalendarViewModel) {
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

        [dateRow, amountRow, nameRow, categoryRow, memoRow].forEach {
            stackView.addArrangedSubview($0)
        }

        scrollView.addSubview(stackView)
        view.addSubview(scrollView)

        scrollView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        stackView.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide).inset(UIEdgeInsets(top: 24, left: 0, bottom: 0, right: 0))
            $0.width.equalTo(scrollView.frameLayoutGuide)
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
                guard let self else { return }

                if let date = transaction.transactionDate.toDate {
                    self.selectedDate = date
                    self.updateDateLabel(with: date)
                }

                if transaction.totalAmount > 0 {
                    self.amountTextField.text = "\(transaction.totalAmount.withComma)원"
                    self.amountTextField.font = Typography.b1.uiFont
                }

                let name = transaction.place ?? ""
                self.nameTextField.text = name
                self.nameTextField.font = name.isEmpty ? Typography.b3.uiFont : Typography.b1.uiFont

                let memo = transaction.paymentMemo ?? ""
                self.memoTextField.text = memo
                self.memoTextField.font = memo.isEmpty ? Typography.b3.uiFont : Typography.b1.uiFont

                if let categoryId = transaction.transactionInfoList.first?.categoryId,
                   let category = IncomeCategory(rawValue: categoryId) {
                    self.selectedCategoryId.accept(categoryId)
                    self.categoryLabelView.text = category.fullDisplay
                    self.categoryLabelView.typography = .b1
                    self.categoryLabelView.textColor = .gray1
                }
            })
            .disposed(by: disposeBag)

        amountTextField.rx.text.orEmpty
            .distinctUntilChanged()
            .map { Int($0.filter(\.isNumber)) ?? 0 }
            .bind(onNext: viewModel.editAmount)
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
        let pickerVC = IncomeCategoryPickerViewController(selectedId: selectedCategoryId.value)
        pickerVC.onSelect = { [weak self] category in
            guard let self else { return }
            self.selectedCategoryId.accept(category.rawValue)
            self.categoryLabelView.text = category.fullDisplay
            self.categoryLabelView.typography = .b1
            self.categoryLabelView.textColor = .gray1
            self.viewModel.editCategory(id: category.rawValue, name: category.name)
        }
        if let sheet = pickerVC.sheetPresentationController {
            sheet.detents = [.custom { _ in 260 }]
            sheet.prefersGrabberVisible = true
        }
        present(pickerVC, animated: true)
    }

    private func updateDateLabel(with date: Date) {
        dateLabelView.text = dateFormatter.string(from: date)
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

extension IncomeViewController: UITextFieldDelegate {
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

extension IncomeViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view is UIButton { return false }
        return true
    }
}
