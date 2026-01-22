# 功能/改动提案模板（1 页）

## 背景与目标

- 要解决什么问题？用户价值是什么？

## 涉及模块（打勾）

- [ ] Product Manager (PM)
- [ ] Runtime / Dialog Engine
- [ ] Server / API / WS
- [ ] WebUI / UX
- [ ] CLI / TUI
- [ ] Tooling & Guardrails
- [ ] QA / Regression Gate
- [ ] MCP Integration

## Owner / Dependencies（必须写）

- Feature owner：
- 协作域：
- Dependencies：
- Rollout/回滚：

## 接口变更（必须写）

- API/WS：新增/变更的路径、参数、响应、错误语义
- 工具协议：新增/变更的工具、权限/审计点
- CLI：命令/参数/输出/退出码
- 事件/状态：新增/变更的状态字段、事件类型、日志语义

## 风险与兼容性

- 可能破坏哪些现有行为？如何降级/回滚？

## 验证与回归点

- 需要新增/更新哪些测试脚本或手工步骤？
- 发布前必须覆盖哪些路径？（交给 QA 纳入清单）

## 里程碑拆分

- M0：接口冻结
- M1：最小可用实现
- M2：回归与文档更新
