# Google Workspace CLI (gws) Integration Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace Google Calendar and Gmail MCP servers with a unified gws CLI integration (Agent + Skill), and expand to support Drive, Sheets, Docs.

**Architecture:** A `gws-reference` Skill provides static command reference for the gws CLI. A `google-workspace-zh-tw` Agent handles dynamic Google Workspace operations by calling `gws` via Bash. The Running Coach agent delegates all Google Calendar operations to this new agent instead of calling MCP tools directly.

**Tech Stack:** gws CLI (`@googleworkspace/cli@0.16.0`), Claude Code plugin system (agents, skills)

**Spec:** `docs/superpowers/specs/2026-03-18-gws-integration-design.md`

---

## File Structure

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `plugins/yuki-toolkit/skills/gws-reference/SKILL.md` | Static gws CLI command reference, auth setup, usage examples |
| Create | `plugins/yuki-toolkit/agents/google-workspace-zh-tw.md` | Dynamic Google Workspace agent, executes gws commands |
| Modify | `plugins/yuki-toolkit/agents/running-coach-zh-tw.md` | Replace MCP tool references with agent dispatch |
| Modify | `plugins/yuki-toolkit/mcp-config.md` | Remove Google Calendar/Gmail MCP, add gws CLI setup |
| Modify | `plugins/yuki-toolkit/.claude-plugin/plugin.json` | Register new agent and skill |

---

### Task 1: Create gws-reference Skill

**Files:**
- Create: `plugins/yuki-toolkit/skills/gws-reference/SKILL.md`

- [ ] **Step 1: Create the skills directory**

```bash
mkdir -p plugins/yuki-toolkit/skills/gws-reference
```

- [ ] **Step 2: Write the Skill file**

Create `plugins/yuki-toolkit/skills/gws-reference/SKILL.md` with the following content:

```markdown
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
```

- [ ] **Step 3: Verify the file was created correctly**

Run: `head -5 plugins/yuki-toolkit/skills/gws-reference/SKILL.md`
Expected: Shows the frontmatter with `name: gws-reference`

- [ ] **Step 4: Commit**

```bash
git add plugins/yuki-toolkit/skills/gws-reference/SKILL.md
git commit -m "feat: add gws-reference skill with CLI command reference"
```

---

### Task 2: Create google-workspace-zh-tw Agent

**Files:**
- Create: `plugins/yuki-toolkit/agents/google-workspace-zh-tw.md`

- [ ] **Step 1: Write the Agent file**

Create `plugins/yuki-toolkit/agents/google-workspace-zh-tw.md` with the following content:

```markdown
---
name: google-workspace-zh-tw
description: Use this agent when the user needs to operate Google Workspace services (Calendar, Gmail, Drive, Sheets, Docs). Executes all Google Workspace operations via the gws CLI. Examples: <example>Context: User wants to check their calendar for this week. user: '幫我看一下這週的行事曆' assistant: '讓我使用 Google Workspace agent 來查詢你的行事曆' <commentary>Since the user is asking to check their calendar, use the google-workspace-zh-tw agent to query events via gws CLI.</commentary></example> <example>Context: User wants to search for emails. user: '搜尋上週來自 Alice 的郵件' assistant: '我來使用 Google Workspace agent 搜尋你的 Gmail' <commentary>Since the user wants to search Gmail, use the google-workspace-zh-tw agent to execute the search via gws CLI.</commentary></example> <example>Context: User wants to upload a file to Drive. user: '把這個檔案上傳到 Google Drive' assistant: '讓我使用 Google Workspace agent 來上傳檔案' <commentary>Since the user wants to upload to Drive, use the google-workspace-zh-tw agent.</commentary></example>
model: sonnet
---

你是 Google Workspace 操作專員，透過 `gws` CLI 執行所有 Google Workspace 操作。使用繁體中文回應。

## 可用服務

- **Calendar** — 行事曆事件查詢、建立、更新、刪除
- **Gmail** — 郵件搜尋、讀取、發送
- **Drive** — 檔案列表、搜尋、上傳、下載
- **Sheets** — 試算表讀寫
- **Docs** — 文件讀寫

## 操作原則

1. **操作前確認** — 寫入、刪除、發送等不可逆操作，必須先向使用者確認內容後再執行
2. **先查 schema 再執行** — 不確定 API 參數時，先執行 `gws schema <service.resource.method>` 確認參數結構
3. **載入 Skill** — 需要指令格式參考時，載入 `gws-reference` skill 取得各服務的使用範例
4. **結果摘要** — 執行完成後以結構化方式摘要回報結果，不直接傾倒大量 JSON
5. **JSON 輸出** — 所有 gws 指令一律加上 `--format json` 以便解析
6. **時間格式** — 所有時間使用 RFC3339 格式，台灣時區為 `+08:00`

## 錯誤處理

- **認證過期（401 錯誤）**：告知使用者需執行 `gws auth login` 重新認證
- **權限不足（403 錯誤）**：告知使用者需檢查 API scope 或重新授權
- **找不到資源（404 錯誤）**：確認 ID 是否正確，並回報使用者

## 不做的事

- 不儲存或快取 Google 資料到本地檔案
- 不自行管理 OAuth token（交給 `gws auth` 處理）
- 不直接呼叫 Google API（一律透過 `gws` CLI）
```

