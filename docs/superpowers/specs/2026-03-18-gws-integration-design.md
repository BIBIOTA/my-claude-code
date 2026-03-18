# Google Workspace CLI (gws) 整合設計

**日期：** 2026-03-18
**狀態：** Approved

## 目標

將 yuki-toolkit plugin 中的 Google 相關 MCP server（Google Calendar、Gmail）替換為統一的 `gws` CLI 整合方案，並擴展支援 Drive、Sheets、Docs 服務。採用 Agent + Skill 組合架構。

## 現狀

- Google Calendar 透過 `@cocal/google-calendar-mcp` MCP server 存取
- Gmail 透過 `@gongrzhe/server-gmail-autoauth-mcp` MCP server 存取
- Running Coach agent 直接呼叫 MCP tools（如 `mcp__google-calender__list-events`，注意：原始 MCP tool 名稱中 "calender" 為既有拼寫錯誤）
- Drive、Sheets、Docs 目前無整合

## 設計方案：Agent + Skill 組合

### 架構

```
User / Other Agents (Running Coach)
            │
            ▼
google-workspace-zh-tw (Agent)
  - 接收任務、規劃步驟、執行 gws CLI
  - 需要指令參考時載入 Skill
            │
            ▼
gws-reference (Skill)
  - gws CLI 指令格式參考
  - 各服務常用操作範例
  - 認證設定說明
            │
            ▼
gws CLI → Google Workspace APIs
```

**分工原則：**
- **Skill** 負責靜態知識 — 指令格式、參數結構、使用範例
- **Agent** 負責動態行為 — 任務理解、步驟規劃、執行與回報

### 元件一：Skill (`gws-reference`)

**檔案位置：** `plugins/yuki-toolkit/skills/gws-reference/SKILL.md`

**內容結構：**

1. **認證設定**
   - `gws auth login` 流程
   - 環境變數：
     - `GOOGLE_WORKSPACE_CLI_CREDENTIALS_FILE` — OAuth 認證檔案路徑
     - `GOOGLE_WORKSPACE_CLI_CLIENT_ID` / `GOOGLE_WORKSPACE_CLI_CLIENT_SECRET` — OAuth client 資訊
     - `GOOGLE_WORKSPACE_CLI_TOKEN` — 預先取得的 access token（最高優先）
     - `GOOGLE_WORKSPACE_CLI_CONFIG_DIR` — 覆寫設定目錄（預設 `~/.config/gws`）
   - 認證過期時的處理方式

2. **通用指令格式**
   - 基本模式：`gws <service> <resource> <method> --params '<JSON>'`
   - Request body：`--json '<JSON>'`
   - 檔案上傳：`--upload <PATH> --upload-content-type <MIME>`
   - 檔案下載：`--output <PATH>`

3. **Schema 查詢**
   - `gws schema <service.resource.method>` 查看 API 參數結構
   - `gws schema <service.resource.method> --resolve-refs` 展開巢狀型別
   - 鼓勵在不確定參數時先查 schema，而非猜測

