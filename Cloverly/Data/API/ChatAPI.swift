//
//  ChatAPI.swift
//  Cloverly
//
//  Created by 이인호 on 12/25/25.
//

import UIKit
import Alamofire

final class ChatAPI {
    let baseURL: String
    
    init() {
        self.baseURL = Bundle.main.infoDictionary?["BASE_URL"] as? String ?? ""
    }
    
    func sendChat(message: String?, image: UIImage?) async throws -> ChatResponse {
        // v2: mode 없이 전송하면 서버가 RECEIPT/CHAT을 자동 분류해 응답
        let url = "\(baseURL)/api/chat/v2/send"

        let response = await NetworkManager.shared.session.upload(
            multipartFormData: { multipart in
                if let message = message, let messageData = message.data(using: .utf8) {
                    multipart.append(messageData, withName: "message", mimeType: "text/plain")
                }

                if let image = image,
                   let imageData = image.resized(maxDimension: 1024).jpegData(compressionQuality: 0.8) {
                    multipart.append(imageData, withName: "image", fileName: "upload.jpg", mimeType: "image/jpeg")
                }
            },
            to: url,
            method: .post
        )
        .validate()
        .serializingData()
        .response

        if let statusCode = response.response?.statusCode {
            print("🔥 [Status Code]: \(statusCode)")
        }
        if let data = response.data, let string = String(data: data, encoding: .utf8) {
            print("🔥 [Body]: \(string)")
        }

        let data = try response.result.get()
        return try JSONDecoder().decode(ChatResponse.self, from: data)
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
    
    func getChatHistory(page: Int, size: Int) async throws -> [ChatHistoryResponse] {
        let url = "\(baseURL)/api/chat/history?page=\(page)&size=\(size)"
        
        return try await NetworkManager.shared.session.request(
            url,
            method: .get
        )
        .validate(statusCode: 200..<300)
        .serializingDecodable([ChatHistoryResponse].self)
        .value
    }
}
