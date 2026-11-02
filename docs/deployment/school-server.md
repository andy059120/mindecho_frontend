# 學校實體伺服器部署評估

日期：2026-11-02。依使用者提供的 mindecho_backend.zip 研究，尚未 SSH 至正式機，也未變更正式服務。壓縮檔內文件僅作為架構資料，未執行其中任何腳本。

## 結論與建議網址

建議第一版使用既有 HTTPS 網域的 `/app/` 路徑，例如 `https://mindechoserver.com/app/`（網址須由網管確認）。沿用 `/api/` 作為 API；前端與 API 同源，不必新增 DNS／憑證，亦不依賴後端目前有問題的 CORS 回應。若網管決定改用其他網域、連接埠或路徑，必須重新確認此結論。

瀏覽器 → HTTPS Nginx → `/app/`：Flutter 靜態檔案
瀏覽器 → 同一個 HTTPS Nginx → `/api/`：backend-prod:8443 → 既有資料庫／推論服務

前端在開發電腦編譯後上傳即可；正式伺服器不需要安裝 Flutter，不需要啟動 Python 開發轉送工具。

## 壓縮檔內的具體依據

| 檔案 | 觀察 |
| --- | --- |
| `docker-compose.prod.yml` | nginx 對外映射 80/443，掛載 `./nginx` 與 `/etc/letsencrypt`；已掛載 dev-frontend/dist 及 admin-frontend/dist |
| `nginx/conf.d/default.conf` | 設定 mindechoserver.com、www.mindechoserver.com 與 Let's Encrypt 憑證；HTTPS `/api/` 已轉送至 `http://backend-prod:8443`，保留 `/api/` 路徑 |
| `nginx/conf.d/default.conf` | 已有 `/testWebpage/chatbot/` 與 `/adminWebpage/`，新增獨立 `/app/` 可保留兩者 |
| `src/server.js` | Express 使用 app.listen，後端是內部 HTTP；不要因 8443 這個數字就改用 HTTPS upstream |
| `src/app.js` | routes 掛在 `/api/`；production CORS 直接讀取 CORS_ORIGIN 字串，並未解析 JSON 陣列 |
| `nginx/mime.types` | 已包含 application/wasm、JavaScript、JSON 與字型 MIME |

本機未安裝 Nginx／Docker，因此範本尚未通過 nginx -t；須由網管在實際部署環境驗證。

原始碼不代表正式機正在使用同一份版本。正式前需由網管比對執行中的 Compose 專案、Nginx 設定、容器網路及憑證。

## 公開入口連線觀察

本次從開發端讀取健康檢查：

- `https://mindechoserver.com:8443/api/alive` 成功，回應 production mode。
- `https://mindechoserver.com/api/alive`（443）兩次測試均在 15 秒逾時，包含沙箱外測試。

這僅證明測試當下從此網路的可達性，無法判定是防火牆、NAT、服務未啟動或其他原因。建議請網管先確認 443 入口、實際 port mapping 與校外連線政策；不能僅依 zip 假設 443 已可使用。目前既有 App 依賴 8443，不應為了新增前端直接關閉或改動它。

若正式機最後決定網站也使用 :8443，前端與 API 必須一併由該 HTTPS 入口提供 `/app/` 與 `/api/`，才是同源；不可只將 :443 網頁的 API 指回 :8443 而宣稱沒有跨來源問題。具體設定應以執行中的入口架構為準。

## 權限分工

一般 SSH 帳號通常可做（仍取決於目錄權限）：

- 查看自己的帳號及群組：`id`。
- 在自己的 home 建立 release 目錄、使用 scp/sftp 上傳及解壓縮前端產物。
- 使用瀏覽器與 curl 檢查公開網站。

需要網管或被授權的管理者：

- 確認正式後端 checkout 位置，以及是否允許使用 `/app/`。
- 提供可上傳的前端目錄與適當的讀取／目錄穿越權限；不使用 chmod 777。
- 在正式 nginx service 新增一個唯讀 bind mount。
- 修改 HTTPS server 區塊、驗證設定並重新建立 nginx 容器。
- 若要新網域，處理 DNS、憑證與校方防火牆。

不需要為此取得資料庫密碼或整台主機的 sudo。Docker 管理權限很高，第一版可由網管執行容器操作，使用者只負責上傳。

## 開發端建置

在本專案 flutter_app 目錄：

```sh
fvm flutter build web --release --base-href /app/ --dart-define=API_BASE_URL=/api
```

上傳 `build/web/` 的所有內容（包含隱藏檔，如有），不要只上傳 index.html。網管掛載來源目錄應直接包含 index.html、flutter_bootstrap.js、main.dart.js、assets/ 等，不要多包一層 web/。

不要把原始碼、.env、後端 zip 或帳密放入公開靜態目錄。此流程不需要上傳任何後端環境變數。

## 網管設定範本：僅供合併，不可整份取代正式設定

假設網管選定後端 checkout 下的 `./flutter-frontend` 作為產物目錄。

