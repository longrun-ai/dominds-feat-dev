# WebUI 可测试性与可回归性（UX 主文档 v1 草案）

本文档的目标：把“可测试性/可回归性”当作 WebUI 的一等 UX 质量指标来设计与实现，使 `ux-stories/*.md` 的手工 E2E 回归可以稳定、低摩擦、可重复地执行，并最终回到“两轮连续验收”gate。

关联文档：

- 运行手册（如何跑回归、允许的恢复动作、报告格式）：`docs/webui-testing-guide.md`
- v0 原则与初始 backlog：`ux-issues/webui-testability-overhaul.md`

---

## 0. 基本前提（不会再单独“约束性能”）

我们是小规模 LAN 应用（~3 用户以内）。只要设计与实现不离谱，性能不是主要问题。

注意：不“约束性能”不代表不需要“可验收时序”。E2E 仍然需要**一致的、可复现的等待策略**（例如跨 tab 状态要在合理窗口内收敛），否则 Pass/Fail 会变成主观判断。

---

## 1. V1 覆盖面（全 WebUI 的最小可枚举范围）

本节回答“全 WebUI”到底包含哪些 surface。目的是让拆分/落地时不会 scope creep。

### 1.1 In-scope（V1 必须覆盖）

P0（直接影响 `ux-stories` 稳定回归）

- **App Shell / 顶栏与工具栏**（`dominds/webapp/src/components/dominds-app.tsx`）
  - 连接状态可见、可读（`<dominds-connection-status>`）
  - 全局操作：Emergency Stop / Resume All（含禁用态语义与原因）
  - Notification history（toast 历史）可打开/可清空/可持久化
  - Tools activity 可打开、可刷新、工具调用可见
  - Problems 可打开、可读、严重度可观察
  - UI language 下拉：可切换、可持久化、刷新后不回退

- **对话创建与选择链路**
  - New Dialog → Create Dialog modal：单例、关闭手势（Esc/点击遮罩）、提交中禁用与反馈（`dominds/webapp/src/components/create-dialog-flow.ts`）
  - 创建成功后：对话被选中、输入可用

- **对话运行控制链路**
  - Send / Stop / Resume（per-dialog + 全局控制）
  - 跨 tab 的关键状态/计数收敛（例如 resumable/proceeding count、interrupted/resumed 等）

- **Q4H（Question for Human）链路（最小可用 + 可定位）**
  - Q4H 面板可见性与选择/导航事件可用（`dominds/webapp/src/components/dominds-q4h-panel.ts`）
  - Q4H 输入框：禁用态、发送主按钮状态、placeholder i18n（`dominds/webapp/src/components/dominds-q4h-input.ts`）

P1（提效/减少摩擦，但不阻塞 v1）

- Setup 页（`dominds/webapp/src/components/dominds-setup.tsx`）：
  - 作为“环境入口”应具备可读状态（rtws/version/status/auth_required/error）与清晰失败反馈
  - 关键按钮/表单具备稳定定位点
- Docs/Team manual/Reminders/Context health 等“辅助面板”：
  - 只要求可打开、可关闭、键盘可达、不会遮挡/卡死主流程

### 1.2 Out-of-scope（V1 明确不做）

- auth-on 模式下的全套回归 gate（本 v1 以 dev 环境无 auth 为主）
- 移动端适配与触屏专门优化（仍需保证基本可用，不作为 gate）
- 大规模并发/高负载性能优化

---

## 2. 可测试性最低规范（v1 MUST / SHOULD）

这里的“可测试性”不是为了自动化，而是为了**人类操作可预测**，并让 E2E 具备稳定锚点。

### 2.1 MUST（必达线）

1. **单一交互目标（Click target is what you see）**

- 用户认为“能点的那块”必须真的能点；不要出现 display-only 容器包着可点 icon 的结构，导致“点到空白没反应”。

2. **键盘可达 + 可触发 + 可见焦点**

- 关键控件必须可 Tab 聚焦；Enter/Space 可触发。
- focus ring 必须可见（不能被样式吞掉）。

3. **禁用态语义正确且原因可理解**

- disabled 必须是语义禁用（`disabled` / `aria-disabled`），而不是仅靠样式灰掉。
- 关键禁用态需有“原因提示”（tooltip 或就地说明均可）。

4. **稳定“可定位”锚点（不依赖易变文案）**

