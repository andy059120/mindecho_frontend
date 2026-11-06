# PsychEcho Flutter

同一個 repository 中的 Flutter iOS、Android 與 Web 前端。Swift 專案保留於上層 `mindecho/`，供功能與畫面對照。

## 固定環境

- Flutter **3.47.8 stable**，Dart **3.13.7**；版本記錄於 `.fvmrc`，套件版本記錄於 `pubspec.lock`。
- iOS 最低版本 **17.6**，Bundle ID **`com.mindecho-2`**，App 顯示名稱 **PsychEcho**。
- 已建立 iOS、Android 與 Web host。Android 第一階段設定、啟動及驗收方式見 [ANDROID.md](ANDROID.md)；Web 已加入第二版響應式配置，驗證範圍見下方「Web 第二版」。

## 啟動

安裝 FVM 與 Xcode 後，在本資料夾執行：

```sh
fvm use 3.47.8
fvm flutter pub get
fvm flutter run
```

實機執行請開啟 `ios/Runner.xcworkspace`，在 Runner 的 Signing & Capabilities 選擇自己的開發團隊，並確認該團隊可使用 `com.mindecho-2`。專案未固定個人開發團隊。

預設重用 Swift 的 `https://mindechoserver.com:8443/api`。需要切換環境時：

```sh
fvm flutter run --dart-define=API_BASE_URL=https://your-server.example/api
```

帳號密碼只從登入表單輸入，不應寫入原始碼、dart-define、文件或測試 fixture。HTTP client 不記錄帳密、token 或對話內容，也不略過 TLS 憑證驗證。

## 目前移植範圍

已實作歡迎、登入、註冊、忘記密碼與隱私政策；登入後顯示首頁、聊天、追蹤與個人檔案四個分頁，各自保留導覽狀態。

- 沿用 `/auth/login`、`/auth/register`、`/auth/reset-password`、`/auth/refresh`、`/auth/logout`、`/chat/sessions` 與訊息 API。
- 支援 `token`／`accessToken`、`user`／`userData` 回應欄位。
- iOS Keychain 儲存 session 與選擇記住的 email；不儲存密碼。
- 401 共用一次 token refresh，每個原請求最多重送一次；其他失敗不自動重送聊天 POST，以免重複建立訊息。
- 聊天列表支援分頁、下拉更新與刪除確認。
- 初談結束時可依後端 `initialMode` 建立建議模式的新聊天室。
- 使用 Cupertino 元件，沿用 Swift 品牌色、App 圖示、五種模式文案、歡迎訊息與危機字詞語料。危機警示可查看登入回應中的緊急聯絡資訊。

UI 還原以 Swift 程式與同尺寸模擬器畫面為依據。未登入時先顯示四頁歡迎輪播；登入與註冊採全螢幕呈現，政策與忘記密碼使用 sheet。iOS 以輕量 MethodChannel 取得原版 SF Symbols 的系統字形，頁面與狀態仍由 Flutter 繪製與管理。

本輪已加入：

| 區域 | 已實作內容 |
| --- | --- |
| 首頁 | 五項指標圖表與期間篩選、每日檢測紀錄、40 則箴言轉盤、檢測／日記提醒、9 份量表入口、收藏捷徑、求助資源與日記輸入 |
| 每日檢測 | 未完成時的登入提醒、五題作答、上一步、提交與失敗重試、結果分數與圓環；沿用 `/main/dailyQuestions` 欄位題序 |
| 追蹤 | 五項指標、每週概況、日記月曆與歷史、量表近五次紀錄與篩選；資料來源為既有 API |
| 日記 | 新增、讀取、編輯與刪除確認、依帳號與日期保存草稿；晚到的伺服器資料不覆蓋已編輯草稿 |
| 量表 | 原版 9 份題目、選項、反向計分、RFQ C/U 計分、作答檢視與結果文案；送出成功後才顯示完成 |
| 個人檔案 | 使用者卡片、基本資料讀取、姓名與 email 更新、頭貼選擇、本機時光寶盒、緊急聯絡、回饋入口與登出 |
| 時光寶盒 | 文字新增／編輯、圖片與影片匯入／預覽、同類排序、刪除確認；與 Swift 一樣儲存在本機 |
| 資源 | 原版求助資源與情緒管理文案、四類共 12 支放鬆影片，沿用原連結 |

