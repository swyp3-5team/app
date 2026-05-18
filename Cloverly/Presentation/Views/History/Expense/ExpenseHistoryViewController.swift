//
//  ExpenseHistoryViewController.swift
//  Cloverly
//
//  Created by 이인호 on 12/20/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

class ExpenseHistoryViewController: UIViewController {
    private let viewModel: CalendarViewModel
    private let disposeBag = DisposeBag()
    private var originalContentOffset: CGPoint = .zero
    private var isScrolledForKeyboard = false

    init(viewModel: CalendarViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.showsVerticalScrollIndicator = false
        return view
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
    
    private let emotionGridView = EmotionGridView()
    
    let amountLabel: AppLabel = {
        let label = AppLabel()
        label.textColor = .gray6
        label.typography = .h1
        return label
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
    
    private let paymentDropDown = PaymentDropDown()
    private let expandableListView = ExpandableListView()

    private var categoryMethodSection: FormItemView!
    private var paymentMethodSection: FormItemView!
    
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 24
        stackView.alignment = .fill
        stackView.distribution = .fill
        return stackView
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bind()
        
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
        
        // 4. 오토레이아웃 (피커를 껍데기 왼쪽에 붙이기)
        datePicker.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16) // 왼쪽 여백 (텍스트필드랑 맞추기)
            $0.centerY.equalToSuperview()
            // 너비나 높이는 굳이 안 잡아도 compact 스타일이 알아서 잡습니다.
        }
        
        categoryMethodSection = FormItemView(title: "지출내역", content: expandableListView, showActionBtn: true, tooltipText: "우측 추가 버튼을 눌러 지출 항목과\n금액, 카테고리를 입력할 수 있습니다.\n지출내역 추가 완료 시 총 금액에 반영됩니다.")
        paymentMethodSection = FormItemView(title: "결제수단", content: paymentDropDown)
        let nameSection = FormItemView(title: "상호명", content: nameTextField)
        let paymentDateSection = FormItemView(title: "날짜", content: dateContainerView)
        let emojiSection = FormItemView(title: "감정", content: emotionGridView)
        let memoSection = FormItemView(title: "메모", content: memoTextField)
        categoryMethodSection.onAction = { [weak self] in
            self?.presentAddTransactionView()
        }

        stackView.addArrangedSubview(amountLabel)
        stackView.addArrangedSubview(categoryMethodSection)
        stackView.addArrangedSubview(nameSection)
        stackView.addArrangedSubview(paymentDateSection)
        stackView.addArrangedSubview(emojiSection)
        stackView.addArrangedSubview(paymentMethodSection)
        stackView.addArrangedSubview(memoSection)
        
        scrollView.addSubview(stackView)
        view.addSubview(scrollView)

        nameTextField.snp.makeConstraints {
            $0.height.equalTo(48)
        }
        
        amountLabel.snp.makeConstraints {
            $0.height.equalTo(48)
        }
        
        emotionGridView.snp.makeConstraints {
            $0.height.equalTo(268)
        }
        
        dateContainerView.snp.makeConstraints {
            $0.height.equalTo(48)
        }
        
        memoTextField.snp.makeConstraints {
            $0.height.equalTo(48)
        }
        
