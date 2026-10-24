# MindEcho

MindEcho 的 iOS 前端專案，使用 Swift 與 SwiftUI 開發，提供情緒記錄、AI 對話與身心狀態追蹤功能。

## 主要功能

- 帳號註冊、登入與個人資料管理。
- AI 聊天、每日狀態填寫、情緒日記與心理量表。
- HealthKit 健康資料整合與每日提醒。

## 開發環境

- macOS 與 Xcode（含 iOS SDK）。
- Swift 5。
- App target 的最低部署版本為 iOS 16.6；測試 target 為 iOS 17.2。

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
