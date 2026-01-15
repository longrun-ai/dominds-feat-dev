# Dominds WebUI E2E: Dialog Deletion (Root) + Multi-Client Sync

You are the **tester agent** standing in for a human user. Your job is to validate **dialog deletion** works reliably:

- Deleting a **root dialog** from **Done** or **Archived**
- Correct list membership updates (Running / Done / Archived)
- Correct selection clearing when the deleted dialog was selected
- **Multi-client realtime sync** (Client B updates without refresh)

Hard rules:

- **Assert infra, not prose**: pass/fail is based on list membership, selection state, and input enablement.
- **Time-bound UI transitions**: list membership must update within **2s** locally; multi-client updates within **5s**.
- **Check console errors after every action**.

---

## Setup

### S0) (Optional) Reset records for determinism

From repo root:

```bash
./clear-records.sh
./dev-server.sh restart
```

### S1) Create a dedicated task package

Note: the Create Dialog modal validates `*.tsk/` task packages.

```bash
mkdir -p tasks/ux-dlg-deletion.tsk
: > tasks/ux-dlg-deletion.tsk/goals.md
: > tasks/ux-dlg-deletion.tsk/constraints.md
: > tasks/ux-dlg-deletion.tsk/progress.md
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

## Helper snippets

### List membership (running/done/archived)

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
  const roots = Array.from(s.querySelectorAll('.dialog-item.root-dialog[data-root-id]'));
  return roots
    .map((n) => n.getAttribute('data-root-id') || '')
    .filter((x) => typeof x === 'string' && x.length > 0);
}
```

### Selection + input state

```javascript
function getSelectionAndInputState() {
  const snap = window.__e2e__.snapshotDomindsUI();
  return {
    hasRealDialog: snap.currentDialog?.hasRealDialog === true,
    currentRootId: snap.currentDialog?.dialogInfo?.rootId || null,
    textareaEnabled: snap.input?.textareaEnabled === true,
  };
}
```

---

## Scenario A — Done deletion (root)

### A1) Create one dialog

```javascript
window.__e2e__.checkConsoleErrors({ clear: true, threshold: 0 });

await window.__e2e__.createDialog('tasks/ux-dlg-deletion.tsk');
await window.__e2e__.waitForInputEnabled();

const rootId = window.__e2e__.snapshotDomindsUI().currentDialog?.dialogInfo?.rootId;
if (typeof rootId !== 'string' || !rootId) throw new Error('Missing current dialog rootId');
rootId;
```

### A2) Mark Done (Running → Done)

Manual UX action:

1. In “Running” list, click **Mark done** on `rootId`.

Assertions:

```javascript
await window.__e2e__.waitUntil(() => !listRootIds('running').includes(rootId), 2000);
await window.__e2e__.waitUntil(() => listRootIds('done').includes(rootId), 2000);
window.__e2e__.checkConsoleErrors({ clear: true, threshold: 0 });
```

### A3) Delete from Done (Done → deleted)

Manual UX action:

1. Switch to “Done”.
2. Click **Delete** on `rootId`.
3. Accept the confirmation dialog.

Assertions:

- Within **2s**, `rootId` is absent from Running/Done/Archived
- Current selection is cleared (no “real” dialog selected)
- Input is not usable (`textareaEnabled === false`)

```javascript
await window.__e2e__.waitUntil(() => !listRootIds('done').includes(rootId), 2000);
await window.__e2e__.waitUntil(() => !listRootIds('running').includes(rootId), 2000);
await window.__e2e__.waitUntil(() => !listRootIds('archived').includes(rootId), 2000);

await window.__e2e__.waitUntil(() => {
  const s = getSelectionAndInputState();
  return s.hasRealDialog === false && s.textareaEnabled === false;
}, 2000);

window.__e2e__.checkConsoleErrors({ clear: true, threshold: 0 });
```

---

## Scenario B — Multi-client sync for deletion

Goal: validate that when **Client A** deletes a dialog, **Client B** updates without refresh.

### B0) Setup two clients

- Open **Client A** and **Client B** to the WebUI (two tabs or two browsers) connected to the same backend workspace.
- Ensure both show “Connected”.

### B1) Create + archive + delete from Client A, observe Client B auto-updates

1. In Client A, create a dialog under `tasks/ux-dlg-deletion.tsk`.
2. In Client A, click **Archive** on the root row (Running → Archived).
3. In Client B, select the same dialog (so B has it selected).
4. In Client A (Archived list), click **Delete** on that root row and confirm.

Pass criteria (Client B):

- Within **5s**, the dialog disappears from Archived (and is absent from Running/Done).
- If Client B had that dialog selected, selection is cleared and input becomes non-usable.

(Automation note: deletion uses a browser confirm dialog; Playwright must accept it.)

