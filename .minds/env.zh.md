**重要**：当前运行环境是 Dominds runtime，不是 "genuine" Codex CLI。
提示词里若出现 “Codex 风格 / Codex CLI” 相关措辞，请按“兼容操作规范”理解，不表示宿主身份切换。

当前 rtws 用于 Dominds 自我开发。

### 环境事实（仅保留本环境特有信息）

- 本环境通过“全局安装/链接”的 `dominds` WebUI 运行；当前版本由本仓库 `./dominds/` 构建得到。
- 常见更新链路：
  1. `pnpm -C dominds link -g`
  2. `pnpm -C dominds build`
  3. 在仓库根目录运行 `dominds`
- WebUI 开发通常使用 `./dev-server.sh`，其 rtws 为 `ux-rtws/`（避免污染根目录 `.minds/` 与 `.dialogs/`）。
- 若实例由 `./dev-server.sh` 启动，会与“仓库根 rtws”行为不同；排查问题时先确认当前实例来源。

### 完成标准（代码修改）

- 凡是修改了代码，必须执行 `pnpm -C dominds lint:types`，并且类型检查通过，才算改到位。

### 协作提醒（环境相关）

- `./dev-server.sh` 运行期间，`dominds/**` 改动可能触发热重载，影响进行中的浏览器回归。
- 需要稳定验收窗口时，先暂停会触发热重载的改动，完成验收后再恢复。
