# Spec: File Edit Tools Unified Redesign (Plan-first + Single Apply)

- Status: Draft (PM proposal)
- Date: 2026-01-24
- Owner: @tooling (implementation), @qa (gate/regression), @pm (spec)

> TL;DR: 把所有“会写文件内容”的文本编辑能力统一成 **plan-first**：先 `plan_*` 生成可复核 diff + 证据 + hunk_id，再用 **唯一**的 `apply_file_modification !<hunk_id>` 落盘；移除/弃用各类 `apply_*` 专用工具（如 `apply_block_replace`）。

## 1. 背景与问题

Dominds 目前存在三套“写文件”心智模型并存：
- 精确困难场景：`plan_file_modification` → `apply_file_modification`（有 diff + 证据，安全）
- 易场景：`append_file` / `insert_after` / `insert_before` 直接写（无预览、低安全性，但省步骤）
- 块替换：`plan_block_replace` → `apply_block_replace`（安全模式，但 apply 分裂）

带来的摩擦（来自 `ux-issues/*` + dogfooding）：
- **工具心智不一致**：有的要 hunk、有的直接写；有的有 plan、有的没有；apply 分裂成多种。
- **输出字段不统一**：虽然多处已用 YAML，但字段命名/摘要不一致（例如 normalized 字段与 summary 表述存在偏差风险）。
- **并发/时序风险**：同一条 assistant 消息里多个工具调用并行执行，容易出现“plan 基于旧文件、其它工具已写入”的竞态；导致 apply 被拒绝或证据失真。
- **换行/空行风格难复核**：目前对 EOF `\n` 有规范化，但“是否需要额外空行/是否保持原风格”缺少可扫读提示。

## 2. 目标（Goals）

- 统一所有文本写入为 **plan-first + preview diff + evidence**，让 agent “敢改、能复核”。
- 统一 apply：所有计划类编辑（append/insert/block/replace-range）都通过 **`apply_file_modification`** 落盘。
- 统一输出：plan/apply 的 YAML 字段结构趋同，减少 agent 解析成本。
- 明确换行/空行策略：至少做到“可观测 + 可预期”，必要时仅提示不自动改风格。

## 3. 非目标（Non-goals）

- 不做二进制/超大文件编辑（应保护性失败或要求更窄范围）。
- 不引入复杂 patch 语言（依然以 unified diff 为主）。
- 不保证兼容旧工具名（Alpha 允许破坏性变更；如需过渡，仅短期 alias + 强 deprecation）。

## 4. 统一工作流（Single Workflow）

### 4.1 统一流程
1) `plan_*`：只读文件，生成 hunk + diff + 证据 + 注意事项（换行/空行风格提示、歧义提示）
2) `apply_file_modification !<hunk_id>`：唯一落盘入口（输出应用证据 + context_match）

### 4.2 关键实现约束：工具并行执行

- 约束：同一条消息中的多个工具调用会并行执行，彼此看不到对方输出/写入。
- 要求：任何 plan→apply 必须是 **两步、两条消息**（或由 runtime/tooling 提供“顺序编排器”能力）。

> 未决：是否需要新增“顺序编排”能力（例如 `orchestrate`/`transaction`），让 agent 可在单条消息中安全串行 plan→apply→next plan。

## 5. 工具集合（Proposed Tool Surface）

### 5.1 保留并扩展：`plan_file_modification`
- 行号范围替换/删除/插入/追加（现有 range 语法保持）
- 输出要求沿用 `ux-issues/text-precise-edit-plan-apply-ux.md`：必须含定位证据（before/range/after）+ summary + diff

### 5.2 新增：`plan_file_append`
**签名**：`plan_file_append <path> [options]`  
**正文**：追加内容 `content`  
**语义**：只计划追加，不落盘；返回可 apply 的 hunk。

**输出必须包含（建议字段）**：
- `action: append`
- `file_line_count_before` / `file_line_count_after`（after 是“计划后”）
- `appended_line_count`
- `newline_analysis`（至少）：
  - `file_eof_has_newline`（原始文件）
  - `content_eof_has_newline`（原始 content）
  - `normalized_file_eof_newline_added`（是否需要补）
  - `normalized_content_eof_newline_added`
- `blankline_style`（至少提示，不一定自动改）：
  - `file_trailing_blank_line_count`（文件末尾已有多少空行）
  - `content_leading_blank_line_count`（content 开头空行数）
  - `style_warning`（例如 “可能产生双空行/可能粘行”）
- `evidence_preview`：计划前末尾 2 行 + 计划追加前 2 行（或更短） + 计划后末尾 2 行
- `unified_diff`

> 你的建议落点：plan_file_append 需要明确提示“原有行数/追加行数/EOF 换行/空行风格是否统一”。

### 5.3 新增：`plan_insertion`（或拆分为 `plan_insert_after` / `plan_insert_before`）
**方案 A（更贴合你提议）**：  
- `plan_insertion <path> <anchor> !before|!after [options]`

**方案 B（更贴近现有工具名）**：  
- `plan_insert_after <path> <anchor> [options]`
- `plan_insert_before <path> <anchor> [options]`

