# Dominds：Runtime + Server 快速索引（@fullstack）

## rtws / dev 约定

- Repo root 默认是 DevOps rtws：`./.minds/**` + `./.dialogs/**`
- WebUI dev/UX rtws：`ux-rtws/`（用 `./dev-server.sh` 启动，避免污染 repo root）
- Dialog 持久化根：`<rtws>/.dialogs/`（实现：`dominds/main/persistence.ts`）

## Dialog runtime（最短定位链路）

- Driver / Dialog 主实现：`dominds/main/dialog.ts`
- Run state（proceeding/idle/interrupted/blocked/terminal 等）：`dominds/main/dialog-run-state.ts`
- Registry：`dominds/main/dialog-global-registry.ts`、`dominds/main/dialog-instance-registry.ts`

## Server（HTTP/WS 入口）

- Server 入口：`dominds/main/server.ts`
- HTTP 路由分发：`dominds/main/server/api-routes.ts#handleApiRoute`
- WS handler：`dominds/main/server/websocket-handler.ts#handleWebSocketMessage`（`/ws`）

## 关键 HTTP 契约锚点

- `GET /api/health`：返回 `workspace`（canonical）与 `rtws`（兼容字段；值同 `workspace`）以及 `version/mode/timestamp`（实现：`dominds/main/server/api-routes.ts#handleHealthCheck`）
- `GET /api/team/config`：Team 配置读取（实现：`dominds/main/server/api-routes.ts#handleGetTeamConfig`）

## /setup 相关（后端）

- 实现：`dominds/main/server/setup-routes.ts`；路由分发在 `dominds/main/server/api-routes.ts`
- `GET /api/setup/status`
- `GET /api/setup/defaults-yaml`
- `GET /api/setup/rtws-llm-yaml`
- `POST /api/setup/write-team-yaml`：写 `.minds/team.yaml`；存在且未 `overwrite:true` → 409；会校验 provider/model（`handleWriteTeamYaml`）
- `POST /api/setup/write-rtws-llm-yaml`：写 `.minds/llm.yaml`；存在且未 `overwrite:true` → 409；会校验 YAML 且要求顶层 `providers`（`handleWriteRtwsLlmYaml`）
- `POST /api/setup/write-shell-env`：写入 `.env.local` 或（posix）`~/.bashrc`/`~/.zshrc`；并同步 `process.env[envVar]=value`（`handleWriteShellEnv`）
