# Progress

- [owner:@prompt] 已更新 `ux-issues/prompts-issues.md`：补充“实现层禁止 `tool_call*`（仅 LLM API/provider 允许）”的命名/分层原则，并把“该改什么/改成什么（不含实现细节）”写入待修复清单。
- [owner:@prompt] 已完成：Collective teammate tellask 运行态验证 —— 对同一诉请 headline `!?@ux @cmdr !tellaskSession collective-fanout-verify`，@cmdr/@ux 均回贴收到，且双方都观察到 targets=`@ux,@cmdr` 与 tellaskSession=`collective-fanout-verify`。
- [owner:@prompt] 下一步（交给 @fullstack）：按文档清单做一次性重命名清理（不做向后兼容；改完清空 `./.dialogs/`、`ux-rtws/.dialogs/`）。