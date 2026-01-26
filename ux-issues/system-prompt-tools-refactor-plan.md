# 重构计划：系统提示与工具设计（基于代码事实）

- 日期：2026-01-26
- 负责人：`@fullstack`
- 状态：迭代中（已冻结 v2 合同）
- 前置：`ux-issues/system-prompt-tools-ux-acceptance.md` 已定稿
- 目标：把“提示-工具-体验”的高风险误导点修到位，并加最小防回归；本轮新增 **context health v2 remediation**（强约束 + 可回归）。
---

## 1. 代码现实（关键入口/锚点）

### 1.1 系统提示（System Prompt）

- 主拼装：`dominds/main/minds/system-prompt.ts`
  - tellask 语法与模板说明
  - “shell 专员”示例使用 `!?@<shell-specialist>`（已较通用）
- 动态注入：`dominds/main/minds/load.ts`
  - 记忆系统（Taskdoc/提醒项/团队记忆/个人记忆）说明
  - 子对话/主对话行为差异（子对话不能 `change_mind`，会引导诉请维护人）
  - shell specialist 列表注入（以 team.yaml 配置为准）

### 1.2 用户可见文案（driver messages）

- `dominds/main/shared/i18n/driver-messages.ts`
  - context health 提醒正文 `formatContextHealthReminderText()`
  - 提醒项 intro `formatReminderIntro()`（你刚看到的“提醒项 #1 …”就是这里来的）
  - `!?@super` 的提示文案（关于 supdialog/父对话的说明）

### 1.3 Context health v2 remediation（下一轮 role=user 注入 + 强制清理循环）

- 关键实现点（计划落地的代码锚点）：
  - `dominds/main/llm/driver.ts`
    - 下一次 LLM gen turn 的 **role=user 指南注入**（但不持久化进对话记录）
    - `caution`：每 10 次 gen 的节流再提醒
    - `critical`：forced-clear loop（最多 3 次），无 `clear_mind` 则丢弃输出（只 log，不写入对话）
    - 3 次失败后触发 Q4H（并让 dialog 进入 suspended，driver 不再继续尝试）
  - `dominds/main/shared/types/q4h.ts`（或等价类型锚点）：为 Q4H 增加 `kind` 判别字段
  - `dominds/webapp/src/components/dominds-q4h-panel.ts`：对 `kind=context_health_critical` 禁用发送

### 1.4 文档

- `dominds/docs/context-health.md`：阈值/倒数/auto-new-round 语义基准
- `dominds/docs/dominds-terminology.md`：tellask 概念与示例

---

## 2. 发现的问题（以“提示-工具-体验”角度）

### P0：提示中出现了不该成为目标的“篇幅指标”

- 现状：多处中文提示仍写“`change_mind(progress)` 写 **5 行** 提炼摘要”，例如：
  - `dominds/main/shared/i18n/driver-messages.ts`：yellow/critical context health 提醒正文
  - `dominds/main/shared/i18n/driver-messages.ts`：提醒项 intro（黄/红建议流程）
- 问题：
  - “5 行”并无语义来源（不应对篇幅设目标），会在大任务/多人协作时误导。
  - 与我们已定稿的验收文档冲突：应强调“可扫读、可行动”，而不是行数。

### P1：shell specialist 表述存在“实例化 ID”渗透到通用语义的风险

- 现状：
  - 系统提示会展示真实配置列表（例如测试里断言 `Shell specialist teammates: @cmdr`），这是合理的“本队配置事实”。
  - 但文档示例（`dominds/docs/dominds-terminology.md`）也直接用 `@cmdr`，容易被误读为通例。
- 风险：跨 rtws / 跨团队配置时，读者会把 `@cmdr` 当固定约定。

### P2：术语层面的“父对话” vs “主对话/根对话”

- 现状：
  - `!?@super` 的语义本质上是“direct parent / supdialog”，用“父对话”在实现语境是准确的。
  - 但当讨论 **Taskdoc 更新责任/维护人** 时，“父对话”容易误导，因为维护责任在“主对话/根对话”而不是任意 parent。
- 需要做的事：在系统提示/文案中区分两类语义：
  - `!?@super`：父对话（supdialog）
  - Taskdoc：主对话/根对话（root/main dialog）

### P0（新增）：context health 黄/红时“可回归性不足”

- 现象：一旦执行 `clear_mind`，若无法在 **≤3 个文件读取**内恢复工作上下文，就说明“耐久层”承载失败。
- 需要做的事：把黄/红时的行为从“owned 提醒项建议”升级为 **driver 强制的 v2 remediation**：
  - 下一次请求注入“重入包”结构与填写指导（role=user；不持久化）；
  - `caution` 给出 `clear_mind` / `add_reminder` 二选一；
  - `critical` 进入 forced-clear loop，并在 3 次失败后 Q4H（kind=专用）。

---

## 3. 重构目标（可回归的、可验证的）