        scrollView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        // (B) 스택뷰 제약조건 (✨ 여기가 핵심)
        stackView.snp.makeConstraints {
            // 1. 스크롤 영역 정의 (위/아래/양옆 꽉 채우기)
            $0.edges.equalTo(scrollView.contentLayoutGuide)
            
            // 2. 가로 스크롤 방지 (너비는 화면 너비와 똑같이!)
            $0.width.equalTo(scrollView.frameLayoutGuide)
        }
        
    }
    
    private func bind() {
        
        // ============================================
        // 1. Output Binding (초기값 보여주기)
        // ============================================
        // VM의 데이터가 바뀌면 UI도 알아서 바뀌도록 설정 (초기 진입 시 등)
        viewModel.currentTransaction
            .filter { $0 != nil }
            .map { $0! }
            .take(1) // 최초 1회만 바인딩 (입력 중 리로드 방지)
            .subscribe(onNext: { [weak self] transaction in
                guard let self = self else { return }
                self.nameTextField.text = transaction.place ?? ""
                self.amountLabel.text = "총 금액 \(transaction.totalAmount.withComma)원" // 콤마 포맷팅 필요 시 .withComma 사용
                self.amountLabel.textColor = transaction.totalAmount == 0 ? .gray6 : .gray1
                self.memoTextField.text = transaction.paymentMemo
                
                // 커스텀 뷰 초기값
                self.emotionGridView.select(emotion: transaction.emotion)
                self.paymentDropDown.selectedPayment.accept(transaction.payment)
            
                expandableListView.configure(with: transaction)
                
                // 날짜 초기값
                if let date = transaction.transactionDate.toDate {
                    self.datePicker.date = date
                }
            })
            .disposed(by: disposeBag)
        

        // 1. 상호명 (Name)
        nameTextField.rx.text.orEmpty
            .distinctUntilChanged()
            .bind(onNext: viewModel.editName)
            .disposed(by: disposeBag)
        
        // 3. 날짜 (Date)
        datePicker.rx.date
            .skip(1) // 초기 로딩 시 이벤트 무시
            .distinctUntilChanged()
            .bind(onNext: viewModel.editDate)
            .disposed(by: disposeBag)
        
        // 4. 감정 (Emotion)
        emotionGridView.selectedEmotion
            .distinctUntilChanged()
            .bind(onNext: viewModel.editEmotion)
            .disposed(by: disposeBag)
        
        // 5. 결제수단 (Payment) - DropDown은 String을 뱉으므로 VM이 변환 처리
        paymentDropDown.selectedPayment
            .distinctUntilChanged()
            .bind(onNext: viewModel.editPaymentMethod)
            .disposed(by: disposeBag)
        
        // 6. 메모 (Memo)
        memoTextField.rx.text.orEmpty
            .distinctUntilChanged()
            .bind(onNext: viewModel.editMemo)
            .disposed(by: disposeBag)
        
        expandableListView.onDeleteItem = { [weak self] index in
            guard let self = self else { return }
            
            // ① 현재 보고 있는 트랜잭션 데이터 꺼내기 (복사본)
            guard var currentData = self.viewModel.currentTransaction.value else { return }
            
            // ② 리스트에서 해당 아이템 삭제
            // (index는 ExpandableListView가 알려준 "몇 번째 줄인지" 정보)
            currentData.transactionInfoList.remove(at: index)
            
            // ③ 금액(totalAmount)도 바뀌었을 테니 재계산 (선택 사항이지만 추천)
            let newTotal = currentData.transactionInfoList.reduce(0) { $0 + $1.amount }
            currentData.totalAmount = newTotal
            self.amountLabel.text = "총 금액 \(newTotal.withComma)원"
            self.amountLabel.textColor = newTotal == 0 ? .gray6 : .gray1
            
            // ④ 수정된 데이터를 다시 ViewModel에 덮어씌움 (상태 저장)
            self.viewModel.currentTransaction.accept(currentData)
            
            // ⑤ 화면 갱신 (지워진 상태로 다시 그림)
            self.expandableListView.configure(with: currentData)
        }
        
        expandableListView.onEditItem = { [weak self] index in
            guard let self = self else { return }
            guard let currentData = self.viewModel.currentTransaction.value else { return }
            
            // ① 수정할 아이템 꺼내기
            let targetItem = currentData.transactionInfoList[index]
            
            // ② 편집 화면 생성 (현재 값 주입)
            let editVC = TransactionInfoEditViewController(
                mode: .edit,
                isIncome: false,
                name: targetItem.name,
                amount: targetItem.amount,
                categoryId: targetItem.categoryId
            )
            
            // ③ ✨ 편집 완료 후 콜백 처리 (여기서 데이터 업데이트!)
            editVC.onSave = { [weak self] newName, newAmount, newCategoryId in
                guard let self = self else { return }
                
                // A. 데이터 수정 (ViewModel의 값 복사본을 수정)
                var updatedTransaction = self.viewModel.currentTransaction.value! // 강제 언래핑 안전함(위에서 guard함)
                
                // 해당 인덱스의 아이템 속성 변경
                updatedTransaction.transactionInfoList[index].name = newName
                updatedTransaction.transactionInfoList[index].amount = newAmount
                updatedTransaction.transactionInfoList[index].categoryId = newCategoryId
                updatedTransaction.transactionInfoList[index].categoryName = self.categoryName(for: newCategoryId)
                
                // B. 총액 재계산 (금액이 바뀌었을 수 있으니까)
                updatedTransaction.totalAmount = updatedTransaction.transactionInfoList.reduce(0) { $0 + $1.amount }
                
                // C. 텍스트필드 UI 업데이트 (총액이 바꼈으니까)
                self.amountLabel.text = "총 금액 \(updatedTransaction.totalAmount.withComma)원"
                self.amountLabel.textColor = updatedTransaction.totalAmount == 0 ? .gray6 : .gray1
                
                
                // D. 뷰모델에 수정된 전체 데이터 다시 덮어씌우기
                self.viewModel.currentTransaction.accept(updatedTransaction)
                
                // E. 리스트뷰 갱신 (화면에 즉시 반영)
                self.expandableListView.configure(with: updatedTransaction)
            }
            
            // ④ 화면 띄우기 (Navigation Push 또는 Present)
             self.navigationController?.pushViewController(editVC, animated: true)
        }
    }
    
    private func categoryName(for id: Int) -> String {
        return ExpenseCategory(rawValue: id)?.name ?? "기타"
    }

    private func presentAddTransactionView() {
        let addVC = TransactionInfoEditViewController(isIncome: false)
        
        // 2. 저장(Save) 콜백 처리
        addVC.onSave = { [weak self] newName, newAmount, newCategoryId in
            guard let self = self else { return }
            guard var currentData = self.viewModel.currentTransaction.value else { return }
            
            // A. 새로운 TransactionInfo 객체 생성
            // (TransactionInfo 구조체에 맞는 init을 사용하세요. 아래는 예시입니다.)
            let newInfo = TransactionInfo(
                transactionId: nil,
                name: newName,
                amount: newAmount,
                categoryId: newCategoryId,
                categoryName: self.categoryName(for: newCategoryId)
            )
            
            // B. 리스트에 추가 (Append)
            currentData.transactionInfoList.append(newInfo)
            
            // C. 총액 재계산
            currentData.totalAmount = currentData.transactionInfoList.reduce(0) { $0 + $1.amount }
            
            // D. 화면 및 데이터 업데이트
            self.amountLabel.text = "총 금액 \(currentData.totalAmount.withComma)원" // 콤마 포맷
            self.amountLabel.textColor = currentData.totalAmount == 0 ? .gray6 : .gray1
            self.viewModel.currentTransaction.accept(currentData)
            self.expandableListView.configure(with: currentData)
        }
        
        // 3. 화면 이동 (Push)
        // 주의: 이 VC가 NavigationController 안에 있어야 push가 동작합니다.
        self.navigationController?.pushViewController(addVC, animated: true)
    }
    
}

extension ExpenseHistoryViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view is UIButton {
            return false
        }

        return true
    }
}
