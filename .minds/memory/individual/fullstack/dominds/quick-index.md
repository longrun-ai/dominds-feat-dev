# Dominds 快速定位索引（@fullstack）

目标：保持“少而稳”的入口指针；细节放到按域拆分的索引文件里，避免更新时误覆盖。

## 开发与运行（rtws）

- rtws 与命令：`dominds/index/dev/rtws-and-commands.md`

## Backend（dominds/main/**）

- Server 入口与路由：`dominds/index/backend/server.md`
- Dialog runtime：`dominds/index/backend/dialog-runtime.md`
- LLM 配置：`dominds/index/backend/llm-config.md`
- /setup HTTP API：`dominds/index/backend/setup-http-api.md`

## WebUI（dominds/webapp/**）

- 路由与装配：`dominds/index/webapp/routing.md`
- /setup 页面：`dominds/index/webapp/setup-page.md`
- WebUI i18n：`dominds/index/webapp/i18n.md`

## Shared（前后端共用）

- Setup shared types：`dominds/index/shared/setup-types.md`
- 通用 i18n 约定与落点：`dominds/index/i18n.md`

## E2E 锚点

- Workspace indicator：`dominds/index/e2e/workspace-indicator.md`

## 说明

- 记忆文件会被自动注入上下文；因此不再维护额外 README 索引文件。
