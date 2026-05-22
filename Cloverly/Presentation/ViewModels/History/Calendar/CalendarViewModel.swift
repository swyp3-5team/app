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
    let monthlyExpenseAmounts = BehaviorRelay<[String: Int]>(value: [:])
    let monthlyIncomeAmounts = BehaviorRelay<[String: Int]>(value: [:])
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
    let categoryTransactions = BehaviorRelay<[TransactionRecord]>(value: [])
    
    // 내역 수정/추가
    let refreshTrigger = PublishRelay<Void>()

    // 내역-기록
    let filteredTransactions = BehaviorRelay<[String: [Transaction]]>(value: [:])
    let selectedCategories = BehaviorRelay<Set<ExpenseCategory>>(value: [])
    var tempSelectedCategories: Set<ExpenseCategory> = []
    let selectedIncomeCategories = BehaviorRelay<Set<IncomeCategory>>(value: [])
    var tempSelectedIncomeCategories: Set<IncomeCategory> = []
    var sortedDateKeys: [String] = []
    
    let selectedIndex = BehaviorRelay<Int>(value: 0)
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
                
                var tempExpense: [String: Int] = [:]
                var tempIncome: [String: Int] = [:]
                for transaction in transactionList {
                    let type = transaction.transactionInfoList.first?.type
                    if type == "INCOME" {
                        tempIncome[transaction.transactionDate, default: 0] += transaction.totalAmount
                    } else {
                        tempExpense[transaction.transactionDate, default: 0] += transaction.totalAmount
                    }
                }

                monthlyExpenseAmounts.accept(tempExpense)
                monthlyIncomeAmounts.accept(tempIncome)
                
                let grouped = Dictionary(grouping: transactionList) { transaction -> String in
                    // 어떤 키로 묶을지 정함 (날짜를 문자열로 변환해서 Key로 사용)
                    return transaction.transactionDate
                }.mapValues { transactions in
                    Array(transactions.reversed())
                }
                
                // 3. Relay에 저장
                groupedTransactions.accept(grouped)
                applyFilter()
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
    
    func getCategoryTransactions(yearMonth: Date, categoryId: Int) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let yearMonthString = formatter.string(from: yearMonth)

        Task {
            do {
                let transactions = try await transactionAPI.getCategoryTransactions(yearMonth: yearMonthString, categoryId: categoryId)
                categoryTransactions.accept(transactions)
            } catch {
                print("카테고리별 지출 내역 조회 실패: \(error)")
            }
        }
    }
    
    // 통계 - 수입
    func getCategoryStatisticsForIncome(yearMonth: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let yearMonthString = formatter.string(from: yearMonth)

        Task {
            do {
                var result: [CategoryStatistic] = []
                for category in IncomeCategory.allCases {
                    let transactions = try await transactionAPI.getCategoryTransactions(yearMonth: yearMonthString, categoryId: category.rawValue)
                    let total = Double(transactions.reduce(0) { $0 + $1.amount })
                    guard total > 0 else { continue }
                    result.append(CategoryStatistic(categoryId: category.rawValue, categoryName: category.name, totalAmount: total))
                }
                let sorted = result.sorted { $0.totalAmount > $1.totalAmount }
                categoryStatistics.accept(sorted)
            } catch {
                print("수입 카테고리별 데이터 로드 실패: \(error)")
            }
        }
    }
    
    
    // 내역-기록
    func applyFilter() {
        let origin = groupedTransactions.value
        let selectedExpense = selectedCategories.value
        let selectedIncome = selectedIncomeCategories.value

        if selectedExpense.isEmpty && selectedIncome.isEmpty {
            filteredTransactions.accept(origin)
            return
        }

        var newGrouped: [String: [Transaction]] = [:]

        for (date, list) in origin {
            let filteredList = list.filter { transaction in
                guard let maxItem = transaction.transactionInfoList.max(by: { $0.amount < $1.amount }) else {
                    return false
                }

                if let expenseCat = ExpenseCategory(rawValue: maxItem.categoryId) {
                    return selectedExpense.contains(expenseCat)
                }

                if let incomeCat = IncomeCategory(rawValue: maxItem.categoryId) {
                    return selectedIncome.contains(incomeCat)
                }

                return false
            }

            if !filteredList.isEmpty {
                newGrouped[date] = filteredList
            }
        }

        filteredTransactions.accept(newGrouped)
    }
    
}