**完整 App 的 1:1 驗收仍未完成。** 目前以原始 Swift 實作和同尺寸模擬器逐頁對照，主要頁面已加入，仍需針對完整量表／日記／收藏流程、彈出頁面、鍵盤、動畫及細部視覺差異繼續驗收。提醒通知與完整模式切換尚未移植；箴言轉盤音效尚未移植。

### API 與資料保存注意事項

- 重用 `/main/dailyQuestions`、`/diaries`、`/user/profile`、`/main/scales/sessions` 與 `/main/scales/{code}/answers`；靜態題目與文案由 Swift 原始碼轉存為 JSON。
- **日記更新相容性待驗證**：Swift 的更新操作使用 DELETE 後 POST。Flutter 目前使用 `PATCH /diaries/{id}`，不在失敗時自動刪除舊文章。真實後端是否支援 PATCH 尚未驗證；若不支援，編輯會顯示失敗並保留原紀錄與草稿，需要後續確認更新契約。日記新增及刪除使用既有 POST／DELETE。
- 個人資料更新沿用 Swift 的 `user_id`、`email`、`firstName`、`lastName`；出生年月目前僅顯示，尚未加入後端未確認的更新欄位。
- 真實帳號驗證僅登入與讀取。本輪未提交健康檢測、日記、量表或個人資料變更；寫入流程使用 Mock HTTP 驗證。
- 時光寶盒及頭貼圖片／影片放在 App Documents；中繼資料、日記草稿與 session 使用 Keychain。檔案使用相對檔名，依帳號分開；登出保留本機收藏與草稿供該帳號下次使用。
- 不同 Bundle ID 的 Swift／Flutter 本機收藏與草稿不會自動同步。

HealthKit 程式及設定繼續保留於 Swift，Flutter 本階段不接入，也不新增健康權限。

Flutter iOS 與原 Swift App 共用 Bundle ID `com.mindecho-2`，用於接續既有 App Store Connect／TestFlight App。相同開發團隊簽署下會作為同一個 App 更新；兩套實作的本機 session、草稿與收藏格式不同，目前未實作資料遷移，不能保證可直接讀取 Swift 的本機資料。後端既有資料仍透過相同帳號與 API 存取。

## 資料夾

```text
lib/
  app/                  App 啟動、四分頁導覽與品牌樣式
  core/network/         API client、錯誤與逾時處理
  core/storage/         session、帳號資料與 Keychain
  core/platform/        iOS 本機媒體儲存 adapter
  features/auth/        歡迎、登入、註冊、密碼重設、政策與 session refresh
  features/chat/        模式、API repository、列表與對話
  features/dashboard/   首頁、追蹤、共用資料、圖表及靜態內容
  features/check_in/    每日檢測與結果
  features/diary/        月曆、日記與草稿
  features/scales/       量表作答、計分與提交
  features/profile/      個人資訊、頭貼與本機收藏
  features/resources/    求助資源、情緒管理與放鬆影片
  shared/               共用 UI
assets/data/            從 Swift 沿用的固定內容
```

## 驗證

```sh
fvm flutter analyze
fvm flutter test
fvm flutter build ios --simulator --debug --no-codesign
```

自動化測試使用記憶體儲存與模擬 HTTP 回應，不連線真實後端。涵蓋登入欄位相容性、錯誤密碼、並行 401 refresh、過期 session、登出與 refresh 競態、聊天 API contract、危機語料，以及登入到聊天再登出的 widget 流程。

`--no-codesign` 僅用於驗證編譯；要在模擬器操作 Keychain，請使用正常的 `fvm flutter run` 流程。直接安裝未簽章的產物可能導致 Keychain 初始化失敗。

模擬器編譯成功不代表已在 iOS 17.6 實機驗收；發布前仍需測試最低支援系統、Keychain 與完整後端流程。

## 本次驗收紀錄（2026-10-30）

- `flutter analyze` 通過；10 項自動化測試通過。
- iOS 模擬器編譯通過，產物的 Bundle ID 為 `com.mindecho-5`、MinimumOSVersion 為 `17.6`。
- iPhone 17 Pro／iOS 26.5 模擬器實際驗證：既有帳號登入、讀取既有列表、建立測試聊天室、發送訊息、顯示後端回覆、重開 App 後恢復登入、重新讀取後端訊息、登出。
- 依使用者要求保留 `flutter-smoke-20261030` 測試對話；未刪除既有對話，未將測試帳密寫入專案。
- iOS 17.6 實機及完整 Swift UI 對照仍待驗收。

## UI 對照紀錄（2026-11-02）

