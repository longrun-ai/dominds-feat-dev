# Dominds WebUI E2E: Dialog Round Control (@clear_mind) + Task Doc Update (@change_mind)

You are the **tester agent** standing in for a human user. Your role is to validate that **dominds** provides flawless dialog round control infrastructure for mental clarity operations. The testee should **cooperate** with your directions to help validate dominds features.

## The Test Purpose

This test validates **dominds dialog round control infrastructure**, not the testee agent's performance.

- The testee is a reasonable LLM-powered AI agent. It should **cooperate with your instructions** to exercise dominds features, but may still make mistakes, miss tool calls, or deviate (as all LLMs do)
- **Dominds must work flawlessly** regardless of testee behavior - providing reliable round reset, Q4H clearing, reminder persistence, and new-round prompt scheduling
- Your job: verify dominds enables you to nudge, correct, and guide the testee toward using round control correctly and consistently

## Business Goal

Enable **autonomous mind clearing** during long-run work (days → months): after information is distilled into the task doc, reminders, and agent memory, the agent can discard noisy dialog/tool-call history without losing durable context.

Dominds must support:

- `@clear_mind`: reset the dialog + optionally add a reminder
- `@change_mind`: overwrite the task doc (or `*.tsk/` section) with **no round reset**
- Follow-up coroutine prompt: appears as the **first visible message** in the new round (target UX: first user message), with **no backfeeding** from the tool call itself
- One-round timeline: UI shows **only one round at a time** (round transitions clear `#dialog-container` then refill)

## Your Tester Agent Principles

1. **Test dominds, not the testee** - The testee should cooperate; if it errs, verify dominds infrastructure handles it
2. **Observe like a human** - Don't poll, don't guess; look at what the UI shows and reason about it
3. **Diagnose before acting** - Check console errors, then verify tool calls and round transitions
4. **Fail fast** - Detect infrastructure issues immediately; testee errors are expected

---

## Tester Hardening Rules

- **Assert infra, not prose** - Pass/fail must be based on UI state + round transition evidence, not the testee’s summary.
- **Time-bound every step** - If the round reset or follow-up coroutine does not manifest within the allowed timeout, treat as infra failure.
- **One retry for infra gaps only** - If no tool call or no new-round prompt appears, retry once with an explicit tool call request and move on.
- **Compliance nudges are separate** - If the testee responds but does not fully comply (formatting, missing reminder, wrong tool), use the _Compliance Nudge Loop_ below (up to 3 nudges).
- **Check console errors after every action** - Catch silent UI/protocol breakage early.
- **Snapshot like a human** - Before and after every step, take a `snapshotDomindsUI()` and log `reportDeltaTo()` against the prior snapshot so you notice subtle UI regressions.
- **Control noise** - Keep prompts short and enforce “one tool call only”.
- **Run the calibration gate first** - Do not proceed with test scenarios unless the testee restates the setup correctly.

---

## Standardized Observation Pattern

All tests follow this pattern. Treat **delta logs** as part of the test evidence.

```javascript
// 0. PREV - keep the last snapshot across steps (human-like continuity)
// Keep this local to your scripted run (no globals).
// Set this once after dialog creation, then update it at the end of every step.
let prev = baseline;

// 1. SNAP - capture current UI state (before action)
const snap = await snapshotDomindsUI();

// 2. DELTA - compare with previous state (returns string for display)
const deltaFromPrev = snap.reportDeltaTo(prev);
// IMPORTANT: Do NOT console.log deltas; record them in local variables and surface them
// in the tester agent's tool result (e.g., return them from the current MCP evaluate block).

// 3. VERIFY - check key assertions
const state = {
  inputEnabled: snap.input?.textareaEnabled,
  hasDialog: snap.currentDialog?.hasRealDialog,
  messageCount: snap.chat?.messageCount,
  visibleMessageCount: snap.chat?.visibleMessageCount,
  pendingCalls: snap.chat?.pendingTeammateCalls,
  visibleSidebar: snap.sidebar?.visibleNodeTitles,
  visibleTimelinePreview: (snap.chat?.visibleMessages || []).slice(0, 3),
};

// 4. ACT - send prompt or click
const msgId = await fillAndSend('your prompt here');

// 5. WAIT - wait for tool call completion and follow-up round
await waitForPendingTeammateCalls();
await waitForInputEnabled();
const post = await snapshotDomindsUI();
const postDelta = post.reportDeltaTo(snap);
// Surface postDelta in the tool result, not browser logs.

// 6. COMMIT - carry continuity into the next step
prev = post;

// 7. EVIDENCE - return these from your MCP evaluate block for the tester agent to inspect
// (e.g. `{ deltaFromPrev, postDelta, state }`).
```

