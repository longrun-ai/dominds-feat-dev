# Dominds WebUI E2E: Dialog Lifecycle (Done / Archived) + Revival + Multi-Client Sync

You are the **tester agent** standing in for a human user. Your role is to validate that **dominds** provides flawless **dialog lifecycle infrastructure**:

- Running → Done (completed) → Archived
- Revival (Done/Archived → Running)
- **Task-level bulk actions**
- **Multi-client realtime sync** (other tab/browser sees list updates without refresh)
- **Read-only UX**: input must be hidden/disabled for Done/Archived dialogs

The testee should **cooperate** with your directions to help exercise the feature surface area.

## The Test Purpose

This test validates **dominds dialog lifecycle infrastructure**, not the testee agent's performance.

- The testee is a reasonable LLM-powered AI agent. It should cooperate with your instructions to exercise dominds features, but may still make mistakes or deviate (as all LLMs do).
- **Dominds must work reliably** regardless of testee behavior: correct persistence move semantics, correct UI state transitions, and correct multi-client event broadcast.

## Business Goal

Enable long-run operators to manage dialog inventory across weeks/months:

- Keep the “Running” list actionable and uncluttered
- Park finished work in “Done”
- Archive irrelevant work in “Archived”
- Recover accidentally-finished work via “Revive”
- Ensure multi-tab/multi-browser usage does not create stale UI state

## Tester Hardening Rules

- **Assert infra, not prose**: pass/fail is based on list membership, selection state, and input enablement—never on agent text.
- **Time-bound UI transitions**: list membership must update within **2s** locally; multi-client updates within **5s**.
- **Check console errors after every action**: lifecycle UX should not throw protocol/type errors.
- **One retry only** for suspected infra race (e.g. slow websocket). If the second attempt fails, treat as infra failure.

---

## Standardized Observation Pattern

Before and after every user-visible action:

1. `SNAP`: `const snap = window.__e2e__.snapshotDomindsUI()`
2. `DELTA`: `snap.reportDeltaTo(prev)` (keep a `prev` snapshot across steps)
3. `VERIFY`: assert the invariants (list membership, selection, input enabled)
4. `ACT`: click or send
5. `WAIT`: `waitUntil` on the expected UI state change
6. `EVIDENCE`: return the deltas + key fields in the tool result

Note: `snapshotDomindsUI()` currently captures the **running** dialog list. For Done/Archived membership, use `listRootIds('done')` / `listRootIds('archived')` from the helper section below.

## Essential Helper Reference

| Helper                                 | Purpose                                      |
| -------------------------------------- | -------------------------------------------- |
| `window.__e2e__.snapshotDomindsUI()`   | Observe current UI state (running list only) |
| `window.__e2e__.waitUntil(fn, ms)`     | Poll until a condition is true               |
| `window.__e2e__.createDialog(taskDoc)` | Create a new dialog via UI                   |
| `window.__e2e__.fillAndSend(text)`     | Send a message to current dialog             |
| `window.__e2e__.waitForInputEnabled()` | Wait until input is usable                   |
| `window.__e2e__.checkConsoleErrors()`  | Fail test when UI logs errors                |

### A small helper for Done/Archived lists (not covered by `snapshotDomindsUI()` yet)

