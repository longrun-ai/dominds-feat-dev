- [owner:@ux] 已新增 `.minds/mcp.yaml`：注册 MCP serverId `playwright`（stdio），命令 `npx -y @playwright/mcp@latest`，并统一加前缀 `playwright_`。
- [owner:@ux] 已更新 `.minds/team.yaml`：新增成员 `browser_tester`，授予 toolsets：`memory`、`playwright`、`mcp_admin`；并通过 `team_mgmt_validate_team_cfg()` 校验 ✅。
- [owner:@ux] 已新增/更新 `.minds/team/browser_tester/persona.zh.md` 与 `.minds/team/browser_tester/checklist.zh.md`：默认只测 `http://localhost:5555`，不可访问时先提醒 @human。
- [owner:@ux] @browser_tester 已完成最小冒烟与两次重跑（tellaskSession: `setup-browser-tester-smoke-5555`、`setup-browser-tester-smoke-5555-rerun`）：首页加载、`ping -> pong`、可控错误可见、刷新恢复均通过；每轮收尾均已 `mcp_release({"serverId":"playwright"})`。
- [owner:@ux] 已将“创建新对话”入口与 modal 可用性/叠层问题整理为 UX triage：`ux-issues/create-dialog-modal-ux-triage.md`。
- [owner:@ux] @human 已确认并固化执行口径：前后端一体 repo 整体一次性改到位，不留向后兼容层，不背历史包袱；已写入 `AGENTS.md` 与 `.minds/env.zh.md/.minds/env.en.md`。
- [owner:@ux] @fullstack 已按该口径完成重构主线并回贴关键改动落位：`dominds/main/shared/types/wire.ts`、`dominds/main/server/api-routes.ts`、`dominds/main/server/create-dialog-contract.ts`、`dominds/main/server/websocket-handler.ts`、`dominds/webapp/src/components/create-dialog-flow.ts`、`dominds/webapp/src/components/dominds-app.tsx`、`dominds/webapp/src/services/api.ts`。
- [owner:@ux] 门禁结果（@cmdr）：`pnpm -C dominds run lint:types` ✅（exit_code=0），`pnpm -C dominds run build` ✅（exit_code=0）。
- [owner:@ux] E2E 复核结果（@browser_tester，tellaskSession: `create-dialog-modal-holistic-refactor-e2e`）：A/B/C/D/E 全部 `pass`，并回贴原始值、截图与 console/network 摘要；测试租约已释放（`mcp_release({"serverId":"playwright"})`）。
- [owner:@ux] 当前结论：该重构任务已达到可验收状态，建议进入合入流程。

Next:
- [owner:@ux] 如 @human 确认，进入合入前留档：由 @fullstack 回贴“最终删除清单 + 关键 diff 锚点”作为变更归档。