# UX Issues (Dominds)

这个目录是 UX 团队的可执行问题池：**可复现、可定位、可验收**，覆盖 WebUI / CLI / WS / API / Runtime / Tools 的端到端体验。

## 使用方式

- 新增 issue：`ux-issues/<short-slug>.md`
- 从模板开始：`ux-issues/_template.md`
- 优先写“端到端复现步骤”，而不是只写组件内部描述
- 必须包含“验收口径”（Acceptance Criteria），确保 QA/人类可验证

## 严重度定义

- **P0**：阻断核心流程；无可行绕过；或存在数据丢失/安全风险
- **P1**：高频失败或重大摩擦；有绕过但成本高
- **P2**：明显摩擦；间歇性；有低成本绕过
- **P3**：体验打磨；边缘场景；不影响主流程

## Owner 路由（按归属分流）

- **@webui**：UI 状态、渲染、实时更新、错误/进度呈现、客户端存储
- **@cli**：CLI 人机工程、exit codes、脚本稳定输出、进度输出
- **@server**：`/api/*` 与 `/ws` 契约、错误 schema、重连与恢复语义
- **@runtime**：dialog engine、状态机、执行模型、生命周期事件
- **@tooling**：工具注册、tool calling contract、guardrails/policies
- **@qa**：回归 gate、冒烟/回归脚本、flake 预防
- **@pm**：范围/优先级决策、rollout 与验收口径对齐

## Issue 内容规范

每个 issue 文件应包含：
- TL;DR（摘要 + 严重度 + area + owner）
- 复现步骤
- 当前 vs 期望
- 影响面（频率/成本/风险）
- 可能根因（未知就写 Unknown + 调查步骤）
- 修复草案（Fix Sketch）
- 验收口径（Acceptance Criteria）
- 手工回归清单（Regression Checklist）

## Index（保持更新）

- `enoent-path-drift-guidance.md` — 缺失文件/路径漂移错误的可操作性不足（P1）
- `tsk-guardrail-guidance.md` — `*.tsk/` 路径封装限制的引导不足（P1）
- `ws-reconnect-language-replay-observability.md` — WS 重连/重放的可观测性与用户反馈不足（P2）
- `round-reset-testability-and-flake.md` — round reset 可验证性差、易引入回归 flake（P2）