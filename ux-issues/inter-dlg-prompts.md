# Inter-Dialog 格式化文案问题分析（校对版）

> 规范声明：当本文件处于 **git 暂存版**（staged）并被标记为“最新规格”时，它就是 inter-dialog 文案/结构的契约来源。
> 运行时实际输出若与该规格不一致，应优先视为实现偏差并修正代码；只有在明确要变更规格时才改动本文件。

## 背景

在 Dominds 对话系统中，`inter-dialog-format.ts` 负责把“对话间”（inter-dialog）的结构化字段格式化为 markdown 文本，供两类用途复用：

- **驱动对话（LLM 输入）**：把“跨对话的背景/请求”包装成 `HumanPrompt.content`，作为 **`prompting_msg` / `role: 'user'`** 注入到被驱动的对话。
- **呈现结果（UI + LLM 上下文）**：把“队友响应”包装成叙事文本，作为 **`tellask_result_msg` / `role: 'tool'`** 展示给用户，并进入对话上下文。

重要：当前实现中“为什么是 `role: 'user'`/`role: 'tool'`”主要是 **Dominds 内部消息类型与持久化/UI 展示契约的选择**，而不是简单的“LLM 会忽略 `role=assistant`”或“提供商限制 `role=system`/`role=tool`”。

另外该模块存在一份前后端 twin：

- 后端：`dominds/main/shared/utils/inter-dialog-format.ts`
- 前端：`dominds/webapp/src/shared/utils/inter-dialog-format.ts`

补充：在当前本地 checkout 中，`dominds/webapp/src/shared` 是指向 `dominds/main/shared` 的符号链接，因此“前后端 twin”在物理文件层面是同一份源码；但在契约层面仍应视为双端共享模块，任何格式改动都需要通过 WebUI dev 校验点确认前后端一致。

WebUI 在 dev 模式会对部分格式化结果做一致性校验（见 `dominds/webapp/src/components/dominds-dialog-container.ts`），因此任何文案/格式改动必须 **两边同步**。

最后校验：2026-02-02（对照实现：`dominds/main/llm/driver.ts`、`dominds/main/llm/client.ts`、`dominds/*/shared/utils/inter-dialog-format.ts`）。

## 相关文档

- `dominds/docs/dialog-system.md` - 对话系统架构与 Type A/B/C 诉请分类
- `dominds/docs/dominds-terminology.md` - Dominds 专有名词表
- `dominds/main/shared/utils/inter-dialog-format.ts` - 格式化模块源码
- `dominds/main/llm/driver.ts` - inter-dialog prompt 注入与 Type A 处理（调用 formatter）
- `dominds/main/llm/client.ts` - `ChatMessage` / `TellaskCallResultMsg` 类型（`role: 'tool'`）
- `dominds/webapp/src/components/dominds-dialog-container.ts` - DEV 下的格式化一致性校验点

## 场景分析

### 三个核心函数的用途（以代码为准）

| 函数                            | 典型调用位置                                               | 产物进入的消息类型/role（当前实现）              | 语义                                                               |
| ------------------------------- | ---------------------------------------------------------- | ------------------------------------------------ | ------------------------------------------------------------------ |
| `formatAssignmentFromSupdialog` | `dominds/main/llm/driver.ts:createSubdialogForSupdialog()` | `HumanPrompt` → `prompting_msg` / `role: 'user'` | supdialog 给 subdialog 的任务分派（assignment）                    |
| `formatSupdialogCallPrompt`     | `dominds/main/llm/driver.ts` Type A handling               | `HumanPrompt` → `prompting_msg` / `role: 'user'` | subdialog 回问 supdialog（Type A 回问）                            |
| `formatTeammateResponseContent` | `dominds/main/llm/driver.ts` 等                            | `tellask_result_msg` / `role: 'tool'`            | 把“响应正文 + 原始诉请 headline”拼成叙事文本，供 UI/LLM 上下文使用 |

### Type A 回问场景（formatSupdialogCallPrompt）

