# ws_mod ergonomics improvement batch (01): consistent `existing_hunk_id`, optional-args ergonomics (non-Codex), line-count semantics, and output consistency

## TL;DR

- **Summary:** `ws_mod` 工具整体方向正确（preview-first + 单 apply），但存在一组可预期的“工学摩擦点”：`existing_hunk_id` 支持不一致、可选参数被哨兵值污染（Codex required-all 泄漏到通用契约）、`read_file` vs `overwrite_entire_file` 行数语义不一致、以及结构化输出（YAML）不一致，导致学习成本与误用成本升高。
- **Severity:** P1
- **Area:** Tools / Docs
- **Owner:** @tooling（需要 @pm 参与参数命名/兼容策略的决策）
- **Status:** Open
- **Added:** 2026-01-25

## Context

`ws_mod` 的核心价值是：在低注意力/并发工具调用的现实下，把“编辑文件”变成可复核、可恢复、可回归的工作流。

当前实现已经做到：

- 增量编辑统一为 `preview_* → apply_file_modification`（两轮消息是刻意防呆）
- `hunk_id` 有 TTL（~1h）+ owner 校验 + apply 队列串行化（同文件）
- `overwrite_entire_file` 有对账护栏 + diff/patch 误写防护

但在实际使用（尤其是跨模型/跨 provider）时，一些接口/输出层面的不一致会持续引发“没必要的试错”。本 issue 把这些摩擦点打包成一批可落地的改进建议与验收口径。

## Repro Steps

### 1) 可选参数被 Codex 的 required-all 约束污染（哨兵值泄漏）

1. 尝试用非 Codex 模型/或更严格的函数调用生成器调用 `read_file({ path })`（不传 `range/max_lines/show_linenos`）。
2. 或调用 `preview_insert_after({ path, anchor, content })`（不传 `occurrence/match/existing_hunk_id`）。
3. 观察：综合指南/错误提示会强引导用户携带哨兵值（例如 `range:""`、`max_lines:0`、`occurrence:""|0`、`existing_hunk_id:""`、`match:""`），把 provider 的限制变成“全局心智模型”。

### 2) `existing_hunk_id` 支持不一致（block_replace 无法覆写规划）

1. 用 `preview_insert_after` 生成一个 hunk。
2. 发现可以用 `existing_hunk_id` 覆写同模式的规划（迭代体验好）。
3. 改用 `preview_block_replace`：发现工具不支持 `existing_hunk_id`（只能不断生成新 hunk）。

### 3) `read_file` 的 totalLines 与 `overwrite_entire_file` 的对账行数语义不一致

1. 对一个空文件调用 `read_file`。
2. 观察 `read_file` 输出 `totalLines` 采用“空文件=1 行空行”的 canonical display 语义（见实现注释）。
3. 立刻尝试用输出里的 “总行数/空文件直觉” 去填 `overwrite_entire_file({ known_old_total_lines })`。
4. 观察：`overwrite_entire_file` 的对账语义是空文件 `known_old_total_lines=0`（实现里 `countFileLinesUtf8` 也是 0）。这会导致新手极高概率的 “对账不匹配 → 拒绝”。

### 4) 结构化输出（YAML）风格不一致，削弱可脚本化/可回归

1. 调用 `preview_*`：得到稳定 YAML + diff。
2. 调用 `read_file`：得到 Markdown（非 YAML）。
3. 调用 `overwrite_entire_file`：得到纯文本（非 YAML）。
4. 观察：同一工作流里输出格式不一致，使“从输出复制参数/写回归脚本/让 agent 复核”的成本变高。

### 5) `match` 参数命名可读性差（容易误解）

1. 读 `preview_insert_after` / `preview_block_replace` 的参数名 `match`。
2. 观察：它实际是 match mode（`contains|equals`），但从名字更像“要匹配的文本/正则”。
3. 在多工具组合中容易误传与误解，增加 anchor 编辑失败率。

## Current Behavior

