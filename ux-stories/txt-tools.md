#!/usr/bin/env markdown

# Dominds WebUI E2E: Text Tools (ripgrep\_\* + easy-edit + preview/apply UX) — For UX testing via dev-server rtws

This UX story validates:

- `ripgrep_*` navigation tools (files/snippets/count/fixed/search)
- preview-first edit workflow (`preview_*` → `apply_file_modification`), including:
  - `preview_file_append`
  - `preview_insert_after`
  - `preview_insert_before`
  - `preview_block_replace`
  - `preview_file_modification`
- `create_new_file` create-only tool (empty content allowed)
- `overwrite_entire_file` guardrails (diff/patch default-refuse; explicit opt-in via `content_format`)

This test validates Dominds **tool contracts + WebUI surfacing**, not “LLM smartness”.

Repo note: `./dev-server.sh` uses runtime workspace (rtws) = `ux-rtws/`. All file paths below are relative to that rtws root.

---

## Setup

### S0) Start Dominds (dev)

From repo root:

```bash
./dev-server.sh restart
```

### S1) Calibration gate: ensure E2E helpers are loaded

Run in browser console:

```javascript
if (typeof window.__e2e__?.snapshotDomindsUI !== 'function') {
  const ts = String(Date.now());

  if (typeof window.__domObservation__ !== 'object') {
    const obs = document.createElement('script');
    obs.src = `/testing/dom-observation-utils.js?ts=${ts}`;
    document.head.appendChild(obs);
    await waitUntil(() => typeof window.__domObservation__ === 'object', 5000);
  }

  const helper = document.createElement('script');
  helper.src = `/testing/e2e-test-helper.js?ts=${ts}`;
  document.head.appendChild(helper);
  await waitUntil(() => typeof window.__e2e__?.snapshotDomindsUI === 'function', 5000);
}
window.__e2e__.checkConsoleErrors({ clear: true, threshold: 0 });
const baseline = window.__e2e__.snapshotDomindsUI();
```

---

## Helper snippets (Tools registry)

```javascript
function getAppShadow() {
  const s = window.__e2e__?.getAppShadow?.();
  if (!s) throw new Error('Missing dominds-app shadow root');
  return s;
}

function clickToolsActivity() {
  const s = getAppShadow();
  const btn = s.querySelector(`.activity-button[data-activity="tools"]`);
  if (!(btn instanceof HTMLButtonElement)) throw new Error('Missing tools activity button');
  btn.click();
}

function getToolsPanelState() {
  const s = getAppShadow();
  const view = s.querySelector(`.activity-view[data-activity-view="tools"]`);
  if (!(view instanceof HTMLElement)) throw new Error('Missing tools activity view');

  const hidden = view.classList.contains('hidden');
  const ts = s.querySelector('#tools-registry-timestamp');
  const list = s.querySelector('#tools-registry-list');
  const refresh = s.querySelector('#tools-registry-refresh');

  if (!(list instanceof HTMLElement)) throw new Error('Missing #tools-registry-list');
  if (!(refresh instanceof HTMLButtonElement)) throw new Error('Missing #tools-registry-refresh');

  const toolsets = [...list.querySelectorAll('details.toolset')].map((d) => {
    const title = d.querySelector('summary.toolset-title')?.textContent?.trim() || '';
    const tools = [...d.querySelectorAll('.tool-item .tool-name')].map((n) =>
      (n.textContent || '').trim(),
    );
    return { title, tools };
  });

  return {
    visible: !hidden,
    timestamp: (ts?.textContent || '').trim(),
    toolsets,
    refresh,
  };
}
```

---

## T1) Verify toolsets list includes new tools

In browser console:

