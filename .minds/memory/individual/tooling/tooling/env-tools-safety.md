# env_* tools 安全边界（仅本地测试）
关键词：`env_get` `env_set` `env_unset` `DEFAULT_ALLOWED_PREFIXES` `redact`

- `dominds/main/tools/env.ts`
  - 目的：运行时修改 `process.env` 以便本地测试（尤其 `.minds/mcp.yaml` 引用 env 的场景）。
  - Key 白名单（`assertAllowedKey`）：
    - 允许前缀：`MCP_`, `UX_`, `DOMINDS_TEST_`
    - 允许精确 key：`DOMINDS_LOG_LEVEL`
    - 其它 key 直接 throw：`env key 'X' is not allowed...`
  - 泄露控制：
    - `env_get` 默认对看起来敏感的 key（包含 `KEY|TOKEN|SECRET|PASSWORD`，不区分大小写）做 `redactValue`，除非 `reveal:true`。
    - `env_set`/`env_unset` 在返回 prev/next 时也会对敏感 key 做 redact（同时日志里只记录长度/是否 set）。