**Per-step UI observations to capture:**

- Sidebar visible nodes from `snap.sidebar.visibleNodeTitles` (prefixed with `Task:`/`Dialog:`/`Subdialog:`)
- Sidebar selection from `snap.sidebar.selectedDialogTitle`
- Pending teammate calls from `snap.chat.pendingTeammateCalls`
- Input enabled state from `snap.input.textareaEnabled`
- Visible message count from `snap.chat.visibleMessageCount`
- Visible chat timeline from `snap.chat.visibleMessages`
- The pre/post deltas (`deltaFromPrev`, `postDelta`) captured as returned tool evidence (not console logs)

---

## Generation Completion Rule (Round Reset Specific)

Round control tools can interrupt/replace the current chat timeline, so treat “stream completion”
as **round + prompt stabilization**, not just the last assistant bubble finishing.

For every `@clear_mind` step:

1. **Tool bubble must appear at least once**: `await waitUntil(() => detectToolCall('clear_mind').hasToolCall, 15000)`
2. **Round must change** (toolbar `#round-nav` text changes): wait up to **20s**, extend to **120s** only if `noLingering()` is false
3. **New-round prompt must appear** in the chat as the **first visible message**

   Note: In the current WebUI, `snapshotDomindsUI()` reports `.generation-bubble` nodes as `type: 'assistant'`
   in `chat.visibleMessages` (even when they contain the new-round prompt). For infra validation, treat
   “first visible message” (index `0`) as the requirement until user-bubble rendering is implemented.

4. **Input must return enabled** after the follow-up coroutine finishes (`await waitForInputEnabled()`)

If any of these fail → infrastructure failure (unless explicitly marked as “testee non-compliance”).

---

### Standardized Variable Names

| Variable   | Purpose                              |
| ---------- | ------------------------------------ |
| `baseline` | Initial state before any actions     |
| `snap`     | Pre-action state snapshot            |
| `post`     | Post-action state snapshot           |
| `delta`    | String returned by `reportDeltaTo()` |

---

## Adhoc Team Bootstrap (No .minds/team.yaml)

Dominds auto-creates an adhoc team when `.minds/team.yaml` is missing by picking the first
configured LLM provider with an API key environment variable set. This should provide the shadow
members `fuxi` and `pangu` (default responder is typically `pangu`).

**Verify before starting tests:**

```javascript
const app = getApp();
await waitUntil(() => Array.isArray(app.teamMembers) && app.teamMembers.length > 0, 10000);
```

If the team never loads, treat it as an infrastructure failure (likely missing LLM API key env var).

---

## Essential Helper Reference

| Helper                                     | Purpose                                                  |
| ------------------------------------------ | -------------------------------------------------------- |
| `snapshotDomindsUI()`                      | Returns `DomindsUI` snapshot instance                    |
| `DomindsUI.reportDeltaTo(prev)`            | Compare snapshots, returns delta string                  |
| `fillAndSend(msg)`                         | Send prompt to testee                                    |
| `waitUntil(fn, timeoutMs)`                 | Poll until condition is true                             |
| `waitForInputEnabled()`                    | Wait until input is enabled                              |
| `waitForPendingTeammateCalls()`            | Wait until teammate/subdialog calls settle               |
| `noLingering()`                            | True when no incomplete generation bubbles remain        |
| `detectToolCall(toolName)`                 | Detect the most recent `@tool_name` call bubble          |
| `findVisibleMessageContainingAll(needles)` | Find visible message node containing required substrings |
| `getRemindersCount()`                      | Read reminders count (from app state)                    |
| `waitForRemindersCount(n)`                 | Wait until reminders count reaches `n`                   |
| `openReminders()`                          | Open reminders widget                                    |
| `closeReminders()`                         | Close reminders widget                                   |
| `getRemindersContent()`                    | Read reminders widget text (widget must be open)         |
| `getQ4HCount()`                            | Current Q4H pending question count                       |
| `createDialog(taskDoc, agent?)`            | Create a new dialog                                      |
| `checkConsoleErrors()`                     | Check for infrastructure errors                          |
| `getCurrentDialogInfo()`                   | Get current dialog ids/agent (rootId/selfId)             |
| `openSubdialog(rootId, subId)`             | Open subdialog by root and self ID                       |
| `selectDialog(title)`                      | Select dialog from sidebar (await this)                  |
| `getSubdialogHierarchy()`                  | Get current subdialog ancestry                           |
| `navigateToParent()`                       | Navigate from subdialog to its parent                    |

