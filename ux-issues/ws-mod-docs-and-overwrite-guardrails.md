# ws_mod: document hunk TTL=1h + replace raw overwrite with `overwrite_entire_file` (known_old_stats + content_format)

## TL;DR

- **Summary:** `ws_mod` 的两轮 preview→apply 工作流本身 OK，但需要把 “hunk TTL=1h + 自动清理 + 未使用无副作用” 写进综合指南以降低焦虑；同时建议**删除** `replace_file_contents`，改为更明确的 `overwrite_entire_file`，并通过 `known_old_stats` + `content_format` 护栏降低误写风险。
- **Severity:** P1
- **Area:** Tools / Docs
- **Owner:** @tooling
- **Status:** Open
- **Added:** 2026-01-24

## Context

用户/agent 进行文本编辑时，`ws_mod` 通过“所有增量编辑先 preview，再 apply”显著降低误操作风险，并且两轮消息设计是刻意的防呆（避免同轮并行导致 preview/apply 竞态）。

但在实际使用中，仍有两类高频摩擦：

1. 文档没有明确写出 `hunk_id` 的 TTL（目前约 1 小时）与“未使用 hunks 无副作用、会自动清理”的心智模型，导致 agent 过度担心“hunk 会不会废弃/会不会影响后续”，进而频繁重新 preview、重复工作。
2. `replace_file_contents` 作为“例外直写”工具，命名容易让人误以为“替换一段/应用 diff”；一旦把 patch/diff 文本当正文传入，会直接覆盖文件造成数据损失。

## Repro Steps

### A. hunk TTL 文档缺失导致焦虑/重复 preview

1. agent 使用 `preview_*` 多次生成多个 `hunk_id`
2. agent 不确定 TTL/清理策略，担心旧 hunk 会影响后续或很快失效
3. agent 选择重复 preview，或不敢并行规划多个变更

### B. raw overwrite 误写 diff（数据损失风险）

1. 复制一段 unified diff / patch 文本（含 `@@` / `diff --git` / `+++` / `---` / `*** Begin Patch` 等）
2. 调用 raw overwrite 工具并把 diff/patch 粘贴为正文
3. 文件被按字面覆盖写入 diff/patch 文本（风险不可逆，除非有 VCS/备份）

## Current Behavior

- `ws_mod` prompt 中仅写 “hunk 有 TTL”，但未给出明确 TTL 数值与“多余 hunks 无副作用、会自动清理”的降压说明。
- 当前 raw overwrite 工具名为 `replace_file_contents`，会直接写盘，不走 preview/apply；对 diff-like 内容最多警示但仍按字面写入（数据损失风险）。
- 当前 “疑似 diff/patch” 启发式可能对 Markdown 项目符号（行首 `-`）产生误报（至少会造成提示噪音）；如果未来升级为“默认拒绝”，必须避免误伤正常写作。

## Expected Behavior

