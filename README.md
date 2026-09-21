# 타이밍 탭 (Tap Timing)

좌우로 움직이는 마커를 초록 구간 안에서 탭하는 Android 게임. Flutter.

- 로직: `lib/game.dart` (순수 Dart, 테스트: `test/game_test.dart`)
- 화면: `lib/main.dart`
- 개인정보처리방침: `docs/privacy.html` (GitHub Pages)
- 스토어 자산: `store/`

```bash
flutter test
flutter run -d chrome            # 빠른 플레이 확인
flutter build appbundle --release   # android/key.properties 필요 (git 제외)
```
