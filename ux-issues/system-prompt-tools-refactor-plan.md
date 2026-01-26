# 重构计划：系统提示与工具设计（基于代码事实）

- 日期：2026-01-26
- 负责人：`@fullstack`
- 状态：定稿
- 前置：`ux-issues/system-prompt-tools-ux-acceptance.md` 已定稿
- 目标：一次性把“提示-工具-体验”的高风险误导点修到位，并加最小防回归。
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

### 1.3 Context health owned reminder（owner 渲染/倒数）

- `dominds/main/tools/context-health.ts`
  - owner header（prompt-only + 约束语义）
  - critical 倒数 meta 校验与递减逻辑
  - `renderReminder` 将 header + content 组合输出

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

---

## 3. 重构目标（可回归的、可验证的）

- 消除“5 行”这种不该成为目标的篇幅约束；替换为“提炼摘要结构建议”（可多行，按任务规模伸缩）。
- 统一 shell specialist 的表述：
  - 系统提示里可以展示“本队 shell 专员列表”（事实），但
  - 文档/模板里用 `@<shell-specialist>` 作为占位符，避免 `@cmdr` 成为通例。
- 明确术语边界：
  - `!?@super` 继续解释为父对话（supdialog）
  - Taskdoc 更新责任明确指向主对话/根对话（并且保持“子对话不能 change_mind”的硬护栏）

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

### 4.1 让 `clear_mind` 成为黄/红时的硬默认动作

- 修改系统提示（建议位置：`dominds/main/minds/load.ts` 的记忆系统段落，或 `dominds/main/minds/system-prompt.ts` 的工具工作流段落）：
  - 明确优先级：当 context-health 为黄/红时，**禁止**继续大实现/大阅读；下一步必须是“提炼闭环”（`update_reminder` → `change_mind(progress)` → `clear_mind`）。
  - 明确允许的例外：最多允许 1 次“紧急收尾”回复（用于写入提炼/触发 tellask），但不得继续扩展实现。

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

---

## 5. 风险与回滚