- [ ] **Step 2: Verify the file was created correctly**

Run: `head -5 plugins/yuki-toolkit/agents/google-workspace-zh-tw.md`
Expected: Shows the frontmatter with `name: google-workspace-zh-tw`

- [ ] **Step 3: Commit**

```bash
git add plugins/yuki-toolkit/agents/google-workspace-zh-tw.md
git commit -m "feat: add google-workspace-zh-tw agent for gws CLI operations"
```

---

### Task 3: Update plugin.json

**Files:**
- Modify: `plugins/yuki-toolkit/.claude-plugin/plugin.json`

- [ ] **Step 1: Update plugin.json**

Edit `plugins/yuki-toolkit/.claude-plugin/plugin.json` to replace its entire contents with:

```json
{
  "name": "yuki-toolkit",
  "description": "個人助理工具包：專業跑步教練 agent + Google Workspace 整合 + MCP server 配置模板",
  "version": "1.1.0",
  "author": {
    "name": "BIBIOTA"
  },
  "keywords": ["running", "strava", "garmin", "calendar", "notion", "google-workspace", "gws", "drive", "sheets", "docs", "gmail"],
  "agents": ["./agents/running-coach-zh-tw.md", "./agents/google-workspace-zh-tw.md"],
  "skills": ["./skills/gws-reference/SKILL.md"]
}
```

Key changes:
- `description`: added "Google Workspace 整合"
- `version`: bumped to `1.1.0`
- `keywords`: added `google-workspace`, `gws`, `drive`, `sheets`, `docs`, `gmail`
- `agents`: added `./agents/google-workspace-zh-tw.md`
- `skills`: new array with `./skills/gws-reference/SKILL.md`

- [ ] **Step 2: Verify JSON is valid**

Run: `python3 -c "import json; json.load(open('plugins/yuki-toolkit/.claude-plugin/plugin.json')); print('Valid JSON')"`
Expected: `Valid JSON`

- [ ] **Step 3: Commit**

```bash
git add plugins/yuki-toolkit/.claude-plugin/plugin.json
git commit -m "feat: register google-workspace agent and gws-reference skill in plugin.json"
```

---

### Task 4: Update Running Coach agent — replace MCP references

**Files:**
- Modify: `plugins/yuki-toolkit/agents/running-coach-zh-tw.md:10,115,152,188,227-232`

This is the most sensitive change. All `mcp__google-calender__*` references and "Google Calendar API" tool-specific mentions must be changed to use `google-workspace-zh-tw` agent dispatch, while preserving the exact same workflow logic.

- [ ] **Step 1: Replace line 10 — core responsibility**

Change:
```
- **強制性行事曆優先檢核**: 查看學生特定日期跑步活動記錄時，務必首先使用 Google Calendar API 查詢該日期的原訂訓練計畫，確保活動是否遵照原先訓練規劃進行，再接著進行分析
```
To:
```
- **強制性行事曆優先檢核**: 查看學生特定日期跑步活動記錄時，務必首先使用 google-workspace-zh-tw agent 查詢該日期的 Google Calendar 原訂訓練計畫，確保活動是否遵照原先訓練規劃進行，再接著進行分析
```

- [ ] **Step 2: Replace line 115 — mandatory first step**

Change:
```
   - **第一步**: 必須使用 Google Calendar API 查詢該特定日期的跑步訓練事件
```
To:
```
   - **第一步**: 必須使用 google-workspace-zh-tw agent 查詢該特定日期的 Google Calendar 跑步訓練事件
```

- [ ] **Step 3: Replace line 152 — mandatory check**

Change:
```
- **強制檢核**: 每次跑步活動分析都必須先使用 Google Calendar API 查詢該日原訂計畫
```
To:
```
- **強制檢核**: 每次跑步活動分析都必須先使用 google-workspace-zh-tw agent 查詢該日 Google Calendar 原訂計畫
```

- [ ] **Step 4: Replace line 188 — data source annotation**

Change:
```
4. **數據來源標注**：明確記錄數據來源 (Strava API、Google Calendar API、詳細數據等)
```
To:
```
4. **數據來源標注**：明確記錄數據來源 (Strava API、Google Calendar (via gws CLI)、詳細數據等)
```

