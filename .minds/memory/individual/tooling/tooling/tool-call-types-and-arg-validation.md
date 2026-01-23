# Tool type & 参数校验（func / tellask）
关键词：`Tool` `FuncTool` `TellaskTool` `argsValidation` `validateArgs`

- `dominds/main/tool.ts`
  - `Tool = FuncTool | TellaskTool`
  - `FuncTool`：
    - `type: 'func'`
    - `name`, `description?`, `descriptionI18n?`
    - `parameters: JsonSchema`
    - `argsValidation?: 'dominds' | 'passthrough'`
    - `call(dlg, caller, args): Promise<string>`
  - `TellaskTool`：
    - `type: 'tellask'`
    - `name`, `usageDescription`, `usageDescriptionI18n?`, `backfeeding: boolean`
    - `call(dlg, caller, headLine, inputBody): Promise<TellaskToolCallResult>`
  - `TellaskToolCallResult`：
    - `{ status:'completed', result?, messages? }` 或 `{ status:'failed', result, messages? }`
  - 参数校验：
    - `validateArgs(schema, args)`：Dominds 自带的“最小校验器”，只做 best-effort（对象根、required、properties、additionalProperties=false 时拒绝未知字段、对常见 `type` 做递归验证）。
    - 非法/未知 schema 形状时倾向放行（例如 `validateValue` 遇到非 record schema 会 `ok: true`）。
  - MCP 工具参数：
    - `mcp/supervisor.ts` 在构造 MCP tool wrapper 时把 `argsValidation: 'passthrough'`，并直接使用 MCP tool 的 `inputSchema` 作为 `parameters`（见 `buildToolsForServer`）。