**共同要求**：
- 必须返回 `inserted_at_line`（resolved）、`occurrence_resolved`
- 必须输出 `blankline_style` 与 `style_warning`（插入点两侧 vs 插入内容的空行风格）
- 必须输出 `evidence_preview`（插入点前/插入内容预览/插入点后）
- 错误与歧义必须失败（或明确 `strict=false` 的回退策略，但推荐 planning 阶段总是 strict）

### 5.4 保留但改造：`plan_block_replace`
- 继续作为“锚点块替换”的 plan-only 工具
- **取消** “下一步：apply_block_replace” 的文案；统一提示 `apply_file_modification !<hunk_id>`
- 输出字段建议与现有保持一致，但应补齐统一字段（见第 6 节）

### 5.5 统一 apply：`apply_file_modification !<hunk_id>`
- 必须能 apply 由任意 `plan_*` 产生的 hunk（不仅限 `plan_file_modification`）
- `context_match` 语义统一：`exact|fuzz|rejected`
- apply 输出必须含应用证据（before/range/after 或插入/追加的 preview）

### 5.6 弃用/移除（Alpha 允许破坏性变更）
- `append_file`（改为 `plan_file_append` + apply）
- `insert_after` / `insert_before`（改为 plan_insertion/plan_insert_* + apply）
- `apply_block_replace`（被 `apply_file_modification` 替代）
- `replace_block`（保持弃用方向：用 plan_block_replace）

## 6. 输出契约（统一 YAML 最小集合）

### 6.1 Plan 输出（最小必需）
- `status: ok|error`
- `mode: plan_file_modification|plan_file_append|plan_insertion|plan_block_replace|...`
- `path`
- `hunk_id` + `expires_at_ms`
- `action: replace|insert|append|block_replace|delete`
- `lines: { old, new, delta }`（若适用）
- `match: exact|fuzz`（若适用）
- `normalized: {...}`（EOF newline 规范化明细）
- `blankline_style: {...}` + `style_warning`（如有）
- `evidence_preview` 或 `evidence`（必须，低注意力确认）
- `summary`（1–2 句，可扫读）
- `unified_diff`（保留 diff，便于审阅）

### 6.2 Apply 输出（最小必需）
- `status`
- `mode: apply_file_modification`
- `path`, `hunk_id`
- `action`
- `applied_range` / `inserted_at_line` / `append_range`（按 action）
- `context_match: exact|fuzz|rejected`
- `apply_evidence`（必须）
- `summary`
- `unified_diff`（可选但建议保留）

## 7. Apply 拒绝语义（减少无谓 re-plan）

未决但必须明确的一点：当文件在 plan→apply 之间发生变化，apply 的拒绝应尽量“只在必要时发生”。

- 建议：以“目标区域/上下文匹配”作为判断依据，而不是“文件任意位置变动就全局拒绝”。
- 仍需保证安全：当目标不再唯一或上下文不足以确认语义位置时，必须 `rejected` 并提示 re-plan。

## 8. 验收口径（Acceptance Criteria）

- 所有文本写入均可通过 `plan_*` 获得 diff + 证据 + hunk_id，并且 **唯一**使用 `apply_file_modification` 落盘。
- plan/apply 的 YAML 字段可稳定解析，summary 可扫读，且中英/中日不会混乱。
- 换行与空行风格在 plan 阶段可见（至少 warning），避免“粘行/双空行”惊喜。
- 锚点歧义永不静默写入：必须失败并提供 `candidates_count`/下一步建议。
- 竞态风险有明确 guidance：工具文案/文档强调 plan→apply 需分消息或使用编排器。

## 9. 回归清单（交 @qa 纳 gate）

- `plan_file_modification`：定位证据 + apply 证据齐全；并发修改后 `context_match=fuzz|rejected` 语义正确。
- `plan_file_append`：EOF 无换行/空文件/已有尾随空行等情况下，normalized 与提示字段正确。
- `plan_insertion`：锚点不存在/多次出现/occurrence 越界/strict 行为与错误码稳定。
- `plan_block_replace`：unique/ambiguous/not found；apply 后内容正确；文件变化时拒绝语义合理。
- `apply_file_modification`：能 apply 来自所有 plan_* 的 hunk；过期/不存在 hunk 给出可行动错误。

## 10. Owner 分工

- @tooling：工具集合与输出契约落地、统一 hunk registry、移除/替换旧工具、文案一致性
- @qa：新增/扩展回归用例（含拒绝语义与 EOF 换行/空行风格）
- @pm：维护 spec、梳理未决决策、推动验收口径落地

## 11. 未决决策（需要 @tooling/@qa 确认）

1) 命名：`plan_insertion !before|!after` vs `plan_insert_before/after`（哪种更易用/更少歧义）
2) apply 拒绝策略：是否允许“文件其它位置变更但目标块仍可唯一匹配”时继续 apply（建议：允许并标记 fuzz）
3) 空行风格：仅提示 warning 还是提供可选自动对齐（`normalize_blanklines=`）
4) hunk 生命周期：TTL 默认多久？是否允许跨进程重启持久化（当前看像内存型）
5) 是否需要顺序编排器：让 agent 在单条消息中串行 plan→apply（降低并发竞态）

## References
- `ux-issues/ripgrep-tools-ux.md`
- `ux-issues/text-precise-edit-plan-apply-ux.md`
- `ux-issues/text-easy-edit-tools.md`
