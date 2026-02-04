# E2E 冒烟检查清单（Playwright MCP）

## 前置

- 默认 `baseUrl = http://localhost:5555`（由 `./dev-server.sh` 启动，通常不需要鉴权）。
- 若无法访问 `http://localhost:5555`：提醒 @human 检查 dev server 是否在跑（以及端口/日志）；不要自行尝试跑 shell 命令。
- 只有在明确说明需要时，才使用其它 `baseUrl` 或执行认证/登录步骤。

## 冒烟旅程（建议顺序）

1. Setup/进入应用

- 打开 `baseUrl`
- 验证页面加载无致命报错（console 无 red error）

2. 建立/进入一个对话

- 创建或进入一个 dialog
- 发送一条最小输入（例如 “ping”）
- 验证运行状态可见、输出可见

3. 工具/错误可见性（最小）

- 触发一个可控错误（例如输入缺失字段/非法参数）
- 验证 UI 有明确的错误文案与下一步提示

4. 退出与恢复

- 刷新页面
- 验证对话状态可恢复（历史可见、可继续）

## 缺陷报告模板

- 标题：
- 严重度：P0/P1/P2
- 复现步骤：
- 期望：
- 实际：
- 证据：截图 / console 摘要 / network 状态码

## 收尾

- 用完调用 `mcp_release({"serverId":"playwright"})`
