# Progress

- [owner:@ux] 已创建 `goals/constraints/progress` 三段骨架。
- [owner:@ux] 已落地 P0 修复：用 driver 内建的 internal prompt 能力稳定触发 priming 的“综合提炼（distillation）”，并避免对话转录/存储被空 prompt 或“伪用户消息”污染。
  - Runtime/driver：`dominds/main/llm/driver.ts` 为 `HumanPrompt` 新增 `persistMode?: 'persist' | 'internal'`；`internal` 模式不写入 `prompting_msg`、不持久化、不触发 tellask 解析，但会在本次 drive 的 LLM 上下文末尾注入一条临时 `environment_msg`（role=user）。
  - Priming：`dominds/main/agent-priming.ts` 的 distillation 用 `driveDialogStream(..., { persistMode: 'internal', skipTaskdoc: true, content: <distill directive> })` 显式锚定为“综合提炼”，并确保 distillation 不受具体差遣牒注入影响；输出要求为 6~12 条结论 bullet 且禁止元话语。
  - Docs：`dominds/docs/dominds-agent-priming.zh.md` 与 `dominds/docs/dominds-agent-priming.md` 已补充 internal prompt + distillation 跳过 Taskdoc 的实现说明与约束。
- [owner:@ux] 已按反馈移除“fallback note / fallbackEntry + 继续对话”的降级路径：priming 失败恢复为 fatal interrupt（对话置 `interrupted` 并输出错误 bubble）；调度层仅吞掉 promise rejection 以避免 unhandled rejection（不产出任何 fallback 内容）。

复查要点（新对话复查必看）：
- internal prompt 不得出现在对话历史/持久化存储/前端可见消息中（只能影响本次 drive 的 LLM 上下文）。
- priming distillation 不应再通过空 prompt 触发（避免持久化空 `prompting_msg`）。
- distillation drive 不应注入 Taskdoc（避免不同差遣牒浸染 priming note/prefixMsgs）。
- internal prompt 的注入顺序：应位于“支线回复注入（sideline responses）”之后，从而作为最后一条 user-turn 指令锚定 distillation。
- internal prompt 可能影响 reminder 插入锚点（reminders 会插在最后一条 user message 之前）；确认 distillation 不会因此被提醒项扰动或引入额外噪音。
- `inflightByAgentId` 现在允许失败时返回 `null`：复用模式（reuse）仅在 entry 存在时回放；失败后应能通过新建“无感/跳过 priming”的对话继续工作流。

Open / 待决策：
- `fbr_effort == 0` 场景：当前实现会因缺少 FBR responses 导致 priming distillation 抛错并 fatal interrupt。需确认这是否符合预期，或是否应在 `fbr_effort==0` 时让 priming 整体可跳过（但本轮先按“失败即中断”处理）。

Next:
- [owner:@ux] 新开对话做一次端到端复查：确认 internal prompt 不落盘、不展示；distillation 输出结构稳定且以“环境结论”为主；失败时对话中断且提示用户改走“无感对话”。
- [owner:@browser_tester]（可选）在 WebUI 侧走一次创建对话→观察 priming 转录→确认无额外 user 消息污染与展示混淆。