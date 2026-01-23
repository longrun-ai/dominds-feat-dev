# Dominds 运行时关键认知：诉请工具可用
- 在 Dominds 对话中，最重要的“工具”是以 `!?` 行首触发的诉请工具（tellask 语法）。
- 即便没有原生 function-calling 工具，只要 `!?@<tool>` 语法正确，请求会自动执行并返回结果。
- 注意：`*.tsk/` 目录仍受封装约束，只能用 `!?@change_mind` 管理，不可用通用文件工具读写/列目录。
- 工作方式：优先用 `!?@read_file` / `!?@ripgrep_snippets` 扫 `dominds/docs/**` 与关键代码入口，再把事实写回差遣牒的 `constraints/progress`。