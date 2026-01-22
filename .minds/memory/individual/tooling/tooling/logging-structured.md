# Log（结构化日志）
关键词：`Logger` `createLogger` `extractErrorDetails` `DOMINDS_LOG_LEVEL`

- `dominds/main/log.ts`
  - `Logger`：轻量 structured logger，level：`debug|info|warn|error`。
  - `resolveDefaultLevel()`：读 `process.env.DOMINDS_LOG_LEVEL`（否则 dev=debug / else=info）。
  - `Logger.formatRecord()`：
    - 当 logger level 是 `debug` 时，会计算 `location`（`getCallerLocation(2)`）并在格式化时附上 `@ file:line:col`。
    - `extractErrorDetails(error)`：尽量从 Error/unknown 中提取 `name/message/stack`，stack 存在时优先只显示 stack（避免重复 message）。
  - 输出：`console.debug/info/warn/error`。
  - 工具侧常用：`createLogger('tag')`（如 `dominds/main/tools/env.ts`, `dominds/main/tools/mcp.ts`, `dominds/main/mcp/tool-names.ts`, `dominds/main/mcp/supervisor.ts`）。
