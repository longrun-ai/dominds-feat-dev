# WebUI 可测试性改造卡片（v1，待分派）

目的：把 `docs/webui-ux-testability-v1.md` 的范围与 MUST/SHOULD 变成可分派的改造工作包（P0/P1），每项都能映射回 `ux-stories/README.md` 的回归抓手。

卡片模板（复制后填写）：

```md
## [P0/P1] <title>

- Surface：...
- 问题（现象/风险）：...
- 期望（用户视角）：...
- 推荐锚点：a11y / id / data-testid（写清落点与命名）
- 验收（Pass/Fail）：...
- 映射到 story：...
- Owner：@fullstack / @ux / ...
```

---

## PR 切片计划（建议，v1 P0 优先）

目标：把 P0 卡片收敛成 3–5 个“可独立合并”的 PR；每个 PR 都绑定到明确的 story gate，合并后可立刻跑一轮 smoke（不追求达标，只检查是否引入新意外）。

### PR-1（优先）：Story 2 稳定化（Stop/Resume + 全局控制 + 一致性可观察）

- 绑定卡片：
  - `[P0] Toolbar 全局控制的点击目标统一`
  - `[P0] Toolbar 全局控制禁用态：语义禁用 + 原因可理解`
  - `[P0] 跨 tab 状态收敛：可观察且在窗口内一致`
  - `[P0] “进行中(proceeding)”态：主按钮切换与输入可用性必须可观察`
  - `[P0] 跨客户端/跨 tab 同步：仅后端事件推送（禁止前端 tab 间通信）`
- 绑定验收：Story 2 `ux-stories/dlg-stop-resume.md` 全 gates 稳定通过（尤其 Step 6/7 的 “count reaches 0” 与 “within 5s”）。
- 备注：这是两轮窗口的最大阻塞项，优先闭环。

### PR-2：Story 1 稳定化（toast + notification history 入账 + 可观察）

- 绑定卡片：`[P0] Toast + Notification history：可靠记录 + 稳定触发锚点`
- 绑定验收：Story 1 `ux-stories/new-dialog-create-modal-regression.md` Gate G6 稳定通过。

### PR-3：Story 3 稳定化（Tools/Problems 刷新成功可观察）

- 绑定卡片：
  - `[P0] Tools panel：可打开/可刷新/时间戳可观察`
  - `[P0] Problems panel：可打开、可读、严重度/数量可观察`
  - （如需要）`[P0] 关键“状态节点”可观察（connected / counts / tool call）`
- 绑定验收：Story 3 `ux-stories/mcp-toolset.md` 所有 gates 稳定通过。

### PR-4：Story 5 稳定化（Q4H 选中态/计数可观察）

- 绑定卡片：`[P0] Q4H：Ask → Select → Answer 的最小闭环`
- 绑定验收：Story 5 `ux-stories/q4h-panel-input.md` 所有 gates 稳定通过。

### PR-5（若需要）：Story 0/4 的小幅加固

- 绑定卡片：
  - `[P0] Setup page smoke：路由 + 关键控件稳定可定位`
  - `[P1] UI language dropdown：键盘可达 + 状态可观察`
- 绑定验收：Story 0/4 gates 稳定通过；避免引入新的定位脆弱点。

## P0（直接影响回归稳定性）

## [P0] Toolbar 全局控制的点击目标统一（Emergency Stop / Resume All）

- Surface：App 顶栏全局控制（`dominds/webapp/src/components/dominds-app.tsx`）
- 问题（现象/风险）：当前 story2 需要强调“只点 icon button，不要点 pill/count”，说明 UI 存在 display-only 区域与可点区域不一致的歧义点。
- 期望（用户视角）：用户认为“能点的那块”整体可点；键盘可达；禁用态语义正确且原因可理解。
- 推荐锚点：保留现有稳定 `id`（`#toolbar-emergency-stop` / `#toolbar-resume-all`；以及 pill/count 的 `#toolbar-*-pill` / `#toolbar-*-count`），并让“用户可见 pill 区域”与“可触发按钮”保持一致（不要求新增锚点，但允许新增 `data-testid=toolbar.emergency_stop` / `toolbar.resume_all` 作为兜底）。
- 验收（Pass/Fail）：Story 2 不再需要“click target semantics”告警仍可稳定执行；键盘 spot-check 仍通过（Tab 聚焦 `#toolbar-emergency-stop` / `#toolbar-resume-all`，Enter/Space 可触发）。
- 映射到 story：Story 2 `ux-stories/dlg-stop-resume.md`
- 回归风险/热重载注意：改动位于 `dominds/webapp/src/components/dominds-app.tsx` 的 header/事件委派；`./dev-server.sh` 下会触发热重载，避免在 `@browser_tester` 进行中的两轮回归窗口中途落改动。
- Owner（建议）：@fullstack

