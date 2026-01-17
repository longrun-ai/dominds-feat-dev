#!/usr/bin/env markdown

# Dominds WebUI E2E: Team Management (team-mgmt toolset + Shadow Members) - For e2e-browser-tester Agent

You are the **tester agent**. Your job is to validate that Dominds supports:

- A dedicated **team-mgmt toolset** that is scoped strictly to `.minds/**`
- **Shadow/hidden teammates** (e.g. `@fuxi`, `@pangu`) that are selectable in **Create New Dialog**
- Correct **permissions separation**: `@pangu` must not be able to access `.minds/**` via general tools

This test validates Dominds infrastructure, not “LLM smartness”.

---

## Setup

### S0) Ensure `.minds/team.yaml` is absent (shadow bootstrap path)

This UX story assumes the rtws has **no team config**.

If it exists, remove it (rtws repo root):

```bash
rm -f .minds/team.yaml
```

### S1) Start Dominds

From repo root:

```bash
./dev-server.sh restart
```

### S2) Calibration gate: ensure E2E helpers are loaded

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

## T1) Verify `team-mgmt` appears in Tools panel

In browser console:

```javascript
clickToolsActivity();
const s0 = getToolsPanelState();
s0.refresh.click();
await window.__e2e__.waitUntil(() => getToolsPanelState().toolsets.length > 0, 5000);
const s1 = getToolsPanelState();
window.__e2e__.checkConsoleErrors({ clear: false, threshold: 0 });

const tm = s1.toolsets.find((x) => x.title.includes('team-mgmt'));
if (!tm) throw new Error(`Missing toolset 'team-mgmt'`);

const mustHave = [
  'team_mgmt_manual',
  'team_mgmt_list_dir',
  'team_mgmt_read_file',
  'team_mgmt_overwrite_file',
  'team_mgmt_patch_file',
  'team_mgmt_apply_patch',
  'team_mgmt_mkdir',
  'team_mgmt_move_path',
  'team_mgmt_rm_file',
  'team_mgmt_rm_dir',
];
for (const name of mustHave) {
  if (!tm.tools.includes(name)) throw new Error(`team-mgmt missing tool: ${name}`);
}
```

Pass criteria:

- Tools panel lists a toolset containing `team-mgmt` and the tools above.
- No new console errors.

---

## T2) Create dialog with shadow member `@fuxi` and exercise team-mgmt tools

### T2a) Create dialog

In browser console:

```javascript
await window.__e2e__.createDialog('tasks/ux-team-mgmt.tsk', '@fuxi');
await window.__e2e__.waitForInputEnabled();
```

### T2b) `team_mgmt_manual` + `.minds` scoping

Send in chat:

```text
@team_mgmt_manual !topics
```

Wait for completion:

```javascript
await window.__e2e__.waitUntil(() => window.__e2e__.noLingering(), 120000);
await window.__e2e__.waitForInputEnabled();
window.__e2e__.checkConsoleErrors({ clear: false, threshold: 0 });
```

Pass criteria:

- Tool call bubble shows `team_mgmt_manual` completed.
- Output mentions `.minds/` and `team.yaml` topics.

### T2c) File ops (must stay under `.minds/**`)

1. Overwrite a test file:

```text
@team_mgmt_overwrite_file .minds/team-mgmt-ws-e2e.txt
hello-1
```

2. Read it back:

```text
@team_mgmt_read_file .minds/team-mgmt-ws-e2e.txt
```

3. Patch it:

````text
@team_mgmt_patch_file .minds/team-mgmt-ws-e2e.txt
```diff
@@ -1,1 +1,1 @@
-hello-1
+hello-2
```
````

4. Confirm:

```text
@team_mgmt_read_file .minds/team-mgmt-ws-e2e.txt
```

5. Clean up:

```text
@team_mgmt_rm_file .minds/team-mgmt-ws-e2e.txt
```

Pass criteria:

- All tool calls complete.
- Readback shows `hello-2`.
- No console errors.

### T2d) Negative scope check: reject paths outside `.minds/**`

Send in chat (expected failure):

```text
@team_mgmt_read_file ../package.json
```

Pass criteria:

- Tool call fails with a clear “must be within `.minds/`” error.

---

## T3) Create dialog with shadow member `@pangu` and verify `.minds/**` is denied for general tools

### T3a) Create dialog

In browser console:

```javascript
await window.__e2e__.createDialog('tasks/ux-team-mgmt.tsk', '@pangu');
await window.__e2e__.waitForInputEnabled();
```

### T3b) Attempt to read `.minds/**` via general tools (expected denied)

Send in chat:

```text
@list_dir .minds
```

Pass criteria:

- Tool call is rejected/failed (access denied).
- No console errors.

---

## Teardown (clean workspace)

If any artifacts remain under `.minds/`, remove them using **team-mgmt tools** from `@fuxi`.

Suggested cleanup:

```text
@team_mgmt_rm_file .minds/team-mgmt-ws-e2e.txt
```
