# UX Spec：`ripgrep_*` 搜索工具集（为文本编辑提供导航能力）

- 日期：2026-01-22
- 作者：`@ux`
- 范围：工作区文本（`.minds/` 镜像同理，但不在本 spec 里重复）
- 目标：为智能体提供可预期、低噪音的全文检索能力，作为 `plan/apply_file_modification` 与易场景编辑工具的“导航前置步骤”。

> 命名原则：使用 `ripgrep_*`，避免占用短工具名（也避免与 teammate id 冲突）；语义与 `rg` 对齐，但输出更适合对话与智能体扫读。

---

## 为什么需要（问题陈述）

- 没有搜索时，复杂文件编辑常退化为“大段读取 + 猜行号”，成本高且风险大。
- `plan/apply_file_modification` 适合精确修改，但它依赖“已定位到正确位置”；`ripgrep_*` 用于把定位变得便宜可靠。

---

## 工具分层：CISC 风格的多工具工学

本 spec 推荐“一套工具”而不是一个全能入口：

- **高频快捷工具**：固定模式、固定输出，最适合对话环境（默认推荐）。
- **可选逃生舱**：`ripgrep_search`（全参数）用于少数需要精细控制的场景。

> 智能体应按场景自主选择 `files/snippets/count/fixed/search`，不强制默认模式。

---

## 输出规范（统一 YAML，低噪音）

所有 `ripgrep_*` 工具返回一个 YAML 块（可附带少量人类可读 summary），字段尽量一致，便于扫读与后续动作选择。

### 通用字段（建议）

```yaml
status: ok|error
pattern: '<string>'
mode: files|snippets|count
path: '<search root>'
globs: ['<glob>', ...] # 若未提供可省略
case: smart|sensitive|insensitive
fixed_strings: true|false
regex: true|false # fixed_strings=true 时可为 false
truncated: true|false
limits:
  max_results: <int>
  max_files: <int>
totals:
  files_matched: <int>
  matches: <int> # snippets/count 时可给 total
summary: '<1-2 句可扫读说明>'
```

### Results 结构（建议）

- `mode=files`：返回文件列表（可选每文件匹配数）
- `mode=snippets`：返回命中片段（含行号、少量上下文）
- `mode=count`：返回每文件计数与 total

示例结构：

```yaml
results:
  - path: 'src/app.ts'
    count: 12 # files/count 模式
  - path: 'src/app.ts'
    line: 42
    col: 5
    match: 'foo(bar)'
    before: ['...'] # 可选上下文
    after: ['...']
```

---

## 工具 1：`ripgrep_files`（先收敛文件）

### 适用场景

- 你知道要找什么（pattern），但不知道在哪个文件。
- 你想先得到候选文件集合，再对个别文件做 `ripgrep_snippets` 或直接进入编辑。

### 交互（建议）

标题：

- `ripgrep_files <pattern> [path] [options]`

建议 options：

- `globs=[...]`（等价 `rg -g`）
- `case=smart|sensitive|insensitive`
- `fixed_strings=true|false`
- `max_files=<n>`（默认例如 50）
- `include_hidden=true|false`（默认 false）
- `follow_symlinks=true|false`（默认 false）

### 输出示例

```yaml
status: ok
pattern: 'location_evidence'
mode: files
path: '.'
case: smart
fixed_strings: true
truncated: false
limits:
  max_files: 50
totals:
  files_matched: 2
summary: 'Found 2 files matching pattern.'
results:
  - path: 'ux-issues/text-precise-edit-plan-apply-ux.md'
  - path: 'docs/tooling.md'
```

### 下一步建议（不强制）

- 选中一个文件后，使用 `ripgrep_snippets <pattern> <that file>` 获取行号与上下文，再进入 `plan/apply_file_modification`。

---

## 工具 2：`ripgrep_snippets`（命中片段 + 行号）

### 适用场景

- 你想立刻定位到具体位置（行号）以便精确编辑。
- 你需要少量上下文来确认命中是否是“语义上的那个位置”。

### 交互（建议）

标题：

- `ripgrep_snippets <pattern> [path] [options]`

建议 options：

