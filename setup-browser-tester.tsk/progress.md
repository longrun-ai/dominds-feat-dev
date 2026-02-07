- [owner:@ux] 已完成 Playwright MCP 与 `browser_tester` 团队成员配置：`.minds/mcp.yaml` 与 `.minds/team.yaml` 已落地并校验通过。
- [owner:@ux] WebUI E2E 协作主线（tellaskSession: `webui-testing-guide-optimize-e2e`）已完成两轮迭代：@browser_tester 提供真实执行量化包，@fullstack 完成文档定稿。
- [owner:@ux] 两轮量化基线已确认：Round1=9min（失败1次/元素波动1/恢复1min/已恢复）、Round2=8min（失败1次/元素波动1/恢复1min/已恢复）。
- [owner:@ux] 文档已对齐最新实现并去除低效方法：`docs/webui-testing-guide.md` 已明确淘汰固定长 sleep、console helper、脚本驱动、API 直连。
- [owner:@ux] 硬约束已固化：WebUI E2E 禁止直接 HTTP/WS API、禁止脚本、仅允许浏览器键盘/鼠标/触控模拟人类交互。
- [owner:@ux] 当前结论：`setup-browser-tester.tsk` 核心目标达成，可作为长期回归与交接基线。
- [owner:@ux] `ux-stories/` 收敛已执行：按 @human 确认批量删除 6 篇低价值/过时文档，仅保留 4 篇高价值场景（`new-dialog-create-modal-regression.md`、`dlg-stop-resume.md`、`mcp-toolset.md`、`work-ui-lang.md`）。
- [owner:@ux] 文档状态修正：`ux-stories/new-dialog-create-modal-regression.md` 已恢复（误删后已补回），当前保留集完整。
- [owner:@ux] 已采纳 @human 建议切换执行策略：进入“@browser_tester 实操先行、@fullstack 同步改文档、按轮次验证封板”的一步到位流程（tellaskSession: `ux-stories-modernize-practical-loop`）。
- [owner:@ux] 已更新 `ux-stories/new-dialog-create-modal-regression.md` 预期：允许不存在的 taskdoc 路径；“创建失败”检查改为可选。
- [owner:@ux] 已更新 @browser_tester persona：浏览器异常可自主关闭并重试（必要时 `mcp_release`/`mcp_restart`），并要求回贴恢复动作。

Next:
- [owner:@ux] 等待 @browser_tester 重新补齐 new-dialog Step2/Step6，并推进其余三篇实操验证回贴。
- [owner:@ux] 实操证据到齐后统一封板 4 篇现代化文档。