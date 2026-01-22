# Tool Calling Contract（字段与错误语义）
关键词：`ToolCall` `ToolResult` `ToolError` `ToolDenied` `require_escalated` `justification`

- 调用输入（概念）：
  - tool name + args（JSON），由 registry 的 schema 校验。
- 输出分类（概念）：
  - `success`: 返回结构化 data（可被 UI/CLI 渲染）
  - `denied`: policy/权限拒绝（应附带 `sandbox_permissions=require_escalated` 与 `justification` 供 UX 提示）
  - `error`: 运行时错误（应包含可诊断 message + 可选 stack；UX 上避免与 denied 混淆）
- 关键一致性点：
  - CLI/webui/server/ws/MCP 之间要用同一套错误类型字段，否则会出现“前端以为是 bug，实际上是权限拒绝”的体验问题。
