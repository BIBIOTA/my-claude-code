# Yuki Marketplace

個人 Claude Code plugin marketplace，整合跑步教練、日曆管理、運動數據分析等工具。

## 快速安裝

```bash
# 在 Claude Code 中執行
/plugin marketplace add BIBIOTA/my-claude-code
/plugin install yuki-toolkit@yuki-marketplace
```

安裝後需手動設定 MCP servers，詳見 [MCP 配置指南](plugins/yuki-toolkit/mcp-config.md)。

## Plugin: yuki-toolkit

### 🏃 跑步教練 Agent

專業繁體中文跑步教練代理，提供：

- Strava 跑步數據分析（配速、心率、步頻）
- Garmin 進階數據整合
- Google Calendar 訓練計畫管理
- Notion 訓練記錄與課表同步
- 個人化心率區間設定與監控
- 80/20 訓練強度分配指導

### 📡 MCP Server 配置模板

提供以下 MCP server 的 `claude mcp add` 指令模板：

| Server | 用途 | 套件 |
|--------|------|------|
| Google Calendar | 日曆管理 | `@cocal/google-calendar-mcp` |
| Strava | 運動數據 | `strava-mcp` (手動設定) |
| Notion | 筆記管理 | `@notionhq/notion-mcp-server` |
| Garmin | 穿戴裝置數據 | `garmin_mcp` (Python/UV) |
| Gmail | 郵件管理 | `@gongrzhe/server-gmail-autoauth-mcp` |
| Chrome DevTools | 瀏覽器自動化 | `chrome-devtools-mcp` |

## 前置需求

- [Claude Code](https://claude.com/claude-code) CLI
- 各 MCP server 對應的帳號和 API 認證（詳見配置指南）

## 授權

MIT
