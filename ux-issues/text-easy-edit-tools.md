# UX Spec：文本“易场景”编辑工具（不覆盖精确 hunk 流程）

- 日期：2026-01-22
- 作者：`@ux`
- 范围：工作区文本文件（`.minds/` 镜像同理，但不在本 spec 里重复）
- 目标：为“意图明确、风险较低”的常见编辑提供直白工具，避免为了方便把 `plan/apply_file_modification` 变成瑞士军刀。

> 术语：本 spec 默认不带任何前缀（例如不写 `team_mgmt_`），`.minds/` 版本应镜像同样的行为与文案。

---

## 设计原则（面向智能体）

- **直白**：不需要行号，不需要 hunk id，不需要推断 range 语义。
- **低注意力负担**：输出把“改了哪里/改了多少/边界换行怎么处理”讲清楚。
- **可预期**：默认策略稳定，尤其是换行与空行。
- **不碰难场景**：不替代 `plan/apply_file_modification`；遇到复杂精确修改应显式引导去用它。

---

## 命名建议（避免误用）

- 使用 `replace_file_contents`。
- 语义：将正文作为**文本内容**原样写入目标文件，**整体替换**旧内容；不解析 diff/patch（例如 `+`/`@@` 等会被按字面写入）。
- 目的：让“会覆盖旧内容”的风险在调用时更显眼，降低 diff 心智误用概率。

## 全局硬规则：换行与空行

为避免“粘行”和隐式格式变化，所有易场景工具遵循同一条硬性原则：

- **假定所有文本行以 `\n` 结尾（包括最后一行）。**

落地为默认行为：

- 若目标文件非空且末尾不是 `\n`，工具在写入前自动补一个 `\n`。
- 若写入 `content` 不以 `\n` 结尾，工具自动补一个 `\n`。
- `content` 允许包含空行（连续 `\n`），均原样保留；工具仅做“末尾补齐一枚 `\n`”的规范化。

> 备注：该规则只对空文件和“EOF 无换行”的文件有影响；我们倾向文本文件始终末尾换行，因此这是可接受的约束。

---

## 工具 1：`append_file`（末尾追加）

### 适用场景

- 在文件末尾追加一段配置/一段 prompt/一个 Markdown 小节。
- 不关心精确插入位置，只要求“追加到最后”。

### 不适用场景

- 需要插入到文件中间
- 需要替换某个精确 range（用 `plan/apply_file_modification`）

### 交互（建议）

标题：

- `append_file <path>`

正文：

- 追加内容 `content`（原样；会按全局规则补齐末尾换行）

### 输出（建议字段 + 可扫读摘要）

- `status: ok|error`
- `path`
- `mode: append`
- `file_line_count_before`
- `file_line_count_after`
- `appended_line_count`
- `normalized`:
  - `added_leading_newline_to_file: true|false`
  - `added_trailing_newline_to_content: true|false`
- 摘要：
  - “Append: +12 lines; file 90 → 102 lines; normalized: file_eof_newline=true, content_eof_newline=true.”

### 示例（输入/输出）

**输入**

```text
append_file notes/prompt.md
<正文>
## Tools
- Use `plan/apply_file_modification` for precise edits.
```

**输出（示例）**

```yaml
status: ok
path: notes/prompt.md
mode: append
file_line_count_before: 89
file_line_count_after: 92
appended_line_count: 3
normalized:
  added_leading_newline_to_file: false
  added_trailing_newline_to_content: true
summary: 'Append: +3 lines; file 89 → 92; normalized: content_eof_newline=true.'
```

---

## 工具 2：`insert_after`（基于锚点插入）

### 适用场景

- 在某个明确锚点（字符串）之后插入几行，例如：
  - 在 `## Config` 之后插入一段
  - 在 `member_defaults:` 块之后插入注释/字段
- 智能体知道“插到哪里附近”，但不想算行号。

### 不适用场景

- 锚点可能出现多次且需要精确选择（除非提供 occurrence）
- 需要替换/删除一个大块（可用 `replace_block`，见下）

### 交互（建议）

标题：

- `insert_after <path> <anchor> [options]`

建议 options：

- `occurrence=<n>`：默认 `1`（第 1 次出现），可选 `last`
- `strict=true|false`：默认 `true`
  - `true`：找不到锚点就失败
  - `false`：找不到则退化为 `append_file`（需要明确摘要提示）

正文：

- 插入内容 `content`

### 输出（建议字段）

- `status`
- `path`
- `mode: insert_after`
- `anchor`
- `occurrence_resolved`（例如 `1` / `last`）
- `inserted_at_line`（锚点行号 + 插入位置行号，至少给插入起始行号）
- `inserted_line_count`
- `normalized`（同全局规则）
- `evidence_preview`（低负担确认用；见下）
- `summary`

