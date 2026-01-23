# PM “四件套”PRD-lite 模板（Dominds）

> 目的：把需求讨论快速收敛为可交付的跨域变更清单，并给出明确验收/回归口径。适用于小范围 LAN（~3 用户）优先、API 可能随时变更的 Dominds 风格项目。

## 1) 需求分流（Ownership / Scope）
- **一句话目标**：
- **用户故事/场景**：
- **不做什么（Non-goals）**：
- **涉及域与 owner（勾选并写负责人）**：
  - docs（@pm）：
  - runtime（@runtime）：
  - server（@server）：
  - webui（@webui）：
  - cli（@cli）：
  - tooling/guardrails（@tooling）：
  - qa/gate（@qa）：
- **影响面**：
  - 是否影响 `*.tsk/` / `!?@change_mind` / `!?@clear_mind` 语义？
  - 是否影响 Q4H、subdialog、keep-going、reminders、Problems？
  - 是否影响 `.minds/*` 配置面（team/llm/mcp）？

## 2) 依赖矩阵（Contracts / Data flow）
- **接口/通道**：
  - HTTP：`/api/...`（请求/响应字段、错误码、鉴权要求）
  - WS：消息类型（如 `problems_snapshot`、`drive_dialog_by_user_answer` 等）
  - 文件/持久化：`.dialogs/**`、`.minds/**`（是否需要 `latest.yaml`、是否新增 index）
- **关键语义对齐点（写成可测试句）**：
  - Backend-driven：前端不驱动状态机，只订阅事件/发请求。
  - Q4H：`!?@human` → `q4h.yaml` index + `questions_count_update`；答复包需带 `questionId`。
  - `*.tsk/`：通用文件工具不得读写；只允许 `!?@change_mind` 修改单一分段全文。
  - MCP：tool name 需满足 `^[a-zA-Z0-9_-]{1,64}$`；热更新 last-known-good；问题走 Problems。
- **权限/安全**：
  - Auth：dev/prod、HTTP Bearer、WS `Sec-WebSocket-Protocol: dominds-auth.<key>`、WebUI `?auth=` 行为。
  - `.minds/`：普通成员默认 deny；用 team-mgmt 工具管理（如有）。

## 3) 验收口径（Acceptance Criteria）
- **用户可见行为**（UI/CLI）：  
- **错误/边界行为**（必须明确“失败长什么样”）：  
- **可观测性**：
  - UI 是否能从 `latest.yaml` 正确显示 `lastModified`？
  - Problems 是否能反映 MCP/Provider/schema 错误？
- **中断/续跑**（若涉及 proceeding 控制）：
  - Stop/Emergency stop/Continue/Resume all 的状态与 reason 是否一致？
  - blocked（需用户输入）时是否禁止 Continue？

## 4) 回归点（Smoke / Regression Checklist）
- **Task doc**：`!?@change_mind` 不触发 round reset；`!?@clear_mind` 清 Q4H 保留 reminders/registry。
- **Q4H**：提出/展示/回答/清除链路（含 subdialog Q4H）。
- **keep-going**：root-only；budget 耗尽→强制 Q4H；空 diligence 禁用。
- **Auth**：dev mode 无效；prod 三态（unset/random、empty/disable、non-empty/enabled）；WebUI `?auth=` 不读写 localStorage。
- **MCP**：toolset 注册/过滤/命名合法性/热更新 last-known-good；`mcp_release`/`mcp_restart` 路径。
- **Tools & Problems UI**：Refresh 清旧 snapshot；`problems_snapshot`/`get_problems` 维持 active set。
