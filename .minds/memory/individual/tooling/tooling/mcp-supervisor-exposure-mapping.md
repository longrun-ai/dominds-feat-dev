# MCP supervisor：加载、过滤、映射、注册、lease
关键词：`startMcpSupervisor` `reloadNow` `MCP_YAML_PATH` `decideToolExposure` `applyToolNameTransforms` `truelyStateless` `lease`

## 配置与重载
- `dominds/main/mcp/supervisor.ts`
  - 配置文件：`MCP_YAML_PATH = .minds/mcp.yaml`
  - `startMcpSupervisor()`：
    - 启动时 `reloadNow('startup')`（串到 `reloadChain`）。
    - watch：对 `.minds/` 目录做 `fs.watch`（并对 workspace root 做 watch 以捕获 `.minds/` 创建/删除），外加 `setInterval` polling（1500ms）保证可靠性。
  - `reloadNow(reason)`：
    - 读 `.minds/mcp.yaml`，不存在视为 empty config（并清理 workspace_config_error problem）。
    - 解析失败会 `upsertWorkspaceConfigProblem(...)`，成功则 `applyWorkspaceConfig(...)`。

## Tool 名称规则、过滤、transform
- `dominds/main/mcp/tool-names.ts`
  - 名称合法性：`TOOL_NAME_VALIDITY_RULE = ^[a-zA-Z0-9_-]{1,64}$`，`isValidProviderToolName()`
  - transform：`applyToolNameTransforms(original, transforms)` 支持 `prefix_add` / `prefix_replace` / `suffix_add`
  - exposure filter：`decideToolExposure(toolName, {whitelist, blacklist})`
    - 无 blacklist：whitelist 为空 => 全接受；否则不在 whitelist => `not_whitelisted`
    - 有 blacklist：whitelist 命中则接受（whitelist override）；否则 blacklist 命中 => `blacklisted`；否则接受
    - wildcard 匹配仅支持 `*` 子串通配（`matchesWildcardPattern`）

- `buildToolsForServer(cfg, dispatch, listedTools)`（`mcp/supervisor.ts:864` 起）
  - 逐个 MCP tool：
    - 原始名不合法：拒绝注册，记录 problem `mcp_tool_invalid_name`（severity warning），detail 附 rule。
    - 被 blacklist / not_whitelisted：不注册，记录相应 problem（warning/info）。
    - transform 后名不合法：拒绝并记录 `mcp_tool_invalid_name`（transformed）。
    - 同 server 内 collision：记录 `mcp_tool_collision` 并跳过。
    - 与已存在 dominds tool collision：记录 `mcp_tool_collision_existing` 并跳过（见 `mcp/supervisor.ts:960+` 与后续段落）。
  - 注册到 Dominds 的工具形态：
    - `type:'func'`, `name: domindsName`, `parameters: tool.inputSchema`, `argsValidation:'passthrough'`
    - `call` 会转发到 `dispatch.callToolForDialog(dlg, originalName, args)`（使用原始 MCP tool name）

## toolset 与 owner/collision
- toolsetName 约定：`desiredToolsetName = serverId`（`applyWorkspaceConfig` / `restartServerNow`）。
- `tryBuildServerState` 会检查 toolset-name collision：如果 registry 中已有同名 toolset 且 owner 不同 server => 整个 server 构建失败（`Toolset name collision: ${toolsetName}`）。

## truelyStateless vs leased runtime
- `McpServerDispatch.callToolForDialog(...)`：
  - `cfg.truelyStateless === true`：复用 `sharedRuntime`（单 client/runtime）。
  - 否则：按 dialogKey 维护 lease（`leasesByDialogKey` + `leaseInitByDialogKey`），每个 dialog 一个 runtime；支持 `releaseLeaseForDialog`。
  - 当 lease 生效，会 `attachLeaseReminder(dlg)`，底层使用 `ensureLeaseReminder`（写入 owner=`mcpLease` 的 reminder，meta `{kind:'mcp_lease', serverId}`）。

## 对外管理工具
- `dominds/main/tools/mcp.ts`
  - `mcp_restart({serverId})` => `requestMcpServerRestart(serverId)`
  - `mcp_release({serverId})` => `releaseMcpToolsetLeaseForDialog(serverId, dlg.id.key())`
  - `mcpLeaseReminderOwner`（name=`mcpLease`）会在 reminder update 时检查 lease 是否仍存在：不存在则 drop（`isMcpToolsetLeasedToDialog`）。
