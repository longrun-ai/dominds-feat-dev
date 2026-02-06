- [owner:@ux] 已新增 `.minds/mcp.yaml`：注册 MCP serverId `playwright`（stdio），命令 `npx -y @playwright/mcp@latest`，并统一加前缀 `playwright_`。
- [owner:@ux] 已更新 `.minds/team.yaml`：新增成员 `browser_tester`，授予 toolsets：`memory`、`playwright`、`mcp_admin`。
- [owner:@ux] 已新增/更新 `.minds/team/browser_tester/persona.zh.md` 与 `.minds/team/browser_tester/checklist.zh.md`：默认只测 `http://localhost:5555`（通常无鉴权）；不可访问时先提醒 @human 确认 dev server 状态。
- [owner:@ux] 已运行 `team_mgmt_validate_team_cfg()`：`.minds/team.yaml` ✅ 无问题。
- [owner:@ux] @browser_tester 已完成最小 E2E 冒烟（tellaskSession: `setup-browser-tester-smoke-5555`）：通过 ✅（首页加载、`ping -> pong`、可控错误可见、刷新恢复；并已 `mcp_release({"serverId":"playwright"})`）。
- [owner:@ux] @browser_tester 已完成重复冒烟 rerun1/rerun2（tellaskSession: `setup-browser-tester-smoke-5555-rerun`）：两次均通过 ✅（`console red error = 0`，network 无 `4xx/5xx`，截图留存，收尾均已释放租约）。
- [owner:@ux] 已将“创建新对话”入口与 modal 的可用性/叠层稳定性问题整理为 UX triage：`ux-issues/create-dialog-modal-ux-triage.md`。
- [owner:@ux] @human 已确认执行原则：早期阶段优先根因修复，允许大重构一次性解决。
- [owner:@ux] 已确认并固化执行口径：前后端一体 repo 整体一次性改到位，不留向后兼容层，不背历史包袱（已写入 `AGENTS.md` 与 `.minds/env.zh.md/.minds/env.en.md`）。
- [owner:@ux] @fullstack 已按新原则回贴可直接实施蓝图（tellaskSession: `create-dialog-modal-holistic-refactor`）：
  - 统一目标态：`shared` 作为唯一创建契约源（可辨别联合 + `requestId` + 统一 `errorCode`，锚点 `dominds/main/shared/types/wire.ts:100`）；`main/server` 仅消费该契约（锚点 `dominds/main/server/api-routes.ts:948`）；`webapp` 仅保留单一创建流控制器（锚点 `dominds/webapp/src/components/dominds-app.tsx:6084`）。
  - 旧路径删除清单已明确：`handleNewDialog`、`showCreateDialogModal`、`setupDialogModalEvents`、`handleDialogCreateAction` 直连创建、`skipAgentPriming` 双轨语义、分散 z-index 魔数（均提供文件锚点）。
  - 单次实施顺序已明确（提交1~7）：shared 契约 → server 创建处理 → webapp API → create-dialog-flow → dominds-app 接线替换 → overlay token 化 → docs+i18n+回归。
  - 门禁矩阵已明确：`pnpm -C dominds run lint:types`、`pnpm -C dominds run build`、E2E 关键旅程（单 modal、单 dialog、task-action 预填、结构化错误可见、键盘/关闭一致、刷新恢复）。

Next:
- [owner:@ux] 已要求 @fullstack 立即按该“单次整体蓝图”进入实现并逐步回贴实际 diff 锚点、删除清单与 `lint:types/build` 结果。
- [owner:@ux] 待 @fullstack 回贴实现完成后，立即安排 @browser_tester 按门禁矩阵执行端到端复核并回传证据。