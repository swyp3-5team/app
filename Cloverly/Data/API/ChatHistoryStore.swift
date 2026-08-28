//
//  ChatHistoryStore.swift
//  Cloverly
//
//  Created by 이인호 on 12/11/25.
//

import Foundation

/// 채팅 히스토리 프리페치 캐시.
/// 홈에서 미리 최신 페이지를 받아두면, 채팅 진입 시 네트워크 대기 없이 즉시 표시할 수 있어
/// (특히 홈→영수증 전송 흐름에서) 히스토리가 뒤늦게 붙으며 스크롤이 튀는 걸 막는다.
final class ChatHistoryStore: @unchecked Sendable {
    static let shared = ChatHistoryStore()
    private init() {}

    private let api = ChatAPI()
    private let lock = NSLock()
    private var cached: [ChatHistoryResponse]?
    private var fetchedAt: Date?
    private var isFetching = false

    /// 최신 페이지를 미리 받아 캐시. 이미 받는 중이거나 최근에 받았으면 스킵.
    func prefetch(size: Int = 30, minInterval: TimeInterval = 20) {
        lock.lock()
        if isFetching {
            lock.unlock()
            return
        }
        if let fetchedAt, Date().timeIntervalSince(fetchedAt) < minInterval {
            lock.unlock()
            return
        }
        isFetching = true
        lock.unlock()

        Task {
            defer {
                lock.lock()
                isFetching = false
                lock.unlock()
            }
            do {
                let history = try await api.getChatHistory(page: 0, size: size)
                lock.lock()
                cached = history
                fetchedAt = Date()
                lock.unlock()
            } catch {
                // 프리페치 실패는 조용히 무시 (진입 시 정상 네트워크 로드로 폴백)
            }
        }
    }

    /// 신선한 캐시가 있으면 반환하고 소진한다. 없으면 nil.
    func consume(maxAge: TimeInterval = 120) -> [ChatHistoryResponse]? {
        lock.lock()
        defer { lock.unlock() }
        guard let cached, let fetchedAt, Date().timeIntervalSince(fetchedAt) < maxAge else {
            return nil
        }
        self.cached = nil
        self.fetchedAt = nil
        return cached
    }
}
