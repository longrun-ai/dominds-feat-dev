# Dominds WebUI E2E: Dialog Stop / Resume (Per-dlg + Global Operator Controls)

You are the **tester agent** standing in for a human operator. Your role is to validate that **dominds** provides flawless **interruption & resumption infrastructure**:

- **Per-dlg Stop** (primary input action toggles `Send ↔ Stop`)
- **Per-dlg Continue** (resume an interrupted dlg from within the dlg history)
- **Global Emergency stop** (interrupt all proceeding dlgs)
- **Global Resume all** (resume all eligible interrupted dlgs)
- **Multi-client realtime sync** (other tab/browser sees stop/resume state quickly)

This UX story is intended to be **re-used for regression detection**. Prefer **observable UI invariants** (counts, button states, visible panels, no console errors) over “agent prose quality”.

Reference design doc: `dominds/docs/interruption-resumption.md`

## The Test Purpose

This test validates **dominds dialog run-control infrastructure**, not the testee agent’s reasoning quality.

- The testee should cooperate with your directions to create long-running “proceeding” states (large streaming responses).
- Pass/fail is based on: button availability, state transitions, resume affordances, counts, and cross-client sync.

## Business Goal

Enable long-run operators to safely manage runaway output / stalled sessions:

- Stop a dlg immediately when needed (no hunting for controls)
- See which dlgs are proceeding vs resumable at a glance (global counts)
- Recover after accidental stop or backend restart (Continue / Resume all)
- Avoid multi-tab desync (state converges quickly)

## Tester Hardening Rules

- **Assert infra, not prose:** Never grade on response content quality.
- **Time-bound UI transitions:** unless noted otherwise:
  - Local UI updates within **2s**
  - Cross-client updates within **5s**
- **One retry only** for suspected websocket lag; second failure = infra bug.
- **Check console errors after every action:** any new errors after a step = fail (unless explicitly allowed).
- **Avoid long tool calls** (e.g. `shell_cmd` with `sleep`) while testing Stop: current tooling does not reliably abort long-running OS processes mid-call.

---

## Standardized Observation Pattern

Before and after every user-visible action:

1. `SNAP`: `const snap = window.__e2e__.snapshotDomindsUI()`
2. `DELTA`: `snap.reportDeltaTo(prev)` (keep a `prev` snapshot across steps)
3. `VERIFY`: assert invariants (input enabled, buttons enabled/disabled, resume panel visibility)
4. `ACT`: click or send
5. `WAIT`: `waitUntil` on the expected state change
6. `EVIDENCE`: record key deltas + key readouts

---

## Essential Helper Reference

| Helper                    | Purpose                                      |
| ------------------------- | -------------------------------------------- |
| `snapshotDomindsUI()`     | Observe UI state (delta-based)               |
| `waitUntil(fn, ms)`       | Poll until condition is true                 |
| `createDialog(taskDoc)`   | Create a new dialog via UI                   |
| `fillAndSend(text)`       | Send a message to current dialog             |
| `waitForInputEnabled()`   | Wait until input is usable                   |
| `waitForDialogIdle(opts)` | Wait until UI is “idle” (stable interaction) |
| `checkConsoleErrors()`    | Fail test when UI logs errors                |
| `getCurrentDialogInfo()`  | Read current `rootId`/`selfId`               |
| `getDialogContainer()`    | Get `<dominds-dialog-container>` element     |
| `getInputArea()`          | Get `<dominds-q4h-input>` element            |
| `getAppShadow()`          | Access `dominds-app` shadow DOM              |

---

## Helper Snippets (Run Controls + Resume Panel)

These are intentionally **small** and use stable selectors/ids.