- 在同一台 iPhone 17 Pro Max／iOS 26.5 模擬器切換 Swift 與 Flutter，對照歡迎及登入畫面。
- 還原四頁輪播、原版 Logo／插圖、字型、漸層、頁碼圓點、按鈕尺寸、輸入框邊框、勾選框、關閉與政策入口。
- 註冊保留兩步驟、性別／教育程度、出生年月、1–3 位緊急聯絡人與重要的一段話；API 沿用既有後端。政策文字自 Swift 原始碼轉存。
- 新增入口導覽、註冊前後步驟、政策閱讀與關閉、忘記密碼及 320／402／440 寬度的版面回歸測試；真實後端未新增帳號或修改密碼。
- 原 Swift 原始碼與 Bundle ID 保留，不改動。
- 19 項測試通過；歡迎／登入排版已在三種寬度與鍵盤彈出狀態檢查。

## 四分頁移植驗證（2026-11-02）

- 自動化測試共 29 項，含原有登入／聊天測試、每日檢測欄位映射與失敗重試、日記載入與草稿保留、更新失敗不刪原文、量表題數與計分、跨月／跨年圖表分組。
- 四分頁切換與首頁捲動已在 320×568、402×874、440×956 測試；每日檢測問題與結果頁包含小螢幕回歸測試。
- iPhone 17 Pro 及 Pro Max／iOS 26.5 模擬器成功建置與登入。於同一台 Pro Max 切換 Swift／Flutter，對照首頁、追蹤與個人檔案；讀取既有量表與聯絡資料，未修改後端紀錄。
- API 真實寫入、照片／相機授權、影片實際播放與 iOS 17.6 實機尚待驗收；模擬器建置成功不代表上述項目已通過。

## 純前端視覺對照（2026-11-02）

本輪依 Swift 原版調整 UI，保留 API、認證、資料模型、計分與本機保存方法。

- 首頁：量表卡片改為 160×180、資源／快捷卡片 160×140；對齊單行截斷、漸層與 SF Symbols。
- 聊天：原版模式漸層卡片、白色紀錄區、聊天室介紹 sheet、白色對話頁首、模式外觀、AI 頭像與氣泡圓角、輸入框邊框與橫向快速回覆。快速回覆只填入文字，送出仍使用原有按鈕與請求。
- 日記：月曆、心情選擇、輸入區與儲存區改回分開排列；對齊米白卡片、心情邊框、日期與歷史入口。草稿與儲存行為維持原實作。
- 量表：沿用 Swift 的 9 份簡介，還原進度條、選項分數、答案檢視、結果卡片；追蹤頁補上原版表格與圖表框線。
- 資源：恢復原版求助資源分組、技巧卡片的圖示與步驟編號，以及放鬆頁的四種分類與影片縮圖外觀。
- 個人檔案：時光寶盒的新增按鈕與空狀態、回饋入口及紅色登出按鈕。
- 分頁：膠囊分段選單、選取動畫、底部模糊背景，以及帶局部鏤空的功能介紹提示。

視覺回歸包含 320／402／440 寬度、彈出頁面、長內容捲動、導覽提示與鍵盤。模式切換的後端功能、列表摘要與訊息時間等尚未暴露給現有 ViewModel 的資料，本輪不擴充；系統原生 sheet／選單及不同 iOS 版本的字型與動態材質，仍需逐狀態對照，不能視為全 App 逐像素驗收完成。

本輪驗證：`flutter analyze` 通過、33 項測試通過；iPhone 17 Pro Max／iOS 26.5 的正常簽章模擬器建置通過。測試涵蓋介紹頁、資源頁、量表與日記捲動、導覽提示和快速回覆；真實帳號僅登入與讀取，未新增或修改後端內容。


## Web 第一版（2026-11-02）

沿用現有歡迎、登入及四分頁功能；桌面瀏覽器採最大 520 px 的置中版面，小螢幕依可用寬度顯示。尚未部署至公開網址。

### 本機啟動（含 API 轉送）

在 `flutter_app/` 執行：

```sh
fvm flutter build web --release --dart-define=API_BASE_URL=/api
python3 tool/serve_web.py
```

瀏覽器開啟 `http://localhost:8080`。停止時按 Ctrl+C。工具只綁定本機介面，僅轉送 `/api/` 至既有 HTTPS 後端，不記錄請求內容或 token，也不略過 TLS 驗證；僅供開發使用。更改 port 時請使用 `--port 8081`，並注意瀏覽器儲存會依來源（含 port）隔離。