```javascript
clickToolsActivity();
const s0 = getToolsPanelState();
s0.refresh.click();
await window.__e2e__.waitUntil(() => getToolsPanelState().toolsets.length > 0, 5000);
const s1 = getToolsPanelState();
window.__e2e__.checkConsoleErrors({ clear: false, threshold: 0 });

const wsRead = s1.toolsets.find((x) => x.title.includes('ws_read'));
if (!wsRead) throw new Error(`Missing toolset 'ws_read'`);

const wsMod = s1.toolsets.find((x) => x.title.includes('ws_mod'));
if (!wsMod) throw new Error(`Missing toolset 'ws_mod'`);

const mustHaveRead = [
  'ripgrep_files',
  'ripgrep_snippets',
  'ripgrep_count',
  'ripgrep_fixed',
  'ripgrep_search',
];
for (const name of mustHaveRead) {
  if (!wsRead.tools.includes(name)) throw new Error(`ws_read missing tool: ${name}`);
}

const mustHaveMod = [
  'read_file',
  'create_new_file',
  'overwrite_entire_file',
  'preview_file_modification',
  'preview_file_append',
  'preview_insert_after',
  'preview_insert_before',
  'preview_block_replace',
  'apply_file_modification',
  ...mustHaveRead,
];
for (const name of mustHaveMod) {
  if (!wsMod.tools.includes(name)) throw new Error(`ws_mod missing tool: ${name}`);
}

const teamMgmt = s1.toolsets.find((x) => x.title.includes('team-mgmt'));
if (!teamMgmt) throw new Error(`Missing toolset 'team-mgmt'`);
const mustHaveTeamMgmt = [
  'team_mgmt_read_file',
  'team_mgmt_create_new_file',
  'team_mgmt_overwrite_entire_file',
  'team_mgmt_preview_file_modification',
  'team_mgmt_apply_file_modification',
];
for (const name of mustHaveTeamMgmt) {
  if (!teamMgmt.tools.includes(name)) throw new Error(`team-mgmt missing tool: ${name}`);
}
```

Pass criteria:

- `ws_read` contains all `ripgrep_*` tools.
- `ws_mod` contains edit tools + `ripgrep_*`.
- No new console errors.

---

## T2) Create dialog as `@ux` (preferred) or fallback `@pangu`

In browser console:

```javascript
await window.__e2e__.createDialog('tasks/ux-txt-tools.tsk', '@ux');
await window.__e2e__.waitForInputEnabled();
```

If `@ux` is not available, fallback:

```javascript
await window.__e2e__.createDialog('tasks/ux-txt-tools.tsk', '@pangu');
await window.__e2e__.waitForInputEnabled();
```

Pass criteria:

- Dialog created and input enabled.

---

## T3) Preview-first edit tools: init (create) → preview+apply append → preview+apply insert → preview+apply block_replace

Send in chat (each block is a separate message):

```text
Call the function tool `preview_file_append` with:
- path: scratch/e2e-txt-tools.txt
- create: true
- content: |
    L1 hello
    L2 anchor: A
    L3 keep
    L4 anchor: B
    L5 tail
```

Apply (copy `hunk_id` from the plan YAML):

```text
Call the function tool `apply_file_modification` with:
{ "hunk_id": "<hunk_id>" }
```

Then plan append:

```text
Call the function tool `preview_file_append` with:
- path: scratch/e2e-txt-tools.txt
- content: |
    APPEND-1
```

Apply (copy `hunk_id` from the plan YAML):

```text
Call the function tool `apply_file_modification` with:
{ "hunk_id": "<hunk_id>" }
```

Then plan insert-after:

```text
Call the function tool `preview_insert_after` with:
- path: scratch/e2e-txt-tools.txt
- anchor: "anchor: A"
- occurrence: 1
- content: |
    AFTER-A
```

Apply (copy `hunk_id` from the plan YAML):

```text
Call the function tool `apply_file_modification` with:
{ "hunk_id": "<hunk_id>" }
```

Then plan insert-before:

```text
Call the function tool `preview_insert_before` with:
- path: scratch/e2e-txt-tools.txt
- anchor: "anchor: B"
- occurrence: 1
- content: |
    BEFORE-B
```

