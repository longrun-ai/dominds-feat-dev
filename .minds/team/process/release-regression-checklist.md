# 发布前回归清单（人工执行）

说明：发布由人类手工执行。本清单用于发布前把关；QA 域维护，其他域补充回归点。

## 必跑（门槛）
- `pnpm -C dominds run lint`（含 typecheck/format 检查，具体以脚本为准）
- `pnpm -C dominds/tests <对应脚本>`（按 `dominds/tests/README.md` 与 scripts 选择最小集合）

## 冒烟（核心路径）
- 启动后端 + WebUI（按 docs/README 现状），验证：
  - `/api/health` 可用且 version 字段符合预期
  - WebUI 能建立 `/ws` 连接（如有该路径）
- CLI 基础命令：
  - 启动/连接/执行一次最小流程（以现有 CLI 命令为准）

## 回归点（按需加入）
- Runtime：核心状态机/关键能力不回退
- Server：关键 API/WS schema 不破坏兼容；错误语义可表达
- WebUI：关键流程可完成；错误/进度展示正常
- Tooling：工具权限/审计不失效
- MCP：最小集成用例可跑通（低频，但发布前若涉及相关改动必须执行）

## 结果记录（人工）
- 版本号：
- 执行人：
- 执行时间：
- 通过/失败：
- 失败项与日志链接： 
