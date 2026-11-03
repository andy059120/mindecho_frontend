# Android 第一階段

沿用現有 Cupertino 畫面與 API，Android host 位於 `android/`。

- Flutter：由 `.fvmrc` 固定為 3.47.8。
- 最低版本：Android 7.0（API 24）。
- Application ID：`com.mindecho.mindecho_flutter`。
- 顯示名稱：MindEcho；圖示沿用現有品牌資產。
- `compileSdk`、`targetSdk`、NDK 沿用固定 Flutter SDK 的設定。

## 啟動與建置

安裝 Android Studio、Android SDK 與相容 JDK，接受 SDK licenses 後：

```sh
fvm flutter doctor -v
fvm flutter pub get
fvm flutter devices
fvm flutter run -d emulator-5554
fvm flutter build apk --release
```

裝置 ID 依 `flutter devices` 的結果調整。`API_BASE_URL` 可透過既有 dart-define 切換；正式 App 僅允許 HTTPS，不略過憑證驗證。Manifest 在 release 亦包含 INTERNET 權限。

Release APK 位於 `build/app/outputs/flutter-apk/app-release.apk`。目前沿用 Flutter 範本的 debug signing，僅供內部安裝驗收；尚未設定 Google Play 正式簽章與上架流程。不得將 keystore 或密碼加入版本控制。

## 平台行為

- 僅作用中分頁接收系統返回；隱藏分頁保留導覽堆疊。功能介紹覆蓋層優先關閉。
- 啟用 Android 返回 callback；沿用 Cupertino 頁面轉場，不宣稱已具備 Material predictive back 的全部動畫。
- 保留 edge-to-edge，透過 SafeArea、鍵盤 inset 與系統列圖示樣式適配畫面。
- SF Symbols 的 iOS MethodChannel 不在 Android 呼叫，使用各元件既有 Flutter fallback。
- Session、email、草稿與收藏中繼資料使用 flutter_secure_storage 的 Android 實作；不儲存密碼。
- 停用雲端備份與裝置搬移，避免加密資料與裝置金鑰分離。App 私有媒體也不進入系統備份；解除安裝會移除本機資料。
- 媒體選取前保存原帳號、用途與操作 ID。登入後恢復尚未完成的選取結果；寫入失敗保留路徑供重試，以操作 ID 避免重複新增收藏。
- 恢復完成後才建立分頁，讓頭貼與收藏讀到恢復後的資料。另一帳號不消耗原帳號的選取結果。
- 照片選擇採系統 picker，沒有新增廣泛儲存存取權限。

## 自動化驗證

```sh
fvm flutter analyze
fvm flutter test
fvm flutter test integration_test/android_smoke_test.dart -d emulator-5554
```

Smoke suite 使用模擬 HTTP，涵蓋登入、聊天、登出、分頁返回、日記新增、量表作答及失敗重試；另使用真實 Android plugin 驗證加密草稿與媒體保存、store 重建及帳號隔離。

跨程序恢復測試使用獨立本機測試帳號，先執行 seed：

```sh
fvm flutter run -d emulator-5554 --target integration_test/android_restart_test.dart
```

待 seed 測試通過後，終止 App 程序，再執行 restore；中間不要解除安裝或清除 App 資料，也不要使用會重新安裝清除資料的 test runner：

```sh
adb -s emulator-5554 shell am force-stop com.mindecho.mindecho_flutter
fvm flutter run -d emulator-5554 --target integration_test/android_restart_test.dart --dart-define=RESTART_PHASE=restore
```

此測試驗證程序終止前的草稿、收藏及已取得檔案路徑但尚未完成的媒體匯入。系統 picker 原生視窗中的低記憶體回收，另以可注入 picker 的單元測試驗證 retrieveLostData 分支；仍需手動端到端驗收實際系統 picker 與相機。

`integration_test/android_live_test.dart` 為手動真實後端驗收入口。透過本機 Dart VM service 在執行期間傳入測試帳密，不能使用 dart-define 或原始碼保存帳密。此測試會新增帶 `android-smoke-` 標記的聊天室與日記，保留既有內容；量表僅讀取歷史，不提交模擬健康答案。

在第一個終端啟動測試，再於第二個終端執行帳密輸入工具；輸入不會回顯：

```sh
fvm flutter run -d emulator-5554 --target integration_test/android_live_test.dart --vmservice-out-file /tmp/mindecho-live-vm.txt
fvm dart run tool/send_android_test_credentials.dart /tmp/mindecho-live-vm.txt
```

## 真實後端驗收（2026-11-02）

靜態分析與 50 項回歸測試通過；Pixel_10_Pro AVD 的 5 項 smoke 整合測試通過。另以保留安裝資料的 flutter run，通過強制終止程序前後的兩階段草稿、收藏與中斷匯入恢復測試。

Release APK 建置成功並已安裝啟動；產物確認為 minSdk 24、targetSdk 36、MindEcho 名稱與上述 Application ID。交付 APK 不含真實帳密測試用的 VM extension。進行整合測試與 release 建置時應依序執行，避免同時重新產生 plugin registrant。

Pixel_10_Pro AVD／Android 16（API 36.1）通過登入、聊天送出與讀回、日記新增與讀回、量表歷史讀取、持久化 session 重建與登出。測試內容標記為 `android-smoke-1793633568735`。

日記 `PATCH /diaries/{id}` 確認回傳 404。編輯功能仍須後端提供更新契約；目前維持失敗保留原文與草稿，不自動刪除後重建。量表真實提交、照片／相機原生介面、影片播放、最低支援版本與實機尚待驗收。
