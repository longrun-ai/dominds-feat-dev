## Progress

范围与口径（v1）
- [owner:@ux] v1 UX 主口径：`docs/webui-ux-testability-v1.md`（覆盖面 in/out-scope + MUST/SHOULD + 稳定标识规范 + 回归包映射缺口）。
- [owner:@ux] v1 可分派卡片（含 PR 切片计划）：`ux-issues/webui-testability-v1-cards.md`（PR-1..PR-4 对应 Story2/1/3/5 的 P0 闭环）。
- [owner:@ux] v0 原则与初始 backlog：`ux-issues/webui-testability-overhaul.md`。

回归 suite（单一来源）
- [owner:@ux] suite 顺序：`ux-stories/README.md`（Story0..5）。
- [owner:@ux] 新增抓手：Story0 `ux-stories/setup-smoke.md`（/setup）、Story5 `ux-stories/q4h-panel-input.md`（Ask→Select→Answer）。
- [owner:@ux] 测试指南：`docs/webui-testing-guide.md`（指向 suite README 的 canonical 顺序）。

关键决策：跨 tab/跨客户端一致性模型
- [owner:@ux] 以 **后端事件推送** 为唯一来源（等价跨机器客户端同步），**不做任何前端 tab 间通信机制**（已写入 `docs/webui-ux-testability-v1.md`、`ux-issues/webui-testability-v1-cards.md`，并在 story2 增补说明）。

已知阻塞点与修复状态（Story2 / Resume all）
- [owner:@ux] 2026-02-09 Round 1（两轮窗口）结果：story1 Pass、story2 Fail、story3 Pass、story4 Pass；因此 Round 1 不计入达标。
- [owner:@ux] story2 Fail 点：全局 `Resume all` 计数未能稳定归零且跨 tab 不一致（未满足“归零 + 5s 内一致”gate）。
- [owner:@ux] issue：`ux-issues/resume-all-cross-tab-sync.md`。

实现推进（PR-1 / Story2 稳定化）
- [owner:@ux] `@fullstack` 已落盘 PR-1（Story2 稳定化）相关改造（主要触达 `dominds/webapp/src/components/dominds-app.tsx`、`dominds/webapp/src/components/dominds-q4h-input.ts`、`dominds/webapp/src/i18n/ui.ts`）。
- [owner:@ux] 2026-02-10 `@cmdr` 代跑类型检查通过：`pnpm -C dominds run lint:types` exit code 0（`tsc -p main/tsconfig.json --noEmit && tsc -p webapp/src/tsconfig.json --noEmit`）。

可测试性增强（已落地一项）
- [owner:@ux] Story1 toast 触发定位已从“依赖 tooltip 文案”改为稳定定位：优先使用 dialog list icon button 的 `data-action="dialog-share-link"`（见 `ux-stories/new-dialog-create-modal-regression.md`）。

环境可用性确认（避免验收启动阻塞）
- [owner:@ux] `browser_tester` 成员已存在：`.minds/team.yaml`。
- [owner:@ux] Playwright MCP toolset（stdio）已配置：`.minds/mcp.yaml`（`playwright` / `playwright2`）。

Next（重开对话后继续）
- [owner:@ux] 续推 `@fullstack` 按 `ux-issues/webui-testability-v1-cards.md` 的 PR-1→PR-4 顺序继续落地（每个 PR 合并后先跑 1 次单轮 smoke）。
- [owner:@ux] 在 PR-1 后执行：`@cmdr` 跑 `./dev-server.sh prep` + 5555/5556 可达验证 → `@browser_tester` 先跑 1 轮 suite（Story0..5），重点复核 Story2 gates；稳定后再重启“两轮连续验收窗口”。