//
//  MultiExpenseViewController.swift
//  Cloverly
//
//  Created by 이인호 on 12/20/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import PhotosUI

class MultiExpenseViewController: UIViewController {
    private let viewModel: TransactionViewModel
    private let disposeBag = DisposeBag()
    private var selectedDate: Date = Date()

    // Keyboard handling
    private var originalContentOffset: CGPoint = .zero
    private var isScrolledForKeyboard = false

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    let requestSingleMode = PublishRelay<Void>()

    var canSave: Observable<Bool> {
        Observable.combineLatest(
            viewModel.currentTransaction,
            viewModel.selectedEmotion,
            viewModel.selectedPayment
        )
        .map { transaction, emotion, payment in
            guard let t = transaction else { return false }
            return !t.transactionInfoList.isEmpty && emotion != nil && payment != nil
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
    
    let amountLabel: AppLabel = {
        let label = AppLabel()
        label.textColor = .gray6
        label.typography = .h1
        return label
    }()
    
    private let expandableListView = ExpandableListView()

    private lazy var dateLabelView: AppLabel = {
        let label = AppLabel()
        label.textAlignment = .right
        label.typography = .b1
        label.textColor = .gray1
        label.isUserInteractionEnabled = true
        return label
    }()

    private lazy var emotionLabelView: AppLabel = {
        let label = AppLabel()
        label.text = "감정을 선택하세요"
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
     
    private lazy var cameraIconView: UIView = {
        let container = UIView()
        let iv = UIImageView(image: UIImage(named: "camera icon"))
        iv.contentMode = .scaleAspectFit
        container.addSubview(iv)
        iv.snp.makeConstraints {
            $0.width.height.equalTo(24)
            $0.trailing.equalToSuperview()
            $0.top.bottom.equalToSuperview()
        }
        return container
    }()

    private lazy var additionalInputRow: FormItemView = {
        let row = FormItemView(title: "추가입력", content: cameraIconView)
        row.isUserInteractionEnabled = true
        row.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(presentImageSourcePicker)))
        return row
    }()

    private lazy var changeExpenseMode: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "단일 품목 입력 "
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
            self?.requestSingleMode.accept(())
        }, for: .touchUpInside)
        
        return btn
    }()

    // MARK: - Rows

    private lazy var dateRow: FormItemView = {
        let row = FormItemView(title: "날짜", content: dateLabelView)
        dateLabelView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(presentDatePicker)))
        return row
    }()

    private lazy var emotionRow: FormItemView = {
        let row = FormItemView(title: "감정", content: emotionLabelView)
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

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bind()

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

        let memoRow = FormItemView(title: "메모", content: memoTextField)

        expandableListView.onAction = { [weak self] in
            self?.presentAddTransactionView()
        }

        [amountLabel, expandableListView, dateRow, emotionRow, paymentRow, memoRow, additionalInputRow].forEach {
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
                guard let self else { return }

                self.amountLabel.text = "총 금액 \(transaction.totalAmount.withComma)원"
                self.amountLabel.textColor = transaction.totalAmount == 0 ? .gray6 : .gray1

                let memo = transaction.paymentMemo ?? ""
                self.memoTextField.text = memo
                self.memoTextField.font = memo.isEmpty ? Typography.b3.uiFont : Typography.b1.uiFont

                if let date = transaction.transactionDate.toDate {
                    self.selectedDate = date
                    self.updateDateLabel(with: date)
                }

                if transaction.trGroupId != -1 {
                    self.updateEmotionLabel(with: self.viewModel.selectedEmotion.value)
                    self.updatePaymentLabel(with: self.viewModel.selectedPayment.value)
                }

                self.expandableListView.configure(with: transaction)
            })
            .disposed(by: disposeBag)

        memoTextField.rx.text.orEmpty
            .distinctUntilChanged()
            .skip(1)
            .do(onNext: { [weak self] text in
                self?.memoTextField.font = text.isEmpty ? Typography.b3.uiFont : Typography.b1.uiFont
            })
            .bind(onNext: viewModel.editMemo)
            .disposed(by: disposeBag)

        expandableListView.onDeleteItem = { [weak self] index in
            guard let self,
                  var currentData = viewModel.currentTransaction.value else { return }
            currentData.transactionInfoList.remove(at: index)
            let newTotal = currentData.transactionInfoList.reduce(0) { $0 + $1.amount }
            currentData.totalAmount = newTotal
            self.amountLabel.text = "총 금액 \(newTotal.withComma)원"
            self.amountLabel.textColor = newTotal == 0 ? .gray6 : .gray1
            self.viewModel.currentTransaction.accept(currentData)
            self.expandableListView.configure(with: currentData)
        }

        expandableListView.onEditItem = { [weak self] index in
            guard let self,
                  let currentData = viewModel.currentTransaction.value else { return }
            let item = currentData.transactionInfoList[index]
            let editVC = TransactionInfoEditViewController(
                mode: .edit,
                isIncome: false,
                name: item.name,
                amount: item.amount,
                categoryId: item.categoryId
            )
            editVC.onSave = { [weak self] newName, newAmount, newCategoryId in
                guard let self,
                      var updated = viewModel.currentTransaction.value else { return }
                updated.transactionInfoList[index].name = newName
                updated.transactionInfoList[index].amount = newAmount
                updated.transactionInfoList[index].categoryId = newCategoryId
                updated.transactionInfoList[index].categoryName = ExpenseCategory(rawValue: newCategoryId)?.name ?? "기타"
                updated.totalAmount = updated.transactionInfoList.reduce(0) { $0 + $1.amount }
                self.amountLabel.text = "총 금액 \(updated.totalAmount.withComma)원"
                self.amountLabel.textColor = updated.totalAmount == 0 ? .gray6 : .gray1
                self.viewModel.currentTransaction.accept(updated)
                self.expandableListView.configure(with: updated)
            }
            navigationController?.pushViewController(editVC, animated: true)
        }
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
        }
        present(pickerVC, animated: true)
    }

    @objc private func presentEmotionPicker() {
        view.endEditing(true)
        let pickerVC = EmotionPickerSheetViewController(emotion: viewModel.selectedEmotion.value)
        pickerVC.onSelect = { [weak self] emotion in
            guard let self else { return }
            self.viewModel.editEmotion(emotion)
            self.updateEmotionLabel(with: emotion)
        }
        if let sheet = pickerVC.sheetPresentationController {
            sheet.detents = [.medium()]
        }
        present(pickerVC, animated: true)
    }

    @objc private func presentPaymentPicker() {
        view.endEditing(true)
        let pickerVC = PaymentPickerSheetViewController(selectedPayment: viewModel.selectedPayment.value)
        pickerVC.onSelect = { [weak self] payment in
            guard let self else { return }
            self.viewModel.editPaymentMethod(payment)
            self.updatePaymentLabel(with: payment)
        }
        if let sheet = pickerVC.sheetPresentationController {
            sheet.detents = [.custom { _ in 260 }]
        }
        present(pickerVC, animated: true)
    }

    private func presentAddTransactionView() {
        let addVC = TransactionInfoEditViewController(isIncome: false)
        addVC.onSave = { [weak self] newName, newAmount, newCategoryId in
            guard let self,
                  var currentData = viewModel.currentTransaction.value else { return }
            let newInfo = TransactionInfo(
                transactionId: nil,
                name: newName,
                amount: newAmount,
                categoryId: newCategoryId,
                categoryName: ExpenseCategory(rawValue: newCategoryId)?.name ?? "기타"
            )
            currentData.transactionInfoList.append(newInfo)
            currentData.totalAmount = currentData.transactionInfoList.reduce(0) { $0 + $1.amount }
            self.amountLabel.text = "총 금액 \(currentData.totalAmount.withComma)원"  
            self.amountLabel.textColor = currentData.totalAmount == 0 ? .gray6 : .gray1
            self.viewModel.currentTransaction.accept(currentData)
            self.expandableListView.configure(with: currentData)
        }
        navigationController?.pushViewController(addVC, animated: true)
    }

    // MARK: - Image Analysis

    @objc private func presentImageSourcePicker() {
        view.endEditing(true)
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "사진", style: .default) { [weak self] _ in
            self?.openGallery()
        })
        alert.addAction(UIAlertAction(title: "카메라", style: .default) { [weak self] _ in
            self?.openCamera()
        })
        present(alert, animated: true)
    }

    private func openGallery() {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return }
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        present(picker, animated: true)
    }

    private func handleSelectedImage(_ image: UIImage) {
        Task {
            do {
                let info = try await viewModel.analyzeReceipt(image: image)
                await MainActor.run { fillFields(from: info) }
            } catch {
                await MainActor.run { self.showErrorToast(error) }
            }
        }
    }

    private func fillFields(from info: TransactionInfoDTO) {
        if let date = info.transactionDate.toDate {
            selectedDate = date
            updateDateLabel(with: date)
            viewModel.editDate(date)
        }

        viewModel.editEmotion(info.emotion)
        updateEmotionLabel(with: info.emotion)

        viewModel.editPaymentMethod(info.payment)
        updatePaymentLabel(with: info.payment)

        let memo = info.paymentMemo ?? ""
        memoTextField.text = memo
        memoTextField.font = memo.isEmpty ? Typography.b3.uiFont : Typography.b1.uiFont
        if !memo.isEmpty { viewModel.editMemo(memo) }

        guard var current = viewModel.currentTransaction.value else { return }
        let items = info.transactions.map { dto -> TransactionInfo in
            let categoryId = ExpenseCategory.allCases.first(where: { $0.name == dto.categoryName })?.rawValue ?? ExpenseCategory.other.rawValue
            return TransactionInfo(transactionId: nil, name: dto.name, amount: dto.amount, categoryId: categoryId, categoryName: dto.categoryName)
        }
        current.transactionInfoList = items
        current.totalAmount = info.totalAmount
        amountLabel.text = "총 금액 \(info.totalAmount.withComma)원"
        amountLabel.textColor = info.totalAmount == 0 ? .gray6 : .gray1
        viewModel.currentTransaction.accept(current)
        expandableListView.configure(with: current)
    }

    // MARK: - Label Updates

    private func updateDateLabel(with date: Date) {
        dateLabelView.text = dateFormatter.string(from : date)
    }

    private func updateEmotionLabel(with emotion: Emotion?) {
        if let emotion {
            emotionLabelView.text = emotion.displayName
            emotionLabelView.typography = .b1
            emotionLabelView.textColor = .gray1
        } else {
            emotionLabelView.text = "감정을 선택하세요"
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

// MARK: - PHPickerViewControllerDelegate

extension MultiExpenseViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let result = results.first else { return }
        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
            DispatchQueue.main.async {
                if let image = image as? UIImage { self?.handleSelectedImage(image) }
            }
        }
    }
}

// MARK: - UIImagePickerControllerDelegate

extension MultiExpenseViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        dismiss(animated: true)
        if let image = info[.originalImage] as? UIImage { handleSelectedImage(image) }
    }
}

// MARK: - UIGestureRecognizerDelegate

extension MultiExpenseViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view is UIButton { return false }
        return true
    }
}
