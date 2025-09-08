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
- 所有具體訓練計畫和記錄會自動更新至 Notion 跑步訓練相關檔案
- 教練會自動執行 Strava 數據、Google Calendar 和 Notion 訓練課表的一致性檢核
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

### Notion MCP
```bash
claude mcp add notion --env NOTION_TOKEN=your_internal_integration_token -- npx -y @notionhq/notion-mcp-server
```

## 主要功能
- 日曆事件管理（建立、修改、刪除、查詢）
- 運動數據追蹤和分析
- 專業跑步教練指導（繁體中文）
- 跑步訓練記錄管理（Notion）
- 馬拉松訓練計畫管理（Notion）
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
├── CLAUDE.md                        # 本配置檔案
└── README.md                        # 專案說明文件
```

## 🏃‍♂️ Notion 檔案結構
```
Notion Workspace
├── 🏃‍♂️ 跑步訓練記錄檔案
│   ├── 2025/08/19 (Tue.)           # 各日訓練記錄子頁面
│   ├── 2025/08/20 (Wed.)
│   ├── ...                         # 按日期組織的訓練記錄
│   └── [未來訓練記錄持續新增]
└── 🏃‍♂️ 馬拉松訓練時程表          # 訓練計畫和課表管理
```

## ⚡ 日期驗證與確認協議

### 核心原則
所有涉及日期操作的任務，**必須**先使用 Linux `date` 指令確認日期和星期，再進行後續作業。

### 強制驗證流程
1. **當前日期確認**：每次執行日期相關操作前，必須使用 `date` 指令確認當前日期和星期
2. **目標日期計算**：使用 `date -d` 指令精確計算目標日期，避免手動計算錯誤  
3. **星期交叉驗證**：驗證計算出的日期星期是否符合預期（例如：週二恢復跑、週四間歇、週六長跑）
4. **多重確認機制**：使用不同的 Linux date 格式進行二次確認

### 必備指令範例
```bash
# 確認今日完整資訊
date +"%Y-%m-%d %A (%a)"              # 輸出：2025-09-08 Monday (Mon)

# 確認特定日期的星期
date -d "2025-09-06" +"%Y-%m-%d %A"   # 輸出：2025-09-06 Friday

# 計算相對日期
date -d "+1 days" +"%Y-%m-%d %A"      # 明日
date -d "-1 days" +"%Y-%m-%d %A"      # 昨日
date -d "+3 days" +"%Y-%m-%d %A"      # 3天後

# 計算特定星期的日期
date -d "next Monday" +"%Y-%m-%d %A"  # 下週一
date -d "last Saturday" +"%Y-%m-%d %A" # 上週六

# 驗證特定日期格式
date -d "2025-09-08" +"%A"            # 僅顯示星期：Monday
```

### 適用範圍
此協議適用於以下所有操作：
- **Google Calendar** 訓練事件建立/更新/查詢
- **Notion** 跑步訓練記錄檔案 記錄更新
- **Notion** 馬拉松訓練時程表 課表更新  
- **跑步活動分析** 日期對照和週期確認
- **訓練計畫制定** 週次安排和日期設定
- **所有涉及日期的系統操作**

### 錯誤防範
- ❌ **絕對禁止**：手動計算日期或憑記憶判斷星期
- ❌ **絕對禁止**：假設或猜測日期對應的星期
- ✅ **必須執行**：每次日期操作都透過 Linux date 指令驗證
- ✅ **必須記錄**：在相關文件中記錄日期驗證結果

### 執行範例
```bash
# 情境：需要確認 2025-09-06 是週幾
$ date -d "2025-09-06" +"%Y-%m-%d %A"
2025-09-06 Friday

# 情境：計算今日後3天的日期和星期
$ date -d "+3 days" +"%Y-%m-%d %A"
2025-09-11 Wednesday

# 情境：確認上週六的確切日期
$ date -d "last Saturday" +"%Y-%m-%d %A"  
2025-09-01 Saturday
```

### 重要提醒
- 任何日期錯誤都可能導致訓練計畫混亂和執行困難
- 日期驗證失敗時，必須停止操作並重新確認
- 所有日期操作完成後，建議再次驗證結果正確性

## 重要提醒
- 認證檔案包含敏感資訊，已加入 `.gitignore`
- Google Calendar token 在測試模式下 7 天後過期，需重新認證
- Notion Integration Token 包含敏感資訊，請妥善保管
- 訓練數據分析結果會自動更新至 Notion 相關檔案