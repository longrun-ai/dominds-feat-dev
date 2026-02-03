# Prompts / System Prompt Issues

维护人：@prompt

目标：把“当前环境系统提示”的问题与决策落盘，形成可执行的修正清单与回归点。

## 决策（已确认）

1. **中文系统提示必须补齐“多人集体诉请（collective teammate tellask）”规则**，且英文版与之语义对齐。
2. 历史上的“诉请工具 / tellask tools”已取消：最新版 `!?@...` 仅用于 **队友诉请** 与 **Q4H（`!?@human`）**。
   - 任何“看起来像工具调用”的文案/示例（如 `!?@tool_a`）必须彻底移除，不留历史痕迹。
3. 参考 `codex-rs/` 的 `codex-cli`：在 `codex_style_tools` 中增加 `update_plan` 工具，并将其语义映射为 Dominds 的 reminder 操作。
4. Dominds 支持暴露内部推理过程：若 provider 对 thought streaming 支持不足/欠佳，需要提出整改方案并修正。
5. **命名与分层原则：实现层禁止出现 `tool_call*` 字眼**。
   - 仅允许在 **LLM API / provider 适配层** 使用 `tool_call`（因为这是各家模型/SDK 的既有术语）。
   - Dominds 自己的实现层（事件类型/持久化记录/前端处理/注释/文档）必须改用语义更精确的命名：
     - `teammate_call_*`：指 **队友诉请（tellask）块** 及其相关事件。
     - `function_call_*`：指 **function tools 执行** 及其相关事件。
6. **Q4H（`!?@human`）使用原则：不外包执行，但允许请求最小必要输入**。
   - `@human` 是特殊成员：只用于向人类用户提问以获取**必要的澄清/决策/授权/缺失输入**，或汇报当前环境中**无法由智能体自主完成**的阻塞点。
   - 禁止把可由智能体完成的执行性工作外包给 `@human`；对 `@human` 的请求应尽量**最小化、可验证**（给出所需信息的明确格式/选项/约束），拿到答复后继续由智能体完成后续工作。
   - 该原则必须 **zh/en 语义对齐**，避免语言切换导致行为漂移。

   建议替换系统提示中的“团队目录/Team Directory”相关段落为如下**规范文案**（仅记录口径，不规定具体实现方式）：
   - 推荐系统提示文案（zh）：

     ```plain-text
     **特殊成员**：人类（@human）是特殊团队成员。你可以使用 `!?@human ...` 发起 Q4H（Question for Human），用于请求必要的澄清/决策/授权/提供缺失输入，或汇报当前环境中无法由智能体自主完成的阻塞事项。
     **注意**：不要把可由智能体完成的执行性工作外包给 @human。向 @human 的请求应尽量最小化、可验证（给出需要的具体信息、预期格式/选项），并在得到答复后继续由智能体完成后续工作。
     ```

   - Recommended system prompt copy (en):
     ```plain-text
     **Special member**: Human (@human) is a special team member. You may use `!?@human ...` to ask a Q4H (Question for Human) when you need necessary clarification/decision/authorization/missing inputs, or to report blockers that cannot be completed autonomously in the current environment.
     **Note**: Do not outsource executable work to @human. Keep Q4H requests minimal and verifiable (ask for specific info, expected format/options), then continue the remaining work autonomously after receiving the answer.
     ```

7. **使用者语境的叙事口径：避免“父/子/主/根对话”**。
   - 原则：在面向使用者（对话的主理人智能体）的文案/提示词中，不应暴露实现层的层级术语（父对话/子对话/主对话/根对话）。
   - 推荐改用“从使用者视角可理解、可操作”的术语来描述机制与行为：
     - **诉请人**：发起诉请的一方（来源对话的主理人智能体）。
     - **被诉请人**：被点名的目标（队友智能体、`@human`，或回问目标）。
     - **来源对话**：诉请从哪个对话发起（用于定位上下文与回链）。
     - **原始对话**：需要汇总结果/需要继续推进的对话（用于解释结果将“回到哪里”）。
   - 仅在“技术实现说明”小节中，才允许使用 `rootId` / `RootDialog` / root dialog 等术语辅助读者理解。
   - 术语表可能需要同步更新：尤其是 `!?@super ...` 的 `super` 关键词会带出“父/上级”语感，后续可评估是否要换成更贴近“回问/回呼/回报”语义的关键词。

8. **中文用词统一：文案中的“代理”应改为“智能体”**。
   - 默认口径：中文对外文案统一使用“智能体”；“代理”仅在引用外部资料或行业惯用译法且确有必要时保留。
   - 对“用户”的表述按上下文选择：
     - “用户（通常是智能体）”
     - “人类用户”

