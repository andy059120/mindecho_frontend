# MindEcho

MindEcho 的 iOS 前端專案，使用 Swift 與 SwiftUI 開發，提供情緒記錄、AI 對話與身心狀態追蹤功能。

## 主要功能

- 帳號註冊、登入與個人資料管理。
- AI 聊天、每日狀態填寫、情緒日記與心理量表。
- 每日提醒通知。

## HealthKit 保留功能

專案保留 `mindecho/hooks/HealthKitManager.swift` 與 `mindecho/pages/Diary/HealthDataView.swift`，已實作讀取心率變異（HRV）、深層睡眠時數、步數與體重，以及對應的健康資料畫面。

目前正式畫面沒有導向 `HealthDataView` 的入口；HealthKit 讀取由該頁面的 `onAppear` 觸發，因此目前正常操作流程不會觸發這項功能。專案仍保留 HealthKit capability 與權限用途說明。追蹤頁的五項指標使用每日填寫資料，並非由 HealthKit 取得。

這些 Swift 程式與設定先保留，Flutter 第一階段不納入 HealthKit／Health Connect 整合。

## Flutter 移植方向

- 第一階段先開發及驗收 iOS，最低支援版本維持 iOS 17.6。
- Web 已建立可本機預覽的第一版，啟動及限制見 Flutter README；Android 留待後續階段。
- Flutter 專案位於 `flutter_app/`，SDK 固定為 Flutter 3.47.8，iOS Bundle ID 為 `com.mindecho-5`。
- 已加入登入、聊天與四個主要分頁的 Flutter 實作；目前完成範圍、待驗收項目與啟動方式見 [Flutter README](flutter_app/README.md)。

## 開發環境

- macOS 與 Xcode（含 iOS SDK）。
- Swift 5。
- App target 的最低部署版本為 iOS 17.6；Project 層級與單元測試 target 為 iOS 17.2。

## 啟動方式

1. 使用 Xcode 開啟 `mindecho.xcodeproj`。
2. 選擇 `mindecho` scheme 與 iOS 模擬器或實體裝置。
3. 使用實體裝置時，在 Signing & Capabilities 設定自己的開發團隊與簽章。
4. 按下 Run（`⌘R`）啟動。

登入、聊天等功能需要可連線的後端 API。目前 API 位址設定於 `mindecho/API/APIService.swift`、`mindecho/API/ChatAPI.swift` 與 `mindecho/auth/AuthService.swift`。

## 專案結構

- `mindecho/pages/`：各功能頁面。
- `mindecho/components/`：共用 UI 元件。
- `mindecho/API/`、`mindecho/auth/`：API 與驗證服務。
- `mindecho/models/`、`mindecho/hooks/`、`mindecho/utils/`：資料模型、狀態管理與工具。
- `mindechoTests/`、`mindechoUITests/`：單元測試與 UI 測試。

## 授權

本專案採用 [MIT License](LICENSE)。
