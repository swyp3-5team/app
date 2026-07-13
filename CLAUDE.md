# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project
iOS Swift 앱 (Cloverly) — 감정 기반 가계부 앱. 주 언어 한국어.

## Architecture
MVVM + 클린 레이어 구조:
- `Presentation/Views/` — UIViewController 기반 화면
- `Presentation/ViewModels/` — 비즈니스 로직 + 상태 관리
- `Domain/Entities/` — 도메인 모델
- `Data/API/`, `Data/Requests/`, `Data/Responses/` — 네트워크 레이어

새 화면 추가 시: ViewController → ViewModel → Data 순서로 작성.

## Dependencies
Swift Package Manager (SPM). CocoaPods 없음, `pod install` 불필요.
주요 패키지: Firebase, KakaoSDK, SnapKit, SDWebImage(+WebP), GoogleMobileAds

## Build Configurations
- **Dev**: Xcode에서 `Cloverly (dev)` Scheme 선택 → `dev.xcconfig` 적용
- **Prod**: `Cloverly (prod)` Scheme 선택 → `prod.xcconfig` 적용
- `BASE_URL`, `NATIVE_APP_KEY` 등 환경변수는 xcconfig로 주입됨 (파일에 직접 하드코딩 금지)

## Branch Conventions
`feature/`, `fix/`, `refactor/` 프리픽스 사용. 커밋 메시지 한국어.

## Localization
한국어 기본 (`ko.lproj`). 커스텀 폰트: Pretendard (`Resources/Fonts/`, 9 weights).
