# WebUI：Human input UI（Bottom panel / Q4H / Input）（@fullstack）

- 主容器与 bottom panel：`dominds/webapp/src/components/dominds-app.tsx`
  - Bottom panel footer tabs 固定在底部；点击活跃 tab 会收起（不再有 `bp-toggle`）。
  - Q4H 空态文案 `.bp-q4h-empty`（通过 `.hidden`/`.bp-q4h-empty.hidden` 控制）。
  - Diligence 真实 checkbox：`#diligence-toggle`，发送 `set_diligence_push`，并消费 `dialog_ready.disableDiligencePush` + `diligence_push_updated`。
  - Bottom panel 顶部抓手：`#bottom-panel-resize-handle`，拖动改变 `--bottom-panel-height`（驱动 `.bottom-panel-content` max-height）。
  - Q4H 选中事件：监听 `q4h-select-question`，同步 `dominds-q4h-input.setDialog({selfId,rootId})`，避免 answer 发错 dialog。

- Q4H 列表 UI：`dominds/webapp/src/components/dominds-q4h-panel.ts`
  - 选中逻辑不再 re-render（避免“闪一下选不中”）；首次选中会自动展开。
  - 展开/自动展开会 emit `q4h-question-expanded`（bubbles/composed）供 parent 做自动展开/调高。

- 输入区组件：`dominds/webapp/src/components/dominds-q4h-input.ts`
  - 顶部 `input-resize-handle`（位于 input-section 内、贴上边框、不额外占高）：手动调整 host 高度（上限约 50vh）。
  - `textarea.message-input` 自动高度：3–20 行（按行高计算）。手动拉高时 textarea 会随容器伸展。
  - send-on-enter 持久化：localStorage key=`dominds-send-on-enter`（'1' Enter 发送，'0' Enter 换行）。

- Docs panel：`dominds/webapp/src/components/dominds-docs-panel.ts` 新增“团队管理手册”tab（`team-mgmt-toolset.md`）。
- i18n：UI 字符串集中在 `dominds/webapp/src/i18n/ui.ts`（新增 `keepGoingToggleAriaLabel`）。