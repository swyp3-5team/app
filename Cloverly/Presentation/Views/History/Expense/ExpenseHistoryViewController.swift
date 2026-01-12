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
    
    init(viewModel: CalendarViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    var statusBarHeight: CGFloat {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            return windowScene.statusBarManager?.statusBarFrame.height ?? 0
        }
        return 0
    }
    
    private lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.showsVerticalScrollIndicator = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "내역 수정"
        label.font = .customFont(.pretendardSemiBold, size: 18)
        label.textColor = .gray1
        return label
    }()
    
    private lazy var xButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "Modal Close Button"), for: .normal)
        button.addAction(UIAction { [weak self] _ in
            self?.dismiss(animated: true)
        }, for: .touchUpInside)
        
        return button
    }()
    
    let nameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "상호명 입력"
        textField.textColor = .gray1
        textField.font = .customFont(.pretendardRegular, size: 14)
        textField.layer.borderColor = UIColor.gray8.cgColor
        textField.layer.borderWidth = 1
        textField.layer.cornerRadius = 8
        textField.clipsToBounds = true
        
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.leftViewMode = .always
        return textField
    }()
    
    private let emotionGridView = EmotionGridView()
    
    let amountTextField: UITextField = {
        let textField = UITextField()
        textField.keyboardType = .numberPad
        textField.placeholder = "금액 입력"
        textField.textColor = .gray1
        textField.font = .customFont(.pretendardRegular, size: 14)
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
        textField.font = .customFont(.pretendardRegular, size: 14)
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
    
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 24
        stackView.alignment = .fill
        stackView.distribution = .fill
        return stackView
    }()
    
    private lazy var saveButton: UIButton = {
        let button = UIButton()
        button.setTitle("저장", for: .normal)
        button.setTitleColor(.gray10, for: .normal)
        button.titleLabel?.font = .customFont(.pretendardSemiBold, size: 16)
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        button.backgroundColor = .green5
        button.addAction(UIAction { [weak self] _ in
            Task {
                do {
                    try await self?.viewModel.saveTransaction()
                    self?.viewModel.refreshTrigger.accept(())
                    self?.dismiss(animated: true)
                } catch {
                    print("지출 저장 실패: \(error)")
                }
            }
        }, for: .touchUpInside)
        
        return button
    }()
    
    private lazy var deleteButton: UIButton = {
        let button = UIButton()
        button.setTitle("삭제", for: .normal)
        button.setTitleColor(.gray1, for: .normal)
        button.titleLabel?.font = .customFont(.pretendardSemiBold, size: 16)
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.gray7.cgColor
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        
        button.addAction(UIAction { [weak self] _ in
            self?.showDeleteAlert()
        }, for: .touchUpInside)
        
        return button
    }()
    
    private lazy var buttonStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [deleteButton, saveButton])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.distribution = .fillEqually
        return stack
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bind()
        updateViewMode()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        view.addGestureRecognizer(tap)
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
        
        let amountSection = FormItemView(title: "금액", content: amountTextField)
        let nameSection = FormItemView(title: "상호명", content: nameTextField)
        let paymentDateSection = FormItemView(title: "날짜", content: dateContainerView)
        let emojiSection = FormItemView(title: "감정", content: emotionGridView)
        let paymentMethodSection = FormItemView(title: "결제수단", content: paymentDropDown)
        let memoSection = FormItemView(title: "메모", content: memoTextField)
        let categoryMethodSection = FormItemView(title: "지출내역", content: expandableListView, showActionBtn: true)
        categoryMethodSection.onAction = { [weak self] in
                self?.presentAddTransactionView()
            }
        
        stackView.addArrangedSubview(amountSection)
        stackView.addArrangedSubview(nameSection)
        stackView.addArrangedSubview(paymentDateSection)
        stackView.addArrangedSubview(emojiSection)
        stackView.addArrangedSubview(paymentMethodSection)
        stackView.addArrangedSubview(memoSection)
        stackView.addArrangedSubview(categoryMethodSection)
        
        scrollView.addSubview(stackView)
        view.addSubview(titleLabel)
        view.addSubview(xButton)
        view.addSubview(scrollView)
        view.addSubview(buttonStackView)
        
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.snp.top).offset(statusBarHeight + 15.5)
            $0.centerX.equalToSuperview()
        }
        
        xButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalTo(titleLabel)
        }
        
        nameTextField.snp.makeConstraints {
            $0.height.equalTo(48)
        }
        
        amountTextField.snp.makeConstraints {
            $0.height.equalTo(48)
        }
        
        emotionGridView.snp.makeConstraints {
            $0.height.equalTo(202)
        }
        
        dateContainerView.snp.makeConstraints {
            $0.height.equalTo(48)
        }
        
        memoTextField.snp.makeConstraints {
            $0.height.equalTo(48)
        }
        
