# WebUI 可测试性改造（系统性）

目标：把“可测性”作为 WebUI 的一等特性（对人也更顺手），使 `ux-stories/*.md` 能稳定、快速、低摩擦地通过，并最终回到“两轮连续验收”gate。

## 标准（v0，优先级从高到低）

1. **单一交互目标**：用户认为“能点的那块”就应该真能点；避免把可点击 icon 包在 display-only 容器里，产生「点了没反应」与 E2E 定位歧义。
2. **键盘可达**：关键控件必须可 Tab 聚焦；Enter/Space 可触发；focus ring 可见。
3. **状态可见且一致**：关键状态（connected / proceeding / interrupted / resumable counts 等）必须在 UI 中有明确、稳定的可观察节点，并且跨 tab 同步可预测（有 SLA）。
4. **a11y 语义优先**：保证正确 `role`、可访问名称、可聚焦性、禁用态语义（`disabled`/`aria-disabled`）与可读的状态文本。
5. **稳定定位优先于文案**：E2E 不能把 i18n 文案作为唯一定位依据；当 a11y 可访问名称会随语言变化时，为关键控件补充稳定标识。
6. **`data-testid` 只用于关键节点**：仅对关键控件/关键状态节点引入 `data-testid`（或稳定 `id`），并形成一致命名规范（见下）。
7. **错误“响亮”**：不吞错；失败必须在 UI 中呈现清晰、可复现的错误信息或状态（不要求截图，但要求可读）。

## 稳定标识命名建议（v0）

- 控件：`data-testid="toolbar.emergency_stop"`、`toolbar.resume_all`、`header.notification_history`、`dialog.create.submit` …
- 状态：`data-testid="conn.status"`、`toolbar.proceeding_count"`、`toolbar.resumable_count"`、`dlg.primary_action"` …

规则：用 `.` 分段；避免把 i18n 文案写进 testid；同一控件不要同时维护 2 套并行标识。

## 现有 stories 暴露的“痛点/风险”摘要

- `ux-stories/dlg-stop-resume.md`：
  - 强依赖“点击目标语义”（icon 可点、pill/count display-only），说明 UI 结构存在歧义点；应收敛为单一可点击目标。
  - 需要跨 tab 5s 内一致：要求明确同步机制与 UI 刷新触发点（SLA + 可观察）。
- `ux-stories/new-dialog-create-modal-regression.md`：
  - 以 tooltip 文案定位（Copy link / Notification history）在 i18n 下易脆；应补稳定标识。
  - modal 单例、关闭手势、double-submit 等需要明确的禁用态与反馈（更可测也更可用）。
- `ux-stories/mcp-toolset.md`：
  - Tools/Problems 面板需要“可达入口 + 可读状态 + 可刷新反馈”三件套，建议补稳定状态节点。
- `ux-stories/work-ui-lang.md`：
  - UI 语言切换与持久化：下拉控件本身与“当前语言标签”应具备稳定可观察节点。

## 初始改造清单（待 @fullstack 拆分落地）

P0（直接影响回归稳定性）

- 统一 toolbar “pill+icon+count”交互：整体可点（一个按钮），且键盘可达；禁用态与原因可见。
- 为故事关键控件补齐稳定标识（优先 `data-testid`）：Emergency Stop / Resume All / New Dialog / Create / Notification history / Tools / Problems / UI language dropdown。
- 为关键计数与连接状态提供稳定状态节点（可在 DOM 中直接读到）。

P1（提效/降低摩擦）

- 统一 modal 的 focus 管理与关闭手势；双击/连点时的禁用与 loading 反馈。
- 关键动作的反馈统一：toast + notification history 一致、可追溯。

## 回归验收

- 改造完成后，更新 `ux-stories/*.md` 以匹配新的稳定标识与交互语义。
- 重新启动“两轮全量回归窗口”：每轮可做一次 `./dev-server.sh prep`；两轮都需“无意外”。