- [ ] **Step 5: Replace lines 227-232 — the MCP tool section**

Change:
```
**📅 Google Calendar API 使用要求**：
每次分析跑步活動時，必須按照以下順序執行API調用：
1. **mcp__google-calender__list-events**: 查詢該日期範圍的所有行事曆事件
2. **mcp__google-calender__search-events**: 如有需要，使用關鍵字搜尋特定跑步訓練事件
3. **事件內容解析**: 提取原訂訓練的距離、配速、心率目標、訓練類型等參數
4. **無事件處理**: 如該日無跑步相關事件，必須明確說明並採用標準分析方法
```
To:
```
**📅 Google Calendar 查詢要求（透過 google-workspace-zh-tw agent）**：
每次分析跑步活動時，必須按照以下順序執行查詢：
1. **使用 google-workspace-zh-tw agent 列出事件**: 查詢該日期範圍的所有行事曆事件
2. **使用 google-workspace-zh-tw agent 搜尋事件**: 如有需要，以關鍵字搜尋特定跑步訓練事件
3. **事件內容解析**: 提取原訂訓練的距離、配速、心率目標、訓練類型等參數
4. **無事件處理**: 如該日無跑步相關事件，必須明確說明並採用標準分析方法
```

- [ ] **Step 6: Verify no remaining MCP references**

Run: `grep -n "mcp__google" plugins/yuki-toolkit/agents/running-coach-zh-tw.md`
Expected: No output (no matches found)

- [ ] **Step 7: Verify no remaining "Google Calendar API" tool-specific references**

Run: `grep -n "Google Calendar API" plugins/yuki-toolkit/agents/running-coach-zh-tw.md`
Expected: No output (all occurrences replaced with agent dispatch or "via gws CLI")

- [ ] **Step 8: Verify the workflow logic is preserved**

Run: `grep -n "google-workspace-zh-tw" plugins/yuki-toolkit/agents/running-coach-zh-tw.md`
Expected: Lines 10, 115, 152, 229, 230 should show the new agent dispatch references

- [ ] **Step 9: Commit**

```bash
git add plugins/yuki-toolkit/agents/running-coach-zh-tw.md
git commit -m "refactor: replace Google Calendar MCP tools with google-workspace-zh-tw agent dispatch"
```

---

### Task 5: Update mcp-config.md — remove Google MCP servers, add gws setup

**Files:**
- Modify: `plugins/yuki-toolkit/mcp-config.md`

**Important:** Execute steps 1-3 in order. Remove sections first, then insert the new one.

- [ ] **Step 1: Remove the Google Calendar section (lines 5-16)**

Remove the entire `## Google Calendar` section:
```markdown
## Google Calendar

\`\`\`bash
claude mcp add google-calendar \
  --env GOOGLE_OAUTH_CREDENTIALS=<path-to-gcp-oauth.keys.json> \
  -- npx @cocal/google-calendar-mcp
\`\`\`

**前置需求**

- Google Cloud 專案 (啟用 Calendar API)
- OAuth 2.0 認證檔案 (Desktop app 類型)
```

- [ ] **Step 2: Remove the Gmail section (lines 77-92)**

Remove the entire `## Gmail` section:
```markdown
## Gmail

\`\`\`bash
claude mcp add gmail -- npx @gongrzhe/server-gmail-autoauth-mcp
\`\`\`

**前置需求**

- Google Cloud 專案 (啟用 Gmail API)
- OAuth 認證檔案放置於 `~/.gmail-mcp/gcp-oauth.keys.json`

首次使用前，執行以下指令完成認證：

\`\`\`bash
npx @gongrzhe/server-gmail-autoauth-mcp auth
\`\`\`
```

- [ ] **Step 3: Add gws CLI section at the top (after the intro paragraph)**

Insert after line 3 (after the intro paragraph), before the first `##` section:

```markdown
## Google Workspace (gws CLI)

Google Calendar、Gmail、Drive、Sheets、Docs 等 Google Workspace 服務統一透過 `gws` CLI 操作，不需要個別的 MCP server。

**安裝**

```bash
npm install -g @googleworkspace/cli
```

**認證**

```bash
gws auth login
```

需要 Google Cloud 專案的 OAuth 2.0 認證。設定方式：
1. 建立 Google Cloud 專案，啟用所需 API（Calendar、Gmail、Drive、Sheets、Docs）
2. 建立 OAuth 2.0 Client ID（Desktop app 類型）
3. 設定環境變數：
   ```bash
   export GOOGLE_WORKSPACE_CLI_CREDENTIALS_FILE=<path-to-oauth-credentials.json>
   ```
4. 執行 `gws auth login` 完成瀏覽器授權流程

**使用方式**

透過 `google-workspace-zh-tw` agent 或直接在終端使用 `gws` 指令。指令格式參考請載入 `gws-reference` skill。
```

