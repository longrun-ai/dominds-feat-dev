# UX Spec：`plan_file_modification` / `apply_file_modification`（精确困难场景专用）

- 日期：2026-01-22
- 作者：`@ux`
- 范围：工作区文本文件（`.minds/` 镜像同理，但不在本 spec 里重复）
- 目标：把“对大且复杂文本文件进行精确修改”的体验做到极致：**敢改**（有定位证据）与 **能复核**（有应用证据）。

> 术语：本 spec 默认不带任何前缀（例如不写 `team_mgmt_`），`.minds/` 版本应镜像同样的行为与文案。

---

## 场景定义（本 spec 的唯一目标）

- 智能体已经通过其它方式获得了**准确行号**或等价的精确定位依据（例如来自编译器报错行、lint 输出、或先前读取的文件片段）。
- 修改目标是一个明确的、可表述为“替换/插入/删除某个精确范围”的编辑意图。
- 该文件可能较大、结构复杂，且在 plan 与 apply 之间可能发生并发修改。

> 非目标：为了“追加几行/插入一段”去扩展本工具的语法糖；这类易场景应使用单独工具（见 `ux-issues/text-easy-edit-tools.md`）。

---

## 全局硬规则：换行与空行

为避免“粘行”和隐式格式变化，精确编辑工具遵循同一条硬性原则：

- **假定所有文本行以 `\n` 结尾（包括最后一行）。**

落地为默认行为：

- 若文件非空且末尾不是 `\n`，在写入前自动补一个 `\n`。
- 若用于替换/插入的正文 `content` 不以 `\n` 结尾，自动补一个 `\n`。
- `content` 内的空行（连续 `\n`）原样保留；仅做“末尾补齐一枚 `\n`”的规范化。

---

## 痛点（面向智能体的真实风险）

1. **缺少“定位证据”**：仅返回 hunk diff 并不足以让智能体确认工具将修改的范围与其意图一致（尤其当文件大、上下文多、或存在并发修改）。
2. **缺少“应用证据”**：apply 后难以低负担复核“是否仍在同一语义位置发生修改”，以及是否出现 fuzz/偏移。
3. **失败信息不够可行动**：失败原因不够清晰时，智能体无法决定应该重 plan、调整范围，还是先重新评估文件整体变化。

---

## 现状实测输出（原样记录，便于对齐实现）

> 实测时间：2026-01-22  
> 实测方式：在工作区创建 `logs/plan-apply-sandbox.txt`（30 行内容），执行一次 plan 与 apply。  
> 结论：当前输出为 “hunk id + unified diff”，没有额外的摘要字段（如 `resolved_range` / `location_evidence` / `context_match`）。

### `plan_file_modification` 实测输出（原样）

调用：

```text
plan_file_modification logs/plan-apply-sandbox.txt 10~12
NEW10
NEW11
NEW12
```

返回：

````text
✅ 已生成修改规划：`!ceaa8b77`

**File:** `logs/plan-apply-sandbox.txt`
**Range:** `10~12`

```diff
diff --git a/logs/plan-apply-sandbox.txt b/logs/plan-apply-sandbox.txt
--- a/logs/plan-apply-sandbox.txt
+++ b/logs/plan-apply-sandbox.txt
@@ -7,9 +7,9 @@
 07 line 07
 08 line 08
 09 line 09
-10 line 10
-11 line 11
-12 line 12
+NEW10
+NEW11
+NEW12
 13 line 13
 14 line 14
 15 line 15
```

下一步：执行 `apply_file_modification !ceaa8b77` 来确认并写入。
````

### `apply_file_modification` 实测输出（原样）

调用：

```text
apply_file_modification !ceaa8b77
```

返回：

````text
✅ 已应用：`logs/plan-apply-sandbox.txt`（`!ceaa8b77`）

```diff
diff --git a/logs/plan-apply-sandbox.txt b/logs/plan-apply-sandbox.txt
--- a/logs/plan-apply-sandbox.txt
+++ b/logs/plan-apply-sandbox.txt
@@ -7,9 +7,9 @@
 07 line 07
 08 line 08
 09 line 09
-10 line 10
-11 line 11
-12 line 12
+NEW10
+NEW11
+NEW12
 13 line 13
 14 line 14
 15 line 15
```
````

---

## 设计要求（输出优先于语法扩展）

本 spec 的核心不在于新增 range 语法，而在于把 plan/apply 的**回显**与**证据**做成“低负担、可复核”的标准输出。

### 共同要求：稳定、可扫读摘要

plan 与 apply 都必须输出一条 `summary`，在 1–2 句内覆盖：

- 修改类型（replace/insert/append/delete）
- 影响范围（起止行号）
- 行数变化（old/new/delta）
- 匹配情况（exact / fuzz / rejected）

---

## 期望输出（完整示例：Markdown 外壳 + YAML 结构化块 + diff）

> 原则：不移除现有 unified diff（它对精确审阅很重要），但需要补上摘要与证据字段，让智能体不必从 diff 自行抽取关键信息。  
> YAML 的目的：比纯自然语言更稳定、比 JSON 更易扫读。

### `plan_file_modification` 期望输出（示例）

输入：

```text
plan_file_modification logs/plan-apply-sandbox.txt 10~12
NEW10
NEW11
NEW12
```

期望输出：

````text
✅ Planned `!ceaa8b77` for `logs/plan-apply-sandbox.txt`

