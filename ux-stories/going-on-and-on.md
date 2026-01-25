# Dominds WebUI E2E: Going On And On (Keep-Going) — Prevent Root Dialog Stopping

You are the **tester agent** standing in for a human operator. Your role is to validate that, when
keep-going is enabled, **dominds does not stop driving the root/main dialog** (becoming idle) unless
the dialog is legitimately suspended (Q4H or pending subdialogs).

Reference design doc: `dominds/docs/keep-going.md`

This UX story is intentionally built around **observable UI invariants**, not “agent prose quality”.

---

## The Test Purpose

This test validates the **keep-going runtime mechanism**:

- **Root/main dialog only**: keep-going must not trigger in subdialogs.
- **No override of legitimate suspension**: keep-going must not fire when the dialog is suspended
  (pending Q4H or pending subdialogs/backfill).
- **Trigger on any would-stop**: whenever the driver would otherwise stop the generation loop, it must
  auto-send a diligence prompt (as a normal user bubble) and continue.
- **Bounded**: bounded by `max-num-prompts` (default: **30**) before forcing a Q4H suspension.
- **Configurable per-rtws** via `.minds/diligence*.md` frontmatter (`max-num-prompts`), and can be
  **disabled** by an empty/whitespace file or `max-num-prompts < 1`.

---

## Tester Hardening Rules

- **Assert infra, not prose**: pass/fail is based on UI state (messages, Q4H, pending subdialogs), not
  whether the testee “sounds good”.
- **Time-bound UI transitions** (unless noted otherwise):
  - keep-going follow-up appears within **10s** after an assistant generation completes (when it would otherwise stop)
  - no “extra” follow-up should appear within **3s** for disabled/suspended cases
- **One retry only** for websocket lag; second failure = infra bug.
- **Check console errors after every scenario**.

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
mkdir -p ux-rtws/tasks/ux-keep-going.tsk
: > ux-rtws/tasks/ux-keep-going.tsk/goals.md
: > ux-rtws/tasks/ux-keep-going.tsk/constraints.md
: > ux-rtws/tasks/ux-keep-going.tsk/progress.md
```

### S2) Install a temporary diligence prompt (private to this UX story)

Keep-going reads diligence from the **rtws** (`process.cwd()` in the backend). For WebUI dev/UX runs,
`./dev-server.sh` uses `ux-rtws/` as the rtws, so the effective path is:

- `ux-rtws/.minds/diligence.md`
- `ux-rtws/.minds/team.yaml` (per-member cap `diligence-push-max`)

This story treats that file as **temporary and private**:

- If there is an existing `ux-rtws/.minds/diligence.md`, **back it up**.
- Write the story-specific content.
- During teardown, **delete** the story file and **restore** the backup (if any).

Run this in a terminal from repo root:

```bash
mkdir -p ux-rtws/.minds

export GOING_ON_AND_ON_DILIGENCE_BAK=""
if [ -f ux-rtws/.minds/diligence.md ]; then
  export GOING_ON_AND_ON_DILIGENCE_BAK="ux-rtws/.minds/diligence.md.bak.going-on-and-on.$(date +%s)"
  mv ux-rtws/.minds/diligence.md "$GOING_ON_AND_ON_DILIGENCE_BAK"
  echo "Backed up diligence to: $GOING_ON_AND_ON_DILIGENCE_BAK"
fi

cat > ux-rtws/.minds/diligence.md <<'EOF'
---
max-num-prompts: 3
---
You are being auto-continued by the dominds runtime (keep-going).

This prompt must be rendered in the chat timeline as an auto-sent user message bubble.
It contains a marker so the tester can detect the bubble:

DILIGENCE_AUTO_SENT

Now reply with EXACTLY this single line and nothing else (no tools):
KG_OK
EOF

# Also ensure @fuxi is allowed to receive keep-going pushes:
# Built-in shadow members fuxi/pangu default to diligence-push-max: 0 unless overridden.
export GOING_ON_AND_ON_TEAM_YAML_BAK=""
if [ -f ux-rtws/.minds/team.yaml ]; then
  export GOING_ON_AND_ON_TEAM_YAML_BAK="ux-rtws/.minds/team.yaml.bak.going-on-and-on.$(date +%s)"
  mv ux-rtws/.minds/team.yaml "$GOING_ON_AND_ON_TEAM_YAML_BAK"
  echo "Backed up team.yaml to: $GOING_ON_AND_ON_TEAM_YAML_BAK"
fi

cat > ux-rtws/.minds/team.yaml <<'EOF'
member_defaults:
  provider: codex
  model: gpt-5.2-codex

