- [owner:@ux] 已落地轻量 MCP stdio server（用于 MCP story 功能性测试）：`ux-rtws/mcp/env-var-echo-mcp-server.js`（工具名 `env_echo`）。
- [owner:@ux] 已为 dev-server(rtws=`ux-rtws/`) 创建 `ux-rtws/.minds/mcp.yaml`：仅注册轻量 `env_echo`，用于 `ux-stories/mcp-toolset.md`，避免把 Playwright 等重量级 MCP server 作为测试目标。
- [owner:@ux] 已更新并现代化 `ux-stories/*.md`（4 篇统一模板）：补齐 hard constraints / round rules（单篇 Fail 继续跑完其它 story；每轮开始先 `./dev-server.sh prep`）/ ops-only recovery actions / Pass rule，并把已知问题显式化以便稳定复跑。
- [owner:@ux] 已把“每轮标准整备动作”固化为工具：`./dev-server.sh prep`（`clear-records + restart`）并写入 `ux-stories` 与测试指南。
- [owner:@ux] `docs/webui-testing-guide.md` 已重写为英文版本（去翻译腔、讲清硬规则/整备/回贴/门禁），并与 `ux-stories` 口径一致。

已跑通的单篇回归：
- [owner:@ux] story3（`ux-stories/mcp-toolset.md`）在标准整备后复跑：结论 Pass；Tools/Problems 面板可用；`env_echo` MCP tool call 可见且完成。

2026-02-09 专项复测（story1+story2）：
- [owner:@ux] `@browser_tester` 起初 **Blocked**（Playwright 侧访问 `localhost:5555/5556`、`127.0.0.1` 对应端口均 `ERR_CONNECTION_REFUSED`），已先释放租约避免占用：`mcp_release({"serverId":"playwright"})`。
- [owner:@ux] `@cmdr` 随后已执行 `./dev-server.sh prep`，并验证 `http://localhost:5555/`（frontend）与 `http://localhost:5556/`（backend）均 HTTP 200（rtws=`ux-rtws/`）。
- [owner:@ux] story1（`ux-stories/new-dialog-create-modal-regression.md`）专项复测结论 **Pass**：触发确定性 toast（例如点击“复制链接”触发“链接已复制。”）后，顶部“通知历史”非空且包含新触发记录；关闭再打开仍在。
- [owner:@ux] story2（`ux-stories/dlg-stop-resume.md`）专项复测结论 **Pass**：对话内继续/顶部紧急停止 + 全局“全部继续”路径下，`全部继续` 计数可从 1 → 0 正常归零（本次专项未做跨 tab 校验）。
- [owner:@ux] `@browser_tester` 收尾释放租约：`mcp_release({"serverId":"playwright2"})`。

2026-02-09 story4 单跑（`ux-stories/work-ui-lang.md`）：
- [owner:@ux] `@cmdr` 执行 `./dev-server.sh prep` exit_code=0，并验证 `http://localhost:5555/` 与 `http://localhost:5556/` 均 HTTP 200（rtws=`ux-rtws/`）。
- [owner:@ux] `@browser_tester` 回贴结论 **Pass**：UI language 下拉可见；中英切换生效且刷新后持久化；创建/选择对话后发送消息不导致 UI language 回退。
- [owner:@ux] 记录一个可绕过的小交互点：一次出现“发送”按钮短暂不可用（对话运行中态），点击输入区旁“⌘”按钮后恢复可发送（需后续观察是否应优化）。
- [owner:@ux] `@browser_tester` 收尾释放租约：`mcp_release({"serverId":"playwright"})`；并额外释放 `mcp_release({"serverId":"playwright2"})` 以避免残留占用。

Next:
- [owner:@ux] 组织 `@browser_tester` 在同一套 `ux-stories` steps 下跑“连续 2 轮”全套 4 篇（每轮开始允许 1 次 `prep` 整备；中途频繁恢复不计入达标），并回贴每篇 `Pass/Fail/Blocked` + 关键发现。
- [owner:@ux] 两轮均达标后，向 `@human` 诉请验收封板。