---

## Before You Begin

Create a fresh dialog using a dedicated task document so `@change_mind` doesn’t clobber other tests.

Before each run, wipe all runtime-workspace dialog records so you start from a known clean slate:

```bash
./ux-rtws/clear-records.sh; ./dev-server.sh restart
```

This deletes `ux-rtws/.dialogs/` in the rtws, so **all prior dialogs/rounds are gone** (intended for deterministic E2E).

```javascript
const baseline = await snapshotDomindsUI();
await createDialog('round-ctrl-test.tsk');
await waitForInputEnabled();
const snap = await snapshotDomindsUI();
const delta = snap.reportDeltaTo(baseline);

const ready = {
  dialogTitle: snap.currentDialog?.title,
  roundNav: snap.currentDialog?.round,
  inputEnabled: snap.input?.textareaEnabled,
  visibleMessageCount: snap.chat?.visibleMessageCount,
  reminders: snap.reminders?.count,
  q4h: snap.q4h?.count,
};
const bootErrors = checkConsoleErrors();

// Keep a baseline reminders count for teardown.
window.__roundCtrlBaselineReminders__ = getRemindersCount();
```

**You should see:**

- `ready.dialogTitle` is non-empty (dialog selected)
- `ready.inputEnabled === true`
- `bootErrors.length === 0`

If these conditions aren’t met → dominds infrastructure bug, stop.

---

## Calibration Gate (Required)

**Goal:** Ensure the testee understands it must issue a **single tool call** per step and that you are testing infra.

**Prompt:**

```
Calibration: Restate the plan in 2 sentences. Sentence 1: you'll make exactly one tool call per step. Sentence 2: you're helping test dominds infra, not your own reasoning.
```

**Pass Criteria:** Testee outputs exactly 2 sentences matching the intent.

---

## Scenario 1: @clear_mind with reminder

**Goal:** Verify round reset, reminder persistence, and new-round prompt injection via follow-up coroutine.

**Prompt to testee:**

```
Step 1: Issue exactly one @clear_mind call. Put the reminder text in the body: "Remember to verify the new-round prompt." No other tool calls.
```

**Expected Infrastructure Outcomes:**

- A `@clear_mind` call bubble appears in the timeline
- The tool call may show a tool result (typically `Mind cleared`) **inside the tool bubble**, but **no extra chat bubbles** are injected by the tool (no environment/guide messages)
- The dialog round resets and the next round begins automatically
- The first visible message in the new round matches this pattern:
  - `This is round #<n> of the dialog, you just cleared your mind and please proceed with the task.`
- After the round transition, the chat timeline is cleared and refilled with **only** the new round’s bubbles:
  - The previous round’s bubbles (including the `@clear_mind` call bubble) should no longer be visible.
- Reminders are preserved (if UI exposes reminders, verify reminder count increased by 1)
- Input returns to enabled after the follow-up coroutine finishes

**Fail Conditions (Infra):**

- Tool call executes but no new-round prompt appears
- New round does not start without manual user input
- Backfeeding messages appear in the chat as if the tool replied

**Scripted Run (JS, recommended):**