Apply (copy `hunk_id` from the plan YAML):

```text
Call the function tool `apply_file_modification` with:
{ "hunk_id": "<hunk_id>" }
```

Then plan block-replace:

```text
Call the function tool `preview_block_replace` with:
- path: scratch/e2e-txt-tools.txt
- start_anchor: "anchor: A"
- end_anchor: "anchor: B"
- occurrence: 1
- include_anchors: true
- content: |
    BLOCK-NEW
```

Apply (copy `hunk_id` from the plan YAML):

```text
Call the function tool `apply_file_modification` with:
{ "hunk_id": "<hunk_id>" }
```

Finally:

```text
Call the function tool `read_file` with:
{ "path": "scratch/e2e-txt-tools.txt" }
```

Pass criteria:

- Each plan tool returns a YAML block with the expected fields (`normalized`, evidence preview, counts).
- Each apply returns YAML with `context_match` + `apply_evidence`.
- Readback confirms anchors preserved and content inserted in the intended locations.

---

## T4) preview/apply: YAML evidence + unified diff retained

Plan:

```text
Call the function tool `preview_file_modification` with:
- path: scratch/e2e-txt-tools.txt
- range: 1~1
- content: |
    L1 HELLO-CHANGED
```

Apply (copy `hunk_id` from the plan YAML):

```text
Call the function tool `apply_file_modification` with:
{ "hunk_id": "<hunk_id>" }
```

Pass criteria:

- Plan output includes a ` ```yaml ` block with `evidence` + `summary`, and still shows the unified diff.
- Apply output includes `context_match` and `apply_evidence`, and still shows the unified diff.

---

## T5) overwrite_entire_file guardrails (function tool)

1. Create a small seed file (deterministic old stats):

```text
Call the function tool `preview_file_append` with:
- path: scratch/e2e-diff-warning.txt
- create: true
- content: |
    seed
```

```text
Call the function tool `apply_file_modification` with:
{ "hunk_id": "<hunk_id>" }
```

2. Ask the agent to call the **function tool** `overwrite_entire_file` with old stats = `known_old_total_lines=1` and `known_old_total_bytes=5`, and content as a diff — but **do not** provide `content_format`:

```text
Call the function tool overwrite_entire_file with:
- path: scratch/e2e-diff-warning.txt
- known_old_total_lines: 1
- known_old_total_bytes: 5
- content: |
    diff --git a/a.txt b/a.txt
    @@ -1,1 +1,1 @@
    -old
    +new
Do not set content_format.
```

3. Repeat, but set `content_format='diff'`, then confirm by calling the function tool `read_file` with `{ "path": "scratch/e2e-diff-warning.txt" }`.

Pass criteria:

- Without `content_format`, the call is rejected as “diff/patch-like content”.
- With `content_format='diff'`, the call succeeds and the diff text is written literally.

---

## T6) ripgrep\_\* navigation

```text
Call the function tool `ripgrep_files` with:
{ "pattern": "HELLO-CHANGED", "path": "scratch" }
```

```text
Call the function tool `ripgrep_snippets` with:
{ "pattern": "HELLO-CHANGED", "path": "scratch", "fixed_strings": true, "context_before": 1, "context_after": 1, "max_results": 10 }
```

```text
Call the function tool `ripgrep_fixed` with:
{ "literal": "@@ -1,1", "path": "scratch", "mode": "snippets" }
```

```text
Call the function tool `ripgrep_count` with:
{ "pattern": "anchor:", "path": "scratch", "fixed_strings": true }
```

Pass criteria:

- `ripgrep_files` returns file list in YAML.
- `ripgrep_snippets` returns line/col + small context in YAML.
- `ripgrep_fixed` finds literal markers safely.
- `ripgrep_count` returns per-file counts + totals.

---

## Done

Capture:

- Any missing/unstable YAML fields
- Any mismatch between Tools panel registry and actual callable tools
- Any confusing defaults / truncation behavior
