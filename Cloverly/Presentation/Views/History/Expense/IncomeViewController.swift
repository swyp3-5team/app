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
    private var originalContentOffset: CGPoint = .zero
    private var isScrolledForKeyboard = false
    
    private struct CategoryItem {
        let id: Int
        let displayText: String
    }
    
    private let selectedCategoryId = BehaviorRelay<Int?>(value: nil)
    private let categories: [CategoryItem] = IncomeCategory.allCases.map { CategoryItem(id: $0.rawValue, displayText: $0.fullDisplay) }
    
    private lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.showsVerticalScrollIndicator = false
        return view
    }()
    
    private lazy var amountTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "금액 입력"
        textField.font = Typography.b7.uiFont
        textField.keyboardType = .numberPad
        textField.layer.borderColor = UIColor.gray8.cgColor
        textField.layer.borderWidth = 1
        textField.layer.cornerRadius = 8
        textField.clipsToBounds = true

        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.leftViewMode = .always

        return textField
    }()
    
    private lazy var collectionView: SelfSizingCollectionView = {
        let layout = LeftAlignedCollectionViewFlowLayout()
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 8
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize

        let cv = SelfSizingCollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.isScrollEnabled = false
        cv.register(FilterCategoryCell.self, forCellWithReuseIdentifier: FilterCategoryCell.identifier)
        cv.dataSource = self
        cv.delegate = self
        cv.allowsMultipleSelection = false
        return cv
    }()
    
    let nameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "상호명 입력"
        textField.textColor = .gray1
        textField.font = Typography.b7.uiFont
        textField.layer.borderColor = UIColor.gray8.cgColor
        textField.layer.borderWidth = 1
        textField.layer.cornerRadius = 8
        textField.clipsToBounds = true
        
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.leftViewMode = .always
        return textField
    }()
    
    private let dateContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white // 배경색
        view.layer.cornerRadius = 8
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.gray8.cgColor // 다른 텍스트필드와 같은 색상
        return view
    }()
    
    private let datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .compact
        picker.locale = Locale(identifier: "ko_KR")
        picker.tintColor = .systemGreen
        picker.contentHorizontalAlignment = .leading
        return picker
    }()
    
    let memoTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "메모 입력"
        textField.textColor = .gray1
        textField.font = Typography.b7.uiFont
        textField.layer.borderColor = UIColor.gray8.cgColor
        textField.layer.borderWidth = 1
        textField.layer.cornerRadius = 8
        textField.clipsToBounds = true
        
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.leftViewMode = .always
        return textField
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 24
        stackView.alignment = .fill
        stackView.distribution = .fill
        return stackView
    }()
    
    init(viewModel: CalendarViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureUI()
        bind()

        amountTextField.delegate = self

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        view.addGestureRecognizer(tap)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard memoTextField.isFirstResponder else { return }
        guard
            let userInfo = notification.userInfo,
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
        let minDistance = 24.0
        let offsetY = textFieldBottomY + minDistance - visibleAreaHeight
        
        guard offsetY > 0 else { return }
        
        let currentContentOffset = scrollView.contentOffset
        scrollView.setContentOffset(
            CGPoint(x: currentContentOffset.x, y: currentContentOffset.y + offsetY),
            animated: true
        )
        scrollView.layoutIfNeeded()
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        guard isScrolledForKeyboard else { return }
        isScrolledForKeyboard = false
        scrollView.setContentOffset(originalContentOffset, animated: true)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func configureUI() {
        view.backgroundColor = .systemBackground

        dateContainerView.addSubview(datePicker)
        datePicker.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
        }

        let amountSection = FormItemView(title: "금액", content: amountTextField)
        let categorySection = FormItemView(title: "카테고리", content: collectionView)
        let nameSection = FormItemView(title: "상호명", content: nameTextField)
        let paymentDateSection = FormItemView(title: "날짜", content: dateContainerView)
        let memoSection = FormItemView(title: "메모", content: memoTextField)

        stackView.addArrangedSubview(amountSection)
        stackView.addArrangedSubview(categorySection)
        stackView.addArrangedSubview(nameSection)
        stackView.addArrangedSubview(paymentDateSection)
        stackView.addArrangedSubview(memoSection)

        scrollView.addSubview(stackView)
        view.addSubview(scrollView)

        amountTextField.snp.makeConstraints { $0.height.equalTo(48) }
        nameTextField.snp.makeConstraints { $0.height.equalTo(48) }
        dateContainerView.snp.makeConstraints { $0.height.equalTo(48) }
        memoTextField.snp.makeConstraints { $0.height.equalTo(48) }

        scrollView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        stackView.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide)
            $0.width.equalTo(scrollView.frameLayoutGuide)
        }
    }

    private func bind() {
        viewModel.currentTransaction
            .filter { $0 != nil }
            .map { $0! }
            .take(1)
            .subscribe(onNext: { [weak self] transaction in
                guard let self = self else { return }
                self.nameTextField.text = transaction.place ?? ""
                if transaction.totalAmount > 0 {
                    self.amountTextField.text = "\(transaction.totalAmount.withComma)원"
                }
                self.memoTextField.text = transaction.paymentMemo

                if let date = transaction.transactionDate.toDate {
                    self.datePicker.date = date
                }

                if let categoryId = transaction.transactionInfoList.first?.categoryId,
                   let index = self.categories.firstIndex(where: { $0.id == categoryId }) {
                    self.selectedCategoryId.accept(categoryId)
                    DispatchQueue.main.async {
                        self.collectionView.selectItem(at: IndexPath(item: index, section: 0), animated: false, scrollPosition: [])
                    }
                }
            })
            .disposed(by: disposeBag)

        selectedCategoryId
            .compactMap { $0 }
            .subscribe(onNext: { [weak self] id in
                guard let self, let category = IncomeCategory(rawValue: id) else { return }
                guard var current = self.viewModel.currentTransaction.value else { return }
                let amount = current.totalAmount
                if current.transactionInfoList.isEmpty {
                    current.transactionInfoList = [TransactionInfo(
                        transactionId: nil, name: category.name, amount: amount,
                        categoryId: id, categoryName: category.name
                    )]
                } else {
                    current.transactionInfoList[0].categoryId = id
                    current.transactionInfoList[0].categoryName = category.name
                    current.transactionInfoList[0].name = category.name
                }
                self.viewModel.currentTransaction.accept(current)
            })
            .disposed(by: disposeBag)

        amountTextField.rx.text.orEmpty
            .distinctUntilChanged()
            .map { Int($0.filter(\.isNumber)) ?? 0 }
            .subscribe(onNext: { [weak self] amount in
                guard let self else { return }
                guard var current = self.viewModel.currentTransaction.value else { return }
                current.totalAmount = amount
                if !current.transactionInfoList.isEmpty {
                    current.transactionInfoList[0].amount = amount
                }
                self.viewModel.currentTransaction.accept(current)
            })
            .disposed(by: disposeBag)

        nameTextField.rx.text.orEmpty
            .distinctUntilChanged()
            .bind(onNext: viewModel.editName)
            .disposed(by: disposeBag)

        datePicker.rx.date
            .skip(1)
            .distinctUntilChanged()
            .bind(onNext: viewModel.editDate)
            .disposed(by: disposeBag)

        memoTextField.rx.text.orEmpty
            .distinctUntilChanged()
            .bind(onNext: viewModel.editMemo)
            .disposed(by: disposeBag)
    }
}

extension IncomeViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FilterCategoryCell.identifier, for: indexPath) as? FilterCategoryCell else { return UICollectionViewCell() }
        cell.configure(text: categories[indexPath.item].displayText)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.selectedCategoryId.accept(categories[indexPath.item].id)
    }
}

extension IncomeViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard textField == amountTextField else { return true }
        guard string.isEmpty || string.allSatisfy({ $0.isNumber }) else { return false }

        let current = (textField.text ?? "") as NSString
        let proposed = current.replacingCharacters(in: range, with: string)
        let digits = proposed.filter { $0.isNumber }

        if digits.isEmpty {
            textField.text = ""
        } else {
            let amount = Int(digits) ?? 0
            textField.text = "\(amount.withComma)원"
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

extension IncomeViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view is UIButton {
            return false
        }
        return true
    }
}
