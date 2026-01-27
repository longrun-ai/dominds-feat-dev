# Progress

- [owner:@fullstack] 已完成代码库入口扫描：确认 repo root 是 DevOps rtws（`.minds/` + `.dialogs/`）；WebUI dev 用 `./dev-server.sh` 固定 rtws 为 `ux-rtws/`，避免污染 repo root。
- [owner:@fullstack] 已定位关键目录：backend `dominds/main/`、server `dominds/main/server/`、tools `dominds/main/tools/`、persistence `dominds/main/persistence.ts`；webui `dominds/webapp/src/`（`services/` + `components/`）。
- [owner:@fullstack] 已把 backend workspace 指示器也接到 `/setup` 页：`dominds/webapp/src/components/dominds-setup.tsx` 启动时调用 `GET /api/health` 并在 header 渲染 `.workspace-indicator`。
- [owner:@fullstack] 已统一 `/setup` 页主题风格到主界面：`dominds/webapp/src/components/dominds-setup.tsx` 的样式改为使用全局 tokens（`--dominds-*` / `--color-*`），跟随 `html[data-theme]` 的 light/dark 切换。
- [owner:@fullstack] i18n 规则已归位到 rtws 层：从 `dominds/main/minds/system-prompt.ts` 移除固有 i18n 段，改为在 `.minds/team/fullstack/knowledge.zh.md` 与 `.minds/team/fullstack/knowledge.en.md` 注入双语维护约束，并在 `.minds/memory/team_shared/onboarding-guide.md` 增补 Guiding constraints。
- [owner:@fullstack] 已推进 `read_file` 行数语义统一：`dominds/main/tools/txt.ts` 的 `read_file` 输出统一为 `total_lines/size_bytes`，空文件语义为 0 行并显示 `<空文件>`；文档/提示词/测试已同步去掉旧字段引用。
- [owner:@fullstack] 已完成 overwrite 对账逻辑收敛：`dominds/main/tools/txt.ts` 的 `overwrite_entire_file` 仅使用 `known_old_total_lines/known_old_total_bytes` 严格对账（不再存在 bytes=0→lines=0 的兼容路径），并将 next 指引统一为“`read_file` 获取 `total_lines/size_bytes`”与“`preview_* → apply_file_modification`”。
- [owner:@fullstack] 回归：@cmdr 已跑 `pnpm -C dominds/tests run parsing`（exit 0）与 `pnpm -C dominds/tests run realtime`（exit 0）。