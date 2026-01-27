# Dominds 快速定位索引（@fullstack）

目标：把常见改动点收敛成“0 次 ripgrep 也能直接开干”的落点表；内容以实际代码为准，随改动即时更新。

## 运行与工作区（rtws）

- Repo root 是 DevOps rtws：`.minds/`（团队定义）+ `.dialogs/`（对话持久化）。
- WebUI dev/UX 固定 rtws：`ux-rtws/`，通过 `./dev-server.sh` 启动，避免污染 repo root。
- `./dev-server.sh`：同时起前端 `5555` + 后端 `5556`；管理：`./dev-server.sh status|stop|restart`。
- wrapper 日志：repo root 的 `logs/`。

## i18n（双语维护约定）

- `zh` 为语义基准；不要从 `en` 反向翻译更新 `zh`，需要对齐时更新 `en`。
- WebUI 字符串集中在：`dominds/webapp/src/i18n/ui.ts`。
- 近期约定：中文文案里出现 “Provider” 语义时，统一用“提供商”。
- Shared i18n 类型：`dominds/main/shared/types/i18n.ts`（`I18nText = Record<'en'|'zh', string>`）；tool registry 的 `descriptionI18n` 见 `dominds/main/shared/types/tools-registry.ts`。

## WebUI 路由/装配（0 搜索版本）

- 入口：`dominds/webapp/index.html`（提前读取 `localStorage.dominds-theme` 写入 `html[data-theme]` 防闪）。
- 路由选择：`dominds/webapp/src/main.ts`
  - `/setup` 或 `/setup/` → `<dominds-setup>`
  - 其它 → `<dominds-app>`

## /setup 页面（DomindsSetup）核心落点（webapp）

- 组件实现：`dominds/webapp/src/components/dominds-setup.tsx`（Shadow DOM + 内联 styles）。
- 主题一致性：使用 tokens（`--dominds-*` / `--color-*`），跟随 `html[data-theme]`。
- Team 配置：嵌套面板渲染 `member_defaults` / `model_params`；prominent enum params 用 description 作为主 label。
- Provider 卡片：API Key 输入框左侧 env pill（`✅/⚠️`），底部一行模型 chips（左）+ rc tags（右，存在=绿框/不存在=灰框）。
- Providers 分组：内置提供商按 `已配置/未配置` 两组渲染，workspace 自定义区插在两组之间。
- Workspace 自定义提供商：面板含 `#workspace-llm-textarea` 多行编辑 + `#write-workspace-llm-yaml` 写入按钮；示例默认内容为 Xiaomi MiMo（`xiaomimimo.com` providerKey，`MIMO_API_KEY`，`mimo-v2-flash`）。
- 覆盖二次确认：
  - `#copy-team-snippet`（写 `.minds/team.yaml`）与 `#write-workspace-llm-yaml`（写 `.minds/llm.yaml`）在目标文件已存在时弹确认 modal；创建新文件不需要确认。

## Backend（dominds/main/\*\*）0-ripgrep 导航图

### Server 启动与路由

- 服务启动入口：`dominds/main/server.ts`。
- HTTP 路由分发：`dominds/main/server/api-routes.ts`。
- Setup 相关 handler：`dominds/main/server/setup-routes.ts`。
- WS handler：`dominds/main/server/websocket-handler.ts`（`/ws`）。

### Dialog runtime（理解“能跑”的最短路径）

- Driver loop：`dominds/main/dialog.ts`
- Run state 语义：`dominds/main/dialog-run-state.ts`
- Registry（global/instance）：`dominds/main/dialog-global-registry.ts`、`dominds/main/dialog-instance-registry.ts`
- Persistence：`dominds/main/persistence.ts`

### LLM 配置与 defaults

- 默认 providers 配置：`dominds/main/llm/defaults.yaml`
- 工作区覆盖：`.minds/llm.yaml`（由 `dominds/main/llm/client.ts#LlmConfig.load()` 读取并与 defaults 合并）
- ProviderConfig 类型：`dominds/main/llm/client.ts`（`ProviderConfig`/`ModelParamOption`/`model_param_options`）

### /setup 相关 HTTP API（契约锚点）

- `GET /api/setup/status` → `buildSetupStatusResponse()`：`dominds/main/server/setup-routes.ts`
- `GET /api/setup/defaults-yaml` → `buildSetupFileResponse('defaults_yaml')`
- `GET /api/setup/workspace-llm-yaml` → `buildSetupFileResponse('workspace_llm_yaml')`
- `POST /api/setup/write-team-yaml` → `handleWriteTeamYaml()`（创建/覆盖 `.minds/team.yaml`）
- `POST /api/setup/write-workspace-llm-yaml` → `handleWriteWorkspaceLlmYaml()`（创建/覆盖 `.minds/llm.yaml`；会校验 YAML 且要求顶层 `providers` 对象；409=需 overwrite）
- `POST /api/setup/write-shell-env` → `handleWriteShellEnv()`（写入 rc 的 managed block，并同步到当前进程 env）

### Shared types（前后端共用）

- Setup 类型：`dominds/main/shared/types/setup.ts`（Webapp 侧通过 `dominds/webapp/src/shared -> ../../main/shared` 复用）。
  - `SetupWriteWorkspaceLlmYamlRequest/Response`（`raw` + `overwrite`）

## Webapp（dominds/webapp/src/\*\*）核心落点

- 主应用装配：`dominds/webapp/src/components/dominds-app.tsx`
- Setup 页：`dominds/webapp/src/components/dominds-setup.tsx`
- HTTP client：`dominds/webapp/src/services/api.ts`
  - `writeWorkspaceLlmYaml()` 调用 `POST /api/setup/write-workspace-llm-yaml`
- WS client：`dominds/webapp/src/services/websocket.ts`

## Workspace Indicator（端到端落点）

- 后端：`GET /api/health` 返回 payload 中的 `workspace: string`。
- Webapp：`dominds/webapp/src/services/api.ts#getHealth()`；主界面与 `/setup` header 都渲染 `.workspace-indicator`。

## 常用命令（本地）

- 启动联调：repo root `./dev-server.sh`
- 类型检查：`pnpm -C dominds run lint:types`
- 构建：`pnpm -C dominds run build` / `build:backend` / `build:frontend`
- 测试：`pnpm -C dominds/tests run parsing`、`pnpm -C dominds/tests run realtime`
