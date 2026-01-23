pm-onboarding（Dominds 现状理解）— Constraints
- 工具机制：以 `!?` 行首触发的诉请工具是主工作流；语法正确即可执行，不依赖函数工具。
- 封装差遣牒约束：不得对 `*.tsk/` 路径使用通用文件工具（read/list/replace/plan/apply/rm 等）；仅用 `!?@change_mind !goals|!constraints|!progress` 维护。
- 对齐原则：结论必须可回指到具体文件/符号/协议锚点（例如 `dominds/docs/**`、`dominds/main/**`），避免“凭印象”。