**证据预览（建议）**

- `before_preview`：插入点前 2 行
- `insert_preview`：插入内容前 2 行（或全部，若很短）
- `after_preview`：插入点后 2 行

### 示例（输入/输出）

**输入**

```text
insert_after docs/spec.md "## Configuration" occurrence=1 strict=true
<正文>
### Defaults
- provider: codex
```

**输出（示例）**

```yaml
status: ok
path: docs/spec.md
mode: insert_after
anchor: '## Configuration'
occurrence_resolved: 1
inserted_at_line: 42
inserted_line_count: 2
normalized:
  added_leading_newline_to_file: false
  added_trailing_newline_to_content: true
evidence_preview:
  before_preview: ['## Configuration', '']
  insert_preview: ['### Defaults', '- provider: codex']
  after_preview: ['', '## Next Section']
summary: 'Insert-after: +2 lines after "## Configuration" (occurrence=1) at line 42.'
```

**失败输出（锚点不存在，strict=true）**

```yaml
status: error
path: docs/spec.md
mode: insert_after
anchor: '## Configuration'
error: ANCHOR_NOT_FOUND
summary: 'Insert-after failed: anchor not found. Use plan/apply_file_modification for precise edits or choose a different anchor.'
```

---

## 工具 3：`insert_before`（基于锚点插入）

### 适用场景

- 在某个明确锚点（字符串）之前插入几行，例如：
  - 在 `## Config` 之前插入一个免责声明段落
  - 在 `member_defaults:` 之前插入注释/字段
- 智能体知道“插到哪里附近”，但不想算行号。

### 不适用场景

- 锚点可能出现多次且需要精确选择（除非提供 occurrence）
- 需要替换/删除一个大块（用 `replace_block` 或 `plan/apply_file_modification`）

### 交互（建议）

标题：

- `insert_before <path> <anchor> [options]`

建议 options：

- `occurrence=<n>`：默认 `1`（第 1 次出现），可选 `last`
- `strict=true|false`：默认 `true`
  - `true`：找不到锚点就失败
  - `false`：找不到则退化为 `append_file`（需要明确摘要提示）

正文：

- 插入内容 `content`

### 输出（建议字段）

- `status`
- `path`
- `mode: insert_before`
- `anchor`
- `occurrence_resolved`（例如 `1` / `last`）
- `inserted_at_line`（锚点行号之前的插入起始行号）
- `inserted_line_count`
- `normalized`（同全局规则）
- `evidence_preview`（低负担确认用；见下）
- `summary`

**证据预览（建议）**

- `before_preview`：插入点前 2 行
- `insert_preview`：插入内容前 2 行（或全部，若很短）
- `after_preview`：插入点后 2 行

### 示例（输入/输出）

**输入**

```text
insert_before docs/spec.md "## Configuration" occurrence=1 strict=true
<正文>
> This section is generated.
```

**输出（示例）**

```yaml
status: ok
path: docs/spec.md
mode: insert_before
anchor: '## Configuration'
occurrence_resolved: 1
inserted_at_line: 42
inserted_line_count: 1
normalized:
  added_leading_newline_to_file: false
  added_trailing_newline_to_content: true
evidence_preview:
  before_preview: ['', '## Intro']
  insert_preview: ['> This section is generated.']
  after_preview: ['## Configuration', '']
summary: 'Insert-before: +1 line before "## Configuration" (occurrence=1) at line 42.'
```

**失败输出（锚点不存在，strict=true）**

```yaml
status: error
path: docs/spec.md
mode: insert_before
anchor: '## Configuration'
error: ANCHOR_NOT_FOUND
summary: 'Insert-before failed: anchor not found. Use plan/apply_file_modification for precise edits or choose a different anchor.'
```

---

## 工具 4：`replace_block`（双锚点替换块）

### 适用场景

- 文档里有明确的 start/end 标记（或可引入标记），要替换其间内容：
  - 例如 `<!-- BEGIN AUTO -->` 与 `<!-- END AUTO -->`
  - 或 YAML/MD 的固定段落头尾
- 目标是“替换一个块”，而不是精确行号范围。

### 不适用场景

- 需要对同一文件做多段复杂联动修改（用 `plan/apply_file_modification`）
- start/end 锚点不稳定或可能嵌套（需要先规范标记）

### 交互（建议）

标题：

- `replace_block <path> <start_anchor> <end_anchor> [options]`

建议 options：

