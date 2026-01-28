# Dominds：WebUI 路由与装配（@fullstack）

## 入口与路由

- 入口：`dominds/webapp/index.html`（提前读取 `localStorage.dominds-theme` 写入 `html[data-theme]` 防闪）。
- 路由选择：`dominds/webapp/src/main.ts`
  - `/setup` 或 `/setup/` → `<dominds-setup>`
  - 其它 → `<dominds-app>`

## Webapp 核心落点

- 主应用装配：`dominds/webapp/src/components/dominds-app.tsx`
- Setup 页：`dominds/webapp/src/components/dominds-setup.tsx`
- HTTP client：`dominds/webapp/src/services/api.ts`
  - `writeWorkspaceLlmYaml()` 调用 `POST /api/setup/write-workspace-llm-yaml`
- WS client：`dominds/webapp/src/services/websocket.ts`
