#!/usr/bin/env markdown

# UAT: Text Tools (ripgrep_* + easy-edit + plan/apply UX) — run as `@ux`

Owner: `ux` (member id `ux` in `ux-rtws/.minds/team.yaml`)

This is a **manual agent UAT script**. It validates **tool contracts + UX** (not “LLM smartness”).

Repo note: `./dev-server.sh` runs Dominds with runtime workspace (rtws) = `ux-rtws/`. All file paths below are relative to that rtws root.

---

## Setup

### S0) Start dev server

From repo root:

```bash
./dev-server.sh restart
```

Open WebUI (default): `http://localhost:5555`

### S1) Ensure you can create a dialog as `@ux`

In WebUI, create a new dialog and select member `@ux`.

If `@ux` is not selectable:

- Confirm `ux-rtws/.minds/team.yaml` defines `members.ux` (not nested under `member_defaults`).
- Confirm `members.ux.toolsets` includes at least: `ws_read`, `ws_mod`, `team-mgmt`.

Pass criteria:

- You can create a dialog as `@ux` and send messages.

---

## T0) Tools panel smoke: toolsets contain the new tools

In the Tools panel (left activity = Tools), refresh and confirm:

### T0a) `ws_read` contains search tools

Must include:

- `ripgrep_files`
- `ripgrep_snippets`
- `ripgrep_count`
- `ripgrep_fixed`
- `ripgrep_search`

### T0b) `ws_mod` contains editing + search tools

Must include (legacy + new):

- `read_file`
- `overwrite_file`
- `replace_file_contents`
- `append_file`
- `insert_after`
- `insert_before`
- `replace_block`
- `plan_file_modification`
- `apply_file_modification`
- all `ripgrep_*` tools above

Pass criteria:

- Toolsets list the tools above.

---

## T1) Prepare scratch file

Send:

```text
!!@replace_file_contents scratch/uat-txt-tools.txt
L1 hello
L2 anchor: A
L3 keep
L4 anchor: B
L5 tail
```

Then:

```text
!!@read_file scratch/uat-txt-tools.txt
```

Pass criteria:

- `replace_file_contents` succeeds.
- `read_file` shows the exact content (line numbers ok).

---

## T2) append_file newline normalization (no “粘行”)

Goal: verify the global newline rule:

- if file doesn’t end with `\n`, tool adds one before writing
- if body doesn’t end with `\n`, tool adds one

### T2a) Force file EOF to have no trailing newline (using overwrite_file)

Because `overwrite_file` / `replace_file_contents` normalize content to end with `\n`, create an EOF-without-newline file via terminal:

From repo root:

```bash
mkdir -p ux-rtws/scratch
printf 'ONE-LINE-NO-TRAILING-NL' > ux-rtws/scratch/uat-eof-no-nl.txt
```

Then append (body intentionally without trailing newline):

```text
!!@append_file scratch/uat-eof-no-nl.txt
APPENDED-1
```

Then:

```text
!!@read_file scratch/uat-eof-no-nl.txt
```

Pass criteria:

- `append_file` returns YAML with `normalized.added_leading_newline_to_file` and `normalized.added_trailing_newline_to_content`.
- Readback shows `ONE-LINE-NO-TRAILING-NL` and `APPENDED-1` on separate lines (no concatenation).

---

## T3) insert_after / insert_before happy path + ambiguity handling

### T3a) insert_after (unique anchor)

```text
!!@insert_after scratch/uat-txt-tools.txt "anchor: A" occurrence=1 strict=true
AFTER-A-1
AFTER-A-2
```

Then:

```text
!!@read_file scratch/uat-txt-tools.txt
```

Pass criteria:

- YAML contains: `inserted_at_line`, `inserted_line_count`, and `evidence_preview` (before/insert/after).

### T3b) insert_before (unique anchor)

```text
!!@insert_before scratch/uat-txt-tools.txt "anchor: B" occurrence=1 strict=true
BEFORE-B-1
```

Then:

```text
!!@read_file scratch/uat-txt-tools.txt
```

Pass criteria:

- YAML contains evidence preview and correct `inserted_at_line`.

### T3c) Ambiguous anchor requires explicit `occurrence`

Create ambiguity (two identical anchors):

```text
!!@insert_after scratch/uat-txt-tools.txt "anchor: A" occurrence=1 strict=true
anchor: A
```

Now attempt insert without occurrence:

```text
!!@insert_after scratch/uat-txt-tools.txt "anchor: A"
SHOULD-FAIL
```

Pass criteria:

- Tool fails with YAML error `ANCHOR_AMBIGUOUS` and a summary telling you to specify `occurrence` or use plan/apply.

