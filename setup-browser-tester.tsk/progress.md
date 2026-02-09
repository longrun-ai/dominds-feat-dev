- [owner:@ux] 已落地轻量 MCP stdio server（用于 MCP story 功能性测试）：`ux-rtws/mcp/env-var-echo-mcp-server.js`（工具名 `env_echo`）。
- [owner:@ux] 已为 dev-server(rtws=`ux-rtws/`) 创建 `ux-rtws/.minds/mcp.yaml`：仅注册轻量 `env_echo`，用于 `ux-stories/mcp-toolset.md`，避免把 Playwright 等重量级 MCP server 作为测试目标。
- [owner:@ux] 已更新并现代化 `ux-stories/*.md`（4 篇统一模板）：补齐 hard constraints / round rules（单篇 Fail 继续跑完其它 story；每轮开始先 `./dev-server.sh prep`）/ ops-only recovery actions / Pass rule，并把已知问题显式化以便稳定复跑。
- [owner:@ux] 已把“每轮标准整备动作”固化为工具：`./dev-server.sh prep`（`clear-records + restart`）并写入 `ux-stories` 与测试指南；`@cmdr` 已可稳定执行且 5555/5556 均返回 HTTP 200。
- [owner:@ux] `docs/webui-testing-guide.md` 已重写为英文版本（去翻译腔、讲清硬规则/整备/回贴/门禁），并与 `ux-stories` 口径一致。
- [owner:@ux] `@browser_tester` 已在标准整备后复跑 story3（`ux-stories/mcp-toolset.md`）：结论 Pass；Tools/Problems 面板可用；`env_echo` MCP tool call 可见且完成；收尾释放租约 `mcp_release({"serverId":"playwright2"})`。

Known issues (from round-1/2):
- [owner:@ux] story1（`new-dialog-create-modal-regression.md`）：toast/通知历史 gate 未通过（Notification history 长期为空）。
- [owner:@ux] story2（`dlg-stop-resume.md`）：全局 `Resume all/全部继续` 计数不归零（对话恢复可正常；跨 tab 计数可同步）。

Next:
- [owner:@ux] 诉请 `@fullstack` 针对 story1/story2 做永久修复；修复完成后组织 `@browser_tester` 在同一套 steps 下连续 2 轮复跑全套 4 篇并回贴；达标后向 `@human` 诉请验收封板。