## [P0] Toolbar 全局控制禁用态：语义禁用 + 原因可理解

- Surface：App 顶栏全局控制（`dominds/webapp/src/components/dominds-app.tsx`）
- 问题（现象/风险）：当前 pill 可能以“样式/展示”表达禁用，用户不一定知道“为什么不能点”；回归跑数时容易产生“是 bug 还是条件未满足”的判断歧义。
- 期望（用户视角）：禁用态是语义禁用（button `disabled` / `aria-disabled`）；并能在 UI 中读到禁用原因（tooltip 或就地说明均可，但不要要求 hover 才能拿到关键信息）。
- 推荐锚点：
  - 继续使用 `#toolbar-emergency-stop` / `#toolbar-resume-all` 做唯一触发点。
  - 为禁用原因提供稳定可读锚点（例如在 pill 内加一段 visually-hidden 的原因文本并用 `aria-describedby` 关联；如需 `data-testid`，建议 `toolbar.emergency_stop.disabled_reason` / `toolbar.resume_all.disabled_reason`）。
- 验收（Pass/Fail）：Story 2 中当 proceeding/resumable count 为 0 时，禁用态符合语义且原因可读；当条件满足时可触发并出现预期确认/行为。
- 映射到 story：Story 2 `ux-stories/dlg-stop-resume.md`（steps 5/6 + gates：disabled 条件与键盘可达）
- 回归风险/热重载注意：涉及 a11y 属性与 tooltip/文案；注意 i18n（`zh` 为语义基准），避免引入仅英文原因。
- Owner（建议）：@fullstack

## [P0] 跨 tab 状态收敛：可观察且在窗口内一致

- Surface：对话运行控制链路 + 全局计数（`dominds/webapp/src/components/dominds-app.tsx`）
- 问题（现象/风险）：Story 2 明确要求第二个 tab 在 5s 内一致；历史上出现过 resume-all count 不归零/跨 tab 不一致导致 Fail。
- 期望（用户视角）：跨 tab 的 proceeding/resumable/interrupted 等关键状态在合理窗口（当前 gate=5s）内自动收敛；UI 有可观察的“已更新”效果，避免只能靠刷新/猜测。
- 推荐锚点：
  - 现有 `#toolbar-emergency-stop-count` / `#toolbar-resume-all-count` 作为计数锚点。
  - 如需新增可观察点，建议新增 **machine-readable 状态节点**（不依赖文案）：
    - `data-testid=toolbar.proceeding_count` / `toolbar.resumable_count`
    - 以及一个“最近一次后端收敛/刷新”的时间戳属性（例如 `data-last-run-control-refresh-ts`），用于让回归能二元判断“确实收到了后端推送并完成 UI 收敛”。
- 验收（Pass/Fail）：Story 2 gate “Second tab reflects stop/resume state within 5s” 稳定通过；且“Resume count reaches 0” gate 稳定通过。
- 映射到 story：Story 2 `ux-stories/dlg-stop-resume.md`（step 7 + gates）
- 回归风险/热重载注意：任何“刷新 hint/定时 refresh”都可能影响 UX（闪动/焦点丢失）；验收需覆盖“连续两轮回归”下无意外。
- Owner（建议）：@fullstack

## [P0] “进行中(proceeding)”态：主按钮切换与输入可用性必须可观察

- Surface：对话输入区（Send/Stop）与 run-state 标记（`dominds/webapp/src/components/dominds-app.tsx`、`dominds/webapp/src/components/dominds-q4h-input.ts`、dialog container）
- 问题（现象/风险）：长回复开始/结束时，Stop/Send 切换、输入禁用/恢复可能闪烁或不同步，导致 story2 gate（2s 内切到 Stop、Stop 2s 内生效、完成后输入恢复）易误判。
- 期望（用户视角）：
  - streaming 开始后，主操作在可预期窗口内切到 Stop；
  - streaming 停止/完成后，输入在可预期窗口内恢复可用；
  - 整个过程有稳定“状态节点”可观察（不靠猜）。