members:
  fuxi:
    diligence-push-max: 3
EOF
```

### S3) Calibration gate: ensure E2E helpers are loaded

Run in the browser DevTools console:

```javascript
async function localWaitUntil(fn, timeoutMs) {
  const deadline = Date.now() + timeoutMs;
  for (;;) {
    if (fn()) return;
    if (Date.now() >= deadline) throw new Error('waitUntil timeout');
    await new Promise((r) => setTimeout(r, 50));
  }
}

if (typeof window.__e2e__?.snapshotDomindsUI !== 'function') {
  const ts = String(Date.now());

  if (typeof window.__domObservation__ !== 'object') {
    const obs = document.createElement('script');
    obs.src = `/testing/dom-observation-utils.js?ts=${ts}`;
    document.head.appendChild(obs);
    await localWaitUntil(() => typeof window.__domObservation__ === 'object', 5000);
  }

  const helper = document.createElement('script');
  helper.src = `/testing/e2e-test-helper.js?ts=${ts}`;
  document.head.appendChild(helper);
  await localWaitUntil(() => typeof window.__e2e__?.snapshotDomindsUI === 'function', 5000);
}
```

Create a dialog:

```javascript
const {
  snapshotDomindsUI,
  waitUntil,
  createDialog,
  fillAndSend,
  waitForInputEnabled,
  checkConsoleErrors,
} = window.__e2e__;

checkConsoleErrors({ clear: true, threshold: 0 });

const baseline = await snapshotDomindsUI();
await createDialog('tasks/ux-keep-going.tsk', '@fuxi');
await waitForInputEnabled();

const snap = await snapshotDomindsUI();
if (!snap.currentDialog?.hasRealDialog) throw new Error('Expected a selected dialog');
```

---

## Helper Snippets (Message Search)

These use only stable helpers already used by other E2E stories in this repo.

```javascript
function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

function countVisibleToken(token) {
  const container =
    typeof window.__e2e__?.getDialogContainer === 'function'
      ? window.__e2e__.getDialogContainer()
      : document.querySelector('dominds-app')?.shadowRoot?.querySelector('#dialog-container');
  const text = container?.shadowRoot?.textContent || '';
  const escaped = token.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const matches = text.match(new RegExp(escaped, 'g'));
  return matches ? matches.length : 0;
}

function hasVisibleToken(token) {
  // Prefer e2e helper if present.
  if (typeof window.__e2e__?.findVisibleMessageContainingAll === 'function') {
    return !!window.__e2e__.findVisibleMessageContainingAll([token]);
  }
  // Fallback: plain DOM text scan (less strict, but good enough for token checks).
  const container =
    typeof window.__e2e__?.getDialogContainer === 'function'
      ? window.__e2e__.getDialogContainer()
      : document.querySelector('dominds-app')?.shadowRoot?.querySelector('#dialog-container');
  const text = container?.shadowRoot?.textContent || '';
  return text.includes(token);
}
```

---

## Scenario A — Root dialog: would-stop → keep-going auto-continues → Q4H appears

### A1) Ask the testee to emit a **normal** assistant response that would otherwise stop

Send this instruction to the testee (the exact token is to make assertions deterministic):

```javascript
checkConsoleErrors({ clear: true, threshold: 0 });

const msgId = await fillAndSend(
  'Keep-going test A1. Reply with EXACTLY this single line, and nothing else:\\n\\n' + 'KG_OK',
);
await waitForInputEnabled();
```

### A2) Assert: `max-num-prompts: 3` → 3 diligence injections → forced Q4H (budget exhausted)

This validates the new config:

- The diligence prompt is visible as an auto-sent user bubble.
- It is injected **3** times (because the diligence file frontmatter sets `max-num-prompts: 3`).
- Then the runtime forces a Q4H whose body includes `Keep-going budget exhausted (max 3)`.

```javascript
const beforeDiligence = countVisibleToken('DILIGENCE_AUTO_SENT');

await waitUntil(() => countVisibleToken('DILIGENCE_AUTO_SENT') === beforeDiligence + 3, 60000);

await waitUntil(() => (snapshotDomindsUI().q4h?.count ?? 0) >= 1, 60000);

await waitUntil(() => {
  const s = snapshotDomindsUI();
  const qs = s.q4h?.questions ?? [];
  return qs.some(
    (q) =>
      q.callBodyPreview.includes('Keep-going budget exhausted') &&
      q.callBodyPreview.includes('max 3'),
  );
}, 60000);