```javascript
function getHeaderRunControls() {
  const shadow = window.__e2e__.getAppShadow();
  if (!shadow) throw new Error('Missing dominds-app shadow root');

  const stopBtn = shadow.querySelector('#toolbar-emergency-stop');
  const resumeAllBtn = shadow.querySelector('#toolbar-resume-all');

  if (!(stopBtn instanceof HTMLButtonElement))
    throw new Error('Missing #toolbar-emergency-stop button');
  if (!(resumeAllBtn instanceof HTMLButtonElement))
    throw new Error('Missing #toolbar-resume-all button');

  const stopCount = stopBtn.querySelector('span')?.textContent?.trim() || '';
  const resumeCount = resumeAllBtn.querySelector('span')?.textContent?.trim() || '';

  return {
    emergencyStop: {
      disabled: stopBtn.disabled,
      count: Number.parseInt(stopCount, 10) || 0,
    },
    resumeAll: {
      disabled: resumeAllBtn.disabled,
      count: Number.parseInt(resumeCount, 10) || 0,
    },
  };
}

function getPrimaryActionState() {
  const input = window.__e2e__.getInputArea();
  const s = input?.shadowRoot;
  if (!s) throw new Error('Missing dominds-q4h-input shadow root');

  const btn = s.querySelector('.send-button');
  if (!(btn instanceof HTMLButtonElement)) throw new Error('Missing .send-button');

  const title = btn.getAttribute('title') || '';
  const className = btn.className || '';

  return {
    disabled: btn.disabled,
    title,
    className,
    // Heuristic “mode” detection for assertions.
    mode: className.includes('stop')
      ? 'stop'
      : title.toLowerCase().includes('stop')
        ? 'stop'
        : title.toLowerCase().includes('stopping')
          ? 'stopping'
          : 'send',
  };
}

function getResumePanelState() {
  const host = window.__e2e__.getDialogContainer();
  const s = host?.shadowRoot;
  if (!s) throw new Error('Missing dominds-dialog-container shadow root');

  const panel = s.querySelector('#resume-panel');
  const btn = s.querySelector('#resume-btn');
  const reason = s.querySelector('#resume-reason');

  if (!(panel instanceof HTMLElement)) throw new Error('Missing #resume-panel');
  if (!(btn instanceof HTMLButtonElement)) throw new Error('Missing #resume-btn');

  return {
    visible: !panel.classList.contains('hidden'),
    btnDisabled: btn.disabled,
    reasonText: (reason?.textContent || '').trim(),
  };
}

function expectedReasonText(kind /* 'user_stop' | 'emergency_stop' | 'server_restart' */) {
  const lang = localStorage.getItem('dominds-ui-language') || 'en';
  if (lang === 'zh') {
    if (kind === 'user_stop') return '已由你停止';
    if (kind === 'emergency_stop') return '已被紧急停止终止';
    if (kind === 'server_restart') return '因服务器重启而中断';
  }
  if (kind === 'user_stop') return 'Stopped by you';
  if (kind === 'emergency_stop') return 'Stopped by emergency stop';
  if (kind === 'server_restart') return 'Interrupted by server restart';
  throw new Error(`Unknown kind: ${String(kind)}`);
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

Use a stable path:

```bash
mkdir -p tasks/ux-dlg-stop-resume.tsk
: > tasks/ux-dlg-stop-resume.tsk/goals.md
: > tasks/ux-dlg-stop-resume.tsk/constraints.md
: > tasks/ux-dlg-stop-resume.tsk/progress.md
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

### S3) Create a new dialog and confirm baseline UI health

```javascript
window.__e2e__.checkConsoleErrors({ clear: true, threshold: 0 });

await window.__e2e__.createDialog('tasks/ux-dlg-stop-resume.tsk');
await window.__e2e__.waitForInputEnabled();
await window.__e2e__.waitForDialogIdle();

const baseline = window.__e2e__.snapshotDomindsUI();
const header = getHeaderRunControls();

if (!baseline.currentDialog?.hasRealDialog) throw new Error('Expected a selected dialog');
if (header.emergencyStop.count !== 0) throw new Error('Expected proceeding count = 0');
if (header.resumeAll.count !== 0) throw new Error('Expected resumable count = 0');

baseline;
```

---

## Calibration Gate (Required)

Goal: ensure the testee can reliably create a “proceeding” state without tool calls.

**Prompt to send (in the dialog):**

```
Calibration: For the next step, you will produce a very long response (at least 300 lines). Do NOT call any tools. You will keep writing until I click Stop.
Reply with exactly: "ACK"
```

**Pass criteria:** The testee replies exactly `ACK`.

If it fails: repeat once with a stricter prompt. If it still fails, record as testee non-cooperation and stop the run (not an infra bug).

---

## Scenario A — Per-dlg Stop while proceeding

### A1) Start a deliberately long streaming response

**Prompt to send:**

```
Write a numbered list from 1 to 500 (one number per line). No tools. No headings. Start now.
```

Assertions (within 2s of send):

- Primary action enters **Stop mode** (`Send ↔ Stop`)
- Input becomes disabled (can’t send new messages mid-proceeding)
- Header proceeding count becomes **≥ 1**

```javascript
const prev = baseline;
const msgId = await window.__e2e__.fillAndSend(
  'Write a numbered list from 1 to 500 (one number per line). No tools. No headings. Start now.',
);

await window.__e2e__.waitUntil(() => getPrimaryActionState().mode === 'stop', 2000);
await window.__e2e__.waitUntil(() => getHeaderRunControls().emergencyStop.count >= 1, 2000);
window.__e2e__.checkConsoleErrors({ clear: true, threshold: 0 });
msgId;
```

### A2) Click Stop mid-stream

Manual UX action:

1. While output is still streaming, click the primary **Stop** button in the input area.

Assertions:

- Primary action quickly enters **Stopping…** / stop-requested mode (button disabled)
- Within **5s**, the dlg transitions to **Interrupted (resumable)**, evidenced by:
- Resume panel becomes visible
- Resume reason matches the current UI language (see `expectedReasonText('user_stop')`)
- Header counts converge:
  - Proceeding count decreases
  - Resumable count increases (≥ 1)

```javascript
// Human click Stop now, then:
await window.__e2e__.waitUntil(() => {
  const s = getPrimaryActionState();
  return s.disabled === true; // stop requested disables the button
}, 2000);

await window.__e2e__.waitUntil(() => {
  const r = getResumePanelState();
  return r.visible === true && r.reasonText === expectedReasonText('user_stop');
}, 5000);

await window.__e2e__.waitUntil(() => getHeaderRunControls().resumeAll.count >= 1, 5000);
window.__e2e__.checkConsoleErrors({ clear: true, threshold: 0 });
```