4. **各服務常用操作範例**

   **Calendar：**
   - 列出事件：`gws calendar events list --params '{"calendarId":"primary","timeMin":"...","timeMax":"..."}'`
   - 搜尋事件（關鍵字）：`gws calendar events list --params '{"calendarId":"primary","q":"跑步","timeMin":"...","timeMax":"..."}'`
     （注意：Google Calendar API 沒有獨立的 search method，使用 `events list` 的 `q` 參數進行關鍵字搜尋，取代原 MCP 的 `search-events`）
   - 建立事件：`gws calendar events insert --params '{"calendarId":"primary"}' --json '{"summary":"...","start":{...},"end":{...}}'`
   - 更新事件：`gws calendar events patch --params '{"calendarId":"primary","eventId":"..."}' --json '{...}'`
   - 刪除事件：`gws calendar events delete --params '{"calendarId":"primary","eventId":"..."}'`

   **Gmail：**
   - 列出郵件：`gws gmail users messages list --params '{"userId":"me","q":"..."}'`
   - 讀取郵件：`gws gmail users messages get --params '{"userId":"me","id":"...","format":"full"}'`
   - 搜尋郵件：使用 `q` 參數搭配 Gmail 搜尋語法
   - 發送郵件：`gws gmail users messages send --params '{"userId":"me"}' --json '{"raw":"<base64>"}'`
     構建 raw MIME 範例：
     ```bash
     # 建構 base64 編碼的 MIME 訊息
     RAW=$(printf 'From: me\r\nTo: recipient@example.com\r\nSubject: Test\r\nContent-Type: text/plain; charset=utf-8\r\n\r\nHello' | base64 | tr -d '\n' | tr '+/' '-_' | tr -d '=')
     gws gmail users messages send --params '{"userId":"me"}' --json "{\"raw\":\"$RAW\"}"
     ```

   **Drive：**
   - 列出檔案：`gws drive files list --params '{"q":"...","pageSize":10}'`
   - 搜尋檔案：使用 Drive 查詢語法（如 `name contains '...'`、`mimeType='...'`）
   - 下載檔案：`gws drive files get --params '{"fileId":"...","alt":"media"}' --output <PATH>`
   - 上傳檔案：`gws drive files create --json '{"name":"...","parents":["..."]}' --upload <PATH>`

   **Sheets：**
   - 讀取儲存格：`gws sheets spreadsheets.values get --params '{"spreadsheetId":"...","range":"Sheet1!A1:D10"}'`
   - 寫入儲存格：`gws sheets spreadsheets.values update --params '{"spreadsheetId":"...","range":"...","valueInputOption":"USER_ENTERED"}' --json '{"values":[...]}'`
   - 建立試算表：`gws sheets spreadsheets create --json '{"properties":{"title":"..."}}'`

   **Docs：**
   - 讀取文件：`gws docs documents get --params '{"documentId":"..."}'`
   - 建立文件：`gws docs documents create --json '{"title":"..."}'`
   - 更新文件：`gws docs documents batchUpdate --params '{"documentId":"..."}' --json '{"requests":[...]}'`

5. **分頁處理**
   - `--page-all`：自動分頁，輸出 NDJSON（每頁一行 JSON）
   - `--page-limit <N>`：限制最大頁數（預設 10）
   - `--page-delay <MS>`：頁間延遲（預設 100ms）

6. **輸出格式**
   - `--format json`（預設，推薦用於程式化處理）
   - `--format table`（適合人類閱讀）
   - `--format csv`（適合資料匯出）

**初始範圍：** 僅涵蓋 Calendar、Gmail、Drive、Sheets、Docs 五個服務。gws CLI 支援的其他服務（Slides、Tasks、People、Chat、Classroom、Forms、Keep、Meet 等）暫不納入，未來按需擴充。

**觸發條件（description）：**
> Use when you need to operate Google Workspace services (Calendar, Gmail, Drive, Sheets, Docs) via the gws CLI. Provides command format reference, authentication setup, and usage examples for all supported services.

### 元件二：Agent (`google-workspace-zh-tw`)

**檔案位置：** `plugins/yuki-toolkit/agents/google-workspace-zh-tw.md`

**Agent frontmatter：**
- `name`: google-workspace-zh-tw
- `description`: 當使用者需要操作 Google Workspace 服務（行事曆、郵件、雲端硬碟、試算表、文件）時使用。透過 gws CLI 執行所有 Google Workspace 操作。
- `model`: sonnet

**行為規範：**

1. **繁體中文回應** — 所有互動使用繁體中文
2. **操作前確認** — 寫入、刪除、發送等不可逆操作必須先向使用者確認
3. **先查 schema 再執行** — 不確定參數時，先跑 `gws schema <method>` 確認
4. **載入 Skill** — 需要指令參考時，載入 `gws-reference` skill 取得範例
5. **結果摘要** — 執行後以結構化方式回報結果，不直接傾倒大量 JSON
6. **錯誤處理** — 認證過期時引導使用者執行 `gws auth login`
7. **JSON 輸出** — 一律使用 `--format json` 以便解析處理

**不做的事：**
- 不儲存或快取 Google 資料到本地
- 不自行管理 OAuth token（交給 `gws auth` 處理）
- 不直接呼叫 Google API（一律透過 `gws` CLI）