checkConsoleErrors({ clear: true, threshold: 0 });
```

**Fail conditions:**

- The assistant replies (you see the `KG_OK` message bubble) but:
  - `DILIGENCE_AUTO_SENT` does not increase by **3**, or
  - no Q4H appears, or
  - the Q4H body does not include `Keep-going budget exhausted (max 3)`
    within the timeout.
- Any new console errors appear during the scenario.

**Note (test validity):** If the testee adds any extra explanatory text in A1, re-run A1 with a stricter
instruction (“Reply only with KG_OK. No other text.”). Any extra content makes token-based assertions noisy.

---

## Scenario B — While Q4H is pending, keep-going must not continue

Keep-going must not override legitimate suspension states. After Scenario A, a Q4H is pending
(forced by budget exhaustion). While that Q4H is pending, no additional keep-going prompt injections
should occur.

### B2) Assert: no keep-going follow-up token while suspended

```javascript
// give the runtime a moment; keep-going should NOT fire during suspension
const beforeDiligence = countVisibleToken('DILIGENCE_AUTO_SENT');
const beforeResponse = countVisibleToken('KG_OK');
await sleep(500);
await sleep(3000);

if (countVisibleToken('DILIGENCE_AUTO_SENT') !== beforeDiligence) {
  throw new Error('Unexpected DILIGENCE_AUTO_SENT delta while dialog is suspended for Q4H');
}
if (countVisibleToken('KG_OK') !== beforeResponse) {
  throw new Error('Unexpected KG_OK delta while dialog is suspended for Q4H');
}

const after = await snapshotDomindsUI();
const q4hCount = after.q4h?.count ?? 0;
if (q4hCount < 1) throw new Error('Expected at least 1 pending Q4H');

checkConsoleErrors({ clear: true, threshold: 0 });
```

**Fail conditions:**

- Any keep-going marker/response appears while Q4H is pending.
- Q4H does not show up / does not suspend.

### B3) Disable keep-going before resuming (avoid loops after answering)

This prevents the dialog from immediately re-entering a keep-going loop once the Q4H is answered.

From repo root:

```bash
: > ux-rtws/.minds/diligence.md
```

### B4) Answer the Q4H (required interaction sequence)

To answer Q4H correctly, you must:

1. Select the pending question (so the input switches into Q4H answering mode).
2. Observe the selection took effect.
3. Only then send the answer.

```javascript
checkConsoleErrors({ clear: true, threshold: 0 });

const input = window.__e2e__.getInputArea();
if (!input) throw new Error('Missing dominds-q4h-input');
if (typeof input.getQuestions !== 'function') throw new Error('Input missing getQuestions()');
if (typeof input.selectQuestion !== 'function') throw new Error('Input missing selectQuestion()');
if (typeof input.getSelectedQuestionId !== 'function')
  throw new Error('Input missing getSelectedQuestionId()');

const qList = input.getQuestions();
if (!Array.isArray(qList) || qList.length < 1)
  throw new Error('Expected input.getQuestions() to return >= 1 question');

const dlgInfo = window.__e2e__.getCurrentDialogInfo();
if (!dlgInfo) throw new Error('Missing current dialog info');

const q = qList.find(
  (qq) =>
    qq &&
    typeof qq.id === 'string' &&
    qq.dialogContext?.selfId === dlgInfo.selfId &&
    qq.dialogContext?.rootId === dlgInfo.rootId,
);
if (!q) throw new Error('Could not find a Q4H question matching the current dialog');
if (typeof q?.id !== 'string' || q.id.trim() === '') throw new Error('Missing Q4H question id');

input.selectQuestion(q.id);
await waitUntil(() => input.getSelectedQuestionId() === q.id, 2000);

// Secondary UI-mode check: the input wrapper should be in q4h-active mode.
const inputShadow = input?.shadowRoot;
const wrapper = inputShadow?.querySelector('.input-wrapper');
if (!(wrapper instanceof HTMLElement)) throw new Error('Missing .input-wrapper');
if (!wrapper.classList.contains('q4h-active'))
  throw new Error('Expected .input-wrapper to have q4h-active class');

await window.__e2e__.answerQ4H('yes');
await waitUntil(() => (window.__e2e__.snapshotDomindsUI().q4h?.count ?? 0) === 0, 15000);

checkConsoleErrors({ clear: true, threshold: 0 });
```

---

## Scenario C — Disable switch: empty diligence file disables keep-going

If the resolved diligence file exists but is empty/whitespace, keep-going must be disabled for that
workspace.

**Note:** If you are running Scenario C standalone (without Scenario B3), disable keep-going first:

```bash
: > ux-rtws/.minds/diligence.md
```

### C1) Repeat a tool-only root scenario; assert there is NO follow-up token

```javascript
checkConsoleErrors({ clear: true, threshold: 0 });

