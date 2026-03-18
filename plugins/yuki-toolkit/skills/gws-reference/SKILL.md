---
name: gws-reference
description: Use when you need to operate Google Workspace services (Calendar, Gmail, Drive, Sheets, Docs) via the gws CLI. Provides command format reference, authentication setup, and usage examples for all supported services.
---

# gws CLI 指令參考

Google Workspace CLI (`gws`) 統一操作所有 Google Workspace 服務。本文件為指令格式參考，涵蓋 Calendar、Gmail、Drive、Sheets、Docs。

## 認證設定

首次使用前需完成認證：

```bash
gws auth login
```

相關環境變數：
- `GOOGLE_WORKSPACE_CLI_CREDENTIALS_FILE` — OAuth 認證檔案路徑
- `GOOGLE_WORKSPACE_CLI_CLIENT_ID` / `GOOGLE_WORKSPACE_CLI_CLIENT_SECRET` — OAuth client 資訊
- `GOOGLE_WORKSPACE_CLI_TOKEN` — 預先取得的 access token（最高優先）
- `GOOGLE_WORKSPACE_CLI_CONFIG_DIR` — 覆寫設定目錄（預設 `~/.config/gws`）

認證過期時會收到 401 錯誤，需重新執行 `gws auth login`。

## 通用指令格式

```bash
# 基本查詢
gws <service> <resource> <method> --params '<JSON>'

# 帶 request body（POST/PATCH/PUT）
gws <service> <resource> <method> --params '<JSON>' --json '<JSON>'

# 檔案上傳
gws <service> <resource> <method> --json '<JSON>' --upload <PATH> --upload-content-type <MIME>

# 檔案下載
gws <service> <resource> <method> --params '<JSON>' --output <PATH>
```

## Schema 查詢

不確定 API 參數時，先查 schema，不要猜測：

```bash
gws schema <service.resource.method>
gws schema <service.resource.method> --resolve-refs  # 展開巢狀型別
```

範例：
```bash
gws schema calendar.events.list
gws schema gmail.users.messages.send --resolve-refs
```

## Calendar

```bash
# 列出事件
gws calendar events list --params '{"calendarId":"primary","timeMin":"2026-03-01T00:00:00+08:00","timeMax":"2026-03-07T23:59:59+08:00"}'

# 搜尋事件（關鍵字）— 取代原 MCP search-events，使用 q 參數
gws calendar events list --params '{"calendarId":"primary","q":"跑步","timeMin":"2026-03-01T00:00:00+08:00","timeMax":"2026-03-07T23:59:59+08:00"}'

# 建立事件
gws calendar events insert --params '{"calendarId":"primary"}' --json '{"summary":"晨跑 10K","start":{"dateTime":"2026-03-18T06:00:00+08:00"},"end":{"dateTime":"2026-03-18T07:00:00+08:00"},"description":"Zone 2 有氧基礎"}'

# 更新事件
gws calendar events patch --params '{"calendarId":"primary","eventId":"<eventId>"}' --json '{"summary":"更新的標題"}'

# 刪除事件
gws calendar events delete --params '{"calendarId":"primary","eventId":"<eventId>"}'
```

## Gmail

```bash
# 列出郵件
gws gmail users messages list --params '{"userId":"me","maxResults":10}'

# 搜尋郵件（使用 Gmail 搜尋語法）
gws gmail users messages list --params '{"userId":"me","q":"from:example@gmail.com subject:報告"}'

# 讀取郵件
gws gmail users messages get --params '{"userId":"me","id":"<messageId>","format":"full"}'

# 發送郵件（需 base64url 編碼的 MIME）
RAW=$(printf 'From: me\r\nTo: recipient@example.com\r\nSubject: 測試\r\nContent-Type: text/plain; charset=utf-8\r\n\r\n郵件內容' | base64 | tr -d '\n' | tr '+/' '-_' | tr -d '=')
gws gmail users messages send --params '{"userId":"me"}' --json "{\"raw\":\"$RAW\"}"
```

## Drive

```bash
# 列出檔案
gws drive files list --params '{"pageSize":10}'

# 搜尋檔案（使用 Drive 查詢語法）
gws drive files list --params '{"q":"name contains '\''報告'\'' and mimeType='\''application/vnd.google-apps.spreadsheet'\''","pageSize":10}'

# 下載檔案
gws drive files get --params '{"fileId":"<fileId>","alt":"media"}' --output /tmp/downloaded-file.pdf

# 上傳檔案（content type 會從副檔名自動偵測，也可用 --upload-content-type 明確指定）
gws drive files create --json '{"name":"新文件.pdf","parents":["<folderId>"]}' --upload /path/to/file.pdf
```

## Sheets

```bash
# 讀取儲存格
gws sheets spreadsheets.values get --params '{"spreadsheetId":"<spreadsheetId>","range":"Sheet1!A1:D10"}'

# 寫入儲存格
gws sheets spreadsheets.values update --params '{"spreadsheetId":"<spreadsheetId>","range":"Sheet1!A1:B2","valueInputOption":"USER_ENTERED"}' --json '{"values":[["名稱","數值"],["測試",123]]}'

# 建立試算表
gws sheets spreadsheets create --json '{"properties":{"title":"新試算表"}}'
```

## Docs

```bash
# 讀取文件
gws docs documents get --params '{"documentId":"<documentId>"}'

# 建立文件
gws docs documents create --json '{"title":"新文件"}'

# 更新文件（使用 batchUpdate）
gws docs documents batchUpdate --params '{"documentId":"<documentId>"}' --json '{"requests":[{"insertText":{"location":{"index":1},"text":"插入的文字"}}]}'
```

## 分頁處理

```bash
# 自動分頁（輸出 NDJSON，每頁一行）
gws drive files list --params '{"pageSize":100}' --page-all

# 限制最大頁數
gws drive files list --params '{"pageSize":100}' --page-all --page-limit 5

# 頁間延遲（毫秒）
gws drive files list --params '{"pageSize":100}' --page-all --page-delay 200
```

## 輸出格式

```bash
--format json   # 預設，推薦用於程式化處理
--format table  # 適合人類閱讀
--format csv    # 適合資料匯出
```

## 注意事項

- 所有時間參數使用 RFC3339 格式，台灣時區為 `+08:00`
- 一律使用 `--format json` 以便程式化解析
- 不確定參數時先用 `gws schema` 查詢，不要猜測
- 初始範圍僅涵蓋 Calendar、Gmail、Drive、Sheets、Docs，其他服務（Slides、Tasks、People 等）未來按需擴充