- 明确告知：`hunk_id` TTL=1 小时、自动清理；agent 只需关注“自己最后一次想 apply 的 hunk_id”，未使用的 hunks 不会产生副作用。
- **删除** `replace_file_contents`，改为语义更明确的 `overwrite_entire_file`（名字直指“整文件覆盖写入”）。
- `overwrite_entire_file` 必须带显式对账参数（`known_old_total_lines/known_old_total_bytes`；对外语义仍称 “known_old_stats（旧文件快照）”）才允许执行，降低“写错文件/写错版本”的概率。
- 通过 `content_format` 明确正文语义：当 `content_format in {'diff','patch'}` 时允许写入 diff/patch 字面量；未指定时，对强特征 diff/patch 默认拒绝并引导改用 `preview_*`。
- toolset prompt 建议：仅在“新内容较小”（例如 `< 100 行）或明确是重置/生成物”场景使用该工具；否则优先走 preview/apply。

## Impact

- **Who:** 所有使用 `ws_mod` 的 agent/操作者
- **Frequency:** often（TTL 文档缺失） / sometimes（raw overwrite 误用，代价极高）
- **Cost:** 时间浪费、反复 preview、对工具不信任；严重时是数据丢失风险

## Observations / Signals

- `dominds/main/tools/prompts/ws_mod.zh.md`：仅描述 “TTL 存在”，缺少 TTL=1h 与“无副作用/自动清理”的降压说明。
- `dominds/docs/txt-editing-tools.md`：描述了 `replace_file_contents` 的“例外直写”定位，但当前契约仍允许 diff-like 正文被写入。
- 现有启发式警示对 Markdown 内容可能产生误报信号噪音；若变成“默认拒绝”，风险更高。

## Likely Root Cause (Hypothesis)

- 工具契约与提示文档没有把“hunk 生命周期”与“直写的风险边界”用足够明确的规则表达出来。
- `replace_file_contents` 命名与用户心智不一致：容易被理解成“替换一段/应用 patch”，而不是“整文件原样覆盖写入”。
- diff-like 检测策略若过于宽松，会把正常文本（尤其 Markdown）误判为 diff/patch。

## Next Investigation Steps

- 确认 hunk TTL 的真实值与清理机制位置（实现锚点）：`dominds/main/tools/txt.ts`（hunk registry）。
- 明确 `overwrite_entire_file` 的参数面：是否允许 create；`total_bytes` 含义（应为文件在磁盘上的字节数）；错误提示文本（中英文）。
- 设计 diff-like 检测策略：仅匹配强特征（例如 `diff --git` / `@@` / `*** Begin Patch` / `+++`/`---`），避免误伤 Markdown 的 `-` 列表与常见 front matter。

## Fix Sketch

### 1) 文档补齐（低风险、立刻缓解）

- 在 `ws_mod` toolset prompt（`dominds/main/tools/prompts/ws_mod.*.md`）补一段明确说明：
  - TTL=1 小时（自动清理）
  - 未使用 hunks 无副作用
  - 推荐工作流：消息 1 并行 `preview_*` 多个变更；消息 2 对选定的 `hunk_id` 逐个 `apply_file_modification`

### 2) 删除 `replace_file_contents`，新增 `overwrite_entire_file`（强护栏）

建议新工具契约（草案）：

- `overwrite_entire_file <path> known_old_total_lines=<n> known_old_total_bytes=<n> [content_format=<text|markdown|json|diff|patch>]`
- 备注：对外语义仍称为 “known_old_stats（旧文件快照）”，但入参使用扁平键，避免诉请语法难以表达嵌套对象。
- 行为：
  - 直接写盘（仍是例外通道，不走 preview/apply）
  - 如果 `<path>` 当前不存在：拒绝（创建文件应走 `preview_file_append create=true` → apply）
  - 如果 `known_old_total_lines/known_old_total_bytes` 与当前文件不一致：拒绝，并提示先 `list_dir` 或 `read_file` 获取实际值（错误输出可回显 `known_old_stats` 作为旧文件快照）
  - 如果未指定 `content_format`：
    - 检测到强特征 diff/patch → 默认拒绝，并提示改用 `preview_*`
  - 如果 `content_format in {'diff','patch'}`：
    - 允许写入 diff/patch 字面量，不进行 diff-like 风险检测（因为这就是用户的显式意图）
- prompt-level 指导：
  - 建议仅在“新内容 < 100 行”或“明确为重置/生成物”的场景使用；其他情况优先 `preview_*`→`apply_file_modification`

## Acceptance Criteria

- [ ] `dominds/main/tools/prompts/ws_mod.zh.md` 与 `.en.md` 明确写出 `hunk_id` TTL=1h、自动清理、未使用 hunks 无副作用
- [ ] `replace_file_contents` 从工具集中彻底删除（无兼容层/无 alias）
- [ ] 新增 `overwrite_entire_file`，并在 `dominds/docs/txt-editing-tools.md` 中替代推荐旧工具
- [ ] `overwrite_entire_file` 在缺少 `known_old_total_lines/known_old_total_bytes` 或对账不匹配时拒绝执行，并返回可复制的 next step（例如先 `list_dir <dir>`）
- [ ] `overwrite_entire_file` 在 `content_format` 未指定且正文含强特征 diff/patch 时默认拒绝；当 `content_format='diff'|'patch'` 时允许写入且不触发风险提示
- [ ] diff-like 检测不会对 Markdown 常见行首 `-`/`+` 项目符号产生误报（仅对强特征触发拒绝）
- [ ] toolset prompt/usage 明确建议：仅在新内容 `< 100` 行（或明确重置/生成物）时使用 `overwrite_entire_file`

## Regression Checklist (Manual)

- [ ] `overwrite_entire_file`：`known_old_total_lines/known_old_total_bytes` 匹配 → 成功覆盖；不匹配 → 拒绝并提示 next step
- [ ] `overwrite_entire_file`：正文包含 `@@`/`diff --git`，且未指定 `content_format` → 默认拒绝并提示改用 `preview_file_modification`
- [ ] `overwrite_entire_file`：正文包含 `@@`/`diff --git`，且 `content_format='diff'` → 成功覆盖
- [ ] `ws_mod` 文档：明确写出 TTL=1h；并说明未使用 hunks 无副作用、会自动清理

## References

- Files:
  - `dominds/main/tools/prompts/ws_mod.zh.md`
  - `dominds/main/tools/prompts/ws_mod.en.md`
  - `dominds/docs/txt-editing-tools.md`
  - `dominds/main/tools/txt.ts`
  - `dominds/main/tools/builtins.ts`
  - `dominds/main/tools/registry.ts`

- Notes:
  - 两轮消息（preview→apply）被视为刻意的防呆设计：本 issue 不要求合并为单轮，只补齐“为什么 + 怎么用 + TTL=1h”的心智模型与 raw overwrite 护栏。
