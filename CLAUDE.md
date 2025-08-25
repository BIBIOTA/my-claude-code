# Claude Code 專案配置文件

## 專案說明
這是一個整合 Google Calendar 和 Strava MCP 伺服器的個人助理專案，透過 Claude Code 提供智能化的日曆管理和運動數據分析功能。

## 專業跑步教練代理使用方式

### 代理檔案位置
`.claude/agents/running-coach-zh-tw.md`

### 啟用方式
當需要專業跑步指導時，直接提出相關需求即可自動啟用繁體中文跑步教練代理：

#### 使用範例：
```
我想要改善我的馬拉松成績，這是我最近三個月的Strava數據
我是跑步新手，想要開始規律的跑步訓練，請幫我制定計畫
請分析我今天的間歇跑訓練效果
```

#### 主要應用場景：
- Strava 數據分析和訓練建議
- 個人化訓練計畫制定
- 跑步技術指導和改善建議
- 訓練目標設定和追蹤

### 重要提醒
- 所有具體訓練計畫和記錄會自動更新至 `/storage/emulated/0/running/` 資料夾
- 教練會自動執行 Strava 數據、Google Calendar 和訓練課表的一致性檢核
- 詳細的專業指導原則和心率區間設定請參考 agents 文件

## MCP 伺服器配置

### Google Calendar MCP
```bash
claude mcp add google-calendar --env GOOGLE_OAUTH_CREDENTIALS=./credentials/gcp-oauth.keys.json -- npx @cocal/google-calendar-mcp
```

### Strava MCP  
```bash
claude mcp add strava --env STRAVA_CLIENT_ID=your_client_id --env STRAVA_CLIENT_SECRET=your_client_secret --env STRAVA_ACCESS_TOKEN=your_access_token --env STRAVA_REFRESH_TOKEN=your_refresh_token -- node /path/to/strava-mcp/dist/server.js
```

## 主要功能
- 日曆事件管理（建立、修改、刪除、查詢）
- 運動數據追蹤和分析
- 專業跑步教練指導（繁體中文）
- 路線檔案匯出
- 智能排程建議

## 檔案結構
```
my-claude-code/
├── .claude/
│   └── agents/
│       └── running-coach-zh-tw.md    # 專業跑步教練代理
├── credentials/
│   └── gcp-oauth.keys.json          # Google API 認證檔案
├── running/
│   ├── running-records.md           # 訓練記錄檔案
│   └── running-schedule.md          # 訓練課表檔案
├── CLAUDE.md                        # 本配置檔案
└── README.md                        # 專案說明文件
```

## 重要提醒
- 認證檔案包含敏感資訊，已加入 `.gitignore`
- Google Calendar token 在測試模式下 7 天後過期，需重新認證
- 訓練數據分析結果會自動更新至 running 資料夾