//
//  TransactionViewModel.swift
//  Cloverly
//
//  Created by 이인호 on 5/22/26.
//

import Foundation
import RxSwift
import RxCocoa
import FirebaseAnalytics

final class TransactionViewModel {
    private let transactionAPI = TransactionAPI()
    private let chatAPI = ChatAPI()

    // 수동 입력 시도 컨텍스트 (manual_entry_started에서 설정, 저장/수정 이벤트에 연결)
    var manualAttempt: InputAttempt?

    let currentTransaction: BehaviorRelay<Transaction?>
    let selectedEmotion: BehaviorRelay<Emotion?>
    let selectedPayment: BehaviorRelay<Payment?>
    let selectedCategoryId: BehaviorRelay<Int?>
    let isAnalyzing = BehaviorRelay<Bool>(value: false)

    private var incomeCategoryName: String = ""

    init() {
        currentTransaction = BehaviorRelay(value: Transaction(
            trGroupId: -1,
            transactionDate: Date().toServerFormat,
            totalAmount: 0,
            payment: .card,
            emotion: .neutral,
            transactionInfoList: []
        ))
        selectedEmotion = BehaviorRelay(value: nil)
        selectedPayment = BehaviorRelay(value: nil)
        selectedCategoryId = BehaviorRelay(value: nil)
    }

    func configure(with transaction: Transaction? = nil) {
        if let t = transaction {
            currentTransaction.accept(t)
            selectedEmotion.accept(t.emotion)
            selectedPayment.accept(t.payment)
            selectedCategoryId.accept(t.transactionInfoList.first?.categoryId)
            incomeCategoryName = t.transactionInfoList.first?.categoryName ?? ""
        } else {
            currentTransaction.accept(Transaction(
                trGroupId: -1,
                transactionDate: Date().toServerFormat,
                totalAmount: 0,
                payment: .card,
                emotion: .neutral,
                transactionInfoList: []
            ))
            selectedEmotion.accept(nil)
            selectedPayment.accept(nil)
            selectedCategoryId.accept(nil)
            incomeCategoryName = ""
        }
    }

    func editName(_ name: String) {
        guard var current = currentTransaction.value else { return }
        guard !current.transactionInfoList.isEmpty else { return }
        current.transactionInfoList[0].name = name
        currentTransaction.accept(current)
    }

    func editAmount(_ amount: Int) {
        guard var current = currentTransaction.value else { return }
        current.totalAmount = amount
        if !current.transactionInfoList.isEmpty {
            current.transactionInfoList[0].amount = amount
        }
        currentTransaction.accept(current)
    }

    func editDate(_ date: Date) {
        guard var current = currentTransaction.value else { return }
        current.transactionDate = date.toServerFormat
        currentTransaction.accept(current)
    }

    func editEmotion(_ emotion: Emotion) {
        selectedEmotion.accept(emotion)
        guard var current = currentTransaction.value else { return }
        current.emotion = emotion
        currentTransaction.accept(current)
    }

    func editPaymentMethod(_ method: Payment) {
        selectedPayment.accept(method)
        guard var current = currentTransaction.value else { return }
        current.payment = method
        currentTransaction.accept(current)
    }

    func editMemo(_ memo: String) {
        guard var current = currentTransaction.value else { return }
        current.paymentMemo = memo
        currentTransaction.accept(current)
    }

    func editCategory(id: Int, name: String) {
        selectedCategoryId.accept(id)
        incomeCategoryName = name
        guard var current = currentTransaction.value else { return }
        if current.transactionInfoList.isEmpty {
            current.transactionInfoList = [TransactionInfo(
                transactionId: nil,
                name: "",
                amount: current.totalAmount,
                categoryId: id,
                categoryName: name
            )]
        } else {
            current.transactionInfoList.indices.forEach {
                current.transactionInfoList[$0].categoryId = id
                current.transactionInfoList[$0].categoryName = name
            }
        }
        currentTransaction.accept(current)
    }

    func saveTransaction(isIncome: Bool) async throws {
        guard var current = currentTransaction.value else { return }

        // 지출인데 결제수단 미선택이면 카드 기본값으로 저장 (저장/수정 양쪽에 적용)
        if !isIncome && current.payment == nil {
            current.payment = .card
        }

        if current.trGroupId != -1 {
            try await transactionAPI.updateTransaction(transaction: current)
        } else {
            let transactionDTOs = current.transactionInfoList.map { info in
                TransactionDTO(name: info.name, amount: info.amount, categoryName: info.categoryName)
            }

            let requestBody = TransactionRequest(
                transactionDate: current.transactionDate,
                payment: current.payment,
                paymentMemo: current.paymentMemo,
                emotion: current.emotion,
                transactions: transactionDTOs
            )
            try await transactionAPI.saveTransaction(requestBody: requestBody)

            // 저장 이벤트 (수동 입력: history_tab / manual)
            let saveId = UUID().uuidString
            let itemCount = current.transactionInfoList.count
            let attempt = manualAttempt
            AnalyticsManager.shared.logTransactionSaved(
                entrySurface: .historyTab,
                inputMethod: .manual,
                entryType: itemCount <= 1 ? .single : .multiple,
                attemptId: attempt?.id,
                saveId: saveId,
                itemCount: itemCount
            )

            // record_id(trGroupId) 확보용 재조회 후 생성 이벤트
            let savedDate = current.transactionDate
            let income: IncomeExpense = isIncome ? .income : .expense
            let api = transactionAPI
            Task {
                let yearMonth = String(savedDate.prefix(7))
                guard let groups = try? await api.getTransactions(yearMonth: yearMonth),
                      let candidate = groups.filter({ $0.transactionDate == savedDate }).max(by: { $0.trGroupId < $1.trGroupId })
                else { return }
                AnalyticsManager.shared.logTransactionRecordCreated(
                    recordId: String(candidate.trGroupId),
                    saveId: saveId,
                    attemptId: attempt?.id,
                    entrySurface: .historyTab,
                    inputMethod: .manual,
                    incomeExpense: income
                )
            }
        }
    }

    func analyzeReceipt(image: UIImage) async throws -> TransactionInfoDTO {
        isAnalyzing.accept(true)
        defer { isAnalyzing.accept(false) }
        let response = try await chatAPI.sendChat(message: nil, image: image)
        guard let info = response.transactionInfo, info.totalAmount > 0 else {
            throw AppError.notReceipt
        }
        return info
    }

    func deleteTransaction() async throws {
        guard let current = currentTransaction.value else { return }
        try await transactionAPI.deleteTransaction(trGroupId: current.trGroupId)
    }
}