```yaml
action: replace
range:
  input: "10~12"
  resolved:
    start: 10
    end: 12
lines:
  old: 3
  new: 3
  delta: 0
match: exact
evidence:
  before: |-
    08 line 08
    09 line 09
  range: |-
    10 line 10
    11 line 11
    12 line 12
  after: |-
    13 line 13
    14 line 14
summary: "Plan: replace lines 10–12 (3 lines) with 3 lines; 0 lines delta; matched exact; hunk_id=ceaa8b77."
```

```diff
diff --git a/logs/plan-apply-sandbox.txt b/logs/plan-apply-sandbox.txt
--- a/logs/plan-apply-sandbox.txt
+++ b/logs/plan-apply-sandbox.txt
@@ -7,9 +7,9 @@
 07 line 07
 08 line 08
 09 line 09
-10 line 10
-11 line 11
-12 line 12
+NEW10
+NEW11
+NEW12
 13 line 13
 14 line 14
 15 line 15
```
````

### `apply_file_modification` 期望输出（示例）

输入：

```text
apply_file_modification !ceaa8b77
```

期望输出：

````text
✅ Applied `!ceaa8b77` to `logs/plan-apply-sandbox.txt`

```yaml
action: replace
range:
  applied:
    start: 10
    end: 12
lines:
  old: 3
  new: 3
  delta: 0
context_match: exact
evidence:
  before: |-
    08 line 08
    09 line 09
  range: |-
    NEW10
    NEW11
    NEW12
  after: |-
    13 line 13
    14 line 14
summary: "Apply: replaced lines 10–12 with 3 lines; 0 lines delta; matched exact; hunk_id=ceaa8b77."
```

```diff
diff --git a/logs/plan-apply-sandbox.txt b/logs/plan-apply-sandbox.txt
--- a/logs/plan-apply-sandbox.txt
+++ b/logs/plan-apply-sandbox.txt
@@ -7,9 +7,9 @@
 07 line 07
 08 line 08
 09 line 09
-10 line 10
-11 line 11
-12 line 12
+NEW10
+NEW11
+NEW12
 13 line 13
 14 line 14
 15 line 15
```
````

---

## `plan_file_modification`：必须输出定位证据

### 输入（保持现有交互风格）

- 标题：`plan_file_modification <path> <range>`
- 正文：新内容 `content`
- range：保持现有 `A~B` / `A~` / `~B` / `~` 等表达（本 spec 不要求新增语法糖）

### 输出（建议字段）

- `status: ok|error`
- `path`
- `range_input`（原始字符串）
- `resolved_range`：`{ start_line, end_line, kind: replace|insert|append|delete }`
- `file_line_count`
- `old_line_count_in_range`
- `new_line_count`
- `delta_lines`
- `hunk_id`
- `location_evidence`（必须）：
  - `before_preview`：目标范围前 2 行（字符串数组）
  - `range_preview`：目标范围预览（建议：前 3 行 + 后 3 行，必要时省略）
  - `after_preview`：目标范围后 2 行
- `match_note`（必须，短语即可）：`exact|fuzz`（以及可选简短原因）
- `summary`（必须）

> `location_evidence` 的目的：让智能体在不另行读取文件的情况下，**低注意力成本确认定位正确**。

---

## `apply_file_modification`：必须输出应用证据与匹配结论

### 输入

- 标题：`apply_file_modification !<hunk_id>`
- 无正文

### 输出（建议字段）

- `status: ok|error`
- `path`
- `hunk_id`
- `applied_range`：`{ start_line, end_line, kind }`
- `old_line_count_in_range`
- `new_line_count`
- `delta_lines`
- `context_match`（必须）：`exact|fuzz|rejected`（短语即可）
- `apply_evidence`（必须）：
  - `applied_before_preview`
  - `applied_range_preview`
  - `applied_after_preview`
- `summary`（必须）

> 注意：这里不输出“必须 replan”的机械指令；只提供失败性质与常见可选动作，交由智能体根据原始意图决策。

---

## `replace_file_contents`：防 diff 心智误用（与精确编辑协作）

### 要求

- 工具说明必须明确：“逐字写入，不解析 diff/patch 语法”
- 运行时轻量检测：出现 `@@` / `diff --git` 或大量 `+`/`-` 前缀时给醒目 warning（不阻断）

### 示例（warning 文案示例）

- “Detected diff-like content. `replace_file_contents` writes literally; `+`/`@@` will be saved into the file.”

---

## 验收用例（精确编辑）

1. **Plan：必须有定位证据**

- 操作：对已知 range 做 plan
- 期望：输出包含 `location_evidence`，摘要包含 kind/range/line delta/match_note

2. **Apply：必须有应用证据**

- 操作：apply 已 plan 的 hunk
- 期望：输出包含 `apply_evidence` 与 `context_match`，摘要可扫读

3. **并发修改：fuzz 可见**

- 操作：plan 后改变同文件附近行，再 apply
- 期望：若仍能对上，`context_match=fuzz` 且 evidence 明显；若对不上，拒绝并给清晰失败性质

4. **EOF 无换行：规范化一致**

- 操作：对 EOF 无换行文件做替换或插入
- 期望：最终文件末尾有换行，且摘要/行为稳定一致

---

## Owner 路由建议（执行落地）

- 工具 contract / help 文案 / 输出回显：`@tooling`
- 回归验收纳入 gate：`@qa`