```javascript
function getListShadow(kind /* 'running' | 'done' | 'archived' */) {
  const appShadow = window.__e2e__.getAppShadow();
  if (!appShadow) throw new Error('Missing dominds-app shadow root');

  if (kind === 'running') {
    const el = appShadow.querySelector('running-dialog-list');
    if (!el || !el.shadowRoot) throw new Error('Missing running-dialog-list shadowRoot');
    return el.shadowRoot;
  }
  if (kind === 'done') {
    const el = appShadow.querySelector('done-dialog-list');
    if (!el || !el.shadowRoot) throw new Error('Missing done-dialog-list shadowRoot');
    return el.shadowRoot;
  }
  if (kind === 'archived') {
    const el = appShadow.querySelector('archived-dialog-list');
    if (!el || !el.shadowRoot) throw new Error('Missing archived-dialog-list shadowRoot');
    return el.shadowRoot;
  }
  throw new Error(`Unknown kind: ${String(kind)}`);
}

function listRootIds(kind) {
  const s = getListShadow(kind);
  // Root rows use data-self-id="" and data-root-id="<id>"
  const roots = Array.from(s.querySelectorAll('.dialog-item.root-dialog[data-root-id]'));
  return roots
    .map((n) => n.getAttribute('data-root-id') || '')
    .filter((x) => typeof x === 'string' && x.length > 0);
}

function isInputReadOnly() {
  const appShadow = window.__e2e__.getAppShadow();
  const banner = appShadow.querySelector('#q4h-readonly-banner');
  const input = appShadow.querySelector('#q4h-input');
  return {
    bannerVisible: !!banner && !banner.classList.contains('hidden'),
    inputHidden: !!input && input.classList.contains('hidden'),
  };
}
```

---

## Setup

### S0) (Optional) Reset records for determinism

From repo root:

```bash
./ux-rtws/clear-records.sh
./dev-server.sh restart
```

### S1) Create a dedicated task doc (task package directory)

Use a stable path (create the directory if missing).

Note: The Create Dialog modal validates that the task doc path ends in `.tsk/` (encapsulated task package directory).

```bash
mkdir -p tasks
mkdir -p tasks/ux-dlg-revival.tsk
# A `.tsk/` task package contains only the encapsulated sections:
# - goals.md
# - constraints.md
# - progress.md
#
: > tasks/ux-dlg-revival.tsk/goals.md
: > tasks/ux-dlg-revival.tsk/constraints.md
: > tasks/ux-dlg-revival.tsk/progress.md
```

### S2) Calibration gate: ensure E2E helpers are loaded

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
```

---

## Scenario A — Running → Done, selection becomes read-only

### A1) Create one dialog

```javascript
window.__e2e__.checkConsoleErrors({ clear: true, threshold: 0 });

await window.__e2e__.createDialog('tasks/ux-dlg-revival.tsk');
await window.__e2e__.waitForInputEnabled();

const snap = window.__e2e__.snapshotDomindsUI();
if (!snap.currentDialog?.hasRealDialog) throw new Error('Expected a selected dialog');
```

Record the current root id for later steps:

```javascript
const rootId = window.__e2e__.snapshotDomindsUI().currentDialog?.dialogInfo?.rootId;
if (typeof rootId !== 'string' || !rootId) throw new Error('Missing current dialog rootId');
rootId;
```

### A2) Mark the dialog Done using the running list root button

Manual UX action:

1. In the sidebar, make sure “Running” is selected.
2. Find the root dialog row for `rootId`.
3. Click the **Mark done** (check icon) button.

Infra assertions:

- Within **2s**, `rootId` disappears from `listRootIds('running')`
- Within **2s**, `rootId` appears in `listRootIds('done')`

```javascript
await window.__e2e__.waitUntil(() => !listRootIds('running').includes(rootId), 2000);
await window.__e2e__.waitUntil(() => listRootIds('done').includes(rootId), 2000);
window.__e2e__.checkConsoleErrors({ clear: true, threshold: 0 });
```

### A3) Select the done dialog and verify input is disabled/hidden

Manual UX action:

1. Click the sidebar “Done” activity (check icon).
2. Click the dialog row for `rootId`.

Assertions:

- Read-only banner becomes visible
- The input panel is hidden (and must not accept user typing)

```javascript
await window.__e2e__.waitUntil(() => {
  const ro = isInputReadOnly();
  return ro.bannerVisible === true && ro.inputHidden === true;
}, 2000);
```

---

## Scenario B — Done → Running (Revive)

### B1) Revive the dialog from Done list

Manual UX action:

1. In “Done” list, click **Revive** on the root row for `rootId`.

Assertions:

- `rootId` disappears from Done and appears in Running
- Selecting it in Running re-enables input (banner hidden, input visible)

```javascript
await window.__e2e__.waitUntil(() => !listRootIds('done').includes(rootId), 2000);
await window.__e2e__.waitUntil(() => listRootIds('running').includes(rootId), 2000);

