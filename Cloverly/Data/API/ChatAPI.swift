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
    
    func sendChat(message: String?, mode: ChatMode, image: UIImage?) async throws -> ChatResponse {
        let url = "\(baseURL)/api/chat/send"
        
        print(mode)
        
        let request = NetworkManager.shared.session.upload(
            multipartFormData: { multipart in
                if let modeData = mode.rawValue.data(using: .utf8) {
                    multipart.append(modeData, withName: "mode", mimeType: "text/plain")
                }

                if let message = message, let messageData = message.data(using: .utf8) {
                    multipart.append(messageData, withName: "message", mimeType: "text/plain")
                }
                
                if let image = image, let imageData = image.jpegData(compressionQuality: 0.5) {
                    multipart.append(imageData, withName: "image", fileName: "upload.jpg", mimeType: "image/jpeg")
                }
            },
            to: url,
            method: .post
        )

        let response = await request.serializingData().response

        // 1. 상태 코드 확인 (이게 제일 중요함!)
        if let statusCode = response.response?.statusCode {
            print("🔥 [Status Code]: \(statusCode)") // 👉 413이면 용량 초과, 500이면 서버 에러
        }

        // 2. 데이터 확인
        if let data = response.data {
            if let string = String(data: data, encoding: .utf8) {
                print("🔥 [Body]: \(string)")
            } else {
                print("🔥 [Body]: 데이터는 있는데 문자열 아님 (혹은 0바이트)")
            }
            
            // 3. 디코딩 시도
            do {
                return try JSONDecoder().decode(ChatResponse.self, from: data)
            } catch {
                print("❌ 디코딩 실패: \(error)")
                throw error
            }
        } else {
            // 여기가 문제의 원인 (데이터가 아예 없음)
            print("🔥 [Error]: 서버가 데이터를 1도 안 보내줌 (Empty Body)")
            throw AFError.responseSerializationFailed(reason: .inputDataNilOrZeroLength)
        }
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