- 推荐锚点：
  - 为 composer/run-state 提供 machine-readable 属性（例如 `data-run-state=idle|proceeding|interrupted` 或 `aria-busy=true|false`），并在状态切换时保证一致更新。
  - Stop/Send 按钮本身保持 a11y name 稳定（不依赖 tooltip 文案做唯一定位）。
- 验收（Pass/Fail）：Story 2 Step 2/3/4 的 gates 稳定通过；且 Story 4 Step 5（发送消息不应触发异常/回退）不再出现“短暂不可发/需要额外点击恢复”的偶发点。
- 映射到 story：Story 2、Story 4
- 回归风险/热重载注意：此类改动容易引入焦点丢失/滚动跳变；需要在两轮回归内验证“无意外”。
- Owner（建议）：@fullstack

## [P0] 关键控件补齐稳定标识（跨语言不脆弱）

- Surface：App shell + dialog create + tools/problems + toast history + ui language + setup + q4h
- 问题：部分 story 仍可能依赖 tooltip 文案或结构定位，i18n 下易脆。
- 期望：关键控件/状态节点具备稳定定位点（优先 a11y；必要时 `data-testid` 兜底），且命名一致。
- 推荐锚点：按 `docs/webui-ux-testability-v1.md` 的 testid 规范；重复列表项用 `data-testid`，单例节点用稳定 `id`。
- 验收：Story 1/3/4/5 在 zh/en 下均可稳定定位关键控件。
- 映射到 story：Story 1/3/4/5
- 回归风险/热重载注意：引入 `data-testid` 不应与现有 `id` 并行漂移；新增锚点后要同步更新 `ux-stories/*.md` 的定位方式，避免 “story 仍用旧定位” 导致假 Fail。
- Owner（建议）：@fullstack（实现）+ @ux（同步更新 stories）

## [P0] 关键“状态节点”可观察（connected / counts / tool call）

- Surface：连接状态、proceeding/resumable 计数、tools registry 时间戳/刷新反馈、tool call 完成态
- 问题：回归过程中容易出现“感觉上应该好了但 UI 不可观察”的判断歧义。
- 期望：关键状态在 UI 中有稳定、可读、可定位的观察点。
- 推荐锚点：优先语义化 role/name；必要时为状态文本/徽标补 `data-testid`。
- 验收：每条 story 的 gate 都能用“可观察节点变化”做二元判断。
- 映射到 story：Story 2/3
- 回归风险/热重载注意：对连接状态（`<dominds-connection-status>`）建议补 `id`/`data-testid`（例如 `conn.status`）以便跨语言定位；不要用仅文案变化来判断连接态。
- Owner（建议）：@fullstack

## [P0] New Dialog → Create Dialog modal：稳定锚点 + 可键盘操作（Story 1 gate）

- Surface：对话创建与选择链路（`dominds/webapp/src/components/dominds-app.tsx` + `dominds/webapp/src/components/create-dialog-flow.ts`）
- 问题（现象/风险）：Story 1 对 modal 单例、关闭手势、可聚焦、double-submit 等都有硬 gate；若锚点或焦点/禁用语义漂移，回归会高摩擦。
- 期望（用户视角）：
  - 工具栏按钮 `#new-dialog-btn` 可见可点；
  - modal 单例，且 backdrop 点击与 Esc 都能关闭；
  - 点击输入区能出现 caret/focus ring（不要求自动聚焦，但必须可聚焦）；
  - `Create Dialog` 提交中禁用且有“Creating...”反馈，不会重复创建。
- 推荐锚点（现有优先）：
  - `#new-dialog-btn`
  - modal：`role="dialog" aria-labelledby="modal-title"`、`#modal-title`
  - 表单：`#task-doc-input`、`#task-doc-suggestions`、`#teammate-select`、`#shadow-teammate-select`
  - 按钮：`#create-dialog-btn`、`#modal-cancel-btn`；关闭按钮建议补 `data-testid=dialog.create.close`
- 验收（Pass/Fail）：Story 1 gates G1/G3/G4 稳定通过（modal 单例+关闭手势、double-submit、create success）。
- 映射到 story：Story 1 `ux-stories/new-dialog-create-modal-regression.md`
- 回归风险/热重载注意：此改动会触发 modal DOM 结构/事件；注意不要引入“只有 hover 才出现关键信息/按钮”的模式。
- Owner（建议）：@fullstack

## [P0] Create Dialog：taskdoc suggestions 空态与 i18n（Story 1 gate）

