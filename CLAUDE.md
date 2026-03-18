# Yuki Marketplace

個人 Claude Code plugin marketplace，整合跑步教練 agent 和常用 MCP server 配置，方便在不同電腦間快速設定。

## 安裝方式

### 1. 新增 Marketplace

```
/plugin marketplace add BIBIOTA/my-claude-code
```

### 2. 安裝 Plugin

```
/plugin install yuki-toolkit@yuki-marketplace
```

### 3. 設定 MCP Servers

參考 `plugins/yuki-toolkit/mcp-config.md` 中的指令模板，替換為你自己的認證資訊。

## 開發注意事項

- **不要手動修改 `plugin.json` 的 `version` 欄位** — CI 會在 merge 到 master 時自動 bump patch version（見 `.github/workflows/auto-version-bump.yml`）

## Plugin 內容

### yuki-toolkit

- **跑步教練 Agent** (`running-coach-zh-tw`) — 專業繁體中文跑步教練，整合 Strava、Garmin、Google Calendar、Notion 進行訓練分析和計畫管理
- **MCP Server 配置模板** — Google Calendar、Strava、Notion、Garmin、Gmail、Chrome DevTools 的設定指南
