//
//  AppUpdateManager.swift
//  Cloverly
//
//  Created by 이인호 on 9/1/26.
//

import Foundation

enum AppUpdateStatus {
    case forced     // 강제: 취소 없이 업데이트만
    case optional   // 선택: "다음"으로 스킵 가능 + 업데이트
    case none
}

/// 앱스토어 최신 버전(iTunes lookup)과 현재 버전을 비교해 업데이트 필요 여부를 판정한다.
/// - 현재 버전이 `minimumRequiredVersion` 미만이면 강제(취소 불가)
/// - 그보다 높지만 스토어에 더 새 버전이 있으면 선택(스킵 가능)
final class AppUpdateManager {
    static let shared = AppUpdateManager()
    private init() {}

    /// 이 버전 미만이면 강제 업데이트. 릴리즈마다 비즈니스 결정으로 갱신한다.
    /// (1.5.1에는 "1.6.0"을 박아, 1.5.1 이하 유저를 1.6.0으로 강제 이동시킨다.
    ///  1.6.0에서는 그대로 두면 1.6.0 유저는 강제 대상이 아니게 된다.)
    private let minimumRequiredVersion = "1.6.0"

    /// "다음"으로 스킵한 선택 업데이트 버전 기억용 (더 새 버전 나오기 전까진 다시 안 물음)
    private let skippedVersionKey = "appUpdate.skippedOptionalVersion"

    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }

    struct Result {
        let status: AppUpdateStatus
        let storeVersion: String?
        let storeURL: URL?
    }

    func check() async -> Result {
        // lookup 실패(오프라인/스토어 미등록 등) 시엔 아무것도 하지 않아 사용자를 방해하지 않는다.
        guard let store = await fetchStoreInfo() else {
            return Result(status: .none, storeVersion: nil, storeURL: nil)
        }

        let current = currentVersion

        // 강제: 현재 < 최소요구, 그리고 스토어에 최소요구 이상 버전이 실제로 올라와 있을 때만
        if isVersion(current, lessThan: minimumRequiredVersion),
           !isVersion(store.version, lessThan: minimumRequiredVersion) {
            return Result(status: .forced, storeVersion: store.version, storeURL: store.url)
        }

        // 선택: 스토어에 더 새 버전이 있고, 이 버전을 "다음"으로 스킵하지 않았을 때
        if isVersion(current, lessThan: store.version),
           UserDefaults.standard.string(forKey: skippedVersionKey) != store.version {
            return Result(status: .optional, storeVersion: store.version, storeURL: store.url)
        }

        return Result(status: .none, storeVersion: store.version, storeURL: store.url)
    }

    /// "다음" 선택 시 해당 스토어 버전을 기억해, 더 새 버전이 나오기 전까진 선택 알림을 다시 띄우지 않는다.
    func skipOptional(storeVersion: String) {
        UserDefaults.standard.set(storeVersion, forKey: skippedVersionKey)
    }

    // MARK: - iTunes Lookup

    private func fetchStoreInfo() async -> (version: String, url: URL)? {
        guard let bundleId = Bundle.main.bundleIdentifier,
              let lookupURL = URL(string: "https://itunes.apple.com/lookup?bundleId=\(bundleId)&country=kr") else {
            return nil
        }

        // CDN 캐시로 신규 버전이 늦게 잡히지 않도록 캐시 무시
        var request = URLRequest(url: lookupURL)
        request.cachePolicy = .reloadIgnoringLocalCacheData

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let lookup = try JSONDecoder().decode(LookupResponse.self, from: data)
            guard let result = lookup.results.first else { return nil }

            // 내 앱 페이지로 여는 URL. trackViewUrl(정식 apps.apple.com URL)이 가장 확실하며,
            // iOS가 이 링크를 앱스토어 앱으로 라우팅한다. 없을 때만 trackId로 구성.
            let storeURL = URL(string: result.trackViewUrl)
                ?? URL(string: "itms-apps://apps.apple.com/app/id\(result.trackId)")
            guard let url = storeURL else { return nil }

            return (result.version, url)
        } catch {
            return nil
        }
    }

    private struct LookupResponse: Decodable {
        let results: [LookupResult]

        struct LookupResult: Decodable {
            let version: String
            let trackId: Int
            let trackViewUrl: String
        }
    }

    // MARK: - Version Compare

    /// "1.6.0" 같은 점 구분 버전을 숫자 기준으로 비교 (1.10.0 > 1.6.0)
    private func isVersion(_ lhs: String, lessThan rhs: String) -> Bool {
        lhs.compare(rhs, options: .numeric) == .orderedAscending
    }
}