- `occurrence=<n|last>`：默认 `1`（处理多次出现）
- `include_anchors=true|false`：默认 `true`
  - `true`：保留 anchors，只替换中间内容
  - `false`：连同 anchors 一起替换（高风险，默认不建议）

正文：

- 新块内容 `content`（作为“anchors 之间”的内容）

### 输出（建议字段）

- `status`
- `path`
- `mode: replace_block`
- `start_anchor` / `end_anchor`
- `occurrence_resolved`
- `replaced_range`（起止行号）
- `old_line_count_in_block`
- `new_line_count_in_block`
- `delta_lines`
- `normalized`
- `evidence_preview`
- `summary`

### 示例（输入/输出）

**输入**

```text
replace_block README.md "<!-- BEGIN AUTO -->" "<!-- END AUTO -->" occurrence=1 include_anchors=true
<正文>
Generated on 2026-01-22.

- Item A
- Item B
```

**输出（示例）**

```yaml
status: ok
path: README.md
mode: replace_block
start_anchor: '<!-- BEGIN AUTO -->'
end_anchor: '<!-- END AUTO -->'
occurrence_resolved: 1
replaced_range:
  start_line: 12
  end_line: 18
old_line_count_in_block: 4
new_line_count_in_block: 4
delta_lines: 0
normalized:
  added_leading_newline_to_file: false
  added_trailing_newline_to_content: true
evidence_preview:
  before_preview: ['<!-- BEGIN AUTO -->']
  range_preview: ['Generated on 2026-01-22.', '', '- Item A', '- Item B']
  after_preview: ['<!-- END AUTO -->']
summary: 'Replace-block: lines 12–18; 4 → 4 lines; anchors preserved.'
```

---

## 工具 5：文件与目录操作（易场景）

> 这些工具的目标是“文件系统层面的直白意图”，不引入 hunk/range 概念。
> 目录与文件删除可直接使用已存在的 `rm_dir` / `rm_file`。

### 工具 5.1：`mk_dir`（创建目录）

#### 适用场景

- 为后续写文件/移动文件准备目录
- 快速创建一组层级目录（parents）

#### 交互（建议）

标题：

- `mk_dir <path> [options]`

建议 options：

- `parents=true|false`：默认 `true`

#### 输出（建议字段）

- `status: ok|error`
- `path`
- `created: true|false`（若目录已存在则 `false`，但仍 `ok`）
- `summary`

#### 示例（输入/输出）

**输入**

```text
mk_dir docs/specs parents=true
```

**输出（示例）**

```yaml
status: ok
path: docs/specs
created: true
summary: 'Mk-dir: docs/specs (parents=true).'
```

**失败输出（示例：路径存在但不是目录）**

```yaml
status: error
path: docs/specs
error: PATH_EXISTS_NOT_DIR
summary: 'Mk-dir failed: path exists and is not a directory.'
```

### 工具 5.2：`move_file`（移动/改名文件）

#### 适用场景

- 重命名一个文件
- 把文件移动到另一个目录（目录已存在）

#### 不适用场景

- 目标路径所在目录不存在（先 `mk_dir`）

#### 交互（建议）

标题：

- `move_file <from> <to>`

#### 输出（建议字段）

- `status: ok|error`
- `from` / `to`
- `summary`：
  - “Move-file: `<from>` → `<to>`.”

#### 示例（输入/输出）

**输入**

```text
move_file docs/old.md docs/new.md
```

**输出（示例）**

```yaml
status: ok
from: docs/old.md
to: docs/new.md
summary: 'Move-file: docs/old.md → docs/new.md.'
```

### 工具 5.3：`move_dir`（移动/改名目录）

#### 适用场景

- 重命名目录
- 把目录整体移动到另一个目录下

#### 不适用场景

- 目标路径的父目录不存在（先 `mk_dir`）
- 需要部分移动（用 `move_file`）

#### 交互（建议）

标题：

- `move_dir <from> <to>`

#### 输出（建议字段）

- `status`
- `from` / `to`
- `moved_entry_count`（建议提供：包含子目录与文件）
- `summary`

#### 示例（输入/输出）

**输入**

```text
move_dir docs/spec docs/specs
```

**输出（示例）**

```yaml
status: ok
from: docs/spec
to: docs/specs
moved_entry_count: 14
summary: 'Move-dir: docs/spec → docs/specs (14 entries).'
```

---

## 与 `plan/apply_file_modification` 的分流规则（文案要求）

当易场景工具遇到以下情况，应在错误/摘要中明确提示“请改用 `plan/apply_file_modification`”：

- 锚点找不到（strict=true）
- 锚点出现多次且未指定 occurrence
- 检测到块嵌套/歧义（例如 start/end 不成对）
- 目标文件疑似二进制或行数异常（保护性失败）

