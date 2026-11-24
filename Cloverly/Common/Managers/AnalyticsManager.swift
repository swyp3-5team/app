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

/// 생성/입력 종류 (단일 1건 / 여러 품목).
enum EntryType: String {
    case single
    case multiple
}

/// 수입/지출.
enum IncomeExpense: String {
    case income
    case expense
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
        static let transactionRecordCreated = "transaction_record_created"
        static let saveToastShown = "save_toast_shown"
        static let saveToastHistoryClicked = "save_toast_history_clicked"
        // Phase 4~: manual_entry_started, transaction_edit_completed,
        //           transaction_field_edited, history_feature_clicked ...
    }

    // MARK: - 속성키
    enum Key {
        static let screenName = AnalyticsParameterScreenName
        static let screenClass = AnalyticsParameterScreenClass
        static let source = "source"
        static let entrySurface = "entry_surface"
        static let inputMethod = "input_method"
        static let attemptId = "attempt_id"
        static let entryType = "entry_type"
        static let saveId = "save_id"
        static let recordId = "record_id"
        static let toastId = "toast_id"
        static let itemCount = "item_count"
        static let incomeExpense = "income_expense"
        static let isFirstRecord = "is_first_record"
        static let isFirstExpense = "is_first_expense"
        // Phase 4~: edit_id, screen_visit_id, field_name, edit_entry_point,
        //           edit_delay_seconds, entry_trigger, feature_name ...
    }

    /// is_first_record/is_first_expense는 전체 이력 기준 판별이라 서버 몫.
    /// 클라는 추정(false) 대신 unknown으로 보내 최초 집계에서 제외되게 한다.
    static let unknownValue = "unknown"

    // MARK: - 공통 로깅
    func log(_ event: String, parameters: [String: Any]? = nil) {
        Analytics.logEvent(event, parameters: parameters)
    }

    // MARK: - 저장 (Phase 3)

    /// 새 내역 저장 성공 (저장 작업당 1회, 수정 제외).
    /// - attemptId: AI 입력이면 해당 시도 ID, 수동 입력이면 manual_entry_started 시도 ID (없으면 nil)
    /// - isFirstRecord/isFirstExpense: 서버가 전체 이력 기준 판별해야 정확 → 클라는 unknown 전송
    func logTransactionSaved(entrySurface: EntrySurface, inputMethod: InputMethod, entryType: EntryType,
                             attemptId: String?, saveId: String, itemCount: Int) {
        var params: [String: Any] = [
            Key.entrySurface: entrySurface.rawValue,
            Key.inputMethod: inputMethod.rawValue,
            Key.entryType: entryType.rawValue,
            Key.saveId: saveId,
            Key.itemCount: itemCount,
            Key.isFirstRecord: Self.unknownValue,
            Key.isFirstExpense: Self.unknownValue
        ]
        if let attemptId { params[Key.attemptId] = attemptId }
        log(Event.transactionSaved, parameters: params)
    }

    /// 새 내역 생성 (record_id당 1회, 수정 제외). record_id는 서버 그룹 ID(trGroupId).
    func logTransactionRecordCreated(recordId: String, saveId: String, attemptId: String?,
                                     entrySurface: EntrySurface, inputMethod: InputMethod, incomeExpense: IncomeExpense) {
        var params: [String: Any] = [
            Key.recordId: recordId,
            Key.saveId: saveId,
            Key.entrySurface: entrySurface.rawValue,
            Key.inputMethod: inputMethod.rawValue,
            Key.incomeExpense: incomeExpense.rawValue
        ]
        if let attemptId { params[Key.attemptId] = attemptId }
        log(Event.transactionRecordCreated, parameters: params)
    }

    /// 저장 완료 토스트 표시.
    func logSaveToastShown(saveId: String, toastId: String) {
        log(Event.saveToastShown, parameters: [Key.saveId: saveId, Key.toastId: toastId])
    }

    /// 저장 토스트의 보기·내역 버튼 클릭.
    func logSaveToastHistoryClicked(saveId: String, toastId: String) {
        log(Event.saveToastHistoryClicked, parameters: [Key.saveId: saveId, Key.toastId: toastId])
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
