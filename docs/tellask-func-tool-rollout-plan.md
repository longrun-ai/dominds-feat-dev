# Tellask 迁移为“特殊函数工具通道”落地计划

## 0. 当前状态（2026-02-11）

1. `func_result`“临时态 -> 正式态替换”已做前置实测验证（`codex-auth` / Responses API 探针），并确认可行。
2. 探针结论固化：同一 `call_id` 采用“上下文组装时动态投影 + 每轮仅一个有效 result”可稳定工作。
3. v1 driver 已删除，`driver-entry` 固定 v2，v1 parity/engine-switch 脚本已移除。
4. driver-v2 tellask-special 通道已落地：`tellaskBack` / `tellask` / `tellaskSessionless` / `askHuman`。
5. tellask-special 执行入口已重构为函数参数直驱（`mentionList + tellaskContent + callId + callKind`），不再保留 `firstMention/tellaskHead` 形状。
6. 语义分流已完全由函数名决定；不再依赖 `tellasker/human` 特殊 id。
7. 协议字段已收敛为 `mentionList + tellaskContent`；`tellaskHead` 已从运行时主链路移除。
8. `tellasker streaming parser` 及 `!?@...` 文本诉请链路已彻底删除（含 `main/tellask.ts`、diag parser 工具、对应专项测试）。
9. 提示词与模型可见文案已收敛到函数工具语义，不再出现 `!?@...` 文本诉请语法。
10. 关键验证已通过：`lint:types`、`driver-v2:integration`、`tellask:typeb-registered-dedupe`。

## 1. 目标与边界

### 1.1 目标

将当前 tellask 诉请语法（`!?@...`）迁移为模型原生函数调用入口，核心目标：

1. 让原生支持 function/tool calling 的模型更稳定地产生正确诉请调用。
2. 保留 tellask 编排语义（并发、互斥锁、可挂起与恢复、支线生命周期）而非降级为普通工具执行。
3. 统一协议语义：tellask 系列进入“特殊工具通道”，由 tellask-special executor 处理，不再依赖文本 parser 入口。

### 1.2 已确认决策（按你的结论固化）

1. 不使用 generic `executeFunctionCalls` 执行诉请；诉请由 tellask-special executor 独立处理（已移除 parser 入口 `executeTellaskCalls`）。
2. 保留 `tellaskBack`，Type A 回问改为独立函数，不再依赖特殊 target id。
3. 前端与深链单独改造，不复用现有函数调用 UI。
4. 历史兼容可放弃（旧记录可丢弃/不迁移）。
5. tellask 仍并发执行，互斥锁机制保留。
6. `func_result` 采用“动态注入临时态 -> 后续替换为正式态”技术路线。
7. tellask 家族函数拆分：`tellaskBack`、`tellask`、`tellaskSessionless`、`askHuman`。
8. v1 driver 可删除，迁移基于 v2。
9. `callId` 统一来自模型函数调用 `call_id`。
10. `tellasker streaming parser`（含 `!?@...` 行语法解析与相关回放路径）本次直接删除，不保留兼容层。
11. 不再使用 `tellasker` / `human` 特殊 id 进行语义分流，统一由函数名区分语义与执行路径。
12. `tellaskBack` 能力仅在 FBR 的“技术性禁用函数工具”场景下受限；在正常支线（函数工具可用）中保持完整可用。

### 1.3 非目标

1. 不做兼容层（无双轨语法，无旧协议 fallback）。
2. 不追求局部最小 diff；按前后端一体一次改到位。

## 2. 总体方案

### 2.1 架构策略

1. 输入侧：提示词与工具定义引导模型输出 tellask 系列 function call。
2. 执行侧：在 driver-v2 中识别 tellask 系列函数，走专用 tellask-special executor。
3. 上下文侧：不持久化“临时 `func_result`”，仅在组装上下文时按 pending 状态动态注入。
4. 展示侧：前端仍用 tellask 专属 UI/事件链路，不复用 generic function-call 组件。
5. 语义分流：Type A/B/C/Q4H 均由函数名决定，不再通过 `@tellasker` / `@human` 这类特殊 mention 解析。
6. 能力边界：FBR 若因策略进入“禁函数工具”模式，将连带无法发起 `tellaskBack`；除此之外不损失回问能力。

### 2.2 `func_result` 动态注入（核心）

