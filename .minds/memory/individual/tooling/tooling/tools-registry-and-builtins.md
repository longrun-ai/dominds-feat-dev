# Tools registry / builtins（工具注册与 toolsets）
关键词：`toolsRegistry` `toolsetsRegistry` `toolsetMetaRegistry` `builtins`

## Registry 结构
- `dominds/main/tools/registry.ts`
  - `toolsRegistry: Map<string, Tool>`：全局工具注册表（按 `tool.name`）。
  - `toolsetsRegistry: Map<string, Tool[]>`：全局 toolset 注册表（按 toolset name -> 工具列表）。
  - `toolsetMetaRegistry: Map<string, ToolsetMeta>`：toolset 元信息（当前仅 `descriptionI18n?: I18nText`）。
  - `reminderOwnersRegistry: Map<string, ReminderOwner>`：ReminderOwner 注册表。
  - API：`registerTool`/`unregisterTool`/`getTool`/`listTools`；`registerToolset`/`unregisterToolset`/`getToolset`/`listToolsets`；`setToolsetMeta`/`getToolsetMeta`；`registerReminderOwner`/`getReminderOwner`/`listReminderOwners`。

## Builtins 初始化入口
- `dominds/main/tools/builtins.ts`
  - 约定：server/cli 入口需要 import 该模块一次以填充 registries（见文件头注释）。
  - 注册了以下内置 tool（部分）：
    - 文件类：`list_dir`, `rm_dir`, `rm_file`（`dominds/main/tools/fs.ts`）；`read_file`, `overwrite_file`, `plan_file_modification`, `apply_file_modification`（`dominds/main/tools/txt.ts`）
    - OS：`shell_cmd`, `stop_daemon`, `get_daemon_output`（`dominds/main/tools/os.ts`）
    - Env：`env_get`, `env_set`, `env_unset`（`dominds/main/tools/env.ts`，仅本地测试）
    - MCP ops：`mcp_restart`, `mcp_release`（`dominds/main/tools/mcp.ts`）
    - Memory：`add_memory`, `drop_memory`, `replace_memory`, `clear_memory` + team 版（`dominds/main/tools/mem.ts`）
    - Control：`add_reminder`, `delete_reminder`, `update_reminder`, `clear_mind`, `change_mind`（`dominds/main/tools/ctrl.ts`）
    - Team mgmt：`teamMgmtTools`（`dominds/main/tools/team-mgmt.ts`，作用域提示为 `.minds/**`）
  - toolset 划分（`registerToolset` + `setToolsetMeta`）：
    - `memory`, `team_memory`, `control`, `os`, `mcp_admin`, `ws_read`, `ws_mod`, `team-mgmt`
  - ReminderOwners 注册：
    - `shellCmdReminderOwner`（name=`shellCmd`，`dominds/main/tools/os.ts`）
    - `contextHealthReminderOwner`（name=`context_health`，`dominds/main/tools/context-health.ts`）
    - `mcpLeaseReminderOwner`（name=`mcpLease`，`dominds/main/tools/mcp.ts`）
