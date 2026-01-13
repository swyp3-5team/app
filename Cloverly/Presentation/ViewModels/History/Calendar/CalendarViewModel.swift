//
//  CalendarViewModel.swift
//  Cloverly
//
//  Created by wayblemac02 on 1/2/26.
//

import Foundation
import RxSwift
import RxCocoa

final class CalendarViewModel {
    let transactionAPI = TransactionAPI()
    
    // 내역-달력
    let dailyTotalAmounts = BehaviorRelay<[String: Int]>(value: [:])
    let currentDate = BehaviorRelay<Date>(value: Date())
    
    // 내역-달력-일자 모달
    let groupedTransactions = BehaviorRelay<[String: [Transaction]]>(value: [:])
    let selectedDate = BehaviorRelay<Date>(value: Date())
    let isSheetPresent = BehaviorRelay<Bool>(value: false)
    var currentDayTransactions: [Transaction] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let key = formatter.string(from: selectedDate.value)
        
        return groupedTransactions.value[key] ?? []
    }
    
    // 내역-통계
    let categoryStatistics = BehaviorRelay<[CategoryStatistic]>(value: [])
    
    // 내역 수정
    let currentTransaction = BehaviorRelay<Transaction?>(value: nil)
    let refreshTrigger = PublishRelay<Void>()
    
    // 내역-기록
    let filteredTransactions = BehaviorRelay<[String: [Transaction]]>(value: [:])
    let categories: [ExpenseCategory?] = [nil] + ExpenseCategory.allCases.map { $0 }
    let selectedCategories = BehaviorRelay<Set<ExpenseCategory>>(value: [])
    var tempSelectedCategories: Set<ExpenseCategory> = [] // 적용 전까지 선택한 카테고리를 담을 변수
    var sortedDateKeys: [String] = []
    
    let selectedIndex = BehaviorRelay<Int>(value: 1)
    private let disposeBag = DisposeBag()
    
    init() {
        bind()
    }
    
    func bind() {
        Observable.merge(
            currentDate.map { _ in },       // 날짜가 바뀔 때
            refreshTrigger.map { _ in }     // 강제 새로고침 신호가 올 때
        )
        .withLatestFrom(currentDate)
        .subscribe(onNext: { [weak self] date in
            self?.getTransactions(yearMonth: date)
        })
        .disposed(by: disposeBag)
        
        filteredTransactions
            .map { $0.keys.sorted(by: >) }
            .subscribe(onNext: { [weak self] keys in
                self?.sortedDateKeys = keys
            })
            .disposed(by: disposeBag)
    }
    
    func updateDate(_ date: Date) {
        currentDate.accept(date)
    }
    
    func getTransactions(yearMonth: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let yearMonthString = formatter.string(from: yearMonth)
        
        Task {
            do {
                let transactionList = try await transactionAPI.getTransactions(yearMonth: yearMonthString)
                
                var tempAmounts: [String: Int] = [:]
                for transaction in transactionList {
                    // 딕셔너리에 금액 누적 (기존 값 + 현재 값)
                    tempAmounts[transaction.transactionDate, default: 0] += transaction.totalAmount
                }
                
                dailyTotalAmounts.accept(tempAmounts)
                
                let grouped = Dictionary(grouping: transactionList) { transaction -> String in
                    // 어떤 키로 묶을지 정함 (날짜를 문자열로 변환해서 Key로 사용)
                    return transaction.transactionDate
                }
                
                // 3. Relay에 저장
                groupedTransactions.accept(grouped)
                filteredTransactions.accept(grouped)
            } catch {
                print("지출 내역 데이터 로드 실패: \(error)")
            }
        }
    }
    
    func getCategoryStatistics(yearMonth: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let yearMonthString = formatter.string(from: yearMonth)
        
        Task {
            do {
                let categoryStatisticsList = try await transactionAPI.getCategoryStatistics(yearMonth: yearMonthString)
                let sortedList = categoryStatisticsList.sorted { $0.totalAmount > $1.totalAmount }
                categoryStatistics.accept(sortedList)
            } catch {
                print("카테고리 통계 데이터 로드 실패: \(error)")
            }
        }
    }
    
    
    // 내역-수정
    func editName(_ name: String) {
        guard var current = currentTransaction.value else { return }
        current.place = name // 상호명 수정
        currentTransaction.accept(current)
    }

    func editAmount(_ amount: Int) {
        guard var current = currentTransaction.value else { return }
        current.totalAmount = amount // 금액 수정
        currentTransaction.accept(current)
    }

    func editDate(_ date: Date) {
        guard var current = currentTransaction.value else { return }
        current.transactionDate = date.toServerFormat
        currentTransaction.accept(current)
    }

    func editEmotion(_ emotion: Emotion) {
        guard var current = currentTransaction.value else { return }
        current.emotion = emotion // 감정 수정
        currentTransaction.accept(current)
    }

    func editPaymentMethod(_ method: Payment) {
        guard var current = currentTransaction.value else { return }
        current.payment = method
        currentTransaction.accept(current)
    }

    func editMemo(_ memo: String) {
        guard var current = currentTransaction.value else { return }
        current.paymentMemo = memo // 메모 수정
        currentTransaction.accept(current)
    }
    
    func updateTransaction() async throws {
        guard let current = currentTransaction.value else { return }
        try await transactionAPI.updateTransaction(transaction: current)
    }
    
    // 내역-기록
    func applyFilter() {
        let origin = groupedTransactions.value
        let selected = selectedCategories.value
        
        // 선택된게 없으면(빈 집합) -> "전체 보기"
        if selected.isEmpty {
            filteredTransactions.accept(origin)
            return
        }
        
        var newGrouped: [String: [Transaction]] = [:]
        
        for (date, list) in origin {
            // ✨ [핵심 수정] 트랜잭션 내부의 상세 리스트 중 '가장 비싼 항목'의 카테고리를 기준으로 필터링
            let filteredList = list.filter { transaction in
                // 1. 가장 비싼 항목 찾기 (없으면 필터 대상에서 제외)
                guard let maxItem = transaction.transactionInfoList.max(by: { $0.amount < $1.amount }) else {
                    return false
                }
                
                // 2. 그 항목의 카테고리 ID를 Enum으로 변환
                guard let category = ExpenseCategory(rawValue: maxItem.categoryId) else {
                    return false
                }
                
                // 3. 선택된 카테고리 목록(Set)에 포함되는지 확인
                return selected.contains(category)
            }
            
            // 필터링 결과가 있는 날짜만 딕셔너리에 추가
            if !filteredList.isEmpty {
                newGrouped[date] = filteredList
            }
        }
        
        filteredTransactions.accept(newGrouped)
    }
    
    // 내역-추가
    func clearCurrentTransaction() {
        // ID는 없거나 -1, 날짜는 오늘, 금액은 0원인 빈 객체를 만듭니다.
        let emptyTransaction = Transaction(
            trGroupId: -1, transactionDate: Date().toServerFormat, totalAmount: 0, payment: .card, emotion: .neutral, transactionInfoList: []
        )
        currentTransaction.accept(emptyTransaction)
    }
    
    func saveTransaction() async throws {
        guard let current = currentTransaction.value else { return }
        
        if current.trGroupId != -1 {
            try await transactionAPI.updateTransaction(transaction: current)
        } else {
            let transactionDTOs = current.transactionInfoList.map { info in
                return TransactionDTO(
                    name: info.name,
                    amount: info.amount,
                    categoryName: info.categoryName
                )
            }
            
            let requestBody = TransactionRequest(place: current.place, transactionDate: current.transactionDate, payment: current.payment, paymentMemo: current.paymentMemo, emotion: current.emotion, transactions: transactionDTOs)
            
            print(requestBody)
            try await transactionAPI.saveTransaction(requestBody: requestBody)
        }
    }
    
    func deleteTransaction() async throws {
        guard let current = currentTransaction.value else { return }
        try await transactionAPI.deleteTransaction(trGroupId: current.trGroupId)
    }
}