- `globs=[...]`
- `case=smart|sensitive|insensitive`
- `fixed_strings=true|false`
- `context_before=<n>`（默认 0 或 1）
- `context_after=<n>`（默认 0 或 1）
- `max_results=<n>`（默认例如 50）

### 输出示例

````yaml
status: ok
pattern: '```json'
mode: snippets
path: 'ux-issues/text-easy-edit-tools.md'
case: smart
fixed_strings: true
truncated: true
limits:
  max_results: 5
totals:
  files_matched: 1
  matches: 12
summary: 'Showing first 5 of 12 matches (truncated=true).'
results:
  - path: 'ux-issues/text-easy-edit-tools.md'
    line: 92
    col: 1
    match: '```json'
    before: ['**输出（示例）**']
    after: ['{', '  "status": "ok",']
````

### 下一步建议（不强制）

- 用 `line` 信息进入 `plan_file_modification <file> <range>` 做精确替换。
- 若结果过多：先用 `ripgrep_files` 或加 `globs/path` 收敛。

---

## 工具 3：`ripgrep_count`（计数）

### 适用场景

- 你只关心“还有没有残留”或“改动前后数量对比”，例如：
  - ` ```json ` 是否清零
  - 某关键字段出现次数是否符合预期

### 交互（建议）

标题：

- `ripgrep_count <pattern> [path] [options]`

建议 options：

- `globs=[...]`
- `case=smart|sensitive|insensitive`
- `fixed_strings=true|false`
- `max_files=<n>`（默认例如 200）

### 输出示例

````yaml
status: ok
pattern: '```json'
mode: count
path: 'ux-issues'
case: smart
fixed_strings: true
truncated: false
totals:
  files_matched: 0
  matches: 0
summary: 'No matches.'
results: []
````

---

## 工具 4：`ripgrep_fixed`（固定字符串快捷）

### 适用场景

- 你不想承担 regex 误伤的心智负担（例如查找 `@@`、`+` 前缀、三反引号等）。
- 你想显式表达“按字面匹配”。

### 交互（建议）

- `ripgrep_fixed <literal> [path] [options]`

行为约束（建议）

- 强制 `fixed_strings=true`
- 其他与 `ripgrep_snippets`/`ripgrep_files` 类似（可用 `mode=files|snippets`，或拆成 `ripgrep_fixed_files`/`ripgrep_fixed_snippets`）

---

## （可选）工具 5：`ripgrep_search`（全参数逃生舱）

### 适用场景

- 需要少见 `rg` 参数组合（多 pattern、特殊 regex、特殊过滤）
- 快捷工具覆盖不到但你又不想退出对话去跑 shell

### 交互（建议）

- 尽量贴近 `rg`：`ripgrep_search <pattern> [path] [options...]`
- 输出仍遵循本 spec 的 YAML 结构与 `max_results` 截断原则

---

## 边界与护栏（对话环境）

- 默认应限制输出：`max_results`、`max_files`，并在 `truncated=true` 时提示如何收敛（加 path/glob、切到 files/count）。
- 默认不搜二进制；遇到疑似二进制文件应跳过并在 summary 中计数说明。
- 对超大单文件：可截断或提示改用更窄 path/glob。

---

## 与编辑工具的联动旅程（推荐但不强制）

- 旅程 A：先 files 再 snippets 再精确改
  1. `ripgrep_files <pattern> <root>`
  2. `ripgrep_snippets <pattern> <one file>`
  3. `plan_file_modification <file> <range>`
  4. `apply_file_modification !<hunk>`

- 旅程 B：直接 snippets 快速定位
  1. `ripgrep_snippets <pattern> <root>`
  2. 直接精确改或改用易场景工具

- 旅程 C：count 用于回归检查
  1. `ripgrep_count <pattern> <root>`
  2. 若非 0，再回到 A 或 B

---

## 验收用例（手工可验证）

1. `ripgrep_files`：给定 pattern，返回文件列表，`files_matched` 与 results 数量一致（或 truncated=true 明确提示）。
2. `ripgrep_snippets`：返回包含 `line` 的命中片段，且上下文行数符合参数。
3. `ripgrep_count`：对同一目录重复运行，结果稳定；用于“残留检查”有效。
4. 截断行为：当 matches 过多时，`truncated=true` 且 summary 给出可收敛建议。