// Select it from running list and verify input returns usable.
// (Human click) then:
await window.__e2e__.waitUntil(() => {
  const ro = isInputReadOnly();
  return ro.bannerVisible === false && ro.inputHidden === false;
}, 2000);
await window.__e2e__.waitForInputEnabled();
```

---

## Scenario C — Archive flow + archived revival

### C1) Running → Archived (archive button)

Manual UX action:

1. In “Running” list, click **Archive** on the root row for `rootId`.

Assertions:

```javascript
await window.__e2e__.waitUntil(() => !listRootIds('running').includes(rootId), 2000);
await window.__e2e__.waitUntil(() => listRootIds('archived').includes(rootId), 2000);
```

### C2) Select archived dialog → read-only input

```javascript
await window.__e2e__.waitUntil(() => {
  const ro = isInputReadOnly();
  return ro.bannerVisible === true && ro.inputHidden === true;
}, 2000);
```

### C3) Archived → Running (revive)

Manual UX action:

1. In “Archived” list, click **Revive** on `rootId`.

Assertions:

```javascript
await window.__e2e__.waitUntil(() => !listRootIds('archived').includes(rootId), 2000);
await window.__e2e__.waitUntil(() => listRootIds('running').includes(rootId), 2000);
```

---

## Scenario D — Task-level bulk actions (mark all done / archive all / revive all)

Goal: validate **task-doc node** action buttons (bulk actions apply to all dialogs under the same task doc path).

### D1) Create two dialogs under the same task doc

```javascript
await window.__e2e__.createDialog('tasks/ux-dlg-revival.tsk');
await window.__e2e__.waitForInputEnabled();
const a = window.__e2e__.snapshotDomindsUI().currentDialog?.dialogInfo?.rootId;
if (typeof a !== 'string' || !a) throw new Error('Missing dialog rootId a');

await window.__e2e__.createDialog('tasks/ux-dlg-revival.tsk');
await window.__e2e__.waitForInputEnabled();
const b = window.__e2e__.snapshotDomindsUI().currentDialog?.dialogInfo?.rootId;
if (typeof b !== 'string' || !b) throw new Error('Missing dialog rootId b');

({ a, b });
```

### D2) Bulk mark done

Manual UX action:

1. In “Running” view, on the **task doc row** (`tasks/ux-dlg-revival.tsk`), click **Mark all done**.

Assertions:

```javascript
await window.__e2e__.waitUntil(
  () => !listRootIds('running').includes(a) && !listRootIds('running').includes(b),
  2000,
);
await window.__e2e__.waitUntil(
  () => listRootIds('done').includes(a) && listRootIds('done').includes(b),
  2000,
);
```

### D3) Bulk revive (Done → Running)

Manual UX action:

1. In “Done” view, on the **task doc row**, click **Revive all**.

Assertions:

```javascript
await window.__e2e__.waitUntil(
  () => !listRootIds('done').includes(a) && !listRootIds('done').includes(b),
  2000,
);
await window.__e2e__.waitUntil(
  () => listRootIds('running').includes(a) && listRootIds('running').includes(b),
  2000,
);
```

---

## Scenario E — Multi-client realtime sync (dialogs_moved broadcast)

Goal: validate that when **Client A** moves dialogs, **Client B** updates lists without refresh.

### E0) Setup two clients

- Open **Client A** and **Client B** to the WebUI (two tabs, or two browsers) connected to the same backend workspace.
- Ensure both clients are connected (connection indicator).

### E1) Move from Client A, observe Client B auto-updates

1. In Client A, mark `rootId` Done (or Archived).
2. In Client B, **do not refresh**.

Pass criteria:

- Within **5s**, Client B’s list membership matches the move (dialog appears in Done/Archived and disappears from Running).
- If Client B currently has `rootId` selected, Client B must transition to **read-only** (banner visible, input hidden) within **5s**.

If automation is available (two-page Playwright), implement this by waiting on Client B DOM for membership change.
If not, validate manually by direct observation.
