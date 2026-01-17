#!/usr/bin/env markdown

# Dominds WebUI E2E: Context Health Monitor (token usage + reminder owner) - For e2e-browser-tester Agent

You are the **tester agent**. Your job is to validate that Dominds supports:

- Persisted per-generation **token usage / context health** snapshots
- A small, always-visible **context usage** pill in the dialog toolbar
- A `ReminderOwner`-backed **context_health** reminder that triggers once, updates, and clears
- “Unknown usage” handling when a provider reports usage unavailable

This test validates Dominds infrastructure, not “LLM smartness”.

---

## Setup (Mock provider for determinism)

### S0) Write `.minds/team.yaml` to force provider/model

Repo root:

```bash
mkdir -p .minds
cat > .minds/team.yaml <<'YAML'
member_defaults:
  provider: mock
  model: context-health-e2e
default_responder: pangu
members: {}
YAML
```

### S1) Write `.minds/llm.yaml` with a `mock` provider + small model limits

Repo root:

```bash
cat > .minds/llm.yaml <<'YAML'
providers:
  mock:
    name: Mock (E2E)
    apiType: mock
    baseUrl: ux-stories/fixtures/mock-llm
    apiKeyEnvVar: MOCK_LLM_KEY
    models:
      context-health-e2e:
        name: Context Health E2E
        context_length: 4000
        input_length: 4000
        output_length: 256
        optimal_max_tokens: 1800
YAML
```

### S2) Start Dominds

From repo root:

```bash
./dev-server.sh restart
```

### S3) Calibration gate: ensure E2E helpers are loaded

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

## Helper snippets (Context health + reminders)

```javascript
function getAppShadow() {
  const s = window.__e2e__?.getAppShadow?.();
  if (!s) throw new Error('Missing dominds-app shadow root');
  return s;
}

function getContextHealthPill() {
  const s = getAppShadow();
  const el = s.querySelector('#toolbar-context-health');
  if (!(el instanceof HTMLElement)) throw new Error('Missing #toolbar-context-health');
  return el;
}

function getReminderCount() {
  const s = getAppShadow();
  const e2e = window.__e2e__;
  if (e2e && typeof e2e.getRemindersCount === 'function') return e2e.getRemindersCount();
  const el = s.querySelector('#toolbar-reminders-toggle span');
  if (!(el instanceof HTMLElement)) throw new Error('Missing reminders count span');
  return Number((el.textContent || '0').trim() || '0');
}

async function waitForContextHealthLevel(expectedLevels, timeoutMs = 10000) {
  const levels = Array.isArray(expectedLevels) ? expectedLevels : [expectedLevels];
  await window.__e2e__.waitUntil(() => {
    const pill = getContextHealthPill();
    const level = pill.getAttribute('data-level');
    return typeof level === 'string' && levels.includes(level);
  }, timeoutMs);
}

async function waitForContextHealthTitleNonEmpty(timeoutMs = 10000) {
  await window.__e2e__.waitUntil(() => {
    const pill = getContextHealthPill();
    const title = String(pill.getAttribute('title') || '').trim();
    return title.length > 0;
  }, timeoutMs);
}
```

---

## T0) Create a new dialog

In browser console:

```javascript
await window.__e2e__.createDialog('tasks/ux-context-health.tsk', '@pangu');
await window.__e2e__.waitForInputEnabled();
```

Pass criteria:

- Dialog opens with input enabled.
- No new console errors.

---

## T1) High usage → indicator updates + reminder appears (once)

1. Send in chat:

```text
hi-high
```

2. Wait for completion:

```javascript
await window.__e2e__.waitUntil(() => window.__e2e__.noLingering(), 120000);
await window.__e2e__.waitForInputEnabled();
await waitForContextHealthLevel(['caution', 'critical'], 10000);
await window.__e2e__.waitUntil(() => getReminderCount() >= 1, 10000);
window.__e2e__.checkConsoleErrors({ clear: false, threshold: 0 });
```

3. Validate indicator + reminder:

```javascript
const pill = getContextHealthPill();
const level = pill.getAttribute('data-level');
const title = String(pill.getAttribute('title') || '');
if (level !== 'caution' && level !== 'critical')
  throw new Error(`Expected caution/critical, got: ${level}`);
if (!title.includes('%')) throw new Error(`Expected pill title to include percent, got: ${title}`);
if (!(pill.querySelector('svg') instanceof SVGElement))
  throw new Error('Expected pill to contain an SVG pie-chart icon');

const rem1 = getReminderCount();
if (rem1 < 1) throw new Error(`Expected at least 1 reminder, got: ${rem1}`);
```

Pass criteria:

- `#toolbar-context-health` shows `data-level` of `caution` or `critical`.
- Reminders count increases (context health reminder added).
- No new console errors.

---

## T2) Repeat high usage → no reminder spam

In browser console:

```javascript
const before = getReminderCount();
```

Send in chat:

```text
hi-high
```

Wait and validate:

```javascript
await window.__e2e__.waitUntil(() => window.__e2e__.noLingering(), 120000);
await window.__e2e__.waitForInputEnabled();
await waitForContextHealthLevel(['caution', 'critical'], 10000);
await window.__e2e__.waitUntilReminderStable(5000);

const after = getReminderCount();
if (after !== before)
  throw new Error(`Reminder count changed unexpectedly: before=${before} after=${after}`);
```

Pass criteria:

- Reminders count does not grow unbounded (owned reminder behavior).

---

## T3) Low usage → reminder auto-clears

Send in chat:

```text
ok-low
```

Wait and validate:

```javascript
await window.__e2e__.waitUntil(() => window.__e2e__.noLingering(), 120000);
await window.__e2e__.waitForInputEnabled();
await window.__e2e__.waitUntil(() => getReminderCount() === 0, 10000);
window.__e2e__.checkConsoleErrors({ clear: false, threshold: 0 });

const pill = getContextHealthPill();
const level = pill.getAttribute('data-level');
if (level !== 'healthy' && level !== 'unknown')
  throw new Error(`Unexpected data-level after ok-low: ${level}`);

const rem3 = getReminderCount();
if (rem3 !== 0) throw new Error(`Expected reminder to clear to 0, got: ${rem3}`);
```

Pass criteria:

- Reminders count returns to `0` (context health reminder dropped).

---

## T4) Usage unavailable → indicator shows “unknown”

Send in chat:

```text
hi-unknown
```

Wait and validate:

```javascript
await window.__e2e__.waitUntil(() => window.__e2e__.noLingering(), 120000);
await window.__e2e__.waitForInputEnabled();
await waitForContextHealthLevel('unknown', 10000);
await waitForContextHealthTitleNonEmpty(10000);

const pill = getContextHealthPill();
const level = pill.getAttribute('data-level');
const title = String(pill.getAttribute('title') || '');
if (level !== 'unknown') throw new Error(`Expected unknown, got: ${level}`);
if (title.includes('%'))
  throw new Error(`Expected unknown title to not include percent, got: ${title}`);
```

Pass criteria:

- Context health indicator uses the “unknown” state for that generation.

---

## Cleanup

Repo root:

```bash
rm -f .minds/team.yaml .minds/llm.yaml
```