1. 为每个 tellask call 维护运行态：
   - `pending`: 已发起，支线未最终反馈。
   - `settled`: 已有最终反馈。
2. 每次发起 LLM 请求前，组装 context 时做“有效结果投影”：
   - `pending` -> 注入临时 `func_result`（文本如“支线对话仍在进行中，已持续 xxx”）。
   - `settled` -> 注入正式 `func_result`。
3. 同一 `call_id` 在同一轮请求上下文中只出现一个“有效 result”（避免重复 result 的 provider 兼容风险）。
4. 临时结果不落盘；最终结果按现有持久化路径落盘。
5. Responses API 前置验证已通过，但正式改造后仍需纳入回归矩阵（防止 provider 行为变更）。

## 3. 分层改造清单

## 3.1 LLM/Driver（v2 only，先做）

1. 删除/下线 v1 driver 入口与依赖引用，确保运行时只走 v2（作为第一步）。
2. 在 v2 tool call 分发中新增 tellask-special channel：
   - tellask 家族函数命中后，不进入 generic `executeFunctionCalls`。
   - 转入 tellask-special executor，保留 suspend/subdialog/queue 编排语义。
   - 由函数名直接选择分支：`tellaskBack`(Type A)、`tellask`(Type B)、`tellaskSessionless`(Type C)、`askHuman`(Q4H)。
3. `callId` 映射策略：
   - 统一使用模型提供的 `call_id` 作为跨层关联主键。
   - 移除 tellask 语法时代的本地 callId 生成路径。
4. 并发与互斥：
   - 继续使用现有锁机制，确保并发 tellask 与恢复流程互不踩踏。

## 3.1.1 v1 删除范围（显式清单）

1. 删除 `main/llm/driver.ts` 及其所有直接引用。
2. 删除 `driver-entry` 中 v1/v2 切换逻辑，入口固定到 v2。
3. 删除测试中所有 v1 parity / engine-switch 脚本与用例。
4. 清理文档中“可切换到 v1”的描述，统一为 v2 基线。

## 3.1.2 tellasker streaming parser 删除范围（显式清单，已完成）

1. 已删除 `TellaskStreamParser` 与 `!?@...` 行语法解析依赖链。
2. 已删除仅用于该 parser 的流式事件桥接代码与对应测试。
3. tellask 触发入口已统一为函数工具调用，不再接受文本诉请语法作为调用通道。
4. 历史解析兼容、回放兼容不保留（按既定决策执行）。

## 3.2 tellask 函数定义与参数约束

1. 新函数集合：
   - `tellaskBack`
   - `tellask`
   - `tellaskSessionless`
   - `askHuman`
2. 各函数参数 schema 采用严格 JSON Schema（`strict: true`），避免 `any` 形态输入。
3. 参数语义直接对应当前 tellask 业务字段，避免额外抽象层。
4. 对参数不合法场景“响亮失败”，返回结构化错误并发可观测事件。

## 3.3 上下文组装与持久化

1. 在 context assembly 层新增 tellask pending projection：
   - 读取当前活跃支线运行态。
   - 计算每个 `call_id` 的单一“有效 result”。
2. 持久化策略：
   - 临时结果：不持久化。
   - 正式结果：按 `func_result_record` 或 tellask result record 正常落盘。
3. 恢复策略：
   - 进程重启后 pending 态由支线状态重建。
   - 首轮恢复请求仍可重新生成临时结果（基于 elapsed now - startedAt）。

## 3.4 协议事件与前端

1. 保留 tellask 专属事件流（`teammate_call_*` / `teammate_call_response_evt` 等）。
2. 补充 pending 展示状态：
   - “进行中 + 持续时长”可视化。
   - 最终反馈到达后替换显示。
3. 深链协议升级：
   - 旧 tellask 行文 deep link 可直接废弃。
   - 新 deep link 直接携带函数化 call 标识或必要上下文参数。
4. 前端不接入 generic function-call 组件，避免语义混淆。

## 3.5 Prompt 与语义规范

1. system prompt 移除 tellask 诉请语法说明。
2. 明确 tellask 家族函数的使用条件、参数字段、并发行为（含 `tellaskBack` 仅用于回问上游对话）。
3. 明确 FBR 特例：若当前回合策略禁用函数工具，`tellaskBack` 属于已知技术性不可用能力，并在提示词中显式告知。
4. 对 `askHuman` 给出触发规则（何时必须回到人类）。
5. zh 语义为基准，同步 en 文案，不反向翻译 zh。