- Surface：Create Dialog modal taskdoc autocomplete（`dominds/webapp/src/components/create-dialog-flow.ts`）
- 问题（现象/风险）：Story 1 gate 要求空态文案本地化、且任意 taskdoc path 仍可创建；若空态依赖英文硬编码或阻止创建，会导致回归失败。
- 期望（用户视角）：无匹配时空态文案随 UI language 切换；输入不存在的 taskdoc path 仍允许创建。
- 推荐锚点：`#task-doc-input`、`#task-doc-suggestions`（若渲染“empty state”，建议为该节点加 `data-testid=dialog.create.taskdoc_suggestions.empty_state`）。
- 验收（Pass/Fail）：Story 1 gate G2 稳定通过。
- 映射到 story：Story 1 `ux-stories/new-dialog-create-modal-regression.md`
- 回归风险/热重载注意：避免让“空态=阻止创建”成为隐式行为；这与当前 story 契约冲突。
- Owner（建议）：@fullstack

## [P0] Toast + Notification history：可靠记录 + 稳定触发锚点（Story 1 gate）

- Surface：toast 系统与通知历史（`dominds/webapp/src/components/dominds-app.tsx` + dialog list copy-link action）
- 问题（现象/风险）：Story 1 已记录“toast 出现但 history 为空”的已知问题；此外当前触发 toast 的步骤依赖 tooltip 文案（`Copy link/复制链接`），不符合“禁止依赖易变文案”的要求。
- 期望（用户视角）：
  - 任何 toast 都会被写入 notification history（至少最新一条）；
  - 触发 toast 的 UI 控件可跨语言稳定定位。
- 推荐锚点（现有优先）：
  - history：`#toast-history-btn`、`#toast-history-modal`、`#toast-history-list`、`#toast-history-clear`
  - toast 触发：优先使用现有 `data-action="dialog-share-link"`（dialog list icon button）作为稳定定位点；如需补充，可为该按钮补 `data-testid=dialog_list.share_link`。
  - history 可观察：为 `#toast-history-list` 增加 machine-readable 属性（例如 `data-count=<n>` 或首条 item 的稳定属性 `data-notification-id`），避免回归只能“肉眼看是否为空”。
- 验收（Pass/Fail）：Story 1 gate G6 稳定通过（toast 后 history 非空且包含最近 toast）。
- 映射到 story：Story 1 `ux-stories/new-dialog-create-modal-regression.md`
- 回归风险/热重载注意：涉及 localStorage/persistence（`dominds-toast-history-v1`）；需要覆盖“刷新后仍可打开且列表一致”。
- Owner（建议）：@fullstack（实现）+ @ux（更新 story1 的定位方式）

## [P0] Tools panel：可打开/可刷新/时间戳可观察（Story 3 gate）

- Surface：Tools activity view（`dominds/webapp/src/components/dominds-app.tsx`）
- 问题（现象/风险）：Story 3 gate 依赖“能打开 tools panel、能 refresh 且 timestamp 更新”；若缺少稳定锚点或刷新反馈不明显，会导致回归主观。
- 期望（用户视角）：Tools 面板可打开且 toolset 可展开；刷新后有可观察变化（timestamp 或列表变化）。
- 推荐锚点（现有优先）：`#tools-registry-refresh`、`#tools-registry-timestamp`、`[data-activity-view="tools"]`。
  - 若当前缺少“可断言的刷新成功”，建议补一个 machine-readable 属性（例如 list 容器 `data-registry-updated-at`），避免回归只能靠“看起来刷新了”。
  - 如需补“打开 Tools 面板”的稳定锚点，建议为 activity bar 的 tools 按钮补 `data-testid=activity.tools`（避免依赖文案）。
- 验收（Pass/Fail）：Story 3 gates 全部通过（open + expand + refresh updates）。
- 映射到 story：Story 3 `ux-stories/mcp-toolset.md`
- 回归风险/热重载注意：避免刷新导致面板关闭/焦点丢失（影响可用性）；新增锚点需同步 story3。
- Owner（建议）：@fullstack

## [P0] Problems panel：可打开、可读、严重度/数量可观察（Story 3 gate）

- Surface：Problems panel（`dominds/webapp/src/components/dominds-app.tsx`）
- 问题（现象/风险）：Story 3 要求 Problems panel 可打开且可读；若仅靠颜色/hover 表达严重度，不利于可测试性。
- 期望（用户视角）：Problems 按钮可稳定定位、可触发打开；panel 内至少能读到“数量/严重度/条目文本”。
- 推荐锚点（现有优先）：`#toolbar-problems-toggle`；如需补充，可为 problems 列表容器增加 `data-testid=problems.list`。
- 验收（Pass/Fail）：Story 3 gate “Problems panel opens and is readable” 稳定通过。
- 映射到 story：Story 3 `ux-stories/mcp-toolset.md`
- 回归风险/热重载注意：注意 i18n（标题/空态/严重度标签），不要让判定只能靠英文关键词。
- Owner（建议）：@fullstack

