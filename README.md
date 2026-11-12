# MindEcho

MindEcho 提供情緒記錄、AI 對話與身心狀態追蹤功能。目前主要開發專案為 `flutter_app/`，支援 iOS、Android 與 Web。

## 目前開發入口：Flutter

日常開發請開啟 `flutter_app/` 資料夾。環境設定、各平台啟動方式、已實作功能及已知限制，請參閱 [Flutter README](flutter_app/README.md)。

```sh
cd flutter_app
fvm flutter pub get
fvm flutter run
```

使用 Xcode 開發目前的 iOS App 時，請開啟 `flutter_app/ios/Runner.xcworkspace`。

## 專案結構

- [`flutter_app/`](flutter_app/README.md)：目前開發中的 Flutter App。
- [`legacy_ios/`](legacy_ios/README.md)：舊版 Swift／SwiftUI 專案、Xcode 專案、測試與資源，保留供參考。
- `docs/`：部署與安全檢查文件。
- `.github/`：GitHub 專案設定。

## 舊版 iOS 專案

舊版入口已移至 `legacy_ios/mindecho.xcodeproj`。相關原始碼、測試與資源一起保留，詳見 [舊版 README](legacy_ios/README.md)。

## 授權

本專案採用 [MIT License](LICENSE)。
