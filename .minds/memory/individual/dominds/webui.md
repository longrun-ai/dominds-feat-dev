# Dominds：WebUI 快速索引（@fullstack）

## 入口与路由

- `dominds/webapp/index.html`：启动前读取 `localStorage.dominds-theme`（`light|dark`）并写入 `html[data-theme]`，用于防闪
- `dominds/webapp/src/main.ts`：`/setup` 或 `/setup/` → `<dominds-setup>`；其它 → `<dominds-app>`

## Services（前端契约落点）

- HTTP client：`dominds/webapp/src/services/api.ts`
  - `getHealth()` → `GET /api/health`（消费 `workspace` + `rtws`）
  - `getTeamConfig()` → `GET /api/team/config`
  - Setup：`getSetupStatus()` / `getSetupRtwsLlmYaml()` / `writeTeamYaml()` / `writeRtwsLlmYaml()` / `writeShellEnv()`
- Auth：`dominds/webapp/src/services/auth.ts`（URL / localStorage key 注入）
- WS client：`dominds/webapp/src/services/websocket.ts`
- Shared types：`dominds/webapp/src/shared` 是 symlink → `../../main/shared`

## 主应用（Bottom panel / Q4H / Keep-going）

- 主容器：`dominds/webapp/src/components/dominds-app.tsx`
  - Diligence push toggle：`#diligence-toggle`（发 WS 包 `set_diligence_push`；消费 `dialog_ready.disableDiligencePush` + `diligence_push_updated`）
  - Bottom panel resize handle：`#bottom-panel-resize-handle`（写 CSS var `--bottom-panel-height`；localStorage key=`dominds-bottom-panel-height-px`）
  - Q4H 选中事件：监听 `q4h-select-question`（来自 `dominds-q4h-panel`/`dominds-q4h-input` 的 bubbling event）

- Q4H 列表：`dominds/webapp/src/components/dominds-q4h-panel.ts`
  - 展开会 emit `q4h-question-expanded`（bubbles/composed）

- 输入区：`dominds/webapp/src/components/dominds-q4h-input.ts`
  - send-on-enter：localStorage key=`dominds-send-on-enter`

## /setup 页面（UI ids / 行为）

- 组件：`dominds/webapp/src/components/dominds-setup.tsx`（Shadow DOM + 内联 styles）
- 写入 `.minds/team.yaml`：`#copy-team-snippet` → `POST /api/setup/write-team-yaml`（存在则 confirm modal）
- rtws LLM 覆盖：
  - textarea：`#rtws-llm-textarea`
  - 写入：`#write-rtws-llm-yaml` → `POST /api/setup/write-rtws-llm-yaml`
  - 查看：`#view-rtws-llm-yaml` → `GET /api/setup/rtws-llm-yaml`
- prominent enum 模型参数：来源 `status.providers[].prominentModelParams`（UI 用 `description` 做 label）

## i18n 约定（最常用锚点）

- UI 字符串集中在：`dominds/webapp/src/i18n/ui.ts`
- 语义基准：`zh`；需要对齐时更新 `en` 以匹配 `zh`
- 中文文案中 “Provider” 语义统一用“提供商”
