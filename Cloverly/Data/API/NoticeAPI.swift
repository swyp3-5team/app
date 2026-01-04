//
//  NoticeAPI.swift
//  Cloverly
//
//  Created by 이인호 on 1/4/26.
//

import Foundation
import Alamofire

final class NoticeAPI {
    let baseURL: String
    
    init() {
        self.baseURL = Bundle.main.infoDictionary?["BASE_URL"] as? String ?? ""
    }
    
    func getNoticies() async throws -> NoticeResponse {
        let url = "\(baseURL)/api/v1/notices"
        
        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        decoder.dateDecodingStrategy = .formatted(formatter)
        
        return try await NetworkManager.shared.session.request(
                url,
                method: .get
            )
            .validate(statusCode: 200..<300)
            .serializingDecodable(NoticeResponse.self, decoder: decoder)
            .value
    }
}
