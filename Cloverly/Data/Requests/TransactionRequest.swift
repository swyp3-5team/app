//
//  TransactionRequest.swift
//  Cloverly
//
//  Created by 이인호 on 12/29/25.
//

import Foundation

struct TransactionRequest: nonisolated Codable {
    let transactionDate: String
    // 수입은 결제수단/감정이 없어 null로 전송될 수 있다.
    let payment: Payment?
    let paymentMemo: String?
    let emotion: Emotion?
    let transactions: [TransactionDTO]
    // send 응답으로 받은 임시 저장 식별자. 서버가 이 건을 확정 처리한다.
    // 내역 수정 등 pending과 무관한 경로에서는 생략 가능하도록 기본값 nil. (memberwise init 포함 위해 var)
    var pendingId: String? = nil
}
