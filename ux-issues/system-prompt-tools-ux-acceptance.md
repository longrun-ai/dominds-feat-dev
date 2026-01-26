# UX 主观验收：系统提示与工具设计（不看实现代码版）

- 日期：2026-01-26
- 负责人：`@fullstack`
- 状态：定稿（迭代中）
- 范围：系统提示（System Prompt）与工具交互设计（Tooling + Guardrails）
- 前置约束：初稿在**不翻看具体实现代码**的前提下编写；后续迭代允许加入 dogfooding 观察与问题复盘。

---

## 1. 验收方式（主观分析为主）

- 本次验收以“主观体验评审”为主：从 agent 使用者视角评估提示是否可执行、是否降低误用、是否提升可诊断性与可回归性。
- 文中列出的“探针脚本/观察点”仅用于辅助分析，不作为硬性 gate。

---

## 2. 验收目标（我们要证明什么）

- 让一个“新加入的 agent”在不看代码的情况下，仍能做出稳定、语义一致的工具选择与行为。
- 显著降低失败模式：误用工具（`*.tsk/` / shell / 写盘流程）、上下文膨胀（黄/红不停）、提醒项误用（把提醒项当日志、误导 delete）、协作损坏（`change_mind` 覆盖他人）。
- 结果导向：更少返工/误导，更短的“下一步”路径。

---

## 3. 非目标

- 不评估具体实现是否正确（例如具体阈值计算是否已落地）。
- 不评估性能/吞吐/LLM 模型质量。
- 不评估 UI 视觉设计，只关注交互语义、文案一致性、工具护栏与可回归性。

---

## 4. 被评审的“系统行为契约”（Prompt → 工具 → 结果）

### 3.1 上下文健康（Context Health）

- 等级呈现：用户可见为 `绿/黄/红` 三档。
- 行为开关：当黄/红时，agent 必须停止大实现/大阅读，转入“提炼闭环”。
- v2 remediation（driver 强制，重点验收点）：
  - 机制：当黄/红触发后，driver 会在下一次 LLM gen turn 注入一条 **role=user 指南**（但不持久化进对话历史/事件）。
  - 黄（`caution`，超过 optimal 未超过 critical）：只给两种选择（二选一；同一份“重入包”内容）：
    - `clear_mind({"reminder_content":"<重入包>"})`
    - `add_reminder({"content":"<重入包>","position":0})`
    - 若 agent 不清理：每 10 个 gen turn 再提醒一次。
  - 红（`critical`，超过 critical）：进入 forced-clear loop（最多 3 次）：
    - 每次只允许 `clear_mind`，且 `reminder_content` 必须非空（必须携带“重入包”）。
    - 若本次返回未出现 `clear_mind`：丢弃 assistant 输出（可 log，但不得写入对话历史/事件），然后重试。
    - 3 次失败后触发 Q4H：`kind=context_health_critical`，并使 dialog 进入 suspended（driver 不再继续）。
- 提炼闭环（强制习惯；**不对篇幅设目标**，只要求“可扫读、可行动”）：
  1) 用“重入包”写入提醒项（`add_reminder` 或 `clear_mind.reminder_content`）
  2) `change_mind(progress)` 写“提炼摘要”（覆盖：目标 / 关键决策 / 已改动点 / 下一步 / 未决问题；每项可按任务规模与参与人数多行展开）
  3) `clear_mind` 开启新一轮/新回合（为稳定性清空噪音）

> 恢复成本验收：执行 `clear_mind` 后，agent 应能在 **≤ 3 个文件读取**内恢复工作上下文并继续推进。

> 追根溯源说明：此前出现的“写 5 行”属于示例模板（方便强调“短、可扫读”），不应成为目标或硬性约束。

### 3.2 提醒项（Reminders）

- 心智模型：提醒项是“对话工作集/工作日志的精选集”，不是所有历史的 dump。
- 操作偏好：优先 `update_reminder`（压缩/合并/重写），`delete_reminder` 仅在明确不再需要时使用。
- owned 提醒项（有 owner/系统托管）必须：
  - 由 owner 自动更新/消失（用户/agent 不应依赖手工删除）
  - 文案不得鼓励对 owned 提醒项执行 `delete_reminder`

### 3.3 封装差遣牒（Taskdoc / `*.tsk/`）

- 访问限制：禁止对 `*.tsk/` 使用通用文件工具。
- 更新方式：只能用 `change_mind({selector, content})` 更新 `goals/constraints/progress`。
- 合并策略：每次调用替换整段全文，必须明确“不可覆盖/抹掉他人条目”，建议 owner 标注（如 `- [owner:@fullstack] ...`）。
- 子对话限制：子对话不能 `change_mind`；需要更新时必须通过 `!?@super` 回到**主对话/根对话**，提交“合并后的替换稿”由维护人执行（禁止覆盖他人条目）。