在既有 `docker-compose.prod.yml` 的 `services.nginx.volumes` 新增一行，保留原有掛載：

```yaml
      - ./flutter-frontend:/usr/share/nginx/html/app:ro
```

來源目錄需先建立並放好產物；如果一般帳號只有 home 目錄可寫，可由網管改為指定的絕對路徑。

在既有 443 SSL server 區塊內新增：

```nginx
location = /app {
    return 301 /app/;
}

location ^~ /app/ {
    root /usr/share/nginx/html;
    index index.html;
    try_files $uri $uri/ =404;
    add_header Cache-Control "no-cache" always;
}
```

這裡使用 `root`，`/app/assets/...` 會對應 `/usr/share/nginx/html/app/assets/...`。目前 Flutter 沿用預設 hash URL strategy，因此不需為任意巢狀路徑回傳 index.html；若未來改用 path strategy，再補 SPA fallback。缺少的 JS／資源目前會正確回傳 404。

80 server 可新增僅針對 `/app` 與 `/app/` 的 HTTPS redirect；由網管依實際網域設定。瀏覽器應使用 HTTPS 網址。現有 API、測試頁、管理頁與 ACME 設定保留。

`/api/` 的既有 proxy_pass 不需修改，也不在 URL 加上 :8443；前端呼叫的是對外 Nginx 443，8443 為此 Compose 的後端內部埠。

## 網管套用與回復

以下為範例，需先確認實際 Compose 專案目錄／檔名／project name 與已部署的一致：

1. 備份現行 Nginx、Compose 與前端產物，確認舊網站可正常使用。
2. 放好新產物，加入上述 mount 與 location。
3. 在正式 checkout 檢查新的容器設定（不要公開貼出完整 compose config，可能含環境機密）：

   ```sh
   docker compose -f docker-compose.prod.yml run --rm --no-deps nginx nginx -t
   ```

4. 語法與相依網路確認無誤後，由網管排定短暫維護時間：

   ```sh
   docker compose -f docker-compose.prod.yml up -d --no-deps nginx
   ```

   新增 bind mount 需要重建容器，單純 nginx reload 不會新增掛載。重建 nginx 會短暫影響共用該容器的其他網站與 API，可能中斷進行中的聊天；須安排時段。

5. 不需要啟動 db-init、不需要資料庫 migration、不需要重建整組服務。
6. 驗證失敗時，恢復原設定、移除新增 mount，依同樣程序驗證及重建 nginx；後端與資料庫維持原服務。

後續單純更新產物，可更新既有 mount 內的檔案，不需要重建後端。更新前備份並安排維護時段，避免使用者在檔案替換途中載入混合版本。不要直接把 bind mount 的來源目錄重新命名替換，執行中的 mount 可能仍指向舊目錄。

## 驗收項目

- `/app` 導向 `/app/`，HTTPS 憑證有效。
- `/app/`、bootstrap、JS、assets 與 wasm 下載成功，沒有被誤送成 HTML。
- `/api/alive` 可回應；這只代表基本連線，不代表登入與所有功能均通過。
- 原有測試頁、管理頁、iOS API 仍可使用。
- 測試帳號登入、讀聊天、送測試訊息、重新整理／重開後恢復登入、登出。
- Web 儲存與 iOS 不同步；第一次在正式網址使用需重新登入。
- 已知 Web 第一版限制仍適用：單檔媒體 2 MB、瀏覽器儲存配額、真實媒體播放待驗收，以及既有 Chrome 隱私政策自動化失敗待定位。

## 尚需網管確認的問題

1. 正式入口是否確為 `https://mindechoserver.com`，可否使用 `/app/`？
2. 正式機是否使用壓縮檔中的 Docker Compose／Nginx 架構？目前專案目錄在哪裡？
3. 我的 SSH 帳號可以上傳到哪個目錄？能否提供專用的前端上傳目錄？
4. 誰負責首次掛載、設定驗證與 nginx 重建？可安排哪個時段？
5. 網站要開放校外，還是限定校內／VPN？
6. 為何現有 :8443 健康檢查可達，但標準 HTTPS 443 從開發端逾時？443 是否已開放／轉送至 nginx？

## 可直接轉交網管的訊息

> 我們已完成 MindEcho Flutter Web 第一版，希望沿用目前伺服器的 HTTPS 網域新增 `/app/`。前端是靜態檔案，API 使用同網域 `/api/`，沿用現有 backend-prod，不需要變更資料庫。可否協助確認網址與上傳目錄，並在現有 nginx 容器新增一個唯讀靜態目錄掛載及 `/app/` location？首次需要驗證設定並重建 nginx，會短暫影響共用入口，想請您安排時段。後續我可負責建置與上傳產物。

## 官方參考

- Flutter 子路徑與 base href：https://docs.flutter.dev/ui/navigation/url-strategies
- Nginx root／try_files：https://nginx.org/en/docs/http/ngx_http_core_module.html
- Docker bind mounts：https://docs.docker.com/engine/storage/bind-mounts/
- Compose up 與 --no-deps：https://docs.docker.com/reference/cli/docker/compose/up/
