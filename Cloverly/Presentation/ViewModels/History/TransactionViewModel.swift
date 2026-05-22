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

    let currentTransaction: BehaviorRelay<Transaction?>
    let selectedEmotion: BehaviorRelay<Emotion?>
    let selectedPayment: BehaviorRelay<Payment?>
    let selectedCategoryId: BehaviorRelay<Int?>
    let currentAmount: BehaviorRelay<Int>

    private(set) var originalTransaction: Transaction?
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
        currentAmount = BehaviorRelay(value: 0)
    }

    func configure(with transaction: Transaction? = nil) {
        if let t = transaction {
            originalTransaction = t
            currentTransaction.accept(t)
            selectedEmotion.accept(t.emotion)
            selectedPayment.accept(t.payment)
            selectedCategoryId.accept(t.transactionInfoList.first?.categoryId)
            incomeCategoryName = t.transactionInfoList.first?.categoryName ?? ""
            currentAmount.accept(t.transactionInfoList.first?.amount ?? 0)
        } else {
            originalTransaction = nil
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
            currentAmount.accept(0)
        }
    }

    func editName(_ name: String) {
        guard var current = currentTransaction.value else { return }
        current.place = name
        currentTransaction.accept(current)
    }

    func editAmount(_ amount: Int) {
        guard var current = currentTransaction.value else { return }
        current.totalAmount = amount
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
        current.transactionInfoList.indices.forEach {
            current.transactionInfoList[$0].categoryId = id
            current.transactionInfoList[$0].categoryName = name
        }
        currentTransaction.accept(current)
    }

    func hasUnsavedChanges(isIncome: Bool, expenseMode: ExpenseEntryMode) -> Bool {
        guard let current = currentTransaction.value else { return false }
        guard current.trGroupId == -1 else {
            return current != originalTransaction
        }

        let hasCommonInput = !(current.place ?? "").isEmpty || !(current.paymentMemo ?? "").isEmpty

        if isIncome {
            return current.totalAmount > 0 || hasCommonInput || selectedCategoryId.value != nil
        } else if expenseMode == .single {
            return hasCommonInput
                || currentAmount.value > 0
                || selectedCategoryId.value != nil
                || selectedEmotion.value != nil
                || selectedPayment.value != nil
        } else {
            return !current.transactionInfoList.isEmpty
                || hasCommonInput
                || selectedEmotion.value != nil
                || selectedPayment.value != nil
        }
    }

    func saveTransaction() async throws {
        guard let current = currentTransaction.value else { return }

        if current.trGroupId != -1 {
            try await transactionAPI.updateTransaction(transaction: current)
        } else {
            var transactionDTOs = current.transactionInfoList.map { info in
                TransactionDTO(name: info.name, amount: info.amount, categoryName: info.categoryName)
            }
            if transactionDTOs.isEmpty {
                transactionDTOs = [TransactionDTO(name: "", amount: current.totalAmount, categoryName: incomeCategoryName)]
            }

            let requestBody = TransactionRequest(
                place: current.place,
                transactionDate: current.transactionDate,
                payment: current.payment,
                paymentMemo: current.paymentMemo,
                emotion: current.emotion,
                transactions: transactionDTOs
            )
            try await transactionAPI.saveTransaction(requestBody: requestBody)

            Analytics.logEvent("transaction_saved", parameters: ["source": "manual"])
        }
    }

    func deleteTransaction() async throws {
        guard let current = currentTransaction.value else { return }
        try await transactionAPI.deleteTransaction(trGroupId: current.trGroupId)
    }
}