- 文档与提示词把“Codex required-all”当作普遍事实，并在示例里大量出现哨兵值（见 `dominds/docs/txt-editing-tools.md:120` 及 `dominds/main/tools/txt.ts:779`）。
- `existing_hunk_id` 的“同模式覆写规划”在 `preview_file_modification` / `preview_file_append` / `preview_insert_*` 存在，但 `preview_block_replace` 明确不支持（`dominds/docs/txt-editing-tools.md:117`）。
- `read_file` 的 `totalLines` 是 display-canonical 语义（空文件显示为 1 行空行）；`overwrite_entire_file` 的 guardrail 行数语义是“逻辑行数”（空文件=0）。
- 输出格式：`preview_*` / `apply` 主打 YAML；`read_file` 输出 Markdown；`overwrite_entire_file` 输出纯文本。

## Expected Behavior

- 工具“参数契约”以语义合理性为主：
  - 非 Codex 模型应可直观地省略可选参数。
  - Codex（或任何 required-all 的 provider）应通过“适配层/默认注入”消化其限制，而不是把哨兵值暴露给所有用户心智。
- `existing_hunk_id` 支持应在所有 `preview_*` 工具中一致（至少语义一致：同模式可覆写；跨模式拒绝；owner 校验一致）。
- 行数语义应统一：`read_file` 报告的“总行数”应可直接用于 `overwrite_entire_file` 的 `known_old_total_lines`（或至少额外输出一个明确可对账字段）。
- 输出应可脚本化：核心字段优先用 YAML 表达，且不同工具的 header 字段尽量对齐（status/mode/path/lines/bytes/summary）。
- 参数命名/描述应降低误解（尤其是 `match`）。

## Impact

- **Who:** 新手用户、在低注意力下工作的 agent、人类 reviewer、以及非 Codex provider 的调用方。
- **Frequency:** often（几乎每次编辑/读文件/覆写都可能触发）
- **Cost:** confusion / time / failure；`overwrite_entire_file` 对账失败属于“高摩擦可预期失败”。

## Observations / Signals

- `read_file` 明确写了“Codex provider 要求函数工具参数字段全部 required”，并在错误提示中推广哨兵值（`dominds/main/tools/txt.ts:779`）。
- `preview_block_replace` 没有 `existing_hunk_id` 参数（`dominds/main/tools/txt.ts:3543`）。
- `read_file` 的 canonical line semantics：空文件 yields 1 empty line（`dominds/main/tools/txt.ts:710`）。
- `overwrite_entire_file` 的行数对账来自 `countFileLinesUtf8`（空文件=0），并要求 known_old_total_lines 与它一致（`dominds/main/tools/txt.ts:1266`）。

## Likely Root Cause (Hypothesis)

- **Optional-args ergonomics:** provider（Codex）在函数调用上存在“字段必填”的行为/偏好，导致提示词与示例选择了“全字段 + 哨兵”的写法以提高成功率；但该策略泄漏成通用 API 心智。
- **existing_hunk_id inconsistency:** `plannedBlockReplacesById` 与 `plannedModsById` 分离实现；block_replace 路径当初为了简单与安全，省略了“覆写规划”的分支。
- **Line count mismatch:** `read_file` 的行数定义偏 display-stable；guardrail 的行数定义偏 file-stat-stable（对账用）。两者未统一或未显式区分。
- **Output inconsistency:** `read_file` 以人类阅读 Markdown 为主；`preview/apply` 以 YAML+diff 为主；`overwrite_entire_file` 走了更早期/更轻量的返回格式。

## Next Investigation Steps

- 明确：目前真实 provider 行为是“必须传所有 fields”还是“模型倾向不传导致失败”？（可以用 @qa 设计最小回归：同一工具在不同 provider 下是否能省略可选字段。）
- 评估：参数/输出的 breaking change 策略（无兼容层 vs 允许一次性 rename）。需要 @pm 给出“可接受的破坏范围”。

## Fix Sketch

### A) 可选参数：以语义为主，provider 限制用适配层消化