## 3.6 测试体系

1. 单元：
   - tellask 函数参数校验与错误路径。
   - pending/settled 上下文投影算法（同 `call_id` 单结果保证）。
2. 集成（driver-v2）：
   - 多 tellask 并发。
   - 支线未完成时主线继续对话。
   - 后续支线完成后上下文替换正确。
3. 前端：
   - pending 到 settled 的 UI 替换。
   - callId 关联一致性（`teammate_call_finish_evt` -> `teammate_call_response_evt`）。
4. Provider 兼容：
   - Chat Completions / OpenAI-compatible / Anthropic / Responses API 全链路回归。

## 4. 关键技术风险与对策

### R1. Responses API 对同一调用“临时后正式”接受度不清晰

风险：若同一 `call_id` 在历史中出现多条 output，可能触发服务端校验失败或行为不稳定。  
对策：严格执行“每次请求只呈现单一有效 result”，通过动态注入而非历史累计替换。

### R2. Provider 对 tool-result 邻接/顺序要求差异

风险：Anthropic 与 OpenAI-compatible 对配对顺序要求更严格。  
对策：在各 provider adapter 层统一执行配对校验，违反即 loud fail（不 silent fallback）。

### R3. 前端关联时序与并发态错配

风险：并发 tellask 下 callId 错绑导致结果串泡泡。  
对策：以模型 `call_id` 为唯一关联键，事件消费层加一致性断言并显式报错。

### R4. 删除 v1 后残留路径

风险：启动入口、测试脚本、文档仍引用 v1。  
对策：一次性删除 v1 相关代码与文档，并执行全量类型检查 + 核心回归。

### R5. 移除 tellasker streaming parser 的连锁影响

风险：前端事件、持久化回放、诊断工具中仍存在 `!?@...` 解析假设。  
对策：按“解析链路全删 + 函数调用链路全补”成对实施，禁止半迁移状态。

## 5. 分阶段执行计划

### Phase 0: 清障（最新优先级，先做）

1. 删除 dlg driver v1 与入口切换逻辑，统一 v2。
2. 跑 `lint:types` 与 driver-v2 集成脚本，确认“无 v1 残留引用”。

### Phase A: 预研与探针（已完成）

1. 在 `auth-doctor.ts` 增加 `func_result` 临时->正式替换探针。
2. 验证 Responses API 可行性并沉淀结果（结论：可行）。

### Phase B: 后端主改造（已完成）

1. v2-only 化与 tellask-special channel 接入。
2. tellask 家族函数 schema 与执行管线接入（`tellaskBack`/`tellask`/`tellaskSessionless`/`askHuman`）。
3. context 动态注入层实现 + 持久化规则重构。

### Phase C: 协议与前端（已完成）

1. 事件与深链改造。
2. tellask UI pending/settled 切换实现。

### Phase D: Prompt/文档/测试收口（已完成）

1. 提示词迁移与 i18n 对齐。
2. 测试矩阵补齐与回归。
3. 删除 tellasker streaming parser 与 `!?@...` 语法通道相关代码/测试/文档。
4. 删除废弃代码与文档清理。

## 6. 验收标准（DoD）

1. 模型在无 tellask 语法提示的情况下可稳定使用 tellask 家族函数完成诉请。
2. Type A 回问仅通过 `tellaskBack`，不再依赖 `@tellasker` 特殊 id。
3. 在正常支线（函数工具可用）中，`tellaskBack` 可用且行为正确；在 FBR 禁函数工具模式下有清晰可见的受限提示。
4. 支线未完成时主线可继续；上下文中仅有临时有效 result。
5. 支线完成后后续轮次自动呈现正式 result，且替换关系正确。
6. 并发 tellask 无 callId 串扰、无时序错配。
7. v1 代码路径已删除，类型检查与关键回归通过。

## 7. 实际执行顺序（已完成）

1. 删除 v1 driver 与入口切换（固定 v2）。
2. driver-v2 tellask-special channel + callId 统一。
3. context 动态注入实现（临时 result 注入与正式 result 替换）。
4. 前端/深链改造（不复用 generic function-call UI）。
5. 删除 tellasker streaming parser 与 `!?@...` 语法解析链。
6. prompt 与测试收口，完成 provider 回归矩阵。