//        expandableListView.snp.makeConstraints {
//            $0.height.equalTo(48)
//        }
        
        scrollView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(saveButton.snp.top).offset(-10)
        }
        
        // (B) 스택뷰 제약조건 (✨ 여기가 핵심)
        stackView.snp.makeConstraints {
            // 1. 스크롤 영역 정의 (위/아래/양옆 꽉 채우기)
            $0.edges.equalTo(scrollView.contentLayoutGuide)
            
            // 2. 가로 스크롤 방지 (너비는 화면 너비와 똑같이!)
            $0.width.equalTo(scrollView.frameLayoutGuide)
        }
        
        buttonStackView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(56)
        }
    }
    
    private func updateViewMode() {
        guard let current = viewModel.currentTransaction.value else { return }
        
        if current.trGroupId != -1 {
            self.titleLabel.text = "내역 수정"
            self.deleteButton.isHidden = false
        } else {
            self.titleLabel.text = "내역 추가"
            self.amountTextField.text = nil
            self.deleteButton.isHidden = true
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
                self.amountTextField.text = "\(transaction.totalAmount.withComma)" // 콤마 포맷팅 필요 시 .withComma 사용
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
        
        // 2. 금액 (Amount)
        amountTextField.rx.text.orEmpty
            .distinctUntilChanged()
            .map { $0.replacingOccurrences(of: ",", with: "") } // 콤마 제거
            .compactMap { Int($0) } // 숫자로 변환
            .bind(onNext: viewModel.editAmount)
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
            self.amountTextField.text = "\(newTotal.withComma)"
            
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
                if let category = ExpenseCategory(rawValue: newCategoryId) {
                    updatedTransaction.transactionInfoList[index].categoryName = category.name
                } else {
                    // 혹시라도 Enum에 없는 ID라면 기본값 처리 (안전을 위해)
                    updatedTransaction.transactionInfoList[index].categoryName = "기타"
                }
                
                // B. 총액 재계산 (금액이 바뀌었을 수 있으니까)
                updatedTransaction.totalAmount = updatedTransaction.transactionInfoList.reduce(0) { $0 + $1.amount }
                
                // C. 텍스트필드 UI 업데이트 (총액이 바꼈으니까)
                self.amountTextField.text = "\(updatedTransaction.totalAmount.withComma)"
                
                // D. 뷰모델에 수정된 전체 데이터 다시 덮어씌우기
                self.viewModel.currentTransaction.accept(updatedTransaction)
                
                // E. 리스트뷰 갱신 (화면에 즉시 반영)
                self.expandableListView.configure(with: updatedTransaction)
            }
            
            // ④ 화면 띄우기 (Navigation Push 또는 Present)
             self.navigationController?.pushViewController(editVC, animated: true)
        }
    }
    
    private func presentAddTransactionView() {
        // 1. "추가" 모드이므로 빈 값으로 초기화해서 생성
        // (amount: 0, categoryId: 1 등 기본값 설정)
        let addVC = TransactionInfoEditViewController()
        
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
                categoryName: ExpenseCategory(rawValue: newCategoryId)?.name ?? "기타"
            )
            
            // B. 리스트에 추가 (Append)
            currentData.transactionInfoList.append(newInfo)
            
            // C. 총액 재계산
            currentData.totalAmount = currentData.transactionInfoList.reduce(0) { $0 + $1.amount }
            
            // D. 화면 및 데이터 업데이트
            self.amountTextField.text = "\(currentData.totalAmount.withComma)" // 콤마 포맷
            self.viewModel.currentTransaction.accept(currentData)
            self.expandableListView.configure(with: currentData)
        }
        
        // 3. 화면 이동 (Push)
        // 주의: 이 VC가 NavigationController 안에 있어야 push가 동작합니다.
        self.navigationController?.pushViewController(addVC, animated: true)
    }
    
    private func showDeleteAlert() {
        let alert = UIAlertController(
            title: "내역을 삭제하시겠습니까?",
            message: "",
            preferredStyle: .alert
        )
        
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)
        
        let deleteAction = UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            Task {
                do {
                    try await self?.viewModel.deleteTransaction()
                    self?.viewModel.refreshTrigger.accept(())
                    self?.dismiss(animated: true)
                } catch {
                    print("지출 삭제 실패: \(error)")
                }
            }
        }
        
        alert.addAction(cancelAction)
        alert.addAction(deleteAction)
        
        present(alert, animated: true)
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
