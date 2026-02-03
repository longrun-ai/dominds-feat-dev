# Progress

- [owner:@prompt] 已更新 `ux-issues/prompts-issues.md`：补充“实现层禁止 `tool_call*`（仅 LLM API/provider 允许）”的命名/分层原则，并把“该改什么/改成什么（不含实现细节）”写入待修复清单。
- [owner:@prompt] 已完成：Collective teammate tellask 运行态验证 —— 对同一诉请 headline `!?@ux @cmdr !tellaskSession collective-fanout-verify`，@cmdr/@ux 均回贴收到，且双方都观察到 targets=`@ux,@cmdr` 与 tellaskSession=`collective-fanout-verify`。
- [owner:@prompt] 已完成：清理 docs/注释中残留术语（聚焦 `tool-call` 与“代理”）。
  - 验收扫描：`rg -n "\btool-call\b" -S dominds --glob '!**/*.tsk/**'` → EXIT:1（无命中）。
  - 验收扫描：`rg -n "\b代理\b" -S dominds/docs --glob '!**/*.tsk/**'` → EXIT:1（无命中）。
  - 验收扫描：`rg -n "\btool_call_\b" -S dominds/main dominds/webapp dominds/docs --glob '!**/*.tsk/**'` → EXIT:1（无命中）。
- [owner:@prompt] 已落点修改（用于回归定位；行号可能随格式化漂移，以当前工作区为准）：
  - `dominds/README.md:187`：将 `conversational/tool-call noise` 改为 `conversational/tool-output noise`。
  - `dominds/docs/dialog-system.md:1017`：将 `markdown / tool-call` 改为 `markdown / function tool call`。
  - `dominds/docs/dialog-system.zh.md:1002`：将 `markdown / tool-call` 改为 `markdown / function tool call`；`dominds/docs/dialog-system.zh.md:1179`：将 `用户/代理` 改为 `用户/智能体`。
  - `dominds/docs/memory-system.md:152`：将 `Tool-call history` 改为 `Function tool call history`；`dominds/docs/memory-system.md:156`：对应段落同改。
  - `dominds/main/tools/txt.ts:850`：错误文案改为 `function tool call text`（避免 `tool-call` 连字符残留）。
  - `dominds/docs/mottos.zh.md`：标题与正文多处将“代理”改为“智能体”。
  - `dominds/docs/design.zh.md`：将文中 5 处“AI 代理/代理：”改为“AI 智能体/智能体：”。
- [owner:@prompt] 下一步（交给 @fullstack）：按文档清单做一次性重命名清理（不做向后兼容；改完清空 `./.dialogs/`、`ux-rtws/.dialogs/`）。