```
1. Supdialog → Subdialog-A: "任务 A，请执行" (assignment)
2. Subdialog-A 执行中遇到需要澄清的问题
3. Subdialog-A → Supdialog: "!?@tellasker 我需要澄清" (Type A 回问)
   ↑ formatSupdialogCallPrompt 处理的就是这一步！
4. Supdialog 收到回问并处理
```

**关键理解：**

- `formatSupdialogCallPrompt` 格式化的是 **Subdialog → Supdialog** 的回问消息
- 消息受众是 Supdialog（接收回问者）
- 消息背景是 Supdialog 分配给 Subdialog 的原始任务

## 问题定位

### 问题 1：`formatSupdialogCallPrompt` 的 greeting 文案

**容易产生歧义的文案模式（示例；见 `dominds/*/shared/utils/inter-dialog-format.ts`）：**

```typescript
const hello =
  language === 'zh'
    ? `你好 @${requireNonEmpty(input.toAgentId, 'toAgentId')}，在处理你最初诉请期间：`
    : `Hi @${requireNonEmpty(input.toAgentId, 'toAgentId')}, during processing your original assignment:`;
```

**歧义分析：**

- 消息是 Subdialog 发送给 Supdialog 的
- "处理**你**最初诉请"中的"你"指 Supdialog
- Supdialog 可能误理解为"处理 Supdialog 自己最初发起的请求"
- 实际语义是"处理 Supdialog **分配给 Subdialog** 的任务期间，Subdialog 发起的回问"

### 问题 2：`formatTeammateResponseContent` 的 tail 文案

**容易产生歧义的文案模式（示例；见 `dominds/*/shared/utils/inter-dialog-format.ts`）：**

```typescript
const tail = language === 'zh' ? '针对你最初的诉请：' : 'to your original tellask:';
```

**歧义分析：**

- 消息渲染给请求者（requesterId）看
- "针对**你**最初的诉请"可能让请求者困惑
- 虽然 requesterId 确实是原始请求发起者，但消息中出现三方指代时存在模糊性

## 改进建议

### 方案：明确指代（推荐）

目标是：在不引入额外前缀/身份噪音的前提下，把“你”改成更稳定的指代（例如“原始任务/该任务/该原始诉请”），减少 supdialog / requester 在三方语境下的误解概率。

同时，当“提及原始诉请/原始任务作为上下文”时，通常只包含 `tellaskHead` 即可；把 `tellaskBody` 一并重复进叙事文本会导致接收者上下文不必要膨胀。

#### 1. `formatSupdialogCallPrompt` 改进

**改进思路：**

- 避免使用第二人称“你”来指代 `toAgentId`
- 明确这是“处理 supdialog 分配的任务期间”的回问

**建议文案（示意；不引入前缀）：**

```typescript
const hello =
  language === 'zh'
    ? `你好 @${requireNonEmpty(input.toAgentId, 'toAgentId')}，在处理以下任务期间（如下引文）：`
    : `Hi @${requireNonEmpty(input.toAgentId, 'toAgentId')}, while working on the following original task:`;

const asking =
  language === 'zh'
    ? `\`@${requireNonEmpty(input.fromAgentId, 'fromAgentId')}\` 回问：`
    : `\`@${requireNonEmpty(input.fromAgentId, 'fromAgentId')}\` TellaskBack:`;
```

**消息结构示例（与当前函数输出结构一致）：**

```
你好 @supdialog，在处理以下任务期间（如下引文）：

> 《任务 A》（assignment headline）

`@subdialog-A` 回问：

