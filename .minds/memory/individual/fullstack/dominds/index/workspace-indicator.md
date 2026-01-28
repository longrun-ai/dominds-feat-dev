# Dominds：Workspace Indicator（端到端落点）（@fullstack）

- 后端：`GET /api/health` 返回 payload 中的 `workspace: string`。
- Webapp：`dominds/webapp/src/services/api.ts#getHealth()`；主界面与 `/setup` header 都渲染 `.workspace-indicator`。