### T3d) Reset scratch file (avoid nested anchors for replace_block)

Because `replace_block` should reject nested/ambiguous anchors, reset the file back to the baseline (single `anchor: A` / `anchor: B`) before T4:

```text
!!@replace_file_contents scratch/uat-txt-tools.txt
L1 hello
L2 anchor: A
L3 keep
L4 anchor: B
L5 tail
```

---

## T4) replace_block (anchors preserved vs replaced)

### T4a) Replace between anchors, preserve anchors (default)

```text
!!@replace_block scratch/uat-txt-tools.txt "anchor: A" "anchor: B" occurrence=1 include_anchors=true
BLOCK-NEW-1
BLOCK-NEW-2
```

Then:

```text
!!@read_file scratch/uat-txt-tools.txt
```

Pass criteria:

- YAML contains `replaced_range`, `old_line_count_in_block`, `new_line_count_in_block`, `delta_lines`, `evidence_preview`.
- `anchor: A` and `anchor: B` remain in the file.

### T4b) Reject nested/ambiguous anchors

If you can easily craft nested anchors, do so and confirm the tool fails with a YAML error that tells you to use plan/apply.

---

## T5) plan/apply UX: YAML summary + evidence + match classification

### T5a) Plan must return location evidence (before/range/after)

```text
!!@plan_file_modification scratch/uat-txt-tools.txt 1~1 !uat1
L1 HELLO-CHANGED
```

Pass criteria:

- Output contains a ` ```yaml ` block including:
  - `action`, `range.input`, `range.resolved`, `lines.old/new/delta`
  - `match: exact`
  - `evidence.before/range/after`
  - `summary`
- Unified diff remains present after the YAML block.

### T5b) Apply must return apply evidence + context_match (exact/fuzz)

```text
!!@apply_file_modification !uat1
```

Pass criteria:

- Output contains YAML with:
  - `context_match: exact` (or `fuzz` if the file changed but the hunk was still applied)
  - `evidence.before/range/after` (applied evidence)
- Unified diff remains present.

### T5c) Fuzz case (optional but recommended)

1) Plan a change against a line that you will move:

```text
!!@plan_file_modification scratch/uat-txt-tools.txt 2~2 !uat2
LINE-TO-REPLACE
```

2) Move the target content to a different location (any edit that preserves the old line text once in the file), e.g.:

```text
!!@insert_before scratch/uat-txt-tools.txt "L1 HELLO-CHANGED" occurrence=1 strict=true
L2 anchor: MOVED
```

3) Apply:

```text
!!@apply_file_modification !uat2
```

Pass criteria:

- Apply succeeds and reports `context_match: fuzz`.

### T5d) Rejected case (must refuse if can’t locate uniquely)

Create multiple identical copies of the planned old-lines so the target becomes ambiguous (e.g. duplicate the exact old line in multiple places), then:

```text
!!@apply_file_modification !uat2
```

Pass criteria:

- Apply returns a YAML error with `context_match: rejected` and an actionable summary (re-plan).

---

## T6) overwrite_file diff-like warning

Send:

```text
!!@overwrite_file scratch/uat-diff-warning.txt
diff --git a/a.txt b/a.txt
@@ -1,1 +1,1 @@
-old
+new
```

Pass criteria:

- Output includes a warning that `overwrite_file` writes literally and will save `+`/`@@` into the file.
- `!!@read_file scratch/uat-diff-warning.txt` shows the diff text was saved literally.

---

## T7) ripgrep_* navigation (snippets + fixed + count)

### T7a) ripgrep_files for “where is it”

```text
!!@ripgrep_files "HELLO-CHANGED" scratch
```

Pass criteria:

- YAML includes `mode: files` and lists `scratch/uat-txt-tools.txt`.

### T7b) ripgrep_snippets for “line numbers + context”

```text
!!@ripgrep_snippets "HELLO-CHANGED" scratch context_before=1 context_after=1 max_results=10 fixed_strings=true
```

Pass criteria:

- YAML results include `line`, `col`, `before`, `after`.

### T7c) ripgrep_fixed (literal match helpers)

```text
!!@ripgrep_fixed "@@ -1,1" scratch mode=snippets
```

Pass criteria:

- Finds the diff hunk marker in `scratch/uat-diff-warning.txt`.

### T7d) ripgrep_count for residue check

```text
!!@ripgrep_count "anchor:" scratch fixed_strings=true
```

Pass criteria:

- YAML includes `totals.matches` and per-file counts.

---

## Done: record verdict

Record pass/fail with notes:

- Any missing YAML fields
- Any confusing summary text
- Any truncation/default issues (max_results/max_files)