```javascript
const snap = await snapshotDomindsUI();
const roundBefore = snap.currentDialog?.round || '';
const remindersBefore = getRemindersCount();
const q4hBefore = getQ4HCount();

const msgId = await fillAndSend(
  'Step 1: Issue exactly one @clear_mind call. Put the reminder text in the body: ' +
    '"Remember to verify the new-round prompt." No other tool calls.',
);

// 1) Tool bubble must appear at least once
let toolAppeared = false;
try {
  await waitUntil(() => detectToolCall('clear_mind').hasToolCall, 15000);
  toolAppeared = true;
} catch {
  // Under fast UI timing, the tool call bubble can be cleared quickly by the round reset.
  // The round-change + new-round prompt are the definitive infra signals.
}
const tool = detectToolCall('clear_mind');

// 2) Reminder should be persisted (+1) even after round reset
await waitForRemindersCount(remindersBefore + 1, 15000);

// 3) Round must change and new-round prompt must appear as FIRST visible user message
await waitUntil(() => (snapshotDomindsUI().currentDialog?.round || '') !== roundBefore, 20000);
await waitForInputEnabled();

const post = await snapshotDomindsUI();
const prompt = findVisibleMessageContainingAll([
  'This is round #',
  'you just cleared your mind',
  'please proceed with the task.',
]);

const firstVisible = post.chat?.visibleMessages?.[0] || null;
const noToolTextInCurrentRound = !findVisibleMessageContainingAll(['@clear_mind', 'clear_mind']);
const q4hAfter = getQ4HCount();

const assertions = {
  toolAppeared,
  promptExists: !!prompt,
  promptIsFirstVisibleBubble: (prompt?.index ?? -1) === 0,
  currentRoundHasNoToolBubble: noToolTextInCurrentRound,
  remindersDelta: { before: remindersBefore, after: getRemindersCount() },
  q4hClearedOrEmpty: q4hAfter === 0,
  consoleErrors: checkConsoleErrors(),
};
```

---

## Scenario 2: @change_mind updates task doc

**Goal:** Verify task doc overwrite with **no** round reset.

**Prompt to testee:**

```
Step 2: Issue exactly one @change_mind !progress call.
Reply with EXACTLY 3 lines:
Line 1: @change_mind !progress
Line 2: # Task Update
Line 3: We are now testing dialog round control.

No other tool calls. No extra text.
```

**Expected Infrastructure Outcomes:**

- A `@change_mind` call bubble appears in the timeline
- Task document content updates to include the new heading (if UI exposes task doc, confirm visible update)
- The dialog round does **not** change
- The tool call may show a tool result (typically `Mind changed`) **inside the tool bubble**, but **no extra chat bubbles** are injected by the tool
- Input remains enabled (no follow-up coroutine is expected)

**Fail Conditions (Infra):**

- Task doc not updated or not visible after the change
- Round changes unexpectedly

**Scripted Run (JS, recommended):**

```javascript
const snap = await snapshotDomindsUI();
const roundBefore = snap.currentDialog?.round || '';

const msgId = await fillAndSend(
  'Step 2: Issue exactly one @change_mind !progress call.\\n' +
    'Reply ONLY with the following 3 lines (copy exactly; no extra text):\\n' +
    '@change_mind !progress\\n' +
    '# Task Update\\n' +
    'We are now testing dialog round control.',
);

let toolAppeared = false;
try {
  await waitUntil(() => detectToolCall('change_mind').hasToolCall, 15000);
  toolAppeared = true;
} catch {
  // Under fast UI timing, the call bubble can be missed; round stability is still a useful signal.
}

// Wait a bit and assert the round did NOT change.
await new Promise((r) => setTimeout(r, 1500));
const roundAfter = (await snapshotDomindsUI()).currentDialog?.round || '';
if (roundAfter !== roundBefore)
  throw new Error(`Round changed unexpectedly: before='${roundBefore}' after='${roundAfter}'`);
await waitForInputEnabled();

const post = await snapshotDomindsUI();
const firstVisible = post.chat?.visibleMessages?.[0] || null;

const assertions = {
  toolAppeared,
  roundStable: roundAfter === roundBefore,
  consoleErrors: checkConsoleErrors(),
};
```

---

## Scenario 3: @clear_mind without reminder (optional)

**Goal:** Ensure reminder persistence logic is optional and round reset still works.

**Prompt to testee:**

```
Step 3 (optional): Issue exactly one @clear_mind call with an empty body. No other tool calls.
```

**Expected Infrastructure Outcomes:**

- Round resets and new-round prompt appears
- No reminder added
- No backfeeding output
- Chat timeline shows only the current round’s bubbles

---

## Scenario 4: Round navigation (required)

