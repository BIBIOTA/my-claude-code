# MCP Server 配置指南

安裝 `yuki-toolkit` plugin 後，需要手動設定以下 MCP server。每個指令中的 `<placeholder>` 需替換為你自己的認證資訊。

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

## Strava

```bash
claude mcp add strava \
  --env STRAVA_CLIENT_ID=<your_client_id> \
  --env STRAVA_CLIENT_SECRET=<your_client_secret> \
  --env STRAVA_ACCESS_TOKEN=<your_access_token> \
  --env STRAVA_REFRESH_TOKEN=<your_refresh_token> \
  -- node <path-to-strava-mcp>/dist/server.js
```

**前置需求**

- Strava 帳號
- 在 https://www.strava.com/settings/api 建立 API 應用程式
- 下載並建置 `strava-mcp`：
  ```bash
  git clone https://github.com/r-huijts/strava-mcp.git
  cd strava-mcp
  npm install
  npm run build
  npx tsx scripts/setup-auth.ts  # 執行驗證以取得 tokens
  ```
- 記下 `strava-mcp` 的本機路徑，在上方指令中替換 `<path-to-strava-mcp>`

## Notion

```bash
claude mcp add notion \
  --env NOTION_TOKEN=<your_internal_integration_token> \
  -- npx -y @notionhq/notion-mcp-server
```

**前置需求**

- Notion 帳號
- 在 My Integrations (https://www.notion.so/my-integrations) 建立 Internal Integration
- 在需要存取的頁面中連接你的 Integration

## Garmin

```bash
claude mcp add garmin -- uvx \
  --python 3.12 \
  --from 'git+https://github.com/Taxuspt/garmin_mcp' \
  garmin-mcp
```

**前置需求**

- Python 3.12 + UV (https://github.com/astral-sh/uv) 套件管理器
- Garmin Connect 帳號

首次使用前，執行以下指令完成認證：

```bash
uvx --python 3.12 --from 'git+https://github.com/Taxuspt/garmin_mcp' garmin-mcp-auth
```

## Chrome DevTools

```bash
claude mcp add chrome-devtools --scope user -- npx chrome-devtools-mcp@latest
```

> `--scope user` 讓此 server 在所有專案中都可使用

**前置需求**

- Chrome 瀏覽器
- 無需額外認證
