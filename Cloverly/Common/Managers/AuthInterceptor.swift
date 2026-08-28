//
//  AuthInterceptor.swift
//  Cloverly
//
//  Created by 이인호 on 12/25/25.
//

import Foundation
import UIKit
import Alamofire

final class AuthInterceptor: RequestInterceptor, @unchecked Sendable {
    let api = LoginAPI()

    // 토큰 갱신 직렬화용. 동시에 여러 요청이 401을 받아도 갱신은 한 번만 수행하고
    // 나머지 요청들의 completion은 대기열에 모아 결과를 일괄 처리한다.
    private let lock = NSLock()
    private var isRefreshing = false
    private var pendingCompletions: [(RetryResult) -> Void] = []

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

        // 갱신 후에도 계속 401/403이면(재발급 토큰마저 거부) 로그아웃
        if request.retryCount >= 2 {
            forceLogout()
            completion(.doNotRetryWithError(error))
            return
        }

        lock.lock()
        // 이 요청의 completion을 대기열에 추가
        pendingCompletions.append(completion)

        // 이미 다른 요청이 갱신을 진행 중이면 대기만 하고 리턴 (갱신 중복 방지)
        if isRefreshing {
            lock.unlock()
            return
        }
        isRefreshing = true
        lock.unlock()

        Task {
            let success: Bool
            do {
                success = try await api.renewAccessToken()
            } catch {
                success = false
            }

            // 갱신 실패 시에만, 그리고 딱 한 번만 로그아웃 (동시 갱신이 없으므로 토큰 재기록 레이스 없음)
            if !success {
                forceLogout()
            }

            // 대기 중인 모든 요청에 결과를 일괄 적용
            lock.lock()
            let completions = pendingCompletions
            pendingCompletions.removeAll()
            isRefreshing = false
            lock.unlock()

            let result: RetryResult = success ? .retry : .doNotRetryWithError(error)
            completions.forEach { $0(result) }
        }
    }

    private func forceLogout() {
        KeychainManager.shared.delete(key: "accessToken")
        KeychainManager.shared.delete(key: "refreshToken")

        DispatchQueue.main.async {
            // 첫 번째 씬이 SceneDelegate를 가진다는 보장이 없으므로 전체에서 찾는다
            let sceneDelegate = UIApplication.shared.connectedScenes
                .compactMap { $0.delegate as? SceneDelegate }
                .first
            sceneDelegate?.checkAndUpdateRootViewController()
        }
    }
}