**Goal:** Verify round navigation UI clears/refills and input gating for historical rounds.

**Setup:** Ensure the dialog has at least **3 rounds** (Scenario 1 + Scenario 2 should already achieve this).

**Steps:**

1. Click **Previous Round** once (toolbar left arrow).
2. Observe chat timeline updates.
3. Click **Next Round** to return to the latest round.

**Expected Infrastructure Outcomes:**

- On navigation, `#dialog-container` is cleared and refilled with the selected round’s bubbles (no mixing rounds).
- When viewing a historical round (`R < totalRounds`), input is disabled.
- When returning to latest round (`R == totalRounds`), input is enabled.

**Scripted Run (JS, recommended):**

```javascript
const snap = await snapshotDomindsUI();
const beforeRoundText = snap.currentDialog?.round || '';
const beforeMessages = JSON.stringify(snap.chat?.visibleMessages || []);

const shadow = getAppShadow();
shadow.querySelector('#toolbar-prev')?.click();

// Historical rounds should disable input
await waitUntil(() => snapshotDomindsUI().input?.textareaEnabled === false, 8000);
const prev = await snapshotDomindsUI();
const prevRoundText = prev.currentDialog?.round || '';
const prevMessages = JSON.stringify(prev.chat?.visibleMessages || []);

// If this previous round is the one where @clear_mind happened, the tool bubble should be visible there.
const clearMindSeenInHistory =
  !!findVisibleMessageContainingAll(['@clear_mind']) ||
  !!findVisibleMessageContainingAll(['Mind cleared']) ||
  !!findVisibleMessageContainingAll(['Function:', 'clear_mind']);

shadow.querySelector('#toolbar-next')?.click();
await waitForInputEnabled();
const post = await snapshotDomindsUI();

const assertions = {
  roundTextChanged: prevRoundText !== beforeRoundText,
  inputDisabledInHistory: prev.input?.textareaEnabled === false,
  inputEnabledOnLatest: post.input?.textareaEnabled === true,
  timelineReplacedOnPrev: prevMessages !== beforeMessages,
  clearMindSeenInHistory,
  consoleErrors: checkConsoleErrors(),
};
```

---

## Scenario 5: Subdialog responder clears its own mind (required)

**Goal:** Validate that a **subdialog responder** can autonomously run `@clear_mind` inside the subdialog,
starting a new round for the **subdialog only**, without resetting or altering the parent dialog round/timeline.

This is the primary round-control scenario for long-run work: sub-agents should be able to shed noise locally
while the orchestration dialog stays stable.

### Step 5A: Create a registered pangu subdialog (topic context)

**Prompt to testee (in parent dialog):**

```
Step 5A (critical): This scenario ONLY validates a TYPE B registered subdialog call.
Reply with EXACTLY 2 lines:
Line 1 MUST be exactly: @pangu !topic subdlg-round-ctrl
Line 2 MUST be exactly: SUBDLG_TOKEN_V2

IMPORTANT: Do NOT put `!topic ...` on a second line (that would be in the body, not the headline).
No other tool calls. No extra text.
```

### Step 5B: Open the pangu subdialog (no chat)

Use the sidebar row `Subdialog: @pangu` or open it programmatically with `openSubdialogAndWait(rootId, subId)`.

**Expected Infrastructure Outcomes:**

- UI selection switches to `@pangu`
- Toolbar round nav reflects the subdialog’s current round (typically `R 1`)
- Input is enabled (latest round)

### Step 5C: In the subdialog, pangu runs `@clear_mind` for itself

**Prompt to testee (in the pangu subdialog):**

```
Step 5C: Reply ONLY with the following 2 lines (copy exactly; no preface, no markdown, no extra lines):
@clear_mind
Remember SUBDLG_TOKEN_V2

Do not repeat these instructions. No other tool calls.
```

**Expected Infrastructure Outcomes (subdialog):**

- A `@clear_mind` call bubble appears in the subdialog timeline
- Subdialog round changes (e.g., `R 1 → R 2`)
- New-round prompt appears as the first visible message in the subdialog
- Input returns enabled after follow-up coroutine

**Expected Infrastructure Outcomes (parent dialog):**

- Parent dialog round does **not** change
- Parent dialog timeline does **not** get cleared/replaced
- Subdialog still exists and remains reachable in the sidebar

