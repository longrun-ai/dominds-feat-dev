# UX Issue：Context health 提醒不自动更新/不消失（owner 渲染与去重失效）

- 日期：2026-01-22
- 提出人：`@ux`
- 模块：Context health monitor / Reminders / ReminderOwner
- 相关代码：
  - 文案：`dominds/main/shared/i18n/driver-messages.ts`
  - 设计文档：`dominds/docs/context-health.md`

---

## 问题陈述

Context health 提醒在对话中出现后：

- 会残留为“旧内容快照”，不会随着最新文案/最新状态自动更新
- 可能重复出现多条相同提醒（同一语义条件），导致刷屏
- 条件恢复后也不会自动消失（应由 owner 机制 drop）

这与 `dominds/docs/context-health.md` 中对 **owned reminder** 的设计（内容应按 owner 动态渲染、并且满足 clear condition 后自动 drop）明显不一致。

---

## 复现步骤（观察式）

1. 触发一次 context health 提醒（例如上下文偏大，出现 “上下文健康：对话上下文已偏大。”）
2. 更新代码中的提醒文案（例如将提醒导向从 `clear_mind` 正文改为 `change_mind !progress`；或新增一条 option）
3. 重启后继续对话，触发新一条提醒
4. 观察：
   - 旧提醒仍保留旧文案（快照不更新）
   - 新提醒使用新文案（导致同一提醒出现多条、且内容不一致）
5. 即使后续上下文恢复健康，旧提醒也不会自动 drop（预期应消失）

---

## 当前行为

- 同一语义的 context health 提醒可能累计为多条（重复刷屏）
- 旧提醒不会被 owner 机制“实时渲染覆盖”，仍展示创建时的 snapshot 文案
- 没有稳定的“只存在一条 context_health owned reminder，并在 clear 后消失”的体验

---

## 期望行为（按设计）

- context health 提醒应为 **owned reminder**：
  - UI/输出时忽略持久化 content snapshot，始终按最新状态渲染 owner 文案
  - 同 owner 在同一 dialog 中只应存在 **1 条**（去重生效）
- 当 clear condition 达成（例如 promptTokens 回落到 `effectiveOptimalMaxTokens` 以下）：
  - owner 应返回 `treatment: drop`，提醒自动消失
- 用户/智能体不需要手动删除旧提醒来“清爽界面”

---

## 影响

- 误导：旧提醒文案可能指向过时的操作方式（例如旧版还引导 `clear_mind` 正文变提醒）
- 噪音：重复提醒占用上下文、削弱提醒的权威性与可读性
- 与“上下文健康监控”目标相悖：提醒本身制造额外上下文负担

---

## 建议修复方向（给实现者的落地要点）

- 确认 context health 使用 `ReminderOwner`（`name: context_health`），并在渲染侧忽略 persisted `content` snapshot，改为 on-demand 渲染。
- 确认创建/更新逻辑是“update existing owned reminder”而不是每轮 add 新 reminder。
- 为 clear condition 实现 `drop`，并补一个最小回归验证：
  - 触发提醒 → 进入健康范围 → 下一轮提醒消失
  - 重启后仍只显示一条且内容跟随最新文案渲染

---

## 验收标准（手工）

1. 同一 dialog 中，context health 提醒最多只有 1 条（不会累计多条重复项）。
2. 修改文案/状态后，提醒内容能随下一轮实时变化（不会保留旧快照）。
3. 当上下文回到健康范围后，提醒能自动消失（无需手动 delete）。
4. 重启后提醒状态与内容一致，且不会“旧提醒快照 + 新提醒”并存。