- 保持工具 schema 中 `required` 仅包含语义必需字段。
- 在 provider 层或 tool-call 构造层（runtime/registry）对 “required-all provider” 做补全：
  - 若缺失可选字段，自动注入默认值（例如 `range:""`、`max_lines:0`、`match:""`、`occurrence:0`、`existing_hunk_id:""`），使调用方不必知道哨兵规则。
- 更新综合指南：将“哨兵值”改为“仅当 provider 要求必填时才使用”的 conditional note，而不是通用说明。

### B) `existing_hunk_id` 全局一致

- 给 `preview_block_replace` 增加 `existing_hunk_id` 参数，语义与其它 `preview_*` 对齐：
  - 允许覆写：同工具/同 kind、同 owner。
  - 拒绝：不存在/过期、owner 不匹配、kind 不匹配。
- 在 YAML 输出中明确标注“是否覆写了旧规划”（例如 `reused_hunk_id: true|false`）。

### C) 统一行数语义（读 vs 对账）

- 选一个“对外一致”的 `total_lines` 定义，并保证：
  - `read_file` 的 totalLines == `overwrite_entire_file` guardrail 的 count（空文件一致）。
- 若必须保留 display-canonical（空文件显示 1 行空行），则：
  - `read_file` 额外输出一个明确可对账字段（例如 `guardrail_total_lines`），并在 `overwrite_entire_file` 的错误提示中引导用户使用它。

### D) 输出一致性（最小可行）

- 为 `read_file` 与 `overwrite_entire_file` 增加一个 YAML header（即使主体仍是 Markdown/纯文本），字段与 `preview_*` 尽量对齐：
  - `status/mode/path/size_bytes/total_lines/summary`。
- `overwrite_entire_file` 的成功/失败输出建议统一为 YAML（失败时尤其重要，便于程序化重试/提示 next step）。

### E) `match` 命名可读性

- 不引入兼容层的前提下：优先升级参数描述（schema description + doc）明确 `match` 是 `contains|equals` 的模式。
- 若允许 breaking rename：`match` → `match_mode`（并同步 `ws_mod` 综合指南与 WebUI/CLI 帮助）。

### F) apply 的 fuzz 可观测性

- 对 `context_match=fuzz` 的场景（尤其是 append），输出更多“变化证据”：
  - 例如 `planned_file_digest/current_file_digest` 或 `file_changed_since_preview: true`，让用户知道 fuzz 的原因与风险边界。

## Acceptance Criteria

- [ ] `preview_block_replace` 支持 `existing_hunk_id`，行为与 `preview_file_append` / `preview_insert_*` 一致（同 owner/同 kind 可覆写；否则拒绝并给出稳定 error code）。
- [ ] 非 Codex 模型调用 `read_file({ path })` / `preview_insert_after({ path, anchor, content })` 等，在不传可选字段时仍可成功（或由适配层补全成功）。
- [ ] `read_file` 输出的行数信息可直接用于 `overwrite_entire_file` 的 `known_old_total_lines`（或提供明确的 guardrail 字段）。
- [ ] `read_file` 与 `overwrite_entire_file` 至少具备统一的 YAML header 字段（便于脚本/回归）。
- [ ] `match` 的含义在文档与工具描述中不再容易被误解。

## Regression Checklist (Manual)

- [ ] 空文件：`read_file` → 用其输出的行数/bytes 填 `overwrite_entire_file` 对账应一次成功。
- [ ] `preview_block_replace` 生成 hunk 后，用 `existing_hunk_id` 覆写同一 hunk 再 apply，应只保留一个有效 hunk 且 apply 成功。
- [ ] `context_match=fuzz` 的 append：在 plan→apply 间手动改文件，应有明确提示“文件已变化”且 apply 输出仍可复核。
- [ ] 非 Codex provider：省略可选参数的工具调用仍能通过。

## References

- Files:
  - `dominds/docs/txt-editing-tools.md`
  - `dominds/main/tools/txt.ts`
  - `dominds/main/tools/ripgrep.ts`
- Related issue:
  - `ux-issues/ws-mod-docs-and-overwrite-guardrails.md`
