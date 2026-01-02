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
    
    let selectedIndex = BehaviorRelay<Int>(value: 1)
    private let disposeBag = DisposeBag()
    
    init() {
        bind()
    }
    
    func bind() {
        currentDate
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] date in
                self?.getTransactions(yearMonth: date)
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
                print(categoryStatisticsList)
                categoryStatistics.accept(categoryStatisticsList)
            } catch {
                print("카테고리 통계 데이터 로드 실패: \(error)")
            }
        }
    }
}