### 直接開發／正式建置

後端 CORS 設定完成後，可直接執行：

```sh
fvm flutter run -d chrome --web-port 8080
fvm flutter build web --release --dart-define=API_BASE_URL=https://your-server.example/api
```

正式產物位於 `build/web/`；需以 HTTPS 提供（本機 localhost 可使用 HTTP），不能直接開啟 index.html。新增 Web 平台與建置方式依 [Flutter 官方文件](https://docs.flutter.dev/platform-integration/web/building)。

### 已知限制與保存方式

- 後端實測的 OPTIONS 回應為 `Access-Control-Allow-Origin: ["http://mindechoserver.com", "https://www.mindechoserver.com"]`。瀏覽器需要單一匹配來源；後端應依 allowlist 回傳請求的 Origin，包含開發用 `http://localhost:8080` 與正式網域，並允許 Content-Type、Authorization 和現有 API methods。本機轉送是開發替代方案，不會修改後端。
- Web session、記住的 email、草稿及收藏使用 flutter_secure_storage 的 WebCrypto 瀏覽器儲存；與 iOS Keychain 分開，清除網站資料後會遺失，不跨裝置同步，也不儲存密碼。需 HTTPS 或 localhost。
- 圖片、頭貼與影片首版以 base64 保存於帳號儲存，每檔最多 2 MB；總容量仍受瀏覽器配額限制，額滿會顯示儲存失敗。影片可播放格式取決於瀏覽器，媒體匯入及播放仍需人工驗收。
- 非 iOS 使用既有 Cupertino icon fallback，不呼叫 SF Symbols 原生 channel。
- 未使用真實帳密提交登入或聊天；登入後的真實後端完整流程仍待測試帳號驗收。現有通知與其他尚未移植功能的限制仍適用。


### 第一版驗證結果

- Web release 編譯通過（含 Wasm dry run）；`flutter analyze` 通過。
- 既有 33 項 VM 測試通過；新增 Web 媒體 adapter 保存／刪除測試通過。
- Chrome 歡迎、註冊欄位、忘記密碼、三種手機寬度，以及 Mock 登入 → 聊天 → 登出共 7 項通過。
- Chrome 的既有隱私政策自動化測試失敗；實際本機瀏覽器已確認政策能載入並顯示內容，自動化失敗原因仍待定位，不能宣稱 Chrome 全測試通過。
- 本機首頁 HTTP 200，已實際檢查歡迎及政策畫面；未登入真實帳號、未寫入後端資料。

## 視覺細節補充（2026-11-02）

- 圖表的指標、時間週期、平均區間及量表篩選，改為靠近觸發按鈕的浮動選單；對齊原版圓角、項目間距、分組分隔與淡入動畫，保留取消不變更原值。
- 日記月曆改用 SF Symbols 月份箭頭，加入月份／年份選擇、月份切換動畫、今日字重與選取狀態。瀏覽月份不會寫入或更改日記。
- 個人資訊改為原版頭像卡片、圖示欄位與編輯入口，並對齊白色導覽背景、圓形返回按鈕及內容高度。頭貼沿用既有讀寫方法。
- 編輯個人資訊改為原生風格的分組表單，調整列高、圓角、背景及保存按鈕；出生年月仍為顯示欄位，本輪不擴充更新資料。
- 新增 7 項測試，涵蓋 320／402／440 寬度、長選單、取消、個人資訊、鍵盤與跨月份／閏年月曆；目前完整 41 項測試與靜態檢查通過。
- API、資料層、認證及本機儲存實作維持本輪開始時的內容。原 Swift 與其他既有 Web 工作保留。

## 首頁、追蹤與聊天細修／iOS 17.6 檢查（2026-11-02）

- 首頁與追蹤圖表：依 Swift 原始碼對齊繪圖區留白、座標與日期標籤、格線、圓角及陰影；單一指標使用較粗折線與數值標示，切換後同步更新提示。量表日期標籤移至圖框外。
- 聊天：對齊訊息泡泡可用寬度、文字行高、輸入列背景與傳送中提示位置；超過 100 個字元顯示字數，以 grapheme cluster 計算 emoji。訊息時間仍待後續資料層規劃，本輪不補造時間或修改 API model。
- UI 使用現有 Flutter 繪製與 Cupertino 元件，沒有新增要求 iOS 18／26 的原生 API。SF Symbols 在較舊系統找不到圖示時會沿用現有 Cupertino icon fallback。

### 最低支援版本的證據與限制

- Runner 的 Debug／Profile／Release deployment target、AppFrameworkInfo.plist 與產生的 Swift Package platform 均設定為 **17.6**，沒有降低到 17.5，也沒有提高最低需求。
- 已檢查鎖定版本的原生套件 manifest：secure storage／URL launcher 最低 iOS 13，image picker／video player 最低 iOS 15；沒有套件要求高於 17.6。
- `flutter build ios --debug --no-codesign --no-pub` 通過。實機產物 Info.plist 的 MinimumOSVersion 與 Runner／Runner.debug.dylib 的 Mach-O minos 為 **17.6**；內嵌 Flutter、App、objective_c framework 的 minos 為 **15.0**，沒有把 App 的最低需求拉高。這份未簽署產物只用於編譯與版本檢查，沒有安裝到實機。
- 本機已安裝的 runtime 為 iOS 17.0、17.5、26.5，沒有 17.6；此次畫面驗收在 **iOS 26.5**，**不代表 iOS 17.6 實機驗收完成**。發布前仍須用 17.6 裝置驗證啟動、登入／Keychain、鍵盤、相片及影片流程。
- Flutter 系統支援範圍可參考 [官方支援平台文件](https://docs.flutter.dev/reference/supported-platforms)；本專案仍固定 Flutter 3.47.8，實際可部署性以鎖定 SDK、套件及產物檢查為準。
- 新增窄螢幕圖表切換測試，並補充含 emoji 的長訊息字數與鍵盤測試；完整 42 項測試通過。API、認證、資料 model 與儲存實作未修改。


## Web 第二版（2026-11-06）

Web 改為依可用寬度配置內容，沿用 iOS 的暖色、Cupertino 元件、卡片樣式、四分頁內容與原有操作。

- **導覽與寬度**：移除全站 520 px 限制；900 px 起使用 216 px 側邊導覽，較窄視窗維持底部分頁。內容最大 1120 px；縮放視窗保留目前分頁與導覽狀態，較矮視窗可捲動側欄。
- **歡迎與表單**：桌面歡迎頁改成品牌介紹與輪播／登入入口雙欄；登入、註冊與密碼重設表單最大 560 px，避免欄位隨桌面過度拉寬。
- **首頁與追蹤**：圖表依實際內容區寬度切換雙欄／單欄；文字放大時回到單欄。量表卡片於寬螢幕自動換列，窄螢幕維持 iOS 橫向捲動。
- **隱私政策**：Web 使用獨立閱讀頁，原生 App 沿用 sheet。桌面加入固定側邊目錄，三個主題膠囊可跳至對應章節；全文可選取，導覽列保留關閉入口，載入失敗可重試。以 iOS 原始碼對齊漸層頁首、主題膠囊、章節標記、保存期限分組與附錄卡片。
- **隱私內容與同意**：既有政策 JSON 全文保留；附錄改用與註冊相同的六項聲明來源，預設不勾選。新增 Web 本機資料保存、不同瀏覽器／來源、清除網站資料及登出保留草稿與收藏的說明；個人檔案與桌面側欄皆可開啟政策。
- **歡迎頁安全文案**：將缺乏實作依據的「端到端加密」改為加密通道傳送及雲端 AI 處理的說明。

### 第二版驗證

```sh
fvm flutter analyze
fvm flutter test
fvm flutter test --platform chrome test/features/auth_ui_test.dart test/features/web_responsive_test.dart test/features/privacy_page_test.dart test/features/app_test.dart
fvm flutter build web --release --dart-define=API_BASE_URL=/api
python3 tool/serve_web.py
```

- 完整 VM 測試 **52 項通過**；指定 Chrome 測試 **14 項通過**。
- Chrome 涵蓋 320／768／1024／1440 px、短視窗、政策目錄與全文捲動、載入失敗重試、大字閱讀、六項同意與返回保留、九張量表卡片換列、分頁與視窗縮放狀態、Mock 登入／聊天／登出。
- 第一版 Chrome 政策測試的 asset 載入問題已修復：瀏覽器 widget 測試使用政策 fixture，另由 VM 檢查 fixture 與正式 JSON、六項聲明一致；正式 App 仍讀取原政策 asset。
- 本機 release 網頁實際檢查桌面與手機的歡迎／政策頁。未使用真實帳號或提交後端資料；未部署至公開網址。既有 API、瀏覽器儲存、CORS、媒體及未移植功能的限制仍適用。
