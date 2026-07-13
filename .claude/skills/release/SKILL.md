---
name: release
description: 릴리스 빌드 전 체크리스트 확인 및 App Store 아카이브 가이드. /release로 호출.
disable-model-invocation: true
---

릴리스 빌드 전 아래 순서로 확인하세요:

1. **Scheme**: Xcode에서 `Cloverly (prod)` Scheme 선택
2. **xcconfig**: `prod.xcconfig`의 BASE_URL, NATIVE_APP_KEY 값 확인
3. **버전/빌드 번호**: Xcode > Target > General에서 Version, Build 번호 업데이트
4. **서명**: 프로비저닝 프로파일 및 인증서 유효 기간 확인
5. **Firebase**: `GoogleService-Info.plist`가 prod용인지 확인 (gitignore 처리 필수)
6. **아카이브**: Product > Archive → Distribute App → App Store Connect
