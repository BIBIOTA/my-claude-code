# Claude Code 個人小秘書

這是一個基於 Claude Code 的個人助理專案，整合了 Google Calendar 和 Strava MCP 伺服器，提供日曆管理和運動數據追蹤功能。

## 功能特色

- **Google Calendar 整合**：管理行程、建立事件、查詢空閒時間
- **Strava 整合**：追蹤運動數據、分析活動記錄
- **智能助理**：透過 Claude Code 提供自然語言交互

## 前置需求

### Google Calendar MCP
- Google Cloud 專案
- 啟用 Calendar API
- OAuth 2.0 認證檔案（Desktop app 類型）

### Strava MCP
- Node.js (建議 v18 或更新版本)
- npm
- Strava 帳號

## 安裝套件

### 1. Google Calendar MCP 伺服器

#### 方法一：使用 NPX（推薦）
無需手動安裝，直接在 Claude Code 設定中使用 `@cocal/google-calendar-mcp` 套件

#### 方法二：本地安裝
```bash
git clone https://github.com/nspady/google-calendar-mcp.git
cd google-calendar-mcp
npm install
npm run build
```

### 2. Strava MCP 伺服器

```bash
git clone https://github.com/r-huijts/strava-mcp.git
cd strava-mcp
npm install
npm run build
```

#### Strava API 設定
1. 在 https://www.strava.com/settings/api 建立 Strava API 應用程式
2. 設定 "Authorization Callback Domain" 為 `localhost`
3. 記錄 Client ID 和 Client Secret
4. 執行驗證設定：
```bash
npx tsx scripts/setup-auth.ts
```

## Claude Code MCP 伺服器設定

### Google Calendar MCP

#### NPX 方式（推薦）
```bash
claude mcp add google-calendar --env GOOGLE_OAUTH_CREDENTIALS=./credentials/gcp-oauth.keys.json -- npx @cocal/google-calendar-mcp
```

#### 本地安裝方式
```bash
claude mcp add google-calendar --env GOOGLE_OAUTH_CREDENTIALS=./credentials/gcp-oauth.keys.json -- node /path/to/google-calendar-mcp/dist/index.js
```

### Strava MCP

```bash
claude mcp add strava --env STRAVA_CLIENT_ID=your_client_id --env STRAVA_CLIENT_SECRET=your_client_secret --env STRAVA_ACCESS_TOKEN=your_access_token --env STRAVA_REFRESH_TOKEN=your_refresh_token -- node /path/to/strava-mcp/dist/server.js
```

詳細的 MCP 設定說明請參考：[Claude Code MCP 文件](https://docs.anthropic.com/en/docs/claude-code/mcp)

## 必要檔案設定

### 1. Google Cloud Platform 認證檔案

建立 `credentials/` 資料夾並放入 Google OAuth 金鑰檔案：

```bash
mkdir -p credentials
# 將你的 gcp-oauth.keys.json 檔案放入 credentials/ 資料夾
```

### 2. Strava 認證設定

執行 Strava 認證設定後，會自動產生所需的 access token 和 refresh token。

## 注意事項

- `credentials/gcp-oauth.keys.json` 檔案包含 Google API 認證資訊，已加入 `.gitignore`
- Google Calendar 在測試模式下，token 會在 7 天後過期，需要重新認證
- 請確保妥善保管這些認證檔案，不要公開分享

## 首次使用

1. 啟動 Claude Code
2. Google Calendar 會開啟瀏覽器進行 OAuth 驗證流程
3. Strava 驗證已在設定階段完成
4. 完成驗證後即可開始使用

## 使用方式

設定完成後，即可在 Claude Code 中使用相關功能：

- 詢問行程安排
- 建立、修改、刪除日曆事件
- 查詢空閒時間
- 查詢運動數據
- 分析 Strava 活動記錄
- 匯出路線檔案

開始享受你的個人 AI 秘書服務吧！