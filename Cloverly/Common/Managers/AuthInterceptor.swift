//
//  AuthInterceptor.swift
//  Cloverly
//
//  Created by 이인호 on 12/25/25.
//

import Foundation
import Alamofire

class AuthInterceptor: RequestInterceptor {
    let api = LoginAPI()
    
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, any Error>) -> Void) {
        var urlRequest = urlRequest
        
        if let token = KeychainManager.shared.accessToken {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        completion(.success(urlRequest))
    }
    
    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        guard let response = request.task?.response as? HTTPURLResponse, (response.statusCode == 401 || response.statusCode == 403) else {
            completion(.doNotRetryWithError(error))
            return
        }
        
        if request.retryCount >= 2 {
            completion(.doNotRetryWithError(error))
            return
        }
        
        Task {
            do {
                let isSuccess = try await api.renewAccessToken()
                
                if isSuccess {
                    completion(.retry)
                } else {
                    completion(.doNotRetryWithError(error))
                }
            } catch {
                completion(.doNotRetryWithError(error))
            }
        }
    }
}
