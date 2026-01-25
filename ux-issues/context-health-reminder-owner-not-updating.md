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
2. 更新代码中的提醒文案（例如将提醒导向从 `clear_mind` 正文改为 `change_mind`（selector=`progress`）；或新增一条 option）
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

## 诊断结论（2026-01-22）

根因不是 `ReminderOwner` 本身（`dominds/main/tools/context-health.ts` 已实现 `updateReminder/drop/renderReminder`），而是 **reminders 持久化/恢复链路丢失 owner 与 meta**，导致重启后“owned reminder”退化为普通 reminder：

- `dominds/main/persistence.ts` 的 `DialogPersistence._saveReminderState()` 写 `reminders.json` 时只保存了 `content`（以及 UI 用的 id/createdAt/priority），**没有保存 `ownerName` / `meta`**。
- `dominds/main/persistence.ts` 的 `DialogPersistence.loadReminderState()` 读回来的 reminders **也就无法 rehydrate owner**（`getReminderOwner(ownerName)` 没有输入）。
- 结果：
  - 重启后，旧的 context health reminder 变成“无 owner 的快照”，`processReminderUpdates()` 不会 update/drop。
  - `applyContextHealthMonitor()` 扫 owner 发现“没有现存 owned reminder”，于是又 `addReminder()` 一条新的（形成“旧快照 + 新提醒”并存，甚至刷屏）。
  - UI 的提醒列表来自 `full_reminders_update` 事件（`dominds/main/dialog.ts: processReminderUpdates()` 发出），展示的是 `content` 快照；当 owner 丢失时，自然不会“随最新文案/状态更新”。

（附带影响：daemon 类 reminders 的 `meta`（pid/command）也会在重启后丢失，前端无法显示 PID。）

---

## 已落地修复（代码）

## 现状检查（2026-01-25）

- 设计上：context health reminder 应为 owned reminder，并在 clear condition 后由 owner 自动 drop；用户/agent 不需要也不应该依赖“手工 delete_reminder”来清理。
- 现实中：系统提示仍存在“我应判断它是否仍然相关；如果不相关，应立即调用 delete_reminder …”的泛化文案（适用于普通 reminders），容易误导为“手动删除是正确/必要的路径”。

### 发现：系统提示仍建议手工 delete（与 owned reminder 心智冲突）

- 相关文案位置：`dominds/main/shared/i18n/driver-messages.ts:23` 的 `formatReminderItemGuide()`。
- 当前输出会对每条 reminder（不区分 owned vs 非 owned）都附加“如不相关应 delete_reminder”的指引。

### 建议（产品/UX 层）

- 对 owned reminders（有 ownerName 的提醒），在渲染时不再附加“请 delete_reminder 清理”的指引，改为：
  - 明确该提醒由 owner 管理，会在条件恢复后自动更新/消失。
  - 若需要强制清理，提供替代建议（例如改用 `clear_mind` 开新回合），而不是引导 delete。
- 对非 owned reminders，保留当前 delete_reminder 指引即可。

### 验收点

- [ ] owned reminders（例如 `context_health`）在 UI/assistant 输出中不再出现“请 delete_reminder”式的误导文案。
- [ ] non-owned reminders 仍保持可手动 delete_reminder 的指引与行为。

- **持久化补全**：`reminders.json` 的 schema 扩展为每条 reminder 可选保存：
  - `ownerName?: string`
  - `meta?: JsonValue`
  - 代码：`dominds/main/shared/types/storage.ts`、`dominds/main/persistence.ts`
- **恢复 rehydrate**：加载 reminders 时按 `ownerName` 通过 registry `getReminderOwner(ownerName)` 还原 owner；同时还原 `meta`。
- **去重加固**：`applyContextHealthMonitor()` 对 `owner.name === 'context_health'` 的 reminders 做防御性去重（最多保留 1 条），避免历史脏数据/异常路径导致累计。
  - 代码：`dominds/main/llm/driver.ts`
- **最小回归脚本**：新增 `dominds/tests/persistence/reminders-owner-meta.ts`，覆盖：
  - ownerName/meta 的写入与读回

---

## 验收标准（手工）

1. 同一 dialog 中，context health 提醒最多只有 1 条（不会累计多条重复项）。
2. 修改文案/状态后，提醒内容能随下一轮实时变化（不会保留旧快照）。
3. 当上下文回到健康范围后，提醒能自动消失（无需手动 delete）。
4. 重启后提醒状态与内容一致，且不会“旧提醒快照 + 新提醒”并存。
