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
            
            // 1. [요청 로그] 실제로 날아가는 JSON 모양 확인 (가장 중요!)
            // Struct 덤프가 아니라, 진짜 인코딩된 JSON 문자열을 봐야 합니다.
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted // 보기 좋게
            if let jsonData = try? encoder.encode(transaction),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                print("🚀 [CLIENT] 보내는 JSON 데이터:\n\(jsonString)")
            }

            // 2. 요청 생성
            let request = NetworkManager.shared.session.request(
                url,
                method: .put,
                parameters: transaction,
                encoder: JSONParameterEncoder.default
            )
            
            // 3. [응답 로그] 서버가 뱉은 에러 메시지(Body) 뜯어보기
            let response = await request.validate().serializingData().response
            
            switch response.result {
            case .success(_):
                print("✅ [SUCCESS] 수정 성공!")
                
            case .failure(let error):
                // 400 에러일 때 서버가 준 메시지 출력
                if let statusCode = response.response?.statusCode, statusCode == 400 {
                    print("🔥 [400 ERROR] 요청 형식이 잘못되었습니다.")
                    
                    if let data = response.data, let serverMessage = String(data: data, encoding: .utf8) {
                        // ✨ 여기가 핵심입니다! 서버가 알려주는 진짜 이유
                        print("🔥 [SERVER MESSAGE]: \(serverMessage)")
                    }
                } else {
                    print("🔥 [ERROR] \(error.localizedDescription)")
                }
                
                // 에러를 다시 던져서 VM이 알게 함
                throw error
            }
    }
}
