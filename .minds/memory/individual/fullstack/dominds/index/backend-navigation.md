# Dominds：Backend（dominds/main/**）导航图（@fullstack）

## Server 启动与路由

- 服务启动入口：`dominds/main/server.ts`。
- HTTP 路由分发：`dominds/main/server/api-routes.ts`。
- Setup 相关 handler：`dominds/main/server/setup-routes.ts`。
- WS handler：`dominds/main/server/websocket-handler.ts`（`/ws`）。

## Dialog runtime（理解“能跑”的最短路径）

- Driver loop：`dominds/main/dialog.ts`
- Run state 语义：`dominds/main/dialog-run-state.ts`
- Registry（global/instance）：`dominds/main/dialog-global-registry.ts`、`dominds/main/dialog-instance-registry.ts`
- Persistence：`dominds/main/persistence.ts`

## LLM 配置与 defaults

- 默认 providers 配置：`dominds/main/llm/defaults.yaml`
- 工作区覆盖：`.minds/llm.yaml`（由 `dominds/main/llm/client.ts#LlmConfig.load()` 读取并与 defaults 合并）
- ProviderConfig 类型：`dominds/main/llm/client.ts`（`ProviderConfig`/`ModelParamOption`/`model_param_options`）
