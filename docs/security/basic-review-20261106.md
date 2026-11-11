# MindEcho 基本資安檢查

檢查日期：2026-11-06（Asia/Taipei）。目標：`https://mindechoserver.com:8443/app/`。

## 結論

發現一項來自後端快照的高風險帳號復原設計，以及需要近期確認的憑證續期與數項防護缺口。不建議將目前結果解讀為「已通過資安驗收」。先處理密碼重設與續期，再處理標頭、登入防護與 Web session 架構。

本次完成前端原始碼／本機產物檢視、2026-11-02 提供的後端 zip 靜態檢視，以及低流量公開 GET／HEAD／OPTIONS。未登入、未提交帳密或重設密碼、未修改資料、未掃描其他連接埠、未執行壓力或暴力測試。未修改應用程式或正式服務。

後端快照不保證與正式部署版本一致；下列「程式碼確認」項目須由後端夥伴比對正式 commit。前端工作區有其他未提交修改，本次未變動它們；本機原始碼也未與線上 JS 做完整對應。

## 1. 高風險：密碼重設只核對姓名與 email（後端程式碼確認，正式機待核對）

依據：壓縮檔 `src/routes/auth.js` 的 `/reset-password` 未使用 authenticate；`src/controllers/authController.js` 的 resetPassword 在核對 email 與 name 後直接呼叫 UserService.updateUser 更新密碼，未驗證舊密碼、信箱所有權、一次性 token 或 OTP。前端 `flutter_app/lib/features/auth/auth_controller.dart` 亦只提交 name、email、newPassword。

影響：若正式機使用相同實作，知道他人姓名及 email 者可能接管帳號。姓名不是身分驗證秘密。這是程式碼證據，沒有在線上對任何帳號嘗試驗證。

處理：請後端夥伴優先確認並在伺服器端停用此復原方式，直到完成短效、不可預測且單次使用的驗證信連結／token；重設後通知使用者，處理既有 session 的失效。隱藏前端按鈕不能阻止直接呼叫 API。

## 2. 近期營運事項：憑證將於 2026-11-12 到期（線上確認）

系統 curl 預設驗證成功，主機名稱匹配，issuer Let's Encrypt YE1。

- notBefore：2026-08-14 00:57:26 UTC。
- notAfter：2026-11-12 00:57:25 UTC，即臺灣時間 11 月 12 日 08:57:25。
- 本次連線協商 TLS 1.3／AEAD-CHACHA20-POLY1305-SHA256。

處理：網管應立即確認 Certbot／ACME 排程、最近續期結果，以及續期後 Nginx reload 或容器部署流程，並在到期前完成更新。沒有證據表示自動續期一定失敗，但目前呈現的憑證尚未更新。

本機 Python ssl 的預設 CA 驗證因找不到 issuer 鏈失敗；後續以系統 curl 成功驗證。此差異未當作伺服器憑證無效的證據，過程未使用 -k 或關閉驗證。只確認本次協商版本，未驗證是否仍接受舊 TLS／弱密碼套件。

## 3. 中度防護缺口：前端 HTML 缺少安全標頭（線上確認）

`/app/` GET／HEAD 回傳 200、text/html、Cache-Control: no-cache，但未包含：

- Content-Security-Policy 或 Content-Security-Policy-Report-Only。
- X-Frame-Options；亦無 CSP frame-ancestors。
- X-Content-Type-Options。
- Referrer-Policy。
- Strict-Transport-Security。

相同來源的 `/api/user/profile` 和 `/api/chat/sessions` 401 回應有 Helmet 安全標頭，並不代表靜態網頁也受相同保護。瀏覽器曾讀到 API 的 HSTS 後仍可能已有 host 政策，因此結論是首頁回應未提供 HSTS，並非所有使用者都完全沒有 HSTS。

處理：網管在提供靜態 HTML 的 Nginx 區塊加入 nosniff、適當 Referrer-Policy、frame-ancestors 'none' 或明確允許的嵌入來源，與經確認的 HSTS 政策。CSP 先以 Report-Only 驗證相容性再強制執行，不能直接套用 API 的 Helmet CSP：Flutter CanvasKit、Wasm、blob 媒體、字型及實際資源來源需要逐一確認；避免因新增政策造成白畫面。新增 add_header 時也需確認 Nginx 標頭繼承。

## 4. 中度設計風險：Web token／敏感資料保存在 JavaScript 可存取的儲存（程式碼確認）

依據：SessionStore 與 AccountStore 使用 FlutterSecureStorage 預設設定；本機套件 flutter_secure_storage_web 2.1.1 使用 localStorage 保存加密資料，預設密鑰也在同來源儲存。AuthSession 保存 access token、可能的 refresh token 與 user。remember 參數只控制 email，並非控制是否持久保存 session。日記草稿、收藏等也使用帳號儲存，登出未刪除這些內容。