**Scripted Run (JS, recommended):**

```javascript
// 5A: create registered pangu subdialog from the parent dialog
const pre = await snapshotDomindsUI();
const parentRoundBefore = pre.currentDialog?.round || '';
const rootInfo = getCurrentDialogInfo();
if (!rootInfo?.rootId) throw new Error('Missing root dialog info');
const topicId = 'subdlg-round-ctrl';

// Ensure we start from the parent/root dialog (not currently inside a subdialog).
// Some UI flows can auto-focus into a subdialog; this scenario assumes Step 5A is issued from the parent.
while (getSubdialogHierarchy().length > 1) {
  const ok = await navigateToParent();
  if (!ok) break;
  await waitForInputEnabled();
}

const msgA = await fillAndSend(
  'Step 5A (critical): This scenario ONLY validates a TYPE B registered subdialog call.\\n' +
    'Reply with EXACTLY 2 lines:\\n' +
    'Line 1 MUST be exactly: @pangu !topic subdlg-round-ctrl\\n' +
    'Line 2 MUST be exactly: SUBDLG_TOKEN_V2\\n\\n' +
    'IMPORTANT: Do NOT put `!topic ...` on a second line (that would be in the body, not the headline).\\n' +
    'No other tool calls. No extra text.',
);

// Wait until the TYPE B (registered) pangu subdialog exists.
// If the testee accidentally creates a transient pangu subdialog (no !topic), nudge once and retry.
let cmdrSub = null;
try {
  await waitUntil(() => {
    const dialogs = getApp().dialogs || [];
    cmdrSub =
      dialogs.filter(
        (d) =>
          d &&
          d.supdialogId === rootInfo.rootId &&
          d.agentId === 'pangu' &&
          d.topicId === topicId &&
          typeof d.selfId === 'string' &&
          d.selfId !== '',
      )[0] || null;
    return !!cmdrSub?.selfId;
  }, 30000);
} catch {
  await fillAndSend(
    'Correction #1: Reply ONLY with the following 2 lines (copy exactly; no extra text):\\n' +
      '@pangu !topic subdlg-round-ctrl\\n' +
      'SUBDLG_TOKEN_V2',
  );
  await waitUntil(() => {
    const dialogs = getApp().dialogs || [];
    cmdrSub =
      dialogs.filter(
        (d) =>
          d &&
          d.supdialogId === rootInfo.rootId &&
          d.agentId === 'pangu' &&
          d.topicId === topicId &&
          typeof d.selfId === 'string' &&
          d.selfId !== '',
      )[0] || null;
    return !!cmdrSub?.selfId;
  }, 30000);
}

await waitForPendingTeammateCalls();
await waitForInputEnabled();

const dialogs = getApp().dialogs || [];
const cmdrSubs = dialogs.filter(
  (d) => d && d.supdialogId === rootInfo.rootId && d.agentId === 'pangu',
);
if (!cmdrSub?.selfId) throw new Error('Missing pangu subdialog id');

const parentTokenMsg = findVisibleMessageContainingAll(['SUBDLG_TOKEN_V2']);

// 5B: open pangu subdialog
await openSubdialogAndWait(rootInfo.rootId, cmdrSub.selfId, {
  requireInputEnabled: true,
});

const subSnap = await snapshotDomindsUI();
const subRoundBefore = subSnap.currentDialog?.round || '';
const promptBefore = findVisibleMessageContainingAll([
  'This is round #',
  'you just cleared your mind',
  'please proceed with the task.',
]);
const hierarchy = getSubdialogHierarchy();
const isInSubdialog = hierarchy.length >= 2 && hierarchy[hierarchy.length - 1]?.agentId === 'pangu';

// 5C: in subdialog, pangu clears its own mind
const msgC = await fillAndSend(
  'Step 5C: Reply ONLY with the following 2 lines (copy exactly; no preface, no markdown, no extra lines):\\n' +
    '@clear_mind\\n' +
    'Remember SUBDLG_TOKEN_V2\\n\\n' +
    'Do not repeat these instructions. No other tool calls.',
);
let toolAppeared = false;
try {
  await waitUntil(() => detectToolCall('clear_mind').hasToolCall, 15000);
  toolAppeared = true;
} catch {
  // Under fast UI timing, the tool call bubble can be cleared quickly by the round reset.
  // The round-change + new-round prompt are the definitive infra signals.
}
// The subdialog may have already cleared its mind (and advanced rounds) before this scripted step
// observes `subRoundBefore`. In that case, `subRoundBefore` might already be the post-clear round,
// so waiting on `round !== subRoundBefore` can flake under fast timing.
//
// The definitive infra signal is: the new-round prompt exists and is the first visible message.
await waitUntil(() => {
  const roundNow = snapshotDomindsUI().currentDialog?.round || '';
  const promptNow = findVisibleMessageContainingAll([
    'This is round #',
    'you just cleared your mind',
    'please proceed with the task.',
  ]);
  return roundNow !== subRoundBefore || (promptNow?.index ?? -1) === 0;
}, 30000);
await waitForInputEnabled();
await waitUntil(() => (snapshotDomindsUI().chat?.visibleMessageCount || 0) > 0, 8000);

const subPost = await snapshotDomindsUI();
const prompt = findVisibleMessageContainingAll([
  'This is round #',
  'you just cleared your mind',
  'please proceed with the task.',
]);

// Return to parent and verify it didn't reset
await navigateToParentAndWait({ requireInputEnabled: true });
const parentPost = await snapshotDomindsUI();
const parentTokenMsgAfter = findVisibleMessageContainingAll(['SUBDLG_TOKEN_V2']);

const assertions = {
  isInSubdialog,
  toolAppeared,
  promptAlreadyPresent: (promptBefore?.index ?? -1) === 0,
  subdialogRoundChanged: (subPost.currentDialog?.round || '') !== subRoundBefore,
  subdialogPromptIsFirst: (prompt?.index ?? -1) === 0,
  parentRoundStable: (parentPost.currentDialog?.round || '') === parentRoundBefore,
  parentStillHasTokenMsg: (parentTokenMsgAfter?.index ?? -1) >= 0 && !!parentTokenMsg,
  consoleErrors: checkConsoleErrors(),
};
```