> !?@tellasker 我需要澄清（request headline）
> …（request body）
```

#### 2. `formatTeammateResponseContent` 改进

**建议文案：**

```typescript
const tail = language === 'zh' ? '针对原始诉请：' : 'regarding the original tellask:';
```

### 方案：内容前缀（谨慎；通常不推荐）

如果确实需要让 LLM/用户一眼区分“系统自动注入的 inter-dialog 文本”，更稳的做法通常是 UI 层用 bubble chrome/样式提示；只有在确认收益大于成本时，再考虑在内容前面加类似 `[系统自动消息]` 的前缀。

注意：前缀会进入 LLM 上下文、增加 token，并且需要后端/前端 twin 同步修改。

**消息结构示例（仅示意“前缀长什么样”，不代表推荐）：**

```
[系统自动消息]
你好 @requester，@responder 已回复：
[响应内容]

针对原始诉请：

> 《任务 A》
```

## 关于 `role=user` 的技术决策

### 以实现事实澄清（2026-02-02 校验）

- **驱动对话的 inter-dialog prompt** 走 `HumanPrompt` 路径，最终被记录为 `prompting_msg` / `role: 'user'`（并会持久化为 user message）。这主要是为了：
  - 让“被驱动对话”的 LLM 明确把它当作“需要回应/需要处理的输入”；
  - 在 UI 与持久化里把它当作“prompt（提示）”而不是“assistant 说过的话”。
- 代码锚点：
  - 创建 subdialog 的初始 prompt：`dominds/main/llm/driver.ts:createSubdialogForSupdialog()` 调用 `formatAssignmentFromSupdialog()`
  - Type A 回问驱动 supdialog：`dominds/main/llm/driver.ts` Type A handling 调用 `formatSupdialogCallPrompt()`
- **队友响应的叙事文本** 走 `tellask_result_msg` / `role: 'tool'`，这是 Dominds 自己的内部 `ChatMessage` 类型；它并不是“提供商工具调用链条”的一部分，因此不涉及“必须有 provider tool_call_id 才能发送 `role=tool`”的问题。
  - 类型锚点：`dominds/main/llm/client.ts` 的 `TellaskCallResultMsg`（`role: 'tool'`）

### 如果要区分“系统自动格式化文本”

- 优先用 **消息类型与事件类型** 区分（例如 `prompting_msg` vs `saying_msg` / `tellask_result_msg`），并在 UI 用 bubble chrome 或样式体现。
- 不建议仅靠在内容里添加 `[SYSTEM_AUTO_MESSAGE]` 前缀来做区分：它会进入 LLM 上下文、影响 token 与可读性，而且需要后端/前端 twin 同步，改动面更大。

## 验收清单

- [ ] 本文档对 inter-dialog 的“消息类型/role/流向”描述与代码一致（见上表与 `dominds/main/llm/driver.ts`）
- [ ] 若要改文案（例如消除 `"你"` 的指代歧义），确认同时更新：
  - `dominds/main/shared/utils/inter-dialog-format.ts`
  - `dominds/webapp/src/shared/utils/inter-dialog-format.ts`
  - 并通过 WebUI dev 校验点（`dominds/webapp/src/components/dominds-dialog-container.ts`）
- [ ] 若涉及用户可见文案或 i18n 规范，需要与 `dominds/docs/i18n.md` 口径对齐（但本文档改动本身不等于产品文案变更）

## 讨论待决议项

1. 是否需要真的引入内容前缀（例如 `[系统自动消息]`）？还是改用消息类型/样式区分即可？
2. （已决议，需重新落地）是否要改 `formatSupdialogCallPrompt` / `formatTeammateResponseContent` 的措辞以减少代词歧义（例如把“你最初诉请”改为“原始任务/原始诉请”）？
   - 注：实现改动曾出现于本地 checkout，但后续被其他改动撤销，因此需要重新提交到 `dominds` 仓 PR。
3. 若改动 inter-dialog-format，是否要顺手修正顶部注释里“UI display contract”与当前输出格式的偏差（这属于额外工作，需 @fullstack 确认范围）？

---

**Owner:** @prompt（本文档校对） / @fullstack（实现与契约）  
**Status:** 文档已校对；代码文案消歧已决议，但实现改动被撤销，待重新落地到 `dominds` 仓 PR + WebUI dev 校验  
**Priority:** P1（语义准确性/减少误解）