加密不等於 HttpOnly：若同來源任一頁面遭 XSS，攻擊腳本仍可能讀取／解密這些資料。此處沒有證實 XSS 或 token 已外洩；屬架構風險。既有測試頁、管理頁若部署於相同 scheme／host／port，亦共享 localStorage 的來源邊界，`/app/` 路徑本身無法隔離。

處理：與後端合作評估 HttpOnly、Secure、SameSite session cookie 或 BFF；改 cookie 認證時一併設計 CSRF 防護。短期縮短 token 生命週期、降低持久化敏感資料、提供清除本機資料操作並加強 CSP。把 token 改存 sessionStorage 只縮短保留時間，不能解決 XSS 存取問題。不可將前端內嵌固定密鑰當作此問題的解法。

## 5. 中度：一般使用者登入缺少程式內限速，且錯誤區分帳號存在（後端快照確認）

`src/routes/auth.js` 未套用 fixedWindowRateLimit；`src/app.js` 與所附 Nginx 未見全域登入限速。現有限速用於組織加入／人員申請，不涵蓋一般 login。authController.login 的帳號不存在與密碼錯誤回傳不同文字，可能被用來辨識已註冊 email。

處理：後端加入帳號與 IP 維度的合理限速／延遲與監控；統一外部登入失敗訊息。網管另確認正式入口是否有未包含在 zip 的限速或 WAF。未以大量請求測試正式機，故不能斷言正式站完全沒有外部防護。

## 6. 低度／設定錯誤：CORS 回傳 JSON 陣列字串（線上確認）

對登入端點 OPTIONS，Origin 使用 `https://security-check.invalid`，回傳：

`Access-Control-Allow-Origin: ["http://mindechoserver.com", "https://www.mindechoserver.com"]`

這不是有效的單一 origin，也不包含目前 https://mindechoserver.com:8443。與後端 app.js 直接把 CORS_ORIGIN 當字串傳入的程式一致。未觀察到反射任意 Origin；不能將此結果描述為允許惡意網站讀取 API。同源 `/api/` 不依賴 CORS，但若有合法跨來源前端會失敗。

處理：解析可信來源 allowlist，僅對匹配來源回傳該單一 Origin（含正確 port）與 Vary: Origin；未允許來源不回傳允許標頭。

## 其他觀察與已通過的基本項目

- 未登入 HEAD `/api/chat/sessions`、`/api/user/profile` 都回傳 401；證明這兩個路徑的匿名請求被拒絕，不代表跨帳號權限已驗證。
- `/app/assets/` 回傳 403，該目錄未提供索引列表；其他目錄未全面測試。
- `/app/.env`、`/app/.git/HEAD`、`/app/main.dart.js.map` 都回傳 200 text/html，但後續 GET 內容與首頁完全相同（1555 bytes）。屬 SPA fallback，未確認這三個路徑有秘密或 source map 外洩。建議 dotfiles 明確 404／403，缺少的靜態資源回傳 404，避免誤判。
- 本機 build/web 的檔名檢查未見 .env、私鑰、Dart 原始碼或 .map；不等於已完整掃描歷史 Git、所有字串及所有公開根路徑。
- 前端 API client 使用 Authorization bearer header，未將 token 放入查詢參數；所檢查程式未見記錄帳密或 token 的日誌。
- 後端密碼使用 bcrypt（cost 12）雜湊，註冊／公開 user projection 排除 password 欄位（依後端快照）。
- 所附 production Compose 仍有 postgres 的 `5432:5432` 映射，與旁邊「移除 ports」註解不符。未掃描 5432，無法判定是否外網可達。請網管核對實機；若只有容器內使用，移除對外映射或明確限制來源。
- 前端 bootstrap 預設可使用 gstatic CanvasKit，CSP／供應鏈檢視需納入；本次未做套件漏洞資料庫比對，不宣稱依賴零漏洞。

## 負責人及建議順序

1. 後端：當天核對並處理密碼重設；不要只改前端。
2. 網管：確認憑證在 11/12 前續期，核對資料庫埠映射及正式防火牆。
3. 後端／網管：登入限速、統一登入失敗訊息及靜態頁安全標頭。
4. 前後端：規劃 Web session／本機敏感資料保存；另安排兩個測試帳號的資料隔離驗證。

尚未檢查：真實帳號授權、IDOR、完整 XSS／注入、session 撤銷、備份權限、SSH 主機、正式 .env、TLS 舊版支援及完整套件 CVE。正式版本與快照差異需由維護者核對。

## 參考依據

- OWASP Forgot Password：https://cheatsheetseries.owasp.org/cheatsheets/Forgot_Password_Cheat_Sheet.html
- OWASP HTTP Headers：https://cheatsheetseries.owasp.org/cheatsheets/HTTP_Headers_Cheat_Sheet.html
- OWASP CSP：https://cheatsheetseries.owasp.org/cheatsheets/Content_Security_Policy_Cheat_Sheet.html
- OWASP HTML5 Storage：https://cheatsheetseries.owasp.org/cheatsheets/HTML5_Security_Cheat_Sheet.html
- OWASP Authentication：https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html