**Fail Conditions (Infra):**

- Subdialog `@clear_mind` resets the **parent** dialog round or clears the parent timeline
- Subdialog round does not increment or new-round prompt does not appear
- Navigation between subdialog and parent breaks (cannot re-open or loses linkage)

---

## Fallback: Missing Tool Call or Missing New Round

If the tool call is missing or the new-round prompt does not appear within timeout, retry once with an explicit directive.

```
Retry: Issue exactly one @clear_mind call now. Do not include any other tool calls or text.
```

If the retry also fails, mark as infra failure and move on.

---

## Compliance Nudge Loop (up to 3 nudges)

Use this when the testee responds but does not fully comply with the requested format
or constraints (extra tool calls, missing reminder text, wrong tool).

```javascript
const nudge = async (n, reason, correction) => {
  const msgId = await fillAndSend(
    `Correction #${n}: ${reason}. ${correction} ` +
      'Reply ONLY with the corrected tool call. No extra text.',
  );
  await waitForInputEnabled();
  const post = await snapshotDomindsUI();
  const errors = checkConsoleErrors();
  return { post, errors };
};
```

If the testee still fails after 3 nudges, mark as **testee non-compliance** and continue. Infra is still considered healthy unless other failures are present.

---

## Teardown / Cleanup (Recommended)

Keep the workspace stable for later tests.

1. Open reminders and record how many were added during this run:

```javascript
await openReminders();
const reminderCount = getRemindersCount();
const reminderContent = getRemindersContent();
await closeReminders();
```

2. If you added a reminder in Scenario 1, delete it via the testee (one call per step):

```javascript
const baselineReminders = Number(window.__roundCtrlBaselineReminders__ || 0);
const reminderNoToDelete = baselineReminders + 1; // @delete_reminder uses 1-based numbering
```

```
Teardown Step A: Issue exactly one @delete_reminder <reminderNoToDelete> call. No other tool calls.
```

3. Verify reminders return to pre-test baseline:

```javascript
await waitForRemindersCount(baselineReminders, 15000);
```

If you added multiple reminders, repeat `@delete_reminder <currentCount>` one-by-one until you reach `baselineReminders`.

If reminders cannot be deleted or the count doesn’t update, treat it as an infrastructure failure in reminder tooling.