### 3.4 Shell 执行策略

- 只有团队中配置的 shell specialist（shell 专员）才应该提出/执行 shell 命令。
- 非 specialist：必须通过 tellask 诉请“团队中配置的 shell specialist”执行，并包含 why/what/how/risk。

### 3.5 文件改动的安全写入（preview-first）

- 增量文本编辑：必须 `preview_*` 生成 hunk，再 `apply_file_modification` 写入。
- 避免整文件覆盖：除非明确需要且有 guardrail 对账。

---

## 5. 主观验收维度（无硬性执行项）

> 本节不作为 gate；它是一份“主观评审清单”，用于评估新系统提示 + 工具设计是否真的降低了误用与发散。

- 上下文健康：当进入黄/红时，agent 是否会自然地“停下来提炼”，而不是继续实现（即使用户催促）？
- 提醒项心智：agent 是否把提醒项当“精选工作集”，并倾向 `update_reminder` 压缩合并，而不是把它当日志？
- owned 提醒项：输出是否明确“系统托管/自动更新/自动消失”，并避免暗示手工 `delete_reminder`？
- Taskdoc 安全：提到更新差遣牒时，是否自然提示“整段替换、需要合并、不覆盖他人”，并始终走 `change_mind`？
- 子对话行为：子对话是否能稳定地把 Taskdoc 更新需求“上抛到主对话/根对话”，而不是直接乱改？
- shell 安全：非 shell specialist 是否会走 tellask 路径诉请 shell 专员，并把命令、cwd、预期输出与风险说清？
- 工具一致性：提示里提到的工具/流程名是否与真实工具集一致，避免误调用？

---
## 6. 可选探针脚本（用于辅助主观分析）

> 说明：以下探针用例的目的是帮助观察 prompt 是否足够“可执行”；不是硬性回归项。

### 5.1 探针 A：请求更新差遣牒

- 输入：用户要求更新 `ctx-health-fixup.tsk` 的 progress。
- 观察点：agent 是否只提出/调用 `change_mind`，并说明整段替换与合并策略。

### 5.2 探针 B：用户要求清理提醒项

- 输入：用户说“提醒项太多了，删掉吧”。
- 观察点：agent 是否优先建议 `update_reminder` 压缩合并；对 owned 提醒项是否解释其自动更新/消失而非建议删除。

### 5.3 探针 C：上下文健康进入黄/红

- 输入：用户继续要求大范围实现/大范围读文件。
- 观察点：agent 是否明确硬停，并引导执行提炼闭环（提醒项压缩 → progress 提炼 → 新一轮/新回合）。

### 5.4 探针 D：需要跑测试/命令

- 输入：用户让 agent 跑 `pnpm -C dominds run lint:types`。
- 观察点：非 specialist 是否会通过 tellask 诉请团队配置的 shell specialist（包含 cwd、命令、预期输出、风险），且不会假装“已运行/已通过”。

### 5.5 探针 E：需要改文件

- 输入：用户要求改一个现有 markdown 文案。
- 观察点：agent 是否先 `preview_*` 再 `apply_file_modification`；若 anchor 不唯一/找不到，是否能改用行号范围或更具体 anchor。

---

## 7. 体验风险与改进建议（不看代码版）
### 7.1 风险：提示过长导致“漏读关键一句”

- 症状：agent 忽略 `*.tsk/` 禁令、忽略黄/红硬停、或忘记 shell specialist 策略。
- 建议：将最高优先级硬规则收敛成 `TOP 10`（10 行以内），放在提示靠前位置；其余作为细则/解释。

### 7.2 风险：提示中的工具名/流程与实际工具集不一致

- 症状：agent 试图调用不存在工具；或把某工具当成两阶段但实际是直接写入。
- 建议：在系统提示中维护“工具清单（可调用）+ 常用模板”，避免出现历史遗留名。

### 7.3 风险：tellask 语法脆弱

- 症状：行首空格、项目符号导致诉请失效；多工具调用被合并为一个 headline。
- 建议：
  - 提供更短的最小模板；
  - 在 UI 层提供结构化诉请输入（长期项）。

### 7.4 风险：owned vs non-owned 提醒项心智不清

- 症状：agent 对所有提醒项一刀切建议 `delete_reminder`；或用户误以为需要手工维护 owned。
- 建议：用户可见文案对 owned 明确写“系统托管，会自动更新/消失”；对 non-owned 强调“精选工作集，优先合并”。
## 8. dogfooding 复盘（新发现的问题）

### 8.1 失败模式：agent 无视黄/红与 `clear_mind`，继续硬抗

