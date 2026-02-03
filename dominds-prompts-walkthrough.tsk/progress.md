# Progress

- [owner:@prompt] 已更新 `ux-issues/prompts-issues.md`：补充“实现层禁止 `tool_call*`（仅 LLM API/provider 允许）”的命名/分层原则，并把“该改什么/改成什么（不含实现细节）”写入待修复清单。
- [owner:@prompt] 已完成：Collective teammate tellask 运行态验证 —— 对同一诉请 headline `!?@ux @cmdr !tellaskSession collective-fanout-verify`，@cmdr/@ux 均回贴收到，且双方都观察到 targets=`@ux,@cmdr` 与 tellaskSession=`collective-fanout-verify`。
- [owner:@prompt] 已完成：清理 docs/注释中残留术语（聚焦 `tool-call` 与“代理”）。
  - 验收扫描：`rg -n "\btool-call\b" -S dominds --glob '!**/*.tsk/**'` → EXIT:1（无命中）。
  - 验收扫描：`rg -n "\btool_call_\b" -S dominds/main dominds/webapp dominds/docs --glob '!**/*.tsk/**'` → EXIT:1（无命中）。
- [owner:@prompt] 已复核 `ux-issues/prompts-issues.md` 的 9 条“决策（已确认）”在当前工作区实现落地情况（锚点以当前工作区为准）：
  - 通过：决策 1/2/3/5/9。
    - `dominds/main/minds/system-prompt.ts:105`：中文补齐“多人集体诉请（一对多拆分）”。
    - `dominds/main/minds/system-prompt.ts:82` / `dominds/main/minds/system-prompt.ts:239`：Q4H（`!?@human`）原则 zh/en 对齐。
    - `dominds/main/tools/plan.ts:62` + `dominds/main/tools/builtins.ts:221`：`update_plan` 工具实现并加入 `codex_style_tools`。
  - 部分通过：决策 4/6。
    - `tool_call` 仅在 provider/模型参数语境仍有出现（例如 `dominds/main/team.ts:79`、`dominds/main/llm/gen/codex.ts:261`、`dominds/main/llm/defaults.yaml:49`），符合“provider-native term”但仍需由 @fullstack 评估是否要进一步收敛命名暴露面。
    - thought streaming 已有异常上报链路：`dominds/main/llm/gen.ts:26`、`dominds/main/llm/driver.ts:574`、`dominds/main/llm/gen/codex.ts:500`；但这不等同于“完整支持欠佳时已整改”。
  - 未完全落实：决策 8（待 @fullstack 落地）。
    - 决策 8：`dominds/docs/**` 中文文档仍大量残留“代理”（约 137 处命中；示例 `dominds/docs/dialog-persistence.zh.md:55`），需由 @fullstack 批量统一为“智能体”（注意避免改动 API 字段名如 `agentId`）。
- [owner:@prompt] 决策 7 已由 @fullstack 落地（不兼容）：
  - runtime：`dominds/main/llm/driver.ts` 已新增 `!?@tellasker` alias（仅支线对话可用），并移除 `@super` special-case。
  - 用户提示：`dominds/main/shared/i18n/driver-messages.ts` 已替换为 `!?@tellasker`，且不再暴露 Type A/B/C 到用户提示。
  - 系统提示：`dominds/main/minds/system-prompt.ts` 已改为 `!?@tellasker`，并使用“主线对话/支线对话 + 诉请者/被诉请者”叙事。
  - 文档：`dominds/docs/dialog-system.md`、`dominds/docs/dialog-system.zh.md`、`dominds/docs/dominds-terminology.md` 等已同步更新（含术语表新增“主线对话/支线对话”交叉说明）。
  - 验收扫描（@fullstack 回贴）：`rg -n "\\!\\?@super\\b|@super\\b" -S . --glob '!**/*.tsk/**'` → EXIT:1（无命中）。
  - 阻塞：仍需清空各 rtws 的 `.dialogs/`（至少 `.dialogs/` 与 `ux-rtws/.dialogs/`；保留 `dominds/tests/.dialogs` 夹具）。

- [owner:@prompt] 已落点修改（用于回归定位；行号可能随格式化漂移，以当前工作区为准）：
  - `dominds/README.md:187`：将 `conversational/tool-call noise` 改为 `conversational/tool-output noise`。
  - `dominds/docs/dialog-system.md:1017`：将 `markdown / tool-call` 改为 `markdown / function tool call`。
  - `dominds/docs/dialog-system.zh.md:1002`：将 `markdown / tool-call` 改为 `markdown / function tool call`；`dominds/docs/dialog-system.zh.md:1179`：将 `用户/代理` 改为 `用户/智能体`。
  - `dominds/docs/memory-system.md:152`：将 `Tool-call history` 改为 `Function tool call history`；`dominds/docs/memory-system.md:156`：对应段落同改。
  - `dominds/main/tools/txt.ts:850`：错误文案改为 `function tool call text`（避免 `tool-call` 连字符残留）。
  - `dominds/docs/mottos.zh.md`：标题与正文多处将“代理”改为“智能体”。
  - `dominds/docs/design.zh.md`：将文中 5 处“AI 代理/代理：”改为“AI 智能体/智能体：”。

- [owner:@prompt] 下一步：
  - 决策 7：请 @cmdr 清空 `.dialogs/` 与 `ux-rtws/.dialogs/`（保留 `dominds/tests/.dialogs`）。
  - 决策 8：等待 @fullstack 批量“代理→智能体”，回贴后验收扫描。