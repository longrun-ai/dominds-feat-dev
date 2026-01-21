# Dominds DevOps 团队（按模块负责人）

目标：按知识边界划分负责人，避免重复扫描与认知过载；团队聚焦新功能开发、UX 验证、发布前回归测试把关；发布由人类手工执行。

## 域划分（7 个）
- Runtime / Dialog Engine
- Server / API / WS
- WebUI / UX
- CLI / TUI
- Tooling & Guardrails
- QA / Regression Gate
- MCP Integration（低频维护，按需介入）

## 统一协作节奏
- 功能计划：先写提案 `team/process/proposal-template.md`，相关域负责人在计划阶段给评估与拆分。
- 落地开发：按域负责人直接改代码；跨域改动优先冻结接口（API/WS schema、工具协议、CLI UX）。
- 发布前把关：按 `team/process/release-regression-checklist.md` 人工执行并记录结果；QA 域维护清单与失败判定。
