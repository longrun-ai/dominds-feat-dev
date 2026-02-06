- [owner:@ux] 已完成 Playwright MCP 与 `browser_tester` 团队成员配置：`.minds/mcp.yaml` 与 `.minds/team.yaml` 已落地并校验通过。
- [owner:@ux] WebUI E2E 协作主线（tellaskSession: `webui-testing-guide-optimize-e2e`）已完成两轮迭代：@browser_tester 提供真实执行量化包，@fullstack 完成文档定稿。
- [owner:@ux] 两轮量化基线已确认：Round1=9min（失败1次/元素波动1/恢复1min/已恢复）、Round2=8min（失败1次/元素波动1/恢复1min/已恢复）。
- [owner:@ux] 文档已对齐最新实现并去除低效方法：`docs/webui-testing-guide.md` 已明确淘汰固定长 sleep、console helper、脚本驱动、API 直连。
- [owner:@ux] 硬约束已固化：WebUI E2E 禁止直接 HTTP/WS API、禁止脚本、仅允许浏览器键盘/鼠标/触控模拟人类交互。
- [owner:@ux] 最终结构已落位：最小稳定流程、反模式清单、失败恢复策略（含元素波动）、G1~G8 二值化验收 gate、证据留存最小集。
- [owner:@ux] 关键核对通过（@ux 复核）：`docs/webui-testing-guide.md:90`（量化基线）、`docs/webui-testing-guide.md:110`（最小稳定流程）、`docs/webui-testing-guide.md:123`（反模式）、`docs/webui-testing-guide.md:153`（G1~G8）、`docs/webui-testing-guide.md:166`（证据留存）。
- [owner:@ux] 当前结论：`setup-browser-tester.tsk` 的核心目标已达成，可作为长期回归与交接基线使用；测试租约释放约束已在流程中保留。
- [owner:@ux] 已启动 `ux-stories/` 文档收敛评估：完成 10 篇盘点，发现 7 篇仍依赖已删除的 helper 注入片段（`/testing/dom-observation-utils.js`、`/testing/e2e-test-helper.js`），存在明显过时内容。
- [owner:@ux] 已形成收敛方向：仅保留少数高价值场景做“现代化改造（纯人类交互、无 helper 依赖、二值化 gate）”，其余重复/低收益/过时 story 计划删除。

Next:
- [owner:@ux] 向 @human 回贴“保留/删除”建议清单并确认后执行批量清理。
- [owner:@ux] 对保留文档执行统一现代化模板改造（前置条件、最小流程、失败恢复、证据最小集、Pass/Fail gate）。