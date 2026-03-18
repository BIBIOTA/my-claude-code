# Yuki Marketplace

個人 Claude Code plugin marketplace（BIBIOTA/my-claude-code）。

## 目錄結構

```
plugins/yuki-toolkit/
├── .claude-plugin/plugin.json   # plugin 註冊（agents, skills, metadata）
├── agents/                       # Agent 定義（.md frontmatter 格式）
├── skills/                       # Skill 定義（.md frontmatter 格式）
└── mcp-config.md                 # MCP server 設定指南
```

## 開發規則

- **不要手動修改 `plugin.json` 的 `version`** — CI merge 到 master 時自動 bump patch version（`.github/workflows/auto-version-bump.yml`）
- **Google Workspace 操作統一用 `gws` CLI** — 不使用個別 MCP server。指令參考見 `plugins/yuki-toolkit/skills/gws-reference/SKILL.md`
- **Agent/Skill 檔案使用 YAML frontmatter** — 開頭和結尾都要有 `---` 分隔線

## Git 慣例

- Branch: `feat/<feature-name>`
- PR target: `master`
- Commit prefix: `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`