- [ ] **Step 4: Verify no Google Calendar MCP or Gmail MCP references remain**

Run: `grep -n "@cocal/google-calendar-mcp\|@gongrzhe/server-gmail-autoauth-mcp" plugins/yuki-toolkit/mcp-config.md`
Expected: No output (no matches found)

- [ ] **Step 5: Verify gws section was added**

Run: `grep -n "gws" plugins/yuki-toolkit/mcp-config.md`
Expected: Multiple matches showing the new gws CLI section

- [ ] **Step 6: Commit**

```bash
git add plugins/yuki-toolkit/mcp-config.md
git commit -m "refactor: replace Google Calendar/Gmail MCP servers with gws CLI setup"
```

---

### Task 6: Smoke test — verify gws CLI auth and basic operations

**Files:** None (validation only)

- [ ] **Step 1: Verify gws is installed and accessible**

Run: `gws --help | head -5`
Expected: Shows `gws — Google Workspace CLI` header

- [ ] **Step 2: Test Calendar — list events for the next 7 days**

Run: `gws calendar events list --params '{"calendarId":"primary","timeMin":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","timeMax":"'$(date -u -v+7d +%Y-%m-%dT%H:%M:%SZ)'","maxResults":5}' --format json`
Expected: JSON response with calendar events (or empty `items` array). If 401 error, run `gws auth login` first.

- [ ] **Step 3: Test Gmail — list recent messages**

Run: `gws gmail users messages list --params '{"userId":"me","maxResults":5}' --format json`
Expected: JSON response with message IDs

- [ ] **Step 4: Test Drive — list root files**

Run: `gws drive files list --params '{"pageSize":5}' --format json`
Expected: JSON response with file list

- [ ] **Step 5: Test Sheets — create and read a test spreadsheet**

Run:
```bash
# Create a test spreadsheet
SHEET_ID=$(gws sheets spreadsheets create --json '{"properties":{"title":"gws-smoke-test"}}' --format json | python3 -c "import sys,json; print(json.load(sys.stdin)['spreadsheetId'])")
echo "Created spreadsheet: $SHEET_ID"
# Read it back
gws sheets spreadsheets.values get --params "{\"spreadsheetId\":\"$SHEET_ID\",\"range\":\"Sheet1!A1:A1\"}" --format json
```
Expected: Spreadsheet created and read successfully (empty values array is fine)

- [ ] **Step 6: Test Docs — create and read a test document**

Run:
```bash
# Create a test document
DOC_ID=$(gws docs documents create --json '{"title":"gws-smoke-test"}' --format json | python3 -c "import sys,json; print(json.load(sys.stdin)['documentId'])")
echo "Created document: $DOC_ID"
# Read it back
gws docs documents get --params "{\"documentId\":\"$DOC_ID\"}" --format json | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'Title: {d[\"title\"]}')"
```
Expected: Document created and title read back as "gws-smoke-test"

- [ ] **Step 7: Test schema query**

Run: `gws schema calendar.events.list | head -20`
Expected: Shows parameter definitions for the Calendar events list API

- [ ] **Step 8: Report results**

If all tests pass, the integration is ready. If any test fails due to auth, guide user through `gws auth login`. If tests fail due to API not enabled, guide user to enable the required APIs in Google Cloud Console.

---

### Task 7: End-to-end validation — agent dispatch and Running Coach workflow

**Files:** None (validation only)

- [ ] **Step 1: Test agent dispatch from main conversation**

From the main Claude Code conversation, ask: "幫我查一下今天的行事曆有什麼事件"
Expected: Claude should route this to the `google-workspace-zh-tw` agent, which executes `gws calendar events list` and returns results in Traditional Chinese.

- [ ] **Step 2: Test Running Coach Google Calendar integration**

From the main Claude Code conversation, ask the Running Coach to analyze a specific date's running activity (e.g., "幫我看一下昨天的跑步活動記錄").
Expected: The Running Coach should first dispatch to `google-workspace-zh-tw` agent to query Google Calendar for that date's training plan, then proceed with Strava data analysis — maintaining the "Google Calendar 絕對優先原則".

- [ ] **Step 3: Verify the complete workflow**

Confirm the Running Coach followed the correct order:
1. Google Calendar query (via google-workspace-zh-tw agent) — first
2. Strava data retrieval — second
3. Cross-reference analysis — third

If the order is incorrect or the agent dispatch fails, check:
- `plugin.json` has the new agent registered
- The Running Coach agent file has the updated dispatch instructions
- `gws auth login` has been completed