const pre = await snapshotDomindsUI();
const preCount = pre.chat?.visibleMessageCount ?? 0;

const msgId = await fillAndSend(
  'Keep-going test C1 (disabled). Reply with ONLY this single function tool call; no other text: ' +
    'add_reminder({\"content\":\"kg-c1 reminder (keep-going disabled; should not auto-continue)\"})',
);
await waitForInputEnabled();

// Wait a short window to ensure no hidden auto-continue happens.
const beforeDiligence = countVisibleToken('DILIGENCE_AUTO_SENT');
const beforeResponse = countVisibleToken('KG_OK');
await sleep(3000);

if (countVisibleToken('DILIGENCE_AUTO_SENT') !== beforeDiligence) {
  throw new Error('Unexpected DILIGENCE_AUTO_SENT delta (keep-going should be disabled)');
}
if (countVisibleToken('KG_OK') !== beforeResponse) {
  throw new Error('Unexpected KG_OK delta (keep-going should be disabled)');
}

const post = await snapshotDomindsUI();
const postCount = post.chat?.visibleMessageCount ?? 0;
if (postCount <= preCount) throw new Error('Expected at least one new visible message bubble');

checkConsoleErrors({ clear: true, threshold: 0 });
```

**Pass intuition:** you should see the tool call and its response bubble, then the dialog returns idle
with **no** extra follow-up from the agent.

---

## Optional Extensions (When You Need Deeper Coverage)

These are not required for a basic regression pass, but they map directly to `dominds/docs/keep-going.md`.

**Important:** Run these extensions _before_ Scenario B3 / Scenario C (which disable keep-going),
or re-enable keep-going by restoring the diligence file created in Setup S2.

### Extension D — Subdialog must not auto-continue

1. Create a subdialog (e.g., ask the testee to call a teammate).
2. Navigate into the subdialog and repeat Extension E’s “tool-only output” step.
3. Even with a non-empty diligence file, **no** `DILIGENCE_AUTO_SENT` / `KG_OK` should appear inside the subdialog.

### Extension E — Tool-only output still triggers keep-going (silent-stop regression)

This reproduces the original “silent-stop” shape where the assistant output is only a function tool call.

Run with the same diligence file from Setup S2 (`max-num-prompts: 3`, diligence instructs `KG_OK`).

1. Ask the testee to reply with ONLY this tool call (no other text):

   ```text
   Call the function tool `add_reminder` with:
   { "content": "kg-e1 reminder (tool-only output)" }
   ```

2. Assert you see:
   - the tool call response, then
   - `DILIGENCE_AUTO_SENT` increases by **3**, then
   - a Q4H appears whose body includes `Keep-going budget exhausted (max 3)`.

---

## Teardown / Cleanup (Recommended)

This story intentionally creates reminders and may leave a pending Q4H. For a clean workspace before
running other E2E stories, prefer hard reset:

```bash
./ux-rtws/clear-records.sh
./dev-server.sh restart
```

If you want to keep the dialog, at minimum:

- Answer the Q4H created in Scenario B (e.g. reply `yes`) so the root dialog is no longer suspended.
- Delete the reminders created in Scenarios A/C (via `delete_reminder({\"reminder_no\": <n>})`), or accept reminder
  state drift for subsequent tests.

### Cleanup the temporary diligence file (required for story isolation)

Run in a terminal from repo root:

```bash
rm -f ux-rtws/.minds/diligence.md

if [ -n "${GOING_ON_AND_ON_DILIGENCE_BAK:-}" ] && [ -f "$GOING_ON_AND_ON_DILIGENCE_BAK" ]; then
  mv "$GOING_ON_AND_ON_DILIGENCE_BAK" ux-rtws/.minds/diligence.md
  echo "Restored diligence from: $GOING_ON_AND_ON_DILIGENCE_BAK"
fi

unset GOING_ON_AND_ON_DILIGENCE_BAK

rm -f ux-rtws/.minds/team.yaml

if [ -n "${GOING_ON_AND_ON_TEAM_YAML_BAK:-}" ] && [ -f "$GOING_ON_AND_ON_TEAM_YAML_BAK" ]; then
  mv "$GOING_ON_AND_ON_TEAM_YAML_BAK" ux-rtws/.minds/team.yaml
  echo "Restored team.yaml from: $GOING_ON_AND_ON_TEAM_YAML_BAK"
fi

unset GOING_ON_AND_ON_TEAM_YAML_BAK
```