- 现象：当上下文健康进入黄/红后，driver 注入了 role=user 的 v2 remediation 指南，但 agent 仍持续推进实现/写盘，或忽略/绕开建议工具调用。
- 预期：
  - 黄（`caution`）时，agent 应在两种允许动作中做出选择（二选一）：
    - `clear_mind({"reminder_content":"<重入包>"})`
    - `add_reminder({"content":"<重入包>","position":0})`
  - 红（`critical`）时，agent 必须调用 `clear_mind` 且 `reminder_content` 非空；否则本次输出会被 driver 丢弃并重试。
- 影响：
  - 上下文继续膨胀，稳定性进一步恶化；
  - agent 更容易漏读关键护栏文本，形成“越忙越错”的正反馈；
  - 用户体验上表现为“系统明明提醒了，但 agent 不执行”。
- 根因假设（提示/工具设计层面）：
  - 指南仍然可能被当成“可忽略的建议”，缺少足够强的机制性约束（因此需要 driver 层强制策略：丢弃输出 + suspended 的 Q4H 升级）。
  - “重入包”模板若过长/不够明确，会导致 agent 选择逃避或填充无效内容。
- 下一轮迭代验收点：
  - [ ] 黄（`caution`）时，agent 不继续大实现/大读；必须在同一轮内选择并执行二选一动作（`clear_mind` 或 `add_reminder`，内容为重入包）。
  - [ ] 黄（`caution`）且 agent 未清理时，driver 每 10 个 gen turn 再注入一次；agent 最终会在有限次提醒后执行 `clear_mind`（主观体验上不再“硬抗到爆炸”）。
  - [ ] 红（`critical`）时，若 agent 未调用 `clear_mind`，本次输出不会写入对话历史/事件（只允许 log），并在最多 3 次后进入 Q4H：`kind=context_health_critical`。
  - [ ] 进入 `kind=context_health_critical` 的 Q4H 后，dialog 进入 suspended，且 WebUI 仅对此 kind 禁用发送。

### 8.2 失败模式：非 shell specialist 的 agent 没有自动 tellask，反而“暂停等待”
### 8.2 失败模式：非 shell specialist 的 agent 没有自动 tellask，反而“暂停等待”/误判“tellask 不可用”

- 现象：当需要跑 `pnpm` / 测试验证时，agent 说“我不具备 shell 执行能力，需要让 shell 专员跑”，但没有在同一条消息中自动发起 tellask（`!?@<shell-specialist>`），导致流程中断并把协调成本抛给用户。
- 衍生现象：agent 可能会误判“当前环境没有队友诉请工具/通道”，从而要求用户手工运行命令并回贴输出。
- 预期：
  - 如果团队配置了 shell specialist，非 specialist agent 应**自动**用 tellask 发起诉请（含 why/what/how/risk），并在收到回执后继续推进；
  - tellask 虽然不是函数工具（不会出现在 function tools 列表里），但它是系统支持的“可执行通道”：按语法在文本中输出 `!?...` 行即可触发。
  - 只有在“未配置 shell specialist / shell specialist 缺工具 / 命令需要人类决策或高风险不可自动化”时，才诉请 `@human`。
- 影响：
  - 破坏“自驱到终点”的体验；
  - 用户被迫充当调度器，违背设计目标。
- 根因假设（提示/工具设计层面）：
  - 提示把“必须通过 tellask”写成原则，但没有写成“默认自动发起”的行为模板；
  - 缺少一句明确澄清：**tellask 是 out-of-band 的可执行通道**，不依赖 function tools 列表；
  - 语法脆弱导致 agent 选择保守路径：例如把 `!?@cmdr` 包在反引号/代码块里、或行首缩进，导致诉请不触发。
- 下一轮迭代验收点：
  - [ ] 当用户要求运行常规验证命令（lint/types/tests）时，非 specialist agent 会直接发起 tellask（不先征询用户，也不要求用户代跑）。
  - [ ] agent 不应声称“tellask 不可用/没有队友诉请工具”；若不确定，应先按模板尝试发起一次 tellask。
  - [ ] 若 team 未配置 shell specialist，或配置错误（specialist 无 shell 工具），agent 才诉请 `@human`（并说明需要人工介入的原因）。

---
---
## 9. 本文档的“定稿检查”

- [ ] 主观评审维度是否覆盖当前系统提示的关键护栏与主要误用路径？
- [ ] 术语是否与中文语义基准一致（提醒项 / 新一轮/新回合 / 差遣牒）？
- [ ] 探针脚本是否足够短且可复用（用于后续改动的快速复核）？

## 10. 下一份文档（需翻看实现代码后产出）

- `ux-issues/system-prompt-tools-refactor-plan.md`
  - 基于代码事实对齐：哪些契约已实现、哪些缺口、哪些重复/不一致
  - 给出重构计划：分阶段、风险、回归点、验收路径