### 遷移變更

**移除：**
1. `mcp-config.md` 中的 `@cocal/google-calendar-mcp` 設定
2. `mcp-config.md` 中的 `@gongrzhe/server-gmail-autoauth-mcp` 設定

**修改：**
1. `running-coach-zh-tw.md` — Google Calendar 操作從 MCP tool 呼叫改為 dispatch `google-workspace-zh-tw` agent

   **修改前（現行 MCP 呼叫）：**
   ```
   1. mcp__google-calender__list-events: 查詢該日期範圍的所有行事曆事件
   2. mcp__google-calender__search-events: 如有需要，使用關鍵字搜尋特定跑步訓練事件
   ```

   **修改後（Agent dispatch）：**
   ```
   1. 使用 google-workspace-zh-tw agent 查詢該日期範圍的所有行事曆事件
   2. 如有需要，使用 google-workspace-zh-tw agent 以關鍵字搜尋特定跑步訓練事件
   ```

   Running Coach agent 內的所有 `mcp__google-calender__*` 引用都改為描述性的 agent dispatch 指示。Claude Code 會根據 agent description 自動路由到正確的 agent。雙向同步（Calendar + Notion）的操作流程同樣改為透過 agent。

2. `mcp-config.md` — 新增 `gws` CLI 認證設定說明，取代移除的兩個 MCP server

3. `plugin.json` — 更新內容：
   - `agents` 陣列新增 `"./agents/google-workspace-zh-tw.md"`
   - 新增 `skills` 陣列：`["./skills/gws-reference/SKILL.md"]`
   - `description` 更新為 `"個人助理工具包：專業跑步教練 agent + Google Workspace 整合 + MCP server 配置模板"`
   - `keywords` 新增 `"google-workspace"`, `"gws"`, `"drive"`, `"sheets"`, `"docs"`, `"gmail"`

**新增：**
1. `plugins/yuki-toolkit/skills/gws-reference/SKILL.md` — gws 指令參考 Skill
2. `plugins/yuki-toolkit/agents/google-workspace-zh-tw.md` — Google Workspace Agent

**不動：**
- Garmin MCP、Strava MCP、Notion MCP、Chrome DevTools MCP — 與 Google 無關，保持不變
- Running Coach agent 中非 Google 相關的邏輯（Strava、Garmin、Notion 整合）保持不變

## 風險與考量

1. **gws auth 狀態**：需確認 `gws auth login` 已完成且 token 有效，否則所有操作都會失敗
2. **Running Coach 相依性**：修改 Running Coach 的 Google Calendar 呼叫方式是最敏感的變更，需確保「Google Calendar 絕對優先原則」在新架構下仍能正確執行
3. **Agent dispatch 延遲**：從直接 MCP tool 呼叫改為 dispatch agent，會增加一層間接性和少量延遲
4. **Gmail raw 格式**：發送郵件需要 base64 編碼的 raw MIME，Skill 中已提供建構範例

## 驗收標準

1. **認證驗證**：`gws calendar events list --params '{"calendarId":"primary","timeMin":"...","timeMax":"..."}'` 成功返回事件
2. **各服務煙霧測試**：
   - Calendar：列出近 7 天事件
   - Gmail：搜尋最近 5 封郵件
   - Drive：列出根目錄檔案
   - Sheets：讀取指定試算表的儲存格
   - Docs：讀取指定文件內容
3. **Running Coach 端對端測試**：執行一次「查看特定日期跑步活動」完整流程，驗證 Google Calendar 絕對優先原則仍正確運作
4. **Agent dispatch 驗證**：從主對話 dispatch google-workspace-zh-tw agent 完成一次 Calendar 查詢

## 回滾計畫

若遷移後發現問題（如 gws auth 不穩定、agent dispatch 延遲不可接受）：
1. `mcp-config.md` 中保留原 MCP server 設定的 git 歷史，可隨時透過 `git revert` 恢復
2. `running-coach-zh-tw.md` 同理，git 歷史保留完整的 MCP tool 呼叫版本
3. 新增的 Agent 和 Skill 檔案不影響原有功能，可安全共存
