//
//  ChatViewModel.swift
//  Cloverly
//
//  Created by 이인호 on 12/11/25.
//

import UIKit
import RxSwift
import RxCocoa
import FirebaseAnalytics

struct MessageSection {
    let dateString: String
    let messages: [Message]
}

final class ChatViewModel {
    // 통합 채팅: 영수증/대화 구분 없이 단일 타임라인
    let messages = BehaviorRelay<[Message]>(value: [])

    var currentSections: [MessageSection] {
        return groupByDate(messages.value)
    }

    var currentSectionsStream: Observable<[MessageSection]> {
        return messages
            .map { [weak self] messages -> [MessageSection] in
                self?.groupByDate(messages) ?? []
            }
    }

    private func groupByDate(_ messages: [Message]) -> [MessageSection] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월 dd일 EEEE"
        formatter.locale = Locale(identifier: "ko_KR")

        var groups: [(Date, [Message])] = []
        for message in messages {
            if let idx = groups.firstIndex(where: { calendar.isDate($0.0, inSameDayAs: message.date) }) {
                groups[idx].1.append(message)
            } else {
                groups.append((calendar.startOfDay(for: message.date), [message]))
            }
        }
        return groups.map { MessageSection(dateString: formatter.string(from: $0.0), messages: $0.1) }
    }
    
    let isSheetPresent = BehaviorRelay<Bool>(value: false)
    let selectedIndex = BehaviorRelay<Int>(value: 0)
    let api = ChatAPI()
    var chatResponse = BehaviorRelay<ChatResponse?>(value: nil)
    let isLoading = BehaviorRelay<Bool>(value: false)
    let errorRelay = PublishRelay<AppError>()
    let didSaveTransaction = PublishRelay<Void>()

    // 히스토리 페이징 (page 0 = 최신 페이지, 각 페이지는 오름차순)
    private let pageSize = 30
    private var currentPage = 0
    private var isLoadingHistory = false
    private var hasMoreHistory = true
    var canLoadMoreHistory: Bool { hasMoreHistory && !isLoadingHistory }
    
    func sendChat(message: String? = nil, image: UIImage? = nil) {
        if let msg = message {
            append(Message(kind: .text(msg), chatType: .send))
        }

        if let img = image {
            append(Message(kind: .photo(img), chatType: .send))
        }

        // 응답 전까지 어시스턴트 버블에 로딩 인디케이터 표시
        let loadingId = UUID()
        append(Message(id: loadingId, kind: .loading, chatType: .receive))

        Task {
            do {
                let response = try await api.sendChat(message: message, image: image)
                remove(id: loadingId)

                if response.transactionInfo != nil {
                    // 영수증으로 분류 → 저장 시트
                    self.chatResponse.accept(response)
                    self.isSheetPresent.accept(true)
                } else {
                    // 대화로 분류 → 메시지 버블
                    append(Message(kind: .text(response.message), chatType: .receive))
                }
            } catch {
                remove(id: loadingId)
                errorRelay.accept(AppError.from(error))
            }
        }
    }

    private func append(_ message: Message) {
        var list = messages.value
        list.append(message)
        messages.accept(list)
    }

    private func remove(id: UUID) {
        messages.accept(messages.value.filter { $0.id != id })
    }
    
    func saveTransaction() async throws {
        guard let info = chatResponse.value?.transactionInfo else {
            throw AppError.unknown
        }
        
        let requestBody = TransactionRequest(
            transactionDate: info.transactionDate,
            payment: info.payment,
            paymentMemo: info.paymentMemo,
            emotion: info.emotion,
            transactions: info.transactions.map { item in
                TransactionDTO(
                    name: item.name,
                    amount: item.amount,
                    categoryName: item.categoryName
                )
            }
        )
        
        try await api.saveTransaction(requestBody: requestBody)
        
        Analytics.logEvent("transaction_saved", parameters: [
            "source": "chat"
        ])
        
        append(Message(kind: .text(chatResponse.value?.message ?? "저장 완료"), chatType: .receive))

        didSaveTransaction.accept(())
    }
    
    // 최초 진입: 최신 페이지(page 0) 로드 후 하단 고정.
    // keepingCurrent=true면 이미 표시 중인 메시지(홈에서 방금 보낸 것)를 유지한 채
    // 히스토리를 앞에 붙인다.
    func loadInitialHistory(keepingCurrent: Bool = false) async {
        isLoadingHistory = true
        defer { isLoadingHistory = false }

        currentPage = 0
        hasMoreHistory = true
        do {
            let history = try await api.getChatHistory(page: 0, size: pageSize)
            hasMoreHistory = history.count == pageSize
            let mapped = mapHistory(history)
            if keepingCurrent {
                messages.accept(mapped + messages.value)
            } else {
                messages.accept(mapped)
            }
        } catch {
            errorRelay.accept(AppError.from(error))
        }
    }

    // 위로 스크롤 시: 다음(더 오래된) 페이지를 앞에 prepend
    func loadMoreHistory() {
        guard canLoadMoreHistory else { return }
        isLoadingHistory = true

        let nextPage = currentPage + 1
        Task {
            defer { isLoadingHistory = false }
            do {
                let history = try await api.getChatHistory(page: nextPage, size: pageSize)
                hasMoreHistory = history.count == pageSize

                let older = mapHistory(history)
                guard !older.isEmpty else { return }
                currentPage = nextPage
                // 각 페이지는 오름차순, 이전 페이지 전체가 더 오래됐으므로 앞에 붙이면 전체 오름차순 유지
                messages.accept(older + messages.value)
            } catch {
                errorRelay.accept(AppError.from(error))
            }
        }
    }

    private func mapHistory(_ history: [ChatHistoryResponse]) -> [Message] {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"

        return history.map { item -> Message in
            let chatType: ChatType = item.chatType == .assistant ? .receive : .send
            let date = dateFormatter.date(from: item.createdAt) ?? Date()

            let kind: MessageKind
            if let imageUrl = item.imageUrl, !imageUrl.isEmpty {
                // 서버가 상대경로(/api/chat/images/...)로 주므로 baseURL을 붙여 절대 URL로
                let absoluteUrl = imageUrl.hasPrefix("http") ? imageUrl : api.baseURL + imageUrl
                kind = .imageURL(absoluteUrl)
            } else {
                kind = .text(item.chatContent)
            }
            return Message(kind: kind, chatType: chatType, date: date)
        }
        .sorted { $0.date < $1.date }
    }
}