## [P0] Q4H：Ask → Select → Answer 的最小闭环（Story 5 gate）

- Surface：Q4H panel + input（`dominds/webapp/src/components/dominds-app.tsx`、`dominds/webapp/src/components/dominds-q4h-panel.ts`、`dominds/webapp/src/components/dominds-q4h-input.ts`）
- 问题（现象/风险）：Q4H 是高频关键链路；如果“选不中/选中后闪烁/答案发错 dialog”会直接阻断回归与真实使用。
- 期望（用户视角）：Q4H 面板在有 pending 时可见；问题卡片可选中且保持可读；输入框可输入并发送；发送后 pending count 下降并在归零时隐藏。
- 推荐锚点（现有优先）：`#q4h-panel`、`#q4h-input`、`.q4h-question-card[data-question-id]`。
  - 如需补充：为“选中态”提供稳定属性（例如 `data-selected="true"`）或 `data-testid=q4h.question.<state>`（避免依赖高亮样式）。
  - 建议：`#q4h-panel`（host）增加 `data-count=<n>` 这类 machine-readable 属性，避免“是否归零/是否隐藏”只能靠肉眼判断。
- 验收（Pass/Fail）：Story 5 gates 全部稳定通过。
- 映射到 story：Story 5 `ux-stories/q4h-panel-input.md`
- 回归风险/热重载注意：该链路容易受 streaming/状态推送影响；避免通过“强制 re-render”修复导致选中态抖动。
- Owner（建议）：@fullstack

## [P0] Setup page smoke：路由 + 关键控件稳定可定位（Story 0 gate）

- Surface：Setup 页（`dominds/webapp/src/components/dominds-setup.tsx` + 路由入口 `dominds/webapp/src/main.ts`）
- 问题（现象/风险）：Setup 是环境入口；若 `/setup` 路由或关键控件锚点漂移，会导致 story0 Blocked/Fail，直接影响两轮回归。
- 期望（用户视角）：`/setup` 能渲染；语言下拉、Refresh、Go 按钮存在且可交互；若需要 auth，相关输入与提交按钮存在。
- 备注：尽管 `docs/webui-ux-testability-v1.md` 覆盖面将 Setup 归类为 P1，但由于 Story 0 已纳入回归套件的 canonical run order，本卡在“两轮连续验收”窗口内按 P0 优先。
- 推荐锚点（现有优先）：`#setup-lang-select`、`#refresh-btn`、`#go-btn`、（auth 模式）`#auth-key`、`#auth-submit`。
- 验收（Pass/Fail）：Story 0 gates 全部通过。
- 映射到 story：Story 0 `ux-stories/setup-smoke.md`
- 回归风险/热重载注意：Setup 在 Shadow DOM 内，锚点必须在 Shadow 内稳定存在；避免把关键按钮改成仅 icon/仅 hover 可见。
- Owner（建议）：@fullstack

## [P0] 跨客户端/跨 tab 同步：仅后端事件推送（禁止前端 tab 间通信）

- Surface：所有依赖“一致性收敛窗口”的状态（例如 Resume All 计数、proceeding/resumable counts、marker events）。
- 问题（现象/风险）：任何前端 tab 间通信（`BroadcastChannel`/`storage event` 等）都会制造“同机 tab 看似同步”的假象，并引入额外分支；Dominds 的一致性模型应直接覆盖跨机器客户端。
- 期望（用户视角）：跨机器/跨客户端一致性完全由后端事件推送达成；跨 tab 只是自然结果；**不实现任何** tab side-channel。
- 推荐锚点：计数/状态仍以 `#toolbar-*-count` 或 `data-testid` 可观察（避免让测试依赖 side-channel 本身）。
- 验收（Pass/Fail）：Story 2 的跨 tab 一致性 gate 稳定通过；在“同机双 tab”与“跨机器双客户端”语义上不矛盾。
- 映射到 story：Story 2 `ux-stories/dlg-stop-resume.md`
- 回归风险/热重载注意：避免用“定时 refresh”掩盖后端推送缺陷；若出现不收敛，应 loud fail 并定位后端推送链路。
- Owner（建议）：@fullstack

---