---

## Scenario B — Per-dlg Continue (resume an interrupted dlg)

### B1) Click Continue and verify the dlg resumes

Manual UX action:

1. In the dialog history area, click **Continue** (resume panel).

Assertions:

- Resume panel hides within **2s**
- Header resumable count decreases (typically to 0 for a single dlg)
- UI eventually becomes idle again (input enabled, no lingering generation)

```javascript
// Human click Continue now, then:
await window.__e2e__.waitUntil(() => getResumePanelState().visible === false, 2000);

// Resume count should decrease eventually; allow more time if the dlg re-enters proceeding.
await window.__e2e__.waitUntil(() => getHeaderRunControls().resumeAll.count === 0, 15000);

await window.__e2e__.waitForDialogIdle({
  timeoutMs: 60000,
  requireInputEnabled: true,
});
window.__e2e__.checkConsoleErrors({ clear: true, threshold: 0 });
```

---

## Scenario C — Stop idempotency / double-stop safety

Goal: clicking Stop twice should not cause errors or weird toggles.

Steps:

1. Start a long streaming response again (same prompt as Scenario A).
2. Click Stop once.
3. Immediately click Stop again (or spam click).

Pass criteria:

- No console errors
- Stop button stays disabled in stop-requested mode
- Dlg ends in interrupted state with resume panel visible

---

## Scenario D — Global Emergency stop affects multiple dialogs (multi-client)

This scenario is the most important regression surface: it validates **backend-wide** stop and **multi-client broadcast**.

### D0) Setup two clients (Client A + Client B)

- Open **Client A** and **Client B** to the WebUI (two tabs or two browsers).
- Ensure both show connected status.
- Create **two dialogs** (one per client) under `tasks/ux-dlg-stop-resume.tsk`.

Record IDs for evidence:

```javascript
window.__e2e__.getCurrentDialogInfo();
```

### D1) Put both dialogs into proceeding state

In **each** client, send the long-output prompt from Scenario A.

Pass criteria (per client):

- Per-dlg primary action switches to Stop
- Header proceeding count becomes **≥ 1** (and should reach **2** once both are proceeding)

### D2) Trigger Emergency stop (from Client A)

Manual UX action:

1. In Client A header (top bar), click **Emergency stop** (the pill immediately left of connection status).
2. Accept the confirmation prompt.

Pass criteria:

- Within **5s**, both clients:
  - show **resumable** state in each affected dialog (resume panel visible)
  - show resume reason matching UI language (`expectedReasonText('emergency_stop')`)
- Header proceeding count goes to **0**
- Header resumable count becomes **2** (or the number of dialogs you had proceeding)

If the count is correct but one dialog does not become resumable, treat as infra bug (partial interrupt).

---

## Scenario E — Global Resume all resumes eligible dialogs

Precondition: you have ≥ 2 interrupted/resumable dialogs from Scenario D.

### E1) Click Resume all

Manual UX action:

1. In either client header, click **Resume all**.

Pass criteria:

- Resumable count decreases to **0** within **15s**
- Each interrupted dialog’s resume panel hides (it should resume proceeding briefly, then become idle)
- No console errors in either client

---

## Scenario F — Button gating & placement regression checks

These checks are meant to catch UI regressions early (layout + affordance).

### F1) Placement

Verify visually:

- **Emergency stop** and **Resume all** appear in the **top header**, immediately to the **left of connection status**.
- They have **pill-like styling** consistent with the connection indicator (compact, rounded, “badge/pill” feel).

### F2) Disabled states

With no proceeding dialogs:

- Emergency stop is disabled (`disabled === true`)

With no resumable dialogs:

- Resume all is disabled (`disabled === true`)

```javascript
getHeaderRunControls();
```

---

## (Optional) Scenario G — Server restart interruption reason

This validates the “Interrupted by server restart” path.

1. Start a long streaming response (dlg is proceeding).
2. Restart backend while it’s proceeding:

```bash
./dev-server.sh restart
```

Pass criteria:

- Connection status indicates reconnecting then connected.
- The dlg ends as interrupted with resume reason **“Interrupted by server restart”**.
- The dlg ends as interrupted with resume reason matching UI language (`expectedReasonText('server_restart')`).
- Resume all count becomes ≥ 1.

---

## Regression Evidence Bundle (What to record)

For each scenario, capture:

- `snap.reportDeltaTo(prev)` before/after
- `getHeaderRunControls()`
- `getPrimaryActionState()`
- `getResumePanelState()`
- `checkConsoleErrors()` output (must be empty)

When filing a bug, include:

- Which scenario + step (e.g. “Scenario D2”)
- Exact observed vs expected counts (proceeding/resumable)
- Whether the confirmation prompt appeared for emergency stop
- Any websocket disconnect/reconnect signs
- Console error stack traces (if any)