- 消除“5 行”这种不该成为目标的篇幅约束；替换为“提炼摘要结构建议”（可多行，按任务规模伸缩）。
- 统一 shell specialist 的表述：
  - 系统提示里可以展示“本队 shell 专员列表”（事实），但
  - 文档/模板里用 `@<shell-specialist>` 作为占位符，避免 `@cmdr` 成为通例。
- 明确术语边界：
  - `!?@super` 继续解释为父对话（supdialog）
  - Taskdoc 更新责任明确指向主对话/根对话（并且保持“子对话不能 change_mind”的硬护栏）

- context health v2 remediation（新增硬目标）：
  - 黄/红触发后，agent 的“下一步路径”必须短且可执行（目标：恢复成本 ≤3 文件读取）。
  - `critical` 下不得把无效输出写入对话记录（可观测但不污染状态）。

---
---

## 4.5 变更记录：`context-health-copy.ts` 已删除

- 用户决定删除该测试脚本（意义不大），因此该回归点不再通过测试守护。
- 后续如需防止“写 5 行”等高风险误导文案回归，建议改为：
  - 仅保留最小的字符串断言（更接近 lint）；或
  - 把此类误导点做成更结构化的 copy 常量/模板（减少散落字符串）。

## 4. 下一次迭代修改计划（仅记录，不改代码）

> 目标：解决 dogfooding 复盘暴露的两类失败模式：
> 1) agent 在 context-health 黄/红时仍会“硬抗”不执行 `clear_mind`；
> 2) 非 shell specialist 在需要跑验证命令时会停在“我不能跑”，而不是自动 tellask shell 专员。

### 4.1 Context health v2 remediation（driver 强制；替代旧的倒数/auto-new-round）

- 新行为契约（与 `ctx-health-fixup.tsk` 对齐）：
  - **摒弃**旧的“5 次倒数归零自动新一轮/新回合”。
  - 黄（`caution`）：在下一次 LLM gen turn 注入 role=user 指南（不持久化），并提供两种选择（二选一；同一份重入包内容）：
    - `clear_mind({"reminder_content":"<重入包>"})`
    - `add_reminder({"content":"<重入包>","position":0})`
    - 若未清理：每 10 个 gen turn 再注入一次。
  - 红（`critical`）：进入 forced-clear loop（最多 3 次）：
    - 每次只允许 `clear_mind` 且 `reminder_content` 必须非空；否则丢弃输出（只 log，不写入对话记录）并重试。
    - 3 次失败后触发 Q4H：`kind=context_health_critical`，并使 dialog 进入 suspended（driver 不再继续）。
- 实现形态：指南拼进发给模型的 **role=user prompt**，但不得持久化进对话历史/事件。

### 4.2 让 tellask shell 专员成为“验证命令”的硬默认动作

- **关键澄清（需写进系统提示）**：tellask 是 out-of-band 的可执行通道，**不需要**出现在 function tools 列表里；只要输出符合语法的 `!?...` 行（第 0 列起始、非代码块/非引用/非列表缩进），运行时就会触发队友执行。
- **反例需强调**：不要把 `!?@<shell-specialist>` 放进反引号/代码块；不要在行首加缩进或 `-` 项目符号，否则诉请不会触发。
- **失败策略**：如果你不确定 tellask 在当前环境是否可用，先按模板尝试发起一次；只有在收不到回执且确认未配置/配置错误时，才升级诉请 `@human`。

- 修改系统提示/模板：
  - 当需要跑 lint/types/tests 等常规验证命令时，非 shell specialist **必须在同一条消息中**直接发起 tellask（`!?@<shell-specialist>`），而不是先解释自己不能跑。
  - 只有在以下情况才诉请 `@human`：未配置 shell 专员、shell 专员缺工具、或命令具有高风险且需要人类决策。

### 4.3 UI 是否存在“按钮/快捷操作”机制？（事实澄清）

- WebUI 确实存在按钮与事件处理（例如 Q4H panel / input send/stop 等），从架构上并不排除新增“恢复模式”按钮。
- 但“供 agent 使用的按钮/快捷操作”要成立，必须满足：
  - UI 能把按钮点击转换成对话输入或 tool call（例如自动注入一段可执行的工具调用请求）；
  - 或后端/driver 能在黄/红时触发强制恢复流程（这更像运行时策略，不依赖 UI）。
- 因此下一轮可以先只做系统提示层的硬默认动作；若仍不稳，再考虑 UI/driver 层引入“恢复模式”交互。

### 4.4 文档同步（context health）

- `dominds/docs/context-health.md`：以 v2 remediation 为语义基准更新：
  - 删除旧的 owned reminder owner + countdown + auto-new-round 描述。
  - 记录新机制：role=user 非持久化注入、`caution` 10-turn cadence、`critical` forced-clear loop、Q4H(kind) 升级与 suspended 语义。

---

## 5. 风险与回滚
