#!/usr/bin/env markdown

# Dominds WebUI E2E: Text Tools (ripgrep\_\* + easy-edit + plan/apply UX) — For UX testing via dev-server rtws

This UX story validates:

- `ripgrep_*` navigation tools (files/snippets/count/fixed/search)
- “easy edit” tools (`append_file`, `insert_after`, `insert_before`, `replace_block`)
- safer precise edit workflow (`plan_file_modification` → `apply_file_modification`)
- `overwrite_file` “diff-like content” warning

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
  'overwrite_file',
  'replace_file_contents',
  'append_file',
  'insert_after',
  'insert_before',
  'replace_block',
  'plan_file_modification',
  'apply_file_modification',
  ...mustHaveRead,
];
for (const name of mustHaveMod) {
  if (!wsMod.tools.includes(name)) throw new Error(`ws_mod missing tool: ${name}`);
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

## T3) Easy-edit tools: replace → append → insert_after/before → replace_block

Send in chat:

```text
!?@replace_file_contents scratch/e2e-txt-tools.txt
!?L1 hello
!?L2 anchor: A
!?L3 keep
!?L4 anchor: B
!?L5 tail
```

Then:

```text
!?@append_file scratch/e2e-txt-tools.txt
!?APPEND-1
```

Then:

```text
!?@insert_after scratch/e2e-txt-tools.txt "anchor: A" occurrence=1 strict=true
!?AFTER-A
```

Then:

```text
!?@insert_before scratch/e2e-txt-tools.txt "anchor: B" occurrence=1 strict=true
!?BEFORE-B
```

Then:

```text
!?@replace_block scratch/e2e-txt-tools.txt "anchor: A" "anchor: B" occurrence=1 include_anchors=true
!?BLOCK-NEW
```

Finally:

```text
!?@read_file scratch/e2e-txt-tools.txt
```

Pass criteria:

- Each tool returns a YAML block with the expected fields (`normalized`, evidence preview, counts).
- Readback confirms anchors preserved and content inserted in the intended locations.

---

## T4) plan/apply: YAML evidence + unified diff retained

Plan with a fixed id:

```text
!?@plan_file_modification scratch/e2e-txt-tools.txt 1~1 !e2e_txt1
!?L1 HELLO-CHANGED
```

Apply:

```text
!?@apply_file_modification !e2e_txt1
```

Pass criteria:

- Plan output includes a ` ```yaml ` block with `evidence` + `summary`, and still shows the unified diff.
- Apply output includes `context_match` and applied evidence, and still shows the unified diff.

---

## T5) overwrite_file diff-like warning

```text
!?@overwrite_file scratch/e2e-diff-warning.txt
!?diff --git a/a.txt b/a.txt
!?@@ -1,1 +1,1 @@
!?-old
!?+new
```

Pass criteria:

- Output includes a warning that `overwrite_file` writes literally (diff is saved as-is).

---

## T6) ripgrep\_\* navigation

```text
!?@ripgrep_files "HELLO-CHANGED" scratch
```

```text
!?@ripgrep_snippets "HELLO-CHANGED" scratch fixed_strings=true context_before=1 context_after=1 max_results=10
```

```text
!?@ripgrep_fixed "@@ -1,1" scratch mode=snippets
```

```text
!?@ripgrep_count "anchor:" scratch fixed_strings=true
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
