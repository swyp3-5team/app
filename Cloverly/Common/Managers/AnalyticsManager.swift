//
//  AnalyticsManager.swift
//  Cloverly
//

import Foundation
import FirebaseAnalytics

/// 입력 시작 위치. 홈에서 시작하면 채팅 이동/저장/수정까지 home 유지.
enum EntrySurface: String {
    case home
    case chatTab = "chat_tab"
    case historyTab = "history_tab"
}

/// 입력 방식.
enum InputMethod: String {
    case text
    case textPaste = "text_paste"
    case gallery
    case camera
    case manual
}

/// 하나의 입력 시도(전송~결과~저장/취소)를 잇는 컨텍스트.
struct InputAttempt {
    let id: String
    let entrySurface: EntrySurface
    let inputMethod: InputMethod

    init(entrySurface: EntrySurface, inputMethod: InputMethod, id: String = UUID().uuidString) {
        self.id = id
        self.entrySurface = entrySurface
        self.inputMethod = inputMethod
    }
}

/// 앱 분석 이벤트 중앙 로거.
/// 이벤트명·속성키를 한 곳에서 관리해 오타/누락을 막고, 커스텀 측정기준(entry_surface 등)을 일관되게 전송한다.
/// Phase 1: 중앙 래퍼 + 기존 이벤트(transaction_saved, screen_view) 이관.
/// 이후 Phase 2~5 에서 입력 컨텍스트(attempt_id 등)와 나머지 이벤트를 여기 추가한다.
final class AnalyticsManager {
    static let shared = AnalyticsManager()
    private init() {}

    // MARK: - 이벤트명
    enum Event {
        static let transactionSaved = "transaction_saved"
        static let screenView = AnalyticsEventScreenView   // Firebase 기본 screen_view
        static let chatMessageSent = "chat_message_sent"
        static let aiResultShown = "ai_result_shown"
        static let resultCancelled = "result_cancelled"
        // Phase 3~: manual_entry_started, transaction_record_created,
        //           save_toast_shown, save_toast_history_clicked,
        //           transaction_edit_completed, transaction_field_edited,
        //           history_feature_clicked ...
    }

    // MARK: - 속성키
    enum Key {
        static let screenName = AnalyticsParameterScreenName
        static let screenClass = AnalyticsParameterScreenClass
        static let source = "source"
        static let entrySurface = "entry_surface"
        static let inputMethod = "input_method"
        static let attemptId = "attempt_id"
        // Phase 3~: entry_type, save_id, record_id, edit_id, toast_id,
        //           screen_visit_id, item_count, is_first_record, is_first_expense ...
    }

    // MARK: - 공통 로깅
    func log(_ event: String, parameters: [String: Any]? = nil) {
        Analytics.logEvent(event, parameters: parameters)
    }

    // MARK: - 기존 이벤트 (Phase 1 이관, 동작 동일)

    /// 내역 저장 성공. source: "chat" | "manual" (Phase 3에서 entry_surface 등으로 확장 예정)
    func logTransactionSaved(source: String) {
        log(Event.transactionSaved, parameters: [Key.source: source])
    }

    /// 화면 조회. (Phase 4에서 screen_visit_id 포함 커스텀 screen_view로 확장 예정)
    func logScreenView(screenName: String, screenClass: String) {
        log(Event.screenView, parameters: [
            Key.screenName: screenName,
            Key.screenClass: screenClass
        ])
    }

    // MARK: - AI 입력 흐름 (Phase 2)

    private func attemptParams(_ attempt: InputAttempt) -> [String: Any] {
        [
            Key.attemptId: attempt.id,
            Key.entrySurface: attempt.entrySurface.rawValue,
            Key.inputMethod: attempt.inputMethod.rawValue
        ]
    }

    /// AI 입력 전송 시도 시작 (전송 시도당 1회)
    func logChatMessageSent(_ attempt: InputAttempt) {
        log(Event.chatMessageSent, parameters: attemptParams(attempt))
    }

    /// AI 결과 바텀시트 실제 표시 (시도당 1회)
    func logAiResultShown(_ attempt: InputAttempt) {
        log(Event.aiResultShown, parameters: attemptParams(attempt))
    }

    /// AI 결과를 저장하지 않고 취소 (시도당 1회)
    func logResultCancelled(_ attempt: InputAttempt) {
        log(Event.resultCancelled, parameters: attemptParams(attempt))
    }
}
