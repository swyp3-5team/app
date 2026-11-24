//
//  AnalyticsManager.swift
//  Cloverly
//

import Foundation
import FirebaseAnalytics

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
        // Phase 2~: chat_message_sent, ai_result_shown, result_cancelled,
        //           manual_entry_started, transaction_record_created,
        //           save_toast_shown, save_toast_history_clicked,
        //           transaction_edit_completed, transaction_field_edited,
        //           history_feature_clicked ...
    }

    // MARK: - 속성키
    enum Key {
        static let screenName = AnalyticsParameterScreenName
        static let screenClass = AnalyticsParameterScreenClass
        static let source = "source"
        // Phase 2~: entry_surface, input_method, entry_type, attempt_id,
        //           save_id, record_id, edit_id, toast_id, screen_visit_id,
        //           item_count, is_first_record, is_first_expense ...
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
}
