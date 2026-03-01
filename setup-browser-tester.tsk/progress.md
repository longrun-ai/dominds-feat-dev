范围与口径（v1）
- [owner:@ux] v1 UX 主口径：`docs/webui-ux-testability-v1.md`（覆盖面 in/out-scope + MUST/SHOULD + 稳定标识规范 + 回归包映射缺口）。
- [owner:@ux] v1 可分派卡片（含 PR 切片计划）：`ux-issues/webui-testability-v1-cards.md`（PR-1..PR-4 对应 Story2/1/3/5 的 P0 闭环）。
- [owner:@ux] v0 原则与初始 backlog：`ux-issues/webui-testability-overhaul.md`。

回归 suite（单一来源）
- [owner:@ux] suite 顺序：`ux-stories/README.md`（Story0..5）。
- [owner:@ux] 新增抓手：Story0 `ux-stories/setup-smoke.md`（/setup）、Story5 `ux-stories/q4h-panel-input.md`（Ask→Select→Answer）。
- [owner:@ux] 测试指南：`docs/webui-testing-guide.md`（指向 suite README 的 canonical 顺序）。
- [owner:@ux] 证据/快照落盘规则：必须写入 `artifacts/browser_tester/`（推荐 `artifacts/browser_tester/snapshots/`），禁止写到 repo root。

关键决策：跨 tab/跨客户端一致性模型
- [owner:@ux] 以 **后端事件推送** 为唯一来源（等价跨机器客户端同步），**不做任何前端 tab 间通信机制**（已写入 `docs/webui-ux-testability-v1.md`、`ux-issues/webui-testability-v1-cards.md`，并在 story2 增补说明）。

已知阻塞点与修复状态（Story2 / Resume all）
- [owner:@ux] 2026-02-09 Round 1（两轮窗口）结果：story1 Pass、story2 Fail、story3 Pass、story4 Pass；因此 Round 1 不计入达标。
- [owner:@ux] story2 Fail 点：全局 `Resume all` 计数未能稳定归零且跨 tab 不一致（未满足“归零 + 5s 内一致”gate）。
- [owner:@ux] issue：`ux-issues/resume-all-cross-tab-sync.md`。

实现推进（PR-1 / Story2 稳定化）
- [owner:@ux] `@fullstack` 已落盘 PR-1（Story2 稳定化）相关改造（主要触达 `dominds/webapp/src/components/dominds-app.tsx`、`dominds/webapp/src/components/dominds-q4h-input.ts`、`dominds/webapp/src/i18n/ui.ts`）。
- [owner:@ux] 2026-02-10 `@cmdr` 代跑类型检查通过：`pnpm -C dominds run lint:types` exit code 0（`tsc -p main/tsconfig.json --noEmit && tsc -p webapp/src/tsconfig.json --noEmit`）。
- [owner:@ux] 2026-02-11 单轮 suite（Story0..5）结果（不计入“两轮连续验收窗口”，用于 gate 回归）：
  - story0 Pass
  - story1 Pass：toast “Link copied.” 可触发；`Notification history` 允许为空态（按设计不持久记录）
  - story2 Fail：跨 tab 5s 一致性 gate 未通过（被确认是浏览器侧计数缓存导致）；方向：去掉浏览器缓存，总是以后端事件推送的最新状态/计数为准
  - story3 Pass
  - story4 Pass
  - story5 Pass（备注：归零后不自动隐藏，显示空态；是否需对齐预期）
  - 观察：Console 多次出现 `[WARNING] DialogContainer: Ignoring event for diff...`（未阻断，疑似与跨 tab 同步相关，待 @fullstack 排查）

可测试性增强（已落地一项）
- [owner:@ux] Story1 toast 触发定位已从“依赖 tooltip 文案”改为稳定定位：优先使用 dialog list icon button 的 `data-action="dialog-share-link"`（见 `ux-stories/new-dialog-create-modal-regression.md`）。

环境可用性确认（避免验收启动阻塞）
- [owner:@ux] `browser_tester` 成员已存在：`.minds/team.yaml`。
- [owner:@ux] Playwright MCP toolset（stdio）已配置：`.minds/mcp.yaml`（`playwright` / `playwright2`）。

2026-03-01 回归复测（本轮）
- [owner:@ux] 已执行环境整备：`./dev-server.sh prep` 与 `./dev-server.sh restart`，前后端可达（`http://127.0.0.1:5555/`、`http://127.0.0.1:5556/` 均 200）。
- [owner:@ux] 期间出现 Playwright MCP 通道级阻塞（`browser_navigate` 超时 / `-32001`）；重启后最小导航采样恢复（`playwright` 与 `playwright2` 对 `/setup` 导航均成功）。
- [owner:@ux] `@browser_tester` 本轮最终矩阵（Story0..5）：`Pass / Pass / Pass / Pass / Pass / Pass`。
- [owner:@ux] Story2 重点 gate 结论：`Resume all` 归零通过；5s 内跨 tab 一致性通过。
- [owner:@ux] 本轮未发现新的产品级回归缺陷，因此无代码修复提交。

Next（重开对话后继续）
- [owner:@ux] 按封板口径，安排“连续 2 轮且全篇无意外”的完整验收窗口（允许每轮开始前一次整备重启）；若再次出现需反复恢复动作的情况，不计入达标轮并转交永久修复。