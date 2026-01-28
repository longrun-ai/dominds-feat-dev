- [owner:@fullstack] 优先完成 bottom panel 的新交互调整：
  - 待处理问题（Problems）数量 > 0 时，header pill 用蓝底高亮。
  - Bottom panel footer：`Dominds 文档` tab 靠右对齐。
  - `团队管理手册`：从 docs-panel 内二级 tab 改为 bottom panel footer 右侧一级 tab（位于 `Dominds 文档` 左边），内容通过后端 `team_mgmt_manual` 工具交互式读取（而非 HTTP 读 markdown）。
  - 新增 `提示词模板` 一级 tab（位于 `团队管理手册` 左边，靠右对齐）：列出内置 `dominds/main/snippets/README.md` 模板，并支持用户新增/保存模板到 rtws `.minds/prompts/`；UI 综合显示内置 + workspace 自定义模板，并提供“一键插入到输入框”。

## Acceptance
- Problems 数量 > 0 时：`#toolbar-problems-toggle` pill 显示蓝底高亮；数量=0 时恢复默认样式。
- Bottom panel footer 右侧显示顺序：`提示词模板`、`团队管理手册`、`Dominds 文档`（三者靠右对齐）。
- `团队管理手册` tab：支持选择 topic（至少支持 topics index + permissions + team），并把结果以 markdown 渲染到面板中；切换 topic 不需要刷新页面。
- `提示词模板` tab：
  - 展示内置模板（从 `dominds/main/snippets/README.md` 提取或由后端提供结构化清单）；
  - 展示 workspace 模板（来自 `.minds/prompts/`）；
  - 点击“插入”会把模板插入 `dominds-q4h-input` 的输入框（光标位置或末尾）。
  - 支持新增模板（name + content），保存后立即出现在列表中，落盘到 `.minds/prompts/`。