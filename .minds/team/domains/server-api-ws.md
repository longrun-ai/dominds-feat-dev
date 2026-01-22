# 域：Server / API / WS

## 覆盖范围（路径）

- `dominds/main/server.ts`
- `dominds/main/server/api-routes.ts`
- `dominds/main/server/websocket-handler.ts`
- `dominds/main/server/**`（其余 server 子模块）

## 职责

- 设计并维护 HTTP API 与 WS 协议（schema、版本兼容、错误与进度语义）
- 处理鉴权/会话/限流/输入校验等边界问题（按现有实现方式）
- 确保 WebUI/CLI 的调用体验稳定

## 交付物

- API/WS 契约（路径、参数、响应、错误码/错误体、WS 消息类型）
- 回归点清单（哪些接口/消息必须覆盖）
- 与 WebUI/CLI 的集成说明

## 接口与协作

- 对 WebUI：`/api/*` + `/ws` 的契约与变更公告
- 对 QA：提供冒烟用例与失败判定标准
