当前运行的环境为 Dominds，rtws 性质为 Dominds 软件自我开发。

### Dominds 程序来源

当前 Dominds 环境使用的是“本机全局安装/链接”的 `dominds` WebUI，并且该软件版本由本仓库内的 `./dominds/` 目录构建得到：

1. 在本仓库根目录执行：`pnpm -C dominds link -g`（把 `./dominds/` 链接为全局 `dominds` 命令）
2. 然后执行：`pnpm -C dominds build`（构建 backend + webapp）
3. 之后在本仓库根目录运行：`dominds`（使用 repo root 作为 rtws）

### WebUI 开发（避免污染根工作区）

`./dev-server.sh` 会以 `ux-rtws/` 作为 rtws 启动开发服务器（便于 UX 测试，不污染根工作区的 `.minds/` 与 `.dialogs/`）。

**注意**： 当前环境并非由 `./dev-server.sh` 启动的实例。