9. **Collective teammate tellask 语义口径：同一诉请块自然支持多目标（一对多拆分）**。
   - 现状问题：系统提示中存在“默认单目标 + 例外模式”的表述，且中文混入英文（headline/headLine/callBody/collective targets 等），不符合词汇表口径。
   - 正确口径：单个诉请块从语义上就允许多个目标；这不是例外模式，而是同一语法的自然行为。
   - 推荐改写为：
     - 当同一条诉请块的**诉请头**（Tellask headline/诉请头，含多行诉请头）中出现多个队友呼号时，Dominds 会将其视为“一对多诉请”，并对每个目标队友进行**一对多拆分**（生成多条队友诉请；诉请头与诉请正文保持一致）。
     - 若诉请头包含 `!tellaskSession <slug>`，它最多出现一次，并对所有被拆分的目标队友生效。
   - 中文中避免混入非必要英文：使用术语表中的中文对照（headline→诉请头等）；“扇出”建议替换为更自然的“一对多拆分”。

## 当前状态（观察到的实现变更，待验收）

说明：本项是对当前工作区 `dominds/` 里已出现的改动做的观察记录（未必已过 lint/test）。

- `dominds/main/minds/system-prompt.ts`：已补齐中文 collective teammate tellask 规则；已移除 `!?@tool_a`/`!?@tool_b` 示例；已清理英文 “tellask tools”。
- `dominds/main/tools/plan.ts`：新增 `update_plan` function tool，将 plan 写入/更新到 reminders（用 meta.kind='plan' 做幂等定位）。
- `dominds/main/tools/builtins.ts`：`codex_style_tools` 已包含 `update_plan` 且 toolset prompt 已补充说明。
- `dominds/main/dialog.ts`、`dominds/main/shared/types/dialog.ts`、`dominds/webapp/src/components/dominds-dialog-container.ts`：注释术语基本已收敛为“tellask call block（`!?@...`）”与“function calls（工具执行）”两类；WebUI 中残留的泛称 “tool calls” 旧措辞已修正为更精确的 “teammate-call / function tool call”。
- `dominds/main/llm/gen.ts`、`dominds/main/llm/gen/openai.ts`、`dominds/main/llm/gen/codex.ts`、`dominds/main/llm/driver.ts`：出现对 thought/streaming 异常的 `streamError` 上报链路（用于暴露/诊断子流重叠等问题）。

## 发现的问题（带定位）

### A) Dominds runtime 系统提示（注入给 agent 的那份）

- **中文缺失 collective teammate tellask 规则**：英文版包含“headline 中多个队友呼号 → 扇出到多个队友”的规则（`dominds/main/minds/system-prompt.ts:241`），中文版本未覆盖。
- **中文重复段落**：`!?@super` 说明在中文版本重复出现两次（`dominds/main/minds/system-prompt.ts:151`、`dominds/main/minds/system-prompt.ts:152`）。
- **示例呈现出“工具调用倾向”**：系统提示示例中使用 `!?@tool_a`（`dominds/main/minds/system-prompt.ts:111`、`dominds/main/minds/system-prompt.ts:119`、`dominds/main/minds/system-prompt.ts:276`）。这会把“队友诉请”误导成“工具调用”。

### B) 代码/类型注释残留“!?@tool_name = 工具调用”说法（已修复）

已修正：实现层注释不再使用 `!?@tool_name` 作为“工具调用”示例；并收敛为 “tellask call block / teammate-call / function tool call” 的精确口径。

### C) 文档残留“诉请工具”说法

- `dominds/docs/dialog-system.md:1039`：出现 “teammate Tellask tools” 表述，需改为“teammate tellask capability / teammate tellask mechanism”等不含 tools 的措辞。

### D) Codex provider 与工具契约

- `codex_style_tools` 目前只包含 `apply_patch` + `readonly_shell`（`dominds/main/tools/builtins.ts:219`），但 Codex 侧 base prompt 强依赖 `update_plan`（例如 `dominds/codex-auth/prompts/gpt_5_2_prompt.md:38`）。
- `codex-rs` 的 `update_plan` schema（来源：`codex-rs/core/src/tools/handlers/plan.rs:39` 起）：
  - 参数：`{ explanation?: string, plan: Array<{ step: string, status: "pending"|"in_progress"|"completed" }> }`
  - `plan` 必填；不允许额外字段；最多一个 `in_progress`。

## 建议修正（给 @fullstack 落盘）

### 1) 修正 `dominds/main/minds/system-prompt.ts`

- 为中文版本补齐与英文一致的 collective teammate tellask 规则（建议直接把英文 `:241` 的语义翻译进中文同位置）。
- 删除中文 `!?@super` 重复条目，保留一个规范版本即可。
- 全面替换 `!?@tool_a` / `!?@tool_b` 等示例为真实队友呼号（例如 `!?@pangu`、`!?@ux`、`!?@cmdr`），并明确“`!?@...` 仅是队友诉请/Q4H，不是工具调用”。

### 2) 清理文档 `dominds/docs/dialog-system.md`

- 将 “teammate Tellask tools” 替换为不含 tools 的表述，避免误导。

