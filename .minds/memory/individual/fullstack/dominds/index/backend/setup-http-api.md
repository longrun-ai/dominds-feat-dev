# Backend：/setup 相关 HTTP API（@fullstack）

- `GET /api/setup/status` → `buildSetupStatusResponse()`：`dominds/main/server/setup-routes.ts`
- `GET /api/setup/defaults-yaml` → `buildSetupFileResponse('defaults_yaml')`
- `GET /api/setup/workspace-llm-yaml` → `buildSetupFileResponse('workspace_llm_yaml')`
- `POST /api/setup/write-team-yaml` → `handleWriteTeamYaml()`（创建/覆盖 `.minds/team.yaml`）
- `POST /api/setup/write-workspace-llm-yaml` → `handleWriteWorkspaceLlmYaml()`（创建/覆盖 `.minds/llm.yaml`；会校验 YAML 且要求顶层 `providers` 对象；409=需 overwrite）
- `POST /api/setup/write-shell-env` → `handleWriteShellEnv()`（写入 rc 的 managed block，并同步到当前进程 env）
