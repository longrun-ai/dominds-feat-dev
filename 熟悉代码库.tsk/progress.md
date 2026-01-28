# Progress

- [owner:@fullstack] 已完成代码库入口扫描：确认 repo root 是 DevOps rtws（`.minds/` + `.dialogs/`）；WebUI dev 用 `./dev-server.sh` 固定 rtws 为 `ux-rtws/`，避免污染 repo root。
- [owner:@fullstack] 已定位关键目录：backend `dominds/main/`、server `dominds/main/server/`、tools `dominds/main/tools/`、persistence `dominds/main/persistence.ts`；webui `dominds/webapp/src/`（`services/` + `components/`）。
- [owner:@fullstack] 已把 backend workspace 指示器也接到 `/setup` 页：`dominds/webapp/src/components/dominds-setup.tsx` 启动时调用 `GET /api/health` 并在 header 渲染 `.workspace-indicator`。
- [owner:@fullstack] 已统一 `/setup` 页主题风格到主界面：`dominds/webapp/src/components/dominds-setup.tsx` 的样式改为使用全局 tokens（`--dominds-*` / `--color-*`），跟随 `html[data-theme]` 的 light/dark 切换。
- [owner:@fullstack] i18n 规则已归位到 rtws 层：从 `dominds/main/minds/system-prompt.ts` 移除固有 i18n 段，改为在 `.minds/team/fullstack/knowledge.zh.md` 与 `.minds/team/fullstack/knowledge.en.md` 注入双语维护约束，并在 `.minds/memory/team_shared/onboarding-guide.md` 增补 Guiding constraints。
- [owner:@fullstack] 已推进 `read_file` 行数语义统一：`dominds/main/tools/txt.ts` 的 `read_file` 输出统一为 `total_lines/size_bytes`，空文件语义为 0 行并显示 `<空文件>`；文档/提示词/测试已同步去掉旧字段引用。
- [owner:@fullstack] 已完成 overwrite 对账逻辑收敛：`dominds/main/tools/txt.ts` 的 `overwrite_entire_file` 仅使用 `known_old_total_lines/known_old_total_bytes` 严格对账（不再存在 bytes=0→lines=0 的兼容路径），并将 next 指引统一为“`read_file` 获取 `total_lines/size_bytes`”与“`preview_* → apply_file_modification`”。
- [owner:@fullstack] 回归：@cmdr 已跑 `pnpm -C dominds/tests run parsing`（exit 0）与 `pnpm -C dominds/tests run realtime`（exit 0）。
- [owner:@fullstack] keep-going 预算改为仅由成员配置决定：移除 `.minds/diligence*.md` frontmatter 的 `max-num-prompts` 语义（frontmatter 仅被剥离不参与预算），默认 `diligence-push-max` 从 30 调整为 3；文档同步更新：`dominds/main/llm/driver.ts`、`dominds/docs/keep-going.md`。
- [owner:@fullstack] sidebar 工具视图按来源拆分为两组：`Dominds 工具` 与 `MCP 工具`（contract：`ToolsetInfo.source`; MCP toolset 在 `dominds/main/mcp/supervisor.ts` 标记为 `mcp`）。
- [owner:@fullstack] 新增 `apiType: openai` 的 LLM generator（参照 Anthropic wrapper）：`dominds/main/llm/gen/openai.ts` + `dominds/main/llm/gen/registry.ts` 注册；并补充冒烟脚本 `dominds/tests/provider/openai-streaming.ts`。
- [owner:@fullstack] WebUI：已完成 `dominds/webapp/src/components/dominds-q4h-input.ts` 清理：移除内嵌 Q4H list/footer 的渲染与交互，组件仅保留输入框 + 选中 question 的回答路由（list 由 bottom panel 的 `dominds/webapp/src/components/dominds-q4h-panel.ts` 负责）。
- [owner:@fullstack] 对账：补齐 subdialog 的 `latest.yaml` 初始化默认值：`dominds/main/persistence.ts` 初始化时写入 `disableDiligencePush:false`，保证 `/api/dialogs` 与 subdialog create 都覆盖该字段。
- [owner:@fullstack] 回归：@cmdr 已跑 `pnpm -C dominds run lint:types`（exit 0）与 `pnpm -C dominds run build`（exit 0）。
- [owner:@fullstack] 文档补齐“10 分钟上手 checklist”并对账路径：新增 `docs/onboarding-10min-checklist.md`；修正 `docs/webui-testing-guide.md` 中过时的 `dominds/webapp/main/**` 路径为 `dominds/webapp/src/**`；更新 `dominds/docs/cli-usage.md` 的 Dialog Storage 结构（`latest.yaml` + `round-001.jsonl`）。