### 3) 在 `codex_style_tools` 增加 `update_plan`

- 新增 `FuncTool`：`name: "update_plan"`，参数 schema 对齐 `codex-rs`。
- 行为建议（“映射为 reminder 操作”）：
  - 将 plan 渲染成一段稳定格式文本（包含可选 explanation + 列表），写入/更新一个“Plan”提醒；
  - 用 `meta` 标记（例如 `{ "kind": "plan" }`）以便幂等查找与更新；
  - 位置建议固定在 reminders 顶部（position=1 的 UI 视觉第一条）或末尾（需与 UX 约定）。

### 4) 内部推理（thought streaming）整改

- 目标：provider 能可靠产生并传输 “thinking/thought” 子流；WebUI 能稳定展示（并遵守单子流不重叠的事件序约束）。
- 建议由 @fullstack 结合现有流式协议实现评估：若 codex provider 或其他 provider 在 thought 子流上缺失/不稳定，给出补丁方案（协议字段/事件类型/前端渲染）。

## 回归清单（最小可复现）

1. **Collective teammate tellask**：在同一条诉请 headline 中放多个队友呼号，验证会 fan-out 成多个队友诉请且 `!tellaskSession` 仅出现一次时可对所有目标生效。（运行态已验收：`!?@ux @cmdr !tellaskSession collective-fanout-verify`；@cmdr/@ux 均回贴收到，且观察到 `tellaskSession=collective-fanout-verify`、targets=`@ux,@cmdr`）
2. **示例净化**：注入的系统提示中不再出现 `!?@tool_a` 这类“工具样式”的示例。
3. **文案净化**：全 repo 不再出现 “tellask tools / 诉请工具” 残留表述。
4. **Codex update_plan**：`codex_style_tools` 列表中出现 `update_plan`；调用一次后能在 reminders 中看到 plan 更新。
5. **Thought streaming（可选/可延后）**：同一代 `genseq` 内 thinking/saying 子流不重叠；WebUI 按到达序渲染。

## 新发现的问题（待修复）

### E) 实现层仍残留 `tool_call_*` 命名（需要一次性清理，不留历史痕迹）

目标：把 Dominds 实现层里所有 `tool_call_*` 相关命名（事件/记录/注释/文档）全部替换为：

- `teammate_call_*`：队友诉请（tellask）块及其 streaming 事件
- `function_call_*`：function tools 执行及其事件/持久化

注意：本项 **不做任何向后兼容**。按最新最优方式改完后，直接删除所有历史记录（例如清空 `./.dialogs/` 及 `ux-rtws/.dialogs/`）即可。

建议修复（给 @fullstack 的“该改什么/改成什么”清单，不涉及实现细节）：

- **Streaming tellask 块事件**：将 `tool_call_*_evt` 全部改为 `teammate_call_*_evt`（含 start/headline/body/finish 等）。
- **Inline 结果事件/记录**：把当前用于“把结果贴回同一 bubble”的 `tool_call_response_evt` / `tool_call_result_record` 改为 `function_call_response_evt` / `function_call_result_record`（或等价命名，只要语义对齐“function tools 的结果”）。
- **函数执行事件**：当前 `func_call_*` / `func_result_*` 建议统一为 `function_call_*` / `function_result_*`（避免缩写，并与上面原则一致）。
- **注释与文案**：实现层不再出现 “tool call(s)” 作为泛称；用 “teammate call（tellask）” 与 “function call（function tool）” 做精确区分。

- **清理 `receiveToolResponse` / `ToolCallResultRecord` 遗留（不留痕迹）**：
  - 若实现中仍存在 `receiveToolResponse` / `ToolCallResultRecord`（或其改名残留），应当按语义做**二选一**：
    1) **改名并收敛为 function tools 语境**：将其改为 `FuncCall*` / `FuncToolResponse*` 等明确指向 function tools 的命名（避免让读者误以为 tellask 是工具调用）。
    2) **直接删除该路径**：若该路径仅用于历史兼容/可被其他事件（如 function call/result 事件）替代，则删除实现与文案，不留历史痕迹。
  - 目标：实现层不再出现“ToolCall/ToolResponse”这类容易混淆的命名；仅 LLM API/provider 适配层允许保留 `tool_call` 既有术语。

### F) WebUI 注释仍残留泛称 “tool calls”（已修复）

已修正：`dominds/webapp/src/components/dominds-dialog-container.ts` 中的注释与错误提示不再使用泛称 “tool call(s)”。

- `dominds/webapp/src/components/dominds-dialog-container.ts:74`
- `dominds/webapp/src/components/dominds-dialog-container.ts:78`
- `dominds/webapp/src/components/dominds-dialog-container.ts:80`
- `dominds/webapp/src/components/dominds-dialog-container.ts:1175`
- `dominds/webapp/src/components/dominds-dialog-container.ts:1561`
