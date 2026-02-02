# Inter-Dialog 格式化文案问题分析

## 背景

在 Dominds 对话系统中，`dominds/main/shared/utils/inter-dialog-format.ts` 模块负责格式化"对话间"（inter-dialog）的消息，将结构化数据渲染为 LLM 可读的 markdown 文本。

这些消息在用户/Agent 视角中呈现为系统自动生成的格式化内容，但底层使用 `role=user` 发送（因 `role=assistant` 会被 LLM 当噪音忽略，`role=tool`/`role=system` 有技术限制）。

## 相关文档

- `dominds/docs/dialog-system.md` - 对话系统架构与 Type A/B/C 诉请分类
- `dominds/docs/dominds-terminology.md` - Dominds 专有名词表
- `dominds/main/shared/utils/inter-dialog-format.ts` - 格式化模块源码

## 场景分析

### 三个核心函数的用途

| 函数                            | 输入参数                                             | 消息流向              | 受众      |
| ------------------------------- | ---------------------------------------------------- | --------------------- | --------- |
| `formatAssignmentFromSupdialog` | `fromAgentId`（supdialog）、`toAgentId`（subdialog） | Supdialog → Subdialog | Subdialog |
| `formatSupdialogCallPrompt`     | `fromAgentId`（subdialog）、`toAgentId`（supdialog） | Subdialog → Supdialog | Supdialog |
| `formatTeammateResponseContent` | `requesterId`、`responderId`                         | Subdialog → 请求者    | 请求者    |

### Type A 回问场景（formatSupdialogCallPrompt）

```
1. Supdialog → Subdialog-A: "任务 A，请执行" (assignment)
2. Subdialog-A 执行中遇到需要澄清的问题
3. Subdialog-A → Supdialog: "!?@super 我需要澄清" (Type A 回问)
   ↑ formatSupdialogCallPrompt 处理的就是这一步！
4. Supdialog 收到回问并处理
```

**关键理解：**

- `formatSupdialogCallPrompt` 格式化的是 **Subdialog → Supdialog** 的回问消息
- 消息受众是 Supdialog（接收回问者）
- 消息背景是 Supdialog 分配给 Subdialog 的原始任务

## 问题定位

### 问题 1：`formatSupdialogCallPrompt` 第 105-110 行

**当前文案：**

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

### 问题 2：`formatTeammateResponseContent` 第 130 行

**当前文案：**

```typescript
const tail = language === 'zh' ? '针对你最初的诉请：' : 'to your original call:';
```

**歧义分析：**

- 消息渲染给请求者（requesterId）看
- "针对**你**最初的诉请"可能让请求者困惑
- 虽然 requesterId 确实是原始请求发起者，但消息中出现三方指代时存在模糊性

## 改进建议

### 方案：明确指代 + 系统标注

#### 1. `formatSupdialogCallPrompt` 改进

**改进思路：**

- 明确 Supdialog 是"上游对话/协调者"角色
- 引用具体的任务标题消除歧义
- 添加 `[SYSTEM_AUTO_MESSAGE]` 前缀

**建议文案：**

```typescript
const systemPrefix = language === 'zh' ? `[系统自动消息] ` : `[SYSTEM_AUTO_MESSAGE] `;

const hello =
  language === 'zh'
    ? `你好 @${requireNonEmpty(input.toAgentId, 'toAgentId')}，我是 @${requireNonEmpty(input.fromAgentId, 'fromAgentId')}。针对《${requireNonEmpty(input.supdialogAssignment.headLine, 'assignmentHeadLine')}》这项你分配的任务，我需要澄清：`
    : `Hi @${requireNonEmpty(input.toAgentId, 'toAgentId')}, this is @${requireNonEmpty(input.fromAgentId, 'fromAgentId')}. Regarding the task you assigned: "${requireNonEmpty(input.supdialogAssignment.headLine, 'assignmentHeadLine')}", I need clarification:`;

const asking = language === 'zh' ? `当前回问内容：` : `Current callback content:`;

return `${systemPrefix}${hello}

${asking}

${markdownQuote(requireNonEmpty(input.subdialogRequest.headLine, 'requestHeadLine'))}
${markdownQuote(input.subdialogRequest.callBody)}
`;
```

**消息结构示例：**

```
[系统自动消息]
你好 @supdialog，我是 @subdialog-A。针对《任务 A》这项你分配的任务，我需要澄清：

当前回问内容：
[回问的具体问题]
```

#### 2. `formatTeammateResponseContent` 改进

**建议文案：**

```typescript
const systemPrefix = language === 'zh' ? `[系统自动消息] ` : `[SYSTEM_AUTO_MESSAGE] `;

const tail =
  language === 'zh'
    ? `该响应针对原始任务：《${requireNonEmpty(input.originalCallHeadLine, 'originalCallHeadLine')}》`
    : `This response addresses the original task: "${requireNonEmpty(input.originalCallHeadLine, 'originalCallHeadLine')}"`;
```

**消息结构示例：**

```
[系统自动消息]
你好 @requester，@responder 已回复：
[响应内容]

该响应针对原始任务：《任务 A》
```

## 关于 `role=user` 的技术决策

### 背景

- `role=assistant`：LLM 经常将其当噪音忽略，不够重视
- `role=tool`：部分提供商严格要求 `tool_call_id`，但实际没有原生 tool call
- `role=system`：OpenAI 限制 1 条，Anthropic 做唯一参数

### 当前策略

由于上述限制，目前必须使用 `role=user`，通过文案优化让 LLM 识别这是系统自动消息而非用户交互消息。

### 替代方案（如果技术可行）

- 使用 `role=tool` + 添加 `tool_call_id` 占位符
- 在消息 metadata 中标注 `generatedBy: "inter-dialog-format.ts"`

## 验收清单

- [ ] `formatSupdialogCallPrompt` 文案消除"你"的指代歧义
- [ ] `formatTeammateResponseContent` 文案明确"原始任务"指向
- [ ] 两个函数均添加 `[SYSTEM_AUTO_MESSAGE]` 前缀
- [ ] 英文文案同步更新
- [ ] 更新 `dominds/docs/i18n.md` 记录此变更

## 讨论待决议项

1. 是否接受 `[SYSTEM_AUTO_MESSAGE]` 前缀方案？
2. 任务标题的引用格式是否需要调整（方括号、书名号、引号等）？
3. 是否需要同步更新 UI 展示层以区分系统格式化消息？

---

**Owner:** @i18n  
**Status:** 分析完成，待实现  
**Priority:** P1（语义准确性修复）