- E2E 不允许把 i18n 文案作为唯一定位依据。
- 对“关键控件/关键状态节点”必须提供稳定标识：
  - 单例全局节点：优先稳定 `id`（例如现有 `#toolbar-emergency-stop`、`#toast-history-btn` 风格）。
  - 列表/重复节点：使用 `data-testid`。

5. **状态可见（可观察）**

- 关键状态必须在 UI 中有稳定、可读的观察点（例如连接状态、proceeding/interrupted/resumable 计数、tool call 完成态）。
- 不能只靠“感觉上应该好了”来判断。

6. **跨 tab/刷新后一致性：可预测**

- 对跨 tab 会影响决策的状态（例如 Resume All 计数、interrupted/resumed）必须在合理窗口内收敛，并在 UI 层有可观察的“已更新”效果。
- 重要约束（Dominds 口径）：**不做任何前端 tab 间通信机制**（例如 `BroadcastChannel`/`localStorage` 事件协作等）。同步应完全基于**后端事件推送**，等价于“跨不同机器的客户端同步”，跨 tab 只是该模型下的自然结果。

7. **失败响亮**

- 不吞错；错误必须在 UI 中呈现可读信息（允许简短，但必须可复现）。

### 2.2 SHOULD（强烈建议）

- **减少“必须刷新才能恢复”的频率**：允许把刷新作为恢复手段，但不应成为常态路径。
- **关键操作尽量可逆/可恢复**：例如 stop/resume、清空 toast history 的确认/可解释。
- **避免只在 hover 才出现的关键信息**：回归跑数时 hover 是不稳定动作；关键信息应常显或可键盘触达。

---

## 3. 稳定标识规范（v1 命名与使用）

### 3.1 优先级

1. a11y 语义（role/name/focus/keyboard）保证“人类可用”。
2. 稳定 `id`（单例全局节点）。
3. `data-testid`（关键节点，尤其是重复列表项、复杂结构、跨语言定位）。

### 3.2 `data-testid` 命名规范（v1）

- 形式：`<domain>.<area>.<item>[.<state>]`
- 例子：
  - 控件：`toolbar.emergency_stop`、`toolbar.resume_all`、`header.toast_history`、`dialog.create.submit`
  - 状态：`conn.status`、`toolbar.resumable_count`、`toolbar.proceeding_count`

规则：

- 不把 i18n 文案写进 testid。
- 同一控件不要并行维护两套稳定标识（避免 drift）。

---

## 4. 回归包与覆盖映射（v1）

最终 gate 仍以同一套 `ux-stories/*.md` 连续 2 轮为准；因此每个 in-scope surface 必须被映射到至少一篇 story 的步骤与二元断言。

### 4.1 当前 4 篇 story 覆盖了什么

- Story 1 `ux-stories/new-dialog-create-modal-regression.md`
  - 覆盖：New Dialog + Create Dialog modal + toast + notification history
- Story 2 `ux-stories/dlg-stop-resume.md`
  - 覆盖：Stop/Resume + Emergency Stop/Resume All + 跨 tab 收敛
- Story 3 `ux-stories/mcp-toolset.md`
  - 覆盖：Tools/Problems 面板 + MCP tool call 可见性
- Story 4 `ux-stories/work-ui-lang.md`
  - 覆盖：UI language 切换与持久化

### 4.2 覆盖缺口（需要补 story 或补断言）

（已转为新增 story 草案）

已新增（草案）：

- Story 0：`ux-stories/setup-smoke.md` — Setup 最小冒烟（/setup 路由 + 关键控件可定位）
- Story 5：`ux-stories/q4h-panel-input.md` — Q4H 最小链路（Ask → Select → Answer）

---

## 5. 交付物与落地节奏（面向协作）

### 5.1 v1 中间交付物（可评审）

- 覆盖矩阵：In-scope surface × story 映射（缺口必须转成 story/断言）。
- 标准落地清单：对每个“关键控件/关键状态节点”列出定位锚点（id/testid/a11y）与验收点。

### 5.2 回到验收窗口

- 标准与覆盖面落地后：更新 `ux-stories/*.md` 以匹配新的稳定锚点与交互语义。
- 再启动新的“两轮全量回归窗口”（按 `docs/webui-testing-guide.md` 执行）。

---

状态：草案（待 @human 审阅讨论）
