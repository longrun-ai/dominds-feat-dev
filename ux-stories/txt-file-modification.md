#!/usr/bin/env markdown

# Dominds WebUI E2E: Text File Editing (plan/apply file modification tools) - For e2e-browser-tester Agent

You are the **tester agent**. Your job is to validate that Dominds supports a safer/ergonomic text
editing workflow via:

- `plan_file_modification` (proposes a diff hunk, caches it with a short hunk id)
- `apply_file_modification` (explicit confirmation by hunk id; refuses to apply if the file changed)

This test validates Dominds infrastructure + tool behavior, not “LLM smartness”.

Note: in this repo, the runtime workspace (rtws) used by `./dev-server.sh` is `ux-rtws/`. All file
paths below are relative to that rtws root.

---

## Setup

### S0) Start Dominds

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

## T1) Verify `ws_mod` includes the new tools (and legacy tools are absent)

In browser console:

```javascript
clickToolsActivity();
const s0 = getToolsPanelState();
s0.refresh.click();
await window.__e2e__.waitUntil(() => getToolsPanelState().toolsets.length > 0, 5000);
const s1 = getToolsPanelState();
window.__e2e__.checkConsoleErrors({ clear: false, threshold: 0 });

const wsMod = s1.toolsets.find((x) => x.title.includes('ws_mod'));
if (!wsMod) throw new Error(`Missing toolset 'ws_mod'`);

const mustHave = [
  'plan_file_modification',
  'apply_file_modification',
  'read_file',
  'overwrite_file',
];
for (const name of mustHave) {
  if (!wsMod.tools.includes(name)) throw new Error(`ws_mod missing tool: ${name}`);
}
```

Pass criteria:

- `ws_mod` contains `plan_file_modification` + `apply_file_modification`.
- No new console errors.

---

## T2) Create dialog and verify the plan → apply → readback loop

### T2a) Create dialog

In browser console:

```javascript
await window.__e2e__.createDialog('tasks/ux-txt-file-modification.tsk', '@pangu');
await window.__e2e__.waitForInputEnabled();
```

### T2b) Basic edit flow on a scratch file

Send in chat:

```text
!?@overwrite_file scratch/txt-e2e.txt
!?hello-1
!?line-2
!?line-3
!?tail
```

Then:

```text
!?@read_file scratch/txt-e2e.txt
```

Then plan a replacement (fixed id so the test doesn’t need to parse tool output):

```text
!?@plan_file_modification scratch/txt-e2e.txt 2~3 !e2e1
!?hello-2
!?hello-3
```

Then apply:

```text
!?@apply_file_modification !e2e1
```

Then confirm:

```text
!?@read_file scratch/txt-e2e.txt
```

Pass criteria:

- Plan call completes and shows a `diff` block for `scratch/txt-e2e.txt`.
- Apply call completes.
- Readback shows `hello-2` and `hello-3` in lines 2–3.
- No new console errors.

---

## T3) Safety checks

### T3a) Applied hunks are removed from cache

Re-apply (expected failure):

```text
!?@apply_file_modification !e2e1
```

Pass criteria:

- Tool call fails with a “not found / expired / already applied” style message.

### T3b) Refuse to apply if the file changed

1. Plan a hunk but don’t apply it yet:

```text
!?@plan_file_modification scratch/txt-e2e.txt 1~1 !e2e2
!?HELLO-CHANGED
```

2. Mutate the same target line via overwrite (any change is fine):

```text
!?@overwrite_file scratch/txt-e2e.txt
!?DIFFERENT-NOW
!?hello-2
!?hello-3
!?tail
```

3. Try to apply the stale plan (expected failure):

```text
!?@apply_file_modification !e2e2
```

Pass criteria:

- Apply fails with a “file content has changed; refusing to apply safely; re-plan” style message.

---

## T4) Multi-file batching (parallel-safe)

Goal: show that multiple modifications can be confirmed in one message when they target **different**
files (safe under parallel tool execution).

1. Create two files:

```text
!?@overwrite_file scratch/a.txt
!?A0
!?A1
```

```text
!?@overwrite_file scratch/b.txt
!?B0
!?B1
```

2. Plan one hunk for each file:

```text
!?@plan_file_modification scratch/a.txt 2~2 !a1
!?A2
```

```text
!?@plan_file_modification scratch/b.txt 2~2 !b1
!?B2
```

3. Apply both in one message:

```text
!?@apply_file_modification !a1
!?@apply_file_modification !b1
```

4. Confirm:

```text
!?@read_file scratch/a.txt
```

```text
!?@read_file scratch/b.txt
```

Pass criteria:

- Both apply calls complete.
- `scratch/a.txt` contains `A2` on line 2; `scratch/b.txt` contains `B2` on line 2.
- No new console errors.

---

## T5) Multi-hunks to a single file in one message (serialized + tolerant to line moves)

Goal: verify multiple `apply_file_modification` calls targeting the **same file** can be sent in one
message and will be applied safely (serialized in-process). This scenario also verifies that a later
hunk can still apply even if earlier hunks changed line numbers, as long as the target content
remains uniquely matchable.

1. Create a file:

```text
!?@overwrite_file scratch/same.txt
!?L1
!?L2
!?L3
!?L4
```

2. Plan two hunks against the original file (in separate messages so the hunk creation order is
   unambiguous):

```text
!?@plan_file_modification scratch/same.txt 2~2 !h1
!?L2a
!?L2b
```

```text
!?@plan_file_modification scratch/same.txt 4~4 !h2
!?L4x
```

3. Apply both in **one** message:

```text
!?@apply_file_modification !h1
!?@apply_file_modification !h2
```

4. Confirm:

```text
!?@read_file scratch/same.txt
```

Pass criteria:

- Both apply calls complete (no mismatch/ambiguous errors).
- Readback contains `L2a`, `L2b`, and `L4x`.

Note:

- This is only safe for **non-overlapping** hunks. Overlapping edits should fail and require re-plan.

---

## Cleanup (optional)

```text
!?@rm_file scratch/txt-e2e.txt
!?@rm_file scratch/a.txt
!?@rm_file scratch/b.txt
!?@rm_file scratch/same.txt
```
