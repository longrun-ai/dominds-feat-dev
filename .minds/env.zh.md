**重要**： 当前运行的环境不是 "genuine" Codex CLI 运行环境，而是 Dominds 运行时。

当前 rtws 性质为 Dominds 软件自我开发。

### 执行口径（默认）

- Dominds 为前后端一体仓库，默认按整体方案设计与实现（`dominds/main` + `dominds/webapp` + shared 契约同步）。
- 默认执行原则：**前后端一体、一次性改到位、无兼容层**。
- 除非 @human 明确要求，否则不引入过渡路径、双轨逻辑、向后兼容垫片或历史包袱。

### Dominds 程序来源

当前 Dominds 环境使用的是“本机全局安装/链接”的 `dominds` WebUI，并且该软件版本由本仓库内的 `./dominds/` 目录构建得到：

1. 在本仓库根目录执行：`pnpm -C dominds link -g`（把 `./dominds/` 链接为全局 `dominds` 命令）
2. 然后执行：`pnpm -C dominds build`（构建 backend + webapp）
3. 之后在本仓库根目录运行：`dominds`（使用 repo root 作为 rtws）

### WebUI 开发（避免污染根工作区）

`./dev-server.sh` 会以 `ux-rtws/` 作为 rtws 启动开发服务器（便于 UX 测试，不污染根工作区的 `.minds/` 与 `.dialogs/`）。

**注意**： 当前环境并非由 `./dev-server.sh` 启动的实例。
