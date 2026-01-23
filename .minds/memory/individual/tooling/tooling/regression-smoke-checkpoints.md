# Tooling 冒烟/回归要点（可用于上岗检测）
关键词：`registry-snapshot` `access denied` `mcp reload` `lease reminder` `stdio noise`

- Registry 快照：
  - `dominds/main/tools/registry-snapshot.ts:createToolsRegistrySnapshot()`：从 `toolsetsRegistry` 导出 `ToolsetInfo[]`（含 tool 名称 + kind + 描述 + descriptionI18n）并带 `timestamp`。
  - 回归点：toolset 名称顺序会受 `mcp/supervisor.ts:reorderMcpToolsetsInRegistry` 影响；快照变动要能解释（新增/删改 toolsets 或 MCP config 变化）。

- Task Doc 封装拒绝：
  - `dominds/main/access-control.ts:isEncapsulatedTaskPath` + `hasReadAccess/hasWriteAccess`：任何通用文件工具触达 `*.tsk/` 都应被拒绝。
  - `getAccessDeniedMessage(..., zh/en)` 应包含 “用 `!?@change_mind !goals|!constraints|!progress` 更新分段” 的指引。

- MCP 过滤与冲突：
  - 过滤：`mcp/tool-names.ts:decideToolExposure`（whitelist/blacklist + `*` wildcard）。
  - 冲突：`mcp/supervisor.ts:tryBuildServerState` 阻止 toolset 名称冲突；`buildToolsForServer` 记录 tool 名称无效/冲突为 problems，并跳过注册而不是崩溃。
  - 重载稳定性：watch + poll 双机制（`startMcpSupervisor`）。

- Lease 机制：
  - 非 truelyStateless：每个 dialog 一个 lease runtime；`mcp_release` 应释放并使 `mcpLeaseReminderOwner.updateReminder` 最终 drop 对应 reminder。

- stdio “stdout 干净”：
  - `mcp/stdio-client.ts` 按行解析 stdout JSON-RPC，非 JSON 会 warn 并丢弃；MCP server 必须避免 stdout 打日志（应打到 stderr）。