//
//  TransactionAPI.swift
//  Cloverly
//
//  Created by 이인호 on 1/2/26.
//

import Foundation
import Alamofire

final class TransactionAPI {
    let baseURL: String
    
    init() {
        self.baseURL = Bundle.main.infoDictionary?["BASE_URL"] as? String ?? ""
    }
    
    func getTransactions(yearMonth: String) async throws -> [Transaction] {
        let url = "\(baseURL)/api/transaction-groups?yearMonth=\(yearMonth)"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        return try await NetworkManager.shared.session.request(
                url,
                method: .get
            )
            .validate(statusCode: 200..<300)
            .serializingDecodable([Transaction].self)
            .value
    }
    
    func getCategoryStatistics(yearMonth: String) async throws -> [CategoryStatistic] {
        let url = "\(baseURL)/api/v1/statistics/transactions/\(yearMonth)"
        
        return try await NetworkManager.shared.session.request(
                url,
                method: .get
            )
            .validate(statusCode: 200..<300)
            .serializingDecodable([CategoryStatistic].self)
            .value
    }
    
    func updateTransaction(transaction: Transaction) async throws {
        let url = "\(baseURL)/api/transaction-groups/\(transaction.trGroupId)"
        
        print(transaction)
        _ = try await NetworkManager.shared.session.request(
                url,
                method: .put,
                parameters: transaction,
                encoder: JSONParameterEncoder.default,
            )
            .validate()
            .serializingData()
            .value
    }
    
    func saveTransaction(requestBody: TransactionRequest) async throws {
         _ = try await NetworkManager.shared.session.request(
            "\(baseURL)/api/transaction-groups",
            method: .post,
            parameters: requestBody,
            encoder: JSONParameterEncoder.default,
        )
        .validate()
        .serializingData()
        .value
    }
}
