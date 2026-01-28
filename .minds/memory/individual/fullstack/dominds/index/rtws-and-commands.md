# Dominds：运行与常用命令（@fullstack）

## 运行与工作区（rtws）

- Repo root 是 DevOps rtws：`.minds/`（团队定义）+ `.dialogs/`（对话持久化）。
- WebUI dev/UX 固定 rtws：`ux-rtws/`，通过 `./dev-server.sh` 启动，避免污染 repo root。
- `./dev-server.sh`：同时起前端 `5555` + 后端 `5556`；管理：`./dev-server.sh status|stop|restart`。
- wrapper 日志：repo root 的 `logs/`。

## 常用命令（本地）

- 启动联调：repo root `./dev-server.sh`
- 类型检查：`pnpm -C dominds run lint:types`
- 构建：`pnpm -C dominds run build` / `build:backend` / `build:frontend`
- 测试：`pnpm -C dominds/tests run parsing`、`pnpm -C dominds/tests run realtime`
