- [owner:@ux] 已完成 Playwright MCP 与 `browser_tester` 团队成员配置：`.minds/mcp.yaml` 与 `.minds/team.yaml` 已落地并校验通过。
- [owner:@ux] WebUI E2E 走查口径已简化：`@browser_tester` 逐篇回贴 `Pass/Fail/Blocked` + 关键发现（纯文本）即可；证据（截图/日志）仅在 Fail/Blocked 时可选最小化。
- [owner:@ux] `ux-stories/` 已收敛为 4 篇高价值场景：`new-dialog-create-modal-regression.md`、`dlg-stop-resume.md`、`mcp-toolset.md`、`work-ui-lang.md`。
- [owner:@ux] `docs/webui-testing-guide.md` 已对齐：E2E 仅浏览器键盘/鼠标/触控交互；禁止脚本/console helper 注入；禁止绕过 UI 直连 HTTP/WS API；测试完必须 `mcp_release({"serverId":"playwright"})`。

Next:
- [owner:@ux] 发起 `@browser_tester` 按 4 篇 story 逐步实操的反馈轮（逐篇 `Pass/Fail/Blocked` + 关键发现），收集“卡点/歧义/易碎步骤/耗时点”。
- [owner:@ux] 汇总反馈后，与 `@fullstack` 联动修复阻塞点；并迭代 `ux-stories/*.md`（步骤、等待策略、失败恢复 SOP）。
- [owner:@ux] 复跑确认稳定性与效率提升；以 `@browser_tester` 明确认可“顺手、可靠、可复跑”为封板口径。