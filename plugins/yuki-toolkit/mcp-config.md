# MCP Server 配置指南

安裝 `yuki-toolkit` plugin 後，需要手動設定以下 MCP server。每個指令中的 `<placeholder>` 需替換為你自己的認證資訊。

## Google Calendar

```bash
claude mcp add google-calendar \
  --env GOOGLE_OAUTH_CREDENTIALS=<path-to-gcp-oauth.keys.json> \
  -- npx @cocal/google-calendar-mcp
```

**前置需求**

- Google Cloud 專案 (啟用 Calendar API)
- OAuth 2.0 認證檔案 (Desktop app 類型)

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

## Gmail

```bash
claude mcp add gmail -- npx @gongrzhe/server-gmail-autoauth-mcp
```

**前置需求**

- Google Cloud 專案 (啟用 Gmail API)
- OAuth 認證檔案放置於 `~/.gmail-mcp/gcp-oauth.keys.json`

首次使用前，執行以下指令完成認證：

```bash
npx @gongrzhe/server-gmail-autoauth-mcp auth
```

## Chrome DevTools

```bash
claude mcp add chrome-devtools --scope user -- npx chrome-devtools-mcp@latest
```

> `--scope user` 讓此 server 在所有專案中都可使用

**前置需求**

- Chrome 瀏覽器
- 無需額外認證
