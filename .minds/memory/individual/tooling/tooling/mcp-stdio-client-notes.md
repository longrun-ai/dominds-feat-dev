# MCP stdio client（JSON-RPC 行协议与“stdout 干净”要求）
关键词：`McpStdioClient` `spawn` `initialize` `tools/list` `tools/call`

- `dominds/main/mcp/stdio-client.ts`
  - 通过 `child_process.spawn` 启动 MCP server，`stdio: 'pipe'`。
  - 读取协议：用 `readline.createInterface({input: proc.stdout})` 按“行”读取；每行 `JSON.parse`，要求 `jsonrpc === '2.0'`。
    - 解析失败/格式不对会 `log.warn(...)` 并忽略该行。
    - 因此 MCP server 必须避免向 stdout 输出非 JSON-RPC 的“杂音”（否则会被当作坏行，导致协议层丢消息/降级）。
  - stderr：直接 `log.debug('[stderr] ...')`（stderr 不参与协议，允许日志）。
  - handshake：`initialize()` 发送 `initialize`，`protocolVersion: '2024-11-05'`，随后 notify `notifications/initialized`。
  - 工具调用：
    - `listTools()` => `tools/list`（支持 cursor，最多迭代 50 次）
    - `callTool(name,args)` => `tools/call`，params `{ name, arguments: args }`，并把 result stringify（`stringifyToolCallResult`）。
  - 退出处理：子进程 exit 时会 reject 所有 pending 请求，错误信息包含 method/id。
