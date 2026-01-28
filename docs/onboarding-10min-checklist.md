# Dominds 上手 Checklist（10 分钟）

目标：在 10 分钟内完成“启动 dev-server → 打开 WebUI → 找到一条 dialog 的持久化文件 → 找到对应 WS/HTTP handler”。

## 0) 前置条件

- Node.js：22.x（>=22 <23）
- 终端工作目录：repo root

## 1) 启动联调（rtws = `ux-rtws/`）

1. 在 repo root 启动：`./dev-server.sh`
2. 打开 WebUI：`http://localhost:5555`
3. 后端端口：`http://localhost:5556`

验证点：页面出现已连接状态（或能正常加载 dialog 列表）。

补充：`./dev-server.sh` 会把 stdout/stderr 写入 repo root 的 `logs/`。

## 2) 在 WebUI 创建一个 dialog

1. 在侧边栏点击 “New Dialog” 并创建
2. 在对话输入框发送任意消息，观察产生对话轮次与 streaming

验证点：侧边栏列表里能看到该 dialog（通常会显示 `rootId`）。

## 3) 在磁盘上找到该 dialog 的持久化文件

后端持久化根目录由 `process.cwd()` 决定：

- 代码：`dominds/main/persistence.ts` → `DialogPersistence.getDialogsRootDir()`
- 目录：`<rtws>/.dialogs/`

当你用 `./dev-server.sh` 启动时，rtws 为 `ux-rtws/`，所以持久化在：

- Root dialog：`ux-rtws/.dialogs/run/<rootId>/`
  - `dialog.yaml`（元信息）
  - `latest.yaml`（当前 round、lastModified、status 等）
  - `round-001.jsonl`（以及后续 `round-002.jsonl`…）
- Subdialog：`ux-rtws/.dialogs/run/<rootId>/subdialogs/<selfId>/`（结构同上）

提示：如果你还没创建过任何 dialog，`ux-rtws/.dialogs/` 目录可能不存在；创建后会自动生成。

## 4) 找到 WebSocket handler（/ws）

前端连接：

- `dominds/webapp/src/services/websocket.ts` → `new WebSocket(...)`

后端处理入口：

- `dominds/main/server/websocket-handler.ts` → `handleWebSocketMessage(ws, packet)`

最常用的 packet types（用于反向定位）：

- `create_dialog` / `display_dialog` / `display_round`
- `drive_dlg_by_user_msg`（用户消息驱动）
- `get_q4h_state` / `drive_dialog_by_user_answer`（Q4H）

## 5) 找到 HTTP handler（API 路由）

后端 HTTP 路由分发：

- `dominds/main/server/api-routes.ts` → `handleApiRequest(req, res)`

示例：

- 读 docs markdown：`GET /api/docs/read`（同文件内对应分支）

## 6) 快速回归检查（手工）

- 刷新页面：dialog 列表与消息能从 `.dialogs/` 恢复
- 切换 dialog：不会出现“残留 streaming bubble”
- 查看 `latest.yaml`：`lastModified` 会随对话推进更新

