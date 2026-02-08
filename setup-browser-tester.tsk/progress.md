- [owner:@ux] 已落地轻量 MCP stdio server（用于 story4 功能性测试）：`ux-rtws/mcp/env-var-echo-mcp-server.js`（工具名 `env_echo`）。
- [owner:@ux] 已为 dev-server(rtws=`ux-rtws/`) 创建 `ux-rtws/.minds/mcp.yaml`：仅注册轻量 `env_echo`，用于 `ux-stories/mcp-toolset.md`，避免把 Playwright 等重量级 MCP server 作为测试目标。
- [owner:@ux] 已更新 `ux-stories/mcp-toolset.md`：对话内触发 MCP tool call 改为调用 `env_echo`（不再要求 Playwright snapshot）。
- [owner:@ux] 已固化“整备操作”口径：每轮开始允许一次 `./dev-server.sh restart` 与必要时一次 `mcp_restart` 作为正常整备；仅当中途频繁恢复动作才能继续推进时，该轮不计入达标（需永久修复后再连续两轮）。
- [owner:@ux] `@cmdr` 已核验并可整备重启 `./dev-server.sh`：frontend/backend 端口 `5555/5556` 监听且 `HTTP 200`。
- [owner:@ux] 团队协作护栏已写入：`.minds/env.zh.md` / `.minds/env.en.md` 追加 dev-server 热重载风险与 owner 自检责任边界；并新增团队记忆 `collaboration-guardrails.md`。

Known issues (from round-1/2):
- [owner:@ux] story1（`new-dialog-create-modal-regression.md`）：toast/通知历史 gate 未通过（Notification history 长期为空）。
- [owner:@ux] story2（`dlg-stop-resume.md`）：全局 `Resume all/全部继续` 计数不归零（对话内继续可归零；跨 tab 计数可同步）。

Next:
- [owner:@ux] 诉请 `@cmdr` 做一次整备 `./dev-server.sh restart` 后，请 `@browser_tester` 先复跑 `ux-stories/mcp-toolset.md`（env_echo）确认 story4 可稳定 Pass。
- [owner:@ux] 诉请 `@fullstack` 针对 story1/story2 做永久修复；修复完成后组织 `@browser_tester` 在同一套 steps 下连续 2 轮复跑全套 4 篇并回贴；达标后向 `@human` 诉请验收封板。