---

## 验收用例（易场景）

1. `append_file`：目标文件 EOF 无换行，追加后应自动补齐并不粘行
2. `append_file`：空文件追加，应得到末尾换行
3. `insert_after`：锚点存在，插入后 evidence_preview 能低负担确认位置
4. `insert_after`：锚点不存在（strict=true），失败并提示改用 `plan/apply_file_modification`
5. `replace_block`：anchors 存在且唯一，替换后 anchors 保留、delta_lines 正确
6. `replace_block`：anchors 不成对或歧义，失败并提示改用 `plan/apply_file_modification`
7. `mk_dir`：目录不存在时创建成功；已存在时 `created=false` 且 `ok`
8. `move_file`：目标父目录存在时移动成功；父目录不存在时失败并提示先 `mk_dir`
9. `move_dir`：目录整体移动后条目数量一致

---

## Proposal: Replace `replace_block` with `plan_block_replace` / `apply_block_replace`

### Motivation

- `replace_block` is convenient but risky: start/end anchors are often non-unique in real docs, and the tool can accidentally edit the wrong region.
- Agent ergonomics suffers when edits are not preview-first: users/agents need a diff to verify before applying.
- We already have a proven safety pattern (`plan_file_modification` / `apply_file_modification`); block replacement should follow the same pattern.

### Decision / Intent

- Deprecate and remove `replace_block`.
- Introduce `plan_block_replace` + `apply_block_replace` as the only block-anchor editing workflow.
- Keep `plan/apply_file_modification` as the precision fallback; `plan/apply_block_replace` is the “anchor-based but safe” option.

### Proposed Tool Specs

#### `plan_block_replace`

**Signature**: `!?@plan_block_replace <path> <start_anchor> <end_anchor> [options]`
**Body**: new content to write into the selected block.
**Options** (suggested):

- `occurrence=<n|last>`: choose which (start,end) pairing to target when multiple matches exist.
- `include_anchors=true|false` (default `true`): whether to keep start/end anchor lines in the file.
- `match=contains|equals` (default `contains`): how anchor lines are matched.
- `require_unique=true|false` (default `true`): if true, multiple candidates must fail with `ANCHOR_AMBIGUOUS`.
- `strict=true|false` (default `true`): if true, not found/ambiguous fails; if false, allows fallback behaviors (recommend: always `true` for planning).
  **Output (YAML)**:
- `status: ok|error`
- `mode: plan_block_replace`
- `path`, `start_anchor`, `end_anchor`, resolved `occurrence`
- `hunk_id` (TTL-limited), `expires_at`
- `candidates_count`, `occurrence_resolved`, `range` (start_line/end_line)
- `unified_diff` (or `diff_preview`) and `evidence_preview` (before/new/after)
- On error: `error: INVALID_FORMAT|CONTENT_REQUIRED|ANCHOR_NOT_FOUND|ANCHOR_AMBIGUOUS|OCCURRENCE_OUT_OF_RANGE|FAILED` with actionable `summary`

#### `apply_block_replace`

**Signature**: `!?@apply_block_replace !<hunk_id>`
**Body**: empty.
**Behavior**:

- Applies the planned block replace if the target region can still be uniquely located (context match).
- Rejects with `APPLY_REJECTED_*` errors if file changed or target is no longer unique; instructs user to re-plan.
  **Output (YAML)**:
- `status: ok|error`
- `mode: apply_block_replace`
- `path`, `hunk_id`, applied `range`
- `normalized` details + `evidence_preview`

### UX Acceptance Criteria

- Users can always see what will change before writing.
- Ambiguous anchors never cause silent writes; they fail with candidate counts and next-step guidance.
- Workflow mirrors `plan_file_modification` / `apply_file_modification` (same TTL, same apply queue, same rejection semantics).
- Clear zh/en messaging (no zh branch returning English-only summaries).

### Owner

- @tooling (implementation in `dominds/main/tools/txt.ts` and tool registry)
- @qa (add/extend regression coverage for plan/apply and rejection cases)

### Minimal Regression Checklist

- Plan succeeds on unique anchors and returns a diff + hunk id.
- Apply succeeds immediately after plan.
- Apply rejects if the file changes between plan and apply.
- Plan fails on ambiguous anchors with `ANCHOR_AMBIGUOUS` and candidate count.
- Plan fails on missing anchors with `ANCHOR_NOT_FOUND`.
- Occurrence out of range produces `OCCURRENCE_OUT_OF_RANGE`.
- Empty body fails with `CONTENT_REQUIRED`.
