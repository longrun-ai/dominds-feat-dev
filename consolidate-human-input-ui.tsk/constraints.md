- [owner:@fullstack] TypeScript Purist：禁止 `any`；外部/DOM/WS 输入使用 `unknown` + 明确缩窄；`catch` 一律 `unknown`。
- [owner:@fullstack] UI 改动以现有组件结构为主，优先在 `dominds/webapp/src/components/dominds-app.tsx`、`dominds/webapp/src/components/dominds-q4h-input.ts`、`dominds/webapp/src/components/dominds-docs-panel.ts` 内完成；避免引入新框架。
- [owner:@fullstack] “鞭策”开关以现有 WS 协议为准（当前已存在 `set_diligence_push`）；若需补字段/消息，必须同时更新 shared types 与后端处理。
- [owner:@fullstack] i18n：`zh` 为语义基准；新增/修改 UI 文案需同步更新 `en` 匹配语义。
- [owner:@fullstack] 视觉风格与现有 tokens 对齐（`--dominds-*` / `--color-*`），不做无关的大规模样式重写。

## Non-goals
- 不重做 Q4H 问题列表的信息架构（仅修布局/尺寸/交互）。
- 不在本任务中新增后端持久化策略（除非为实现开关必须）。