## P1（提效/降低摩擦）

## [P1] Create Dialog modal 的 focus/禁用/反馈一致性

- Surface：Create Dialog modal（`dominds/webapp/src/components/create-dialog-flow.ts`）
- 问题（现象/风险）：回归/日常使用中会频繁触发创建对话；若焦点/禁用/反馈不一致，会造成误操作（重复创建、以为卡死）与回归摩擦。
- 期望：连点/双击不会导致重复创建；提交中禁用与文案反馈一致；Esc/遮罩关闭稳定。
- 推荐锚点：沿用 P0 卡中的 modal/form/button 锚点（`#task-doc-input` / `#create-dialog-btn` / `#modal-cancel-btn` / `#modal-title`），避免新增第二套定位点。
- 验收：Story 1 对“单例 + 关闭手势 + double-submit”稳定通过。
- 映射到 story：Story 1
- 回归风险/热重载注意：此处通常会影响 modal 的 DOM/焦点管理；需 spot-check 键盘可达（Tab/Enter/Escape）与 focus ring 可见。
- Owner（建议）：@fullstack

## [P1] UI language dropdown：键盘可达 + 状态可观察（减少“只靠文案”）

- Surface：UI language 下拉（`dominds/webapp/src/components/dominds-app.tsx`）
- 问题（现象/风险）：Story 4 目前用“至少一处可见文案变化”做断言，容易因为文案调整/i18n 细节变得脆弱；同时需要确保键盘可达与焦点可见。
- 期望（用户视角）：下拉可通过键盘打开/选择；选择后 header label 更新且刷新后持久化；并提供一个不依赖具体文案的可观察点。
- 推荐锚点（现有优先）：`#ui-language-menu-button`、`#ui-language-menu`、`#ui-language-menu-button-label`；如需兜底可为按钮补 `data-testid=header.ui_language`。
- 验收（Pass/Fail）：Story 4 gates 稳定通过；并能在不依赖具体文案的前提下确认“语言已切换”（例如观察 `data-ui-language` 变化）。
- 映射到 story：Story 4 `ux-stories/work-ui-lang.md`
- 回归风险/热重载注意：避免让关键信息只存在于 tooltip 的多行文本里（hover 不稳定）。
- Owner（建议）：@fullstack + @ux（更新 story4 的断言/锚点）

## [P1] Toast + Notification history 的一致性与可追溯

- Surface：toast + history（`dominds/webapp/src/components/dominds-app.tsx`）
- 问题（现象/风险）：即便 P0 已让“toast 必入库”，若 history 的清空/关闭/可追溯性不稳，仍会降低排障与回归效率。
- 期望：toast 出现后 history 必然可见且不空；清空/关闭手势稳定。
- 推荐锚点：`#toast-history-btn` / `#toast-history-modal` / `#toast-history-list` / `#toast-history-clear`（避免新增第二套）。
- 验收：Story 1 的通知历史 gate 稳定通过。
- 映射到 story：Story 1
- 回归风险/热重载注意：toast/history 涉及本地持久化与刷新后的恢复；需要覆盖刷新后仍可打开且列表不异常。
- Owner（建议）：@fullstack

## [P1] 辅助面板（Docs/Team manual/Reminders/Context health）：可打开可关闭且键盘可达

- Surface：辅助面板（`dominds/webapp/src/components/dominds-app.tsx` 及相关 panel components）
- 问题（现象/风险）：回归与日常操作会频繁打开辅助面板；若遮挡/卡死主流程、或只能鼠标 hover 操作，会显著增加回归摩擦。
- 期望（用户视角）：面板可通过键盘打开/关闭；关闭后焦点回到合理位置；不会遮挡导致无法继续 story（例如无法回到对话输入/Toolbar）。
- 推荐锚点：为每个 panel toggle 提供稳定 `id` 或 `data-testid`（建议 `panel.docs.toggle` / `panel.team_manual.toggle` / `panel.reminders.toggle` / `panel.context_health.toggle`），并为面板根节点提供 `role`/`aria-label`。
- 验收（Pass/Fail）：不新增 story gate（v1 P1），但在两轮回归过程中打开/关闭面板不引入“必须刷新才能恢复”的情况。
- 映射到 story：间接影响 Story 1/2/3/4/5（跑数过程中的操作摩擦）
- 回归风险/热重载注意：此类改动易引入焦点/滚动/遮罩层 bug；需要配套最小手工 spot-check（Tab 导航 + Escape 关闭）。
- Owner（建议）：@fullstack
