# Dominds WebUI E2E: Teammate Calls to @pangu - For e2e-browser-tester Agent

You are the **tester agent** standing in for a human user. Your role is to validate that **dominds** provides flawless agentic infrastructure for teammate call delegation. The testee should **cooperate** with your directions to help validate dominds features.

## The Test Purpose

This test validates **dominds teammate call infrastructure**, not the testee agent's performance.

- The testee is a reasonable LLM-powered AI agent. It should **cooperate with your instructions** to exercise dominds features, but may still make mistakes, miss tool calls, or deviate (as all LLMs do)
- **Dominds must work flawlessly** regardless of testee behavior - providing reliable teammate call routing, proper subdialog management, and context preservation
- Your job: verify dominds enables you to nudge, correct, and guide the testee toward achieving business goals through teammate delegation

## Business Goal

**Fluent autonomous OS environment variable queries via teammate delegation.**

The testee, when properly guided, must be able to:

- Execute oneshot teammate calls to `@pangu` for single env var queries (TYPE C - transient subdialog)
- Execute topic-based teammate calls to `@pangu` for multiple related queries (TYPE B - registered subdialog)
- Maintain context across multiple topic-based calls within the same registered subdialog
- Properly handle subdialog completion and response supply to supdialog

## Your Tester Agent Principles

1. **Test dominds, not the testee** - The testee should cooperate; if it errs, verify dominds infrastructure handles it
2. **Observe like a human** - Don't poll, don't guess; look at what the UI shows and reason about it
3. **Diagnose before acting** - Check console errors, then verify tool calls and subdialog behavior
4. **Fail fast** - Detect infrastructure issues immediately; testee errors are expected

---

## Tester Hardening Rules

- **Assert infra, not prose** - Pass/fail must be based on UI state + teammate call bubbles, not the testee’s summary.
- **Time-bound every step** - If `waitForTeammateResponse()` or `waitForPendingTeammateCalls()` does not resolve within the allowed timeout, treat as infra failure.
- **One retry for infra gaps only** - If no teammate response or wrong callsite, immediately retry once with explicit `@pangu` call + tool-formatted instruction and move on.
- **Compliance nudges are separate** - If the testee responds but does not fully comply (formatting, missing confirmation, extra lines, etc.), use the _Compliance Nudge Loop_ below (up to 3 nudges).
- **Check console errors after every action** - Catch silent UI/protocol breakage early.
- **Control noise** - Keep prompts short and enforce “one tool call only”.
- **Run the calibration gate first** - Do not proceed with test scenarios unless the testee restates the setup correctly.

---

## Standardized Observation Pattern

All tests follow this pattern:

```javascript
// 1. SNAP - capture current UI state
const snap = await snapshotDomindsUI();

// 2. DELTA - compare with previous state (returns string for display)
const delta = snap.reportDeltaTo(baseline);

// 3. VERIFY - check key assertions
const state = {
  inputEnabled: snap.input?.textareaEnabled,
  hasDialog: snap.currentDialog?.hasRealDialog,
  messageCount: snap.chat?.messageCount,
  visibleMessageCount: snap.chat?.visibleMessageCount,
  pendingCalls: snap.chat?.pendingTeammateCalls,
  visibleSidebar: snap.sidebar?.visibleNodeTitles,
};

// 4. ACT - send prompt or click
const teammateStart = getTeammateMessageCount();
const callSiteBefore = getLatestTeammateCallSiteId();
const msgId = await fillAndSend('your prompt here');

// 5. WAIT - when you expect a teammate response
const callSiteId = await waitForTeammateCallSiteId({
  after: callSiteBefore,
  firstMention: '@pangu',
});
let pendingDone = await waitForPendingTeammateCalls();
let responseReady = await waitForTeammateResponse({
  initialCount: teammateStart,
  callSiteId: callSiteId ?? undefined,
});
const lingering = !noLingering();
if ((!pendingDone || !responseReady) && lingering) {
  pendingDone = await waitForPendingTeammateCalls(120000);
  responseReady = await waitForTeammateResponse({
    initialCount: teammateStart,
    callSiteId: callSiteId ?? undefined,
    timeoutMs: 120000,
  });
}
await waitForInputEnabled();
// If pendingDone or responseReady is still false, use the fallback (below).

// 6. REPEAT - capture post-action state
const post = await snapshotDomindsUI();
const postDelta = post.reportDeltaTo(snap);
```

**Per-step UI observations to capture:**

- Sidebar visible nodes from `snap.sidebar.visibleNodeTitles` (prefixed with `Task:`/`Dialog:`/`Subdialog:`)
- Sidebar selection from `snap.sidebar.selectedDialogTitle`
- Pending teammate calls from `snap.chat.pendingTeammateCalls`
- Input enabled state from `snap.input.textareaEnabled`
- Visible message count from `snap.chat.visibleMessageCount`
- Visible chat timeline from `snap.chat.visibleMessages` (includes teammate responses)
- Teammate response narratives from `getTeammateResponseDetails()` (use `narrativeLine`, `callHeadLine`; narrative should start with `Hi @` and include `provided response`, and `callHeadLine` is parsed from the `to your original call:` block)

`reportDeltaTo()` will include `Sidebar visible: ...` and `Visible messages: ...` when those counts change.

---

## Generation Completion Rule

When waiting for teammate responses, capture a new call-site ID with
`waitForTeammateCallSiteId()` and pass it to `waitForTeammateResponse()`.
Only extend waits when `noLingering()` is false
(incomplete generation bubbles remain). If `pendingDone` or `responseReady`
remains false after the extended wait and `noLingering()` is true, treat it as a
testee non-response and retry once using the fallback below.

### Fallback: No Teammate Response

If no response bubble appears and `noLingering()` shows no active generation,
retry once with a more explicit prompt (keep the same goal, but require a single
tool call).

```javascript
if (!pendingDone || !responseReady) {
  const retryTeammateStart = getTeammateMessageCount();
  const retryCallSiteBefore = getLatestTeammateCallSiteId();
  const retryId = await fillAndSend(
    'Retry: @pangu please run shell_cmd command="echo $HOME". Use only one shell_cmd call.',
  );

  const retryCallSiteId = await waitForTeammateCallSiteId({
    after: retryCallSiteBefore,
    firstMention: '@pangu',
  });
  let retryDone = await waitForPendingTeammateCalls();
  let retryReady = await waitForTeammateResponse({
    initialCount: retryTeammateStart,
    callSiteId: retryCallSiteId ?? undefined,
  });
  const retryLingering = !noLingering();
  if ((!retryDone || !retryReady) && retryLingering) {
    retryDone = await waitForPendingTeammateCalls(120000);
    retryReady = await waitForTeammateResponse({
      initialCount: retryTeammateStart,
      callSiteId: retryCallSiteId ?? undefined,
      timeoutMs: 120000,
    });
  }
  await waitForInputEnabled();
}
```

**Fallback: Missing or Wrong Teammate Call**

If the teammate call site does not appear (or appears without `@pangu`), retry once with
an explicit `@pangu` directive and a single tool-formatted instruction. Do not keep re-prompting.

---

## Compliance Nudge Loop (up to 3 nudges)

Use this when the testee **responds** but does not fully comply with the requested format
or constraints (extra lines, missing confirmation, wrong ordering, missing variables, etc.).
This is **not** for infra failures (use the fallback above for missing callsite or no response).

**Rule:** You may nudge up to **3 times**. If the testee fully complies on the 2nd or 3rd try,
count the step as **pass**. If it still fails after 3 nudges, mark as **testee non-compliance**
and continue (infra is still considered healthy unless other failures are present).

```javascript
const nudge = async (n, reason, correction) => {
  const teammateStart = getTeammateMessageCount();
  const callSiteBefore = getLatestTeammateCallSiteId();
  const msgId = await fillAndSend(
    `Correction #${n}: ${reason}. ${correction} ` +
      'Reply ONLY with the corrected response. No extra text.',
  );
  const callSiteId = await waitForTeammateCallSiteId({
    after: callSiteBefore,
    firstMention: '@pangu',
  });
  let pendingDone = await waitForPendingTeammateCalls();
  let responseReady = await waitForTeammateResponse({
    initialCount: teammateStart,
    callSiteId: callSiteId ?? undefined,
  });
  const lingering = !noLingering();
  if ((!pendingDone || !responseReady) && lingering) {
    pendingDone = await waitForPendingTeammateCalls(120000);
    responseReady = await waitForTeammateResponse({
      initialCount: teammateStart,
      callSiteId: callSiteId ?? undefined,
      timeoutMs: 120000,
    });
  }
  await waitForInputEnabled();
  const post = await snapshotDomindsUI();
  const errors = checkConsoleErrors();
  return { pendingDone, responseReady, post, errors };
};

// Example usage:
// for (let i = 1; i <= 3 && !fullyCompliant; i += 1) {
//   const { post } = await nudge(
//     i,
//     'Your response did not follow the required 3-line format',
//     'Return exactly three lines: USER=..., PATH=..., SHELL=... (truncate PATH if needed).',
//   );
//   // re-evaluate compliance from `post` and break if satisfied
// }
```

## Adhoc Team Bootstrap (No .minds/team.yaml)

Dominds auto-creates an adhoc team when `.minds/team.yaml` is missing by picking the first
configured LLM provider with an API key environment variable set. This should provide
at least the shadow members `fuxi` and `pangu` (default responder is typically `pangu`).

**Verify before starting tests:**

```javascript
const app = getApp();
await waitUntil(() => Array.isArray(app.teamMembers) && app.teamMembers.length > 0, 10000);
const teamIds = app.teamMembers.map((m) => m.id);
const teamState = {
  teamIds,
  defaultResponder: app.defaultResponder,
};
```

**You should see:**

- `teamState.teamIds` includes `fuxi` and `pangu`
- `teamState.defaultResponder` is a non-empty string (typically `pangu`)

If the team never loads, treat it as an infrastructure failure (likely missing LLM API key env var).

### Standardized Variable Names

| Variable   | Purpose                              |
| ---------- | ------------------------------------ |
| `baseline` | Initial state before any actions     |
| `snap`     | Pre-action state snapshot            |
| `post`     | Post-action state snapshot           |
| `delta`    | String returned by `reportDeltaTo()` |

---

## Essential Helper Reference

| Helper                          | Purpose                                                                                        |
| ------------------------------- | ---------------------------------------------------------------------------------------------- |
| `snapshotDomindsUI()`           | Returns `DomindsUI` snapshot instance (shorthand)                                              |
| `DomindsUI.reportDeltaTo(prev)` | Compare snapshots, returns delta string                                                        |
| `fillAndSend(msg)`              | Send prompt to testee                                                                          |
| `waitForInputEnabled()`         | Optional: wait when dialog selection is uncertain                                              |
| `getTeammateMessageCount()`     | Current count of `.message.teammate` bubbles                                                   |
| `waitForPendingTeammateCalls()` | Wait until no pending teammate calls remain                                                    |
| `getLatestTeammateCallSiteId()` | Latest teammate call-site ID rendered in the call section                                      |
| `waitForTeammateCallSiteId()`   | Wait for a new call-site ID (opts: timeoutMs/after/firstMention)                               |
| `waitForTeammateResponse(opts)` | Wait for teammate response bubble(s) with content (opts: timeoutMs/minChars/minNew/callSiteId) |
| `waitStreamingComplete(msgId)`  | Wait for the current assistant response to finish                                              |
| `noLingering()`                 | True when no incomplete generation bubbles remain                                              |
| `latestUserText()`              | Latest user prompt text in the current dialog                                                  |
| `createDialog(taskDoc, agent?)` | Create new dialog (agent optional - uses default responder)                                    |
| `checkConsoleErrors()`          | Check for infrastructure errors                                                                |
| `getPendingTeammateCalls()`     | Get current pending teammate call entries                                                      |
| `getSubdialogHierarchy()`       | Get subdialog nesting depth                                                                    |
| `selectDialog(title)`           | Select dialog from sidebar (await this; ensures lazy-loaded subdialogs)                        |
| `openSubdialog(rootId, subId)`  | Open subdialog by root and self ID                                                             |

---

## Part A: Oneshot Teammate Call (TYPE C - Transient Subdialog)

### Before You Begin

First, ensure you have a working dialog:

```javascript
// Optional if .minds/team.yaml is missing: wait for adhoc team
const app = getApp();
await waitUntil(() => Array.isArray(app.teamMembers) && app.teamMembers.length > 0, 10000);
```

```javascript
// 1. Capture baseline
const baseline = await snapshotDomindsUI();

// 2. Create dialog
await createDialog('cmds-test.tsk');

// 3. Wait for new dialog selected
await waitForInputEnabled();

// 4. Capture post-create state
const snap = await snapshotDomindsUI();

// 5. Get delta
const delta = snap.reportDeltaTo(baseline);

// 6. Verify dialog is ready
const ready = {
  dialogTitle: snap.currentDialog?.title,
  inputEnabled: snap.input?.textareaEnabled,
  messageCount: snap.chat?.messageCount,
  visibleMessageCount: snap.chat?.visibleMessageCount,
};
const bootErrors = checkConsoleErrors();
```

**You should see:**

- `ready.dialogTitle` includes the task name
- `ready.inputEnabled === true`
- `ready.visibleMessageCount === 0`
- `bootErrors.length === 0`

If these conditions aren't met → dominds infrastructure bug, stop.

**UI observation (post-create):**

- Sidebar visible list includes `Task: cmds-test.tsk` and a single `Dialog: @...` row
- Sidebar selection matches `snap.currentDialog.title`
- Chat area shows no pending teammate calls and no messages

---

## Calibration Gate: Explain the Test Setup Before Running Scenarios

**Goal:** Ensure the testee understands the test setup and can articulate it correctly in its own words.

**Important:** Avoid `@` symbols here to prevent unintended teammate calls. Use words like “Pangu” instead of `@pangu`.

```javascript
const preflightStart = await snapshotDomindsUI();
const msgId = await fillAndSend(
  'Calibration: You are the testee in a dominds teammate-call infrastructure test. ' +
    'In your own words, explain how you will behave during this test. ' +
    'Cover: (1) you will cooperate with instructions, (2) you will only contact the Pangu teammate when explicitly instructed, ' +
    '(3) you will use exactly one tool action when requested, (4) you will not call any teammates or tools during calibration. ' +
    'Do not use the @ symbol.',
);
const completed = await waitStreamingComplete(msgId, 120000);
await waitForInputEnabled();
const preflightPost = await snapshotDomindsUI();
const preflightErrors = checkConsoleErrors();
```

**Pass Criteria (Calibration):**

- [ ] Response is **semantically correct**: acknowledges cooperation, limits teammate contact to explicit instructions, and commits to exactly one tool action when requested
- [ ] Response explicitly states no teammate/tool calls during calibration
- [ ] Response avoids teammate calls (no new `Subdialog:` rows added)
- [ ] `preflightErrors.length === 0` and `completed === true`

**If the calibration fails:** **STOP** the test run and write a short advisory (see below). Do not proceed to Part A/B/C.

**Advisory template (use if calibration fails):**

- Suggest stronger prompt constraints, e.g. “Do not call any teammates or tools unless explicitly asked; never emit @ or !topic.”
- Suggest a single-sentence checklist that the testee must repeat verbatim before proceeding.
- Suggest adding a final confirmation question: “Do you agree? Reply only with ‘YES’.”

---

### Scenario A0: Direct User-Initiated Call (TYPE C)

**Goal:** Validate a **user-initiated** teammate call (the tester triggers the call directly).

**Important:** This is intentionally a direct `@pangu` call from the tester (human). The call
text is delivered straight to the pangu subdialog (no intermediary instruction step). Expect
the call origin to show **Human → @pangu** if your UI exposes it.

```javascript
// 1. Send a direct teammate call (user-initiated)
const teammateStart = getTeammateMessageCount();
const callSiteBefore = getLatestTeammateCallSiteId();
const msgId = await fillAndSend(
  '@pangu Please run shell_cmd command="echo $HOME". Use exactly one tool call and reply with the HOME value only.',
);

const callSiteId = await waitForTeammateCallSiteId({
  after: callSiteBefore,
  firstMention: '@pangu',
});
let pendingDone = await waitForPendingTeammateCalls();
let responseReady = await waitForTeammateResponse({
  initialCount: teammateStart,
  callSiteId: callSiteId ?? undefined,
});
const lingering = !noLingering();
if ((!pendingDone || !responseReady) && lingering) {
  pendingDone = await waitForPendingTeammateCalls(120000);
  responseReady = await waitForTeammateResponse({
    initialCount: teammateStart,
    callSiteId: callSiteId ?? undefined,
    timeoutMs: 120000,
  });
}
await waitForInputEnabled();

const post = await snapshotDomindsUI();
const errors = checkConsoleErrors();
```

**Pass Criteria (A0):**

- [ ] `@pangu` call site appears
- [ ] HOME value returned by pangu
- [ ] Subdialog created and completed (TYPE C)
- [ ] No console errors

---

### Scenario A1: Responder-Initiated Env Query (TYPE C)

**Goal:** Test TYPE C teammate call initiated by the **current dialog responder**

```javascript
// 1. Verify ready state
const pre = await snapshotDomindsUI();
const preState = {
  inputEnabled: pre.input?.textareaEnabled,
  hasDialog: pre.currentDialog?.hasRealDialog,
};
const teammateStart = getTeammateMessageCount();
const callSiteBefore = getLatestTeammateCallSiteId();
// preState should be: { inputEnabled: true, hasDialog: true }
```

**UI observation (pre-send):**

- Sidebar visible list shows the current root dialog but no subdialog row
- Pending teammate calls count is 0
- Input is enabled and focused in the main panel

```javascript
// 2. Send the prompt
const msgId = await fillAndSend(
  'Current dialog responder: issue a teammate call to the pangu teammate (mention `@pangu` without `!topic`) ' +
    'to query the HOME environment variable. ' +
    'Roles: root dialog responder sends the teammate call; pangu runs shell_cmd; tester/human runs nothing. ' +
    'Use shell_cmd with command="echo $HOME". Use only one shell_cmd call, no extra commands.',
);

const callSiteId = await waitForTeammateCallSiteId({
  after: callSiteBefore,
  firstMention: '@pangu',
});
let pendingDone = await waitForPendingTeammateCalls();
let responseReady = await waitForTeammateResponse({
  initialCount: teammateStart,
  callSiteId: callSiteId ?? undefined,
});
const lingering = !noLingering();
if ((!pendingDone || !responseReady) && lingering) {
  pendingDone = await waitForPendingTeammateCalls(120000);
  responseReady = await waitForTeammateResponse({
    initialCount: teammateStart,
    callSiteId: callSiteId ?? undefined,
    timeoutMs: 120000,
  });
}
await waitForInputEnabled();
```

```javascript
// 3. Capture post-action state
const post = await snapshotDomindsUI();
const delta = post.reportDeltaTo(pre);

// 4. Check console errors
const errors = checkConsoleErrors();
```

**What to look for in `delta` and verification:**

| Check                                                          | Expected          | Meaning                  |
| -------------------------------------------------------------- | ----------------- | ------------------------ |
| `post.chat.visibleMessageCount > pre.chat.visibleMessageCount` | true              | Response appended        |
| `pendingDone && responseReady`                                 | true              | Teammate call completed  |
| `post.input.textareaEnabled`                                   | true              | Processing complete      |
| `latestTeammate.author`                                        | contains `@pangu` | Teammate call visible    |
| `errors.length`                                                | 0                 | No infrastructure errors |

**UI observation (post-call):**

- `delta` includes a `Sidebar visible:` line that adds a `Subdialog: ...` entry
- The root dialog is expanded and the subdialog row is visible in the sidebar
- Pending teammate calls drops back to 0 and input re-enables

```javascript
// 6. Detailed verification
const lastGen = post.chat?.latestMessage;
const teammateMessages = (post.chat?.visibleMessages || []).filter((m) => m.type === 'teammate');
const latestTeammate = teammateMessages[teammateMessages.length - 1] || null;
const verification = {
  teammateAuthor: latestTeammate?.author,
  teammatePreview: latestTeammate?.preview,
  hasThinking: lastGen?.hasThinking,
  hasFuncCall: lastGen?.hasFuncCall,
  funcName: lastGen?.funcName,
  genPreview: lastGen?.markdownPreview?.slice(0, 100),
};
```

**Expected verification values:**

- `teammateAuthor` includes `@pangu` or `Pangu`
- `hasFuncCall === true` with `funcName === 'shell_cmd'`
- `teammatePreview` contains a non-empty HOME path (e.g., `/Users/...` or `/home/...`)
- `errors.length === 0`

```javascript
// 7. Verify transient subdialog completed
const hierarchy = getSubdialogHierarchy();
const subdialogState = {
  levels: hierarchy.length,
  isTransientComplete: hierarchy.length === 1,
};
// subdialogState should be: { levels: 1, isTransientComplete: true }
```

**Pass Criteria (A1):**

- [ ] `@pangu` teammate call visible in response
- [ ] `shell_cmd` tool call executed with `echo $HOME`
- [ ] Response contains HOME environment variable value
- [ ] Call origin is the current dialog responder → pangu (not Human → pangu)
- [ ] Subdialog hierarchy shows 1 level (transient subdialog completed)
- [ ] No console errors

---

### Scenario A2: Batch `@change_mind` + Teammate Call in One Message (Mixed Actions)

**Goal:** Validate that dominds can process **multiple** `@change_mind` updates (multiple sections) and a **teammate call** in the **same user message**, without dropping/merging actions or corrupting subdialog routing.

This is a “mixed actions” stress case:

- Multiple task-doc section updates (Goals/Constraints/Progress)
- A teammate call to `@pangu` (TYPE C)
- All triggered from a single send (one user message)

**Important notes:**

- `@change_mind` for `*.tsk/` still requires **exactly one** selector per call. This scenario uses **multiple calls** in one message.
- The user message must **not** begin with `@pangu` (otherwise you’ve turned it into a **direct user-initiated** teammate call and you’re no longer testing “responder delegates to teammate”).

#### Steps

1. Capture a baseline snapshot (`pre`) and record the current round indicator (should remain stable; `@change_mind` must not reset rounds).
2. Send exactly **one** user message instructing the responder to:
   1. Call `@change_mind !goals` with a new goals list
   2. Call `@change_mind !constraints` with a new constraints list
   3. Call `@change_mind !progress` with a new progress list
   4. Then issue a teammate call to `@pangu` (no `!topic`) to run exactly one `shell_cmd` with `command="echo $HOME"`, and return the HOME value
3. Wait for all teammate calls to complete and input to re-enable.
4. Verify in UI:
   - There is **one** assistant turn that contains **three** successful `@change_mind` tool bubbles (one per selector) and a visible `@pangu` teammate call + response.
   - No cross-write: the “goals-like” text is in goals, “constraints-like” text is in constraints, etc.
   - Subdialog hierarchy returns to a single level after completion (transient subdialog completed).
   - No console errors.
5. Verify in the workspace filesystem (outside dominds file tools; `*.tsk/` is encapsulated):
   - `cmds-test.tsk/goals.md` matches the new goals body (semantic match).
   - `cmds-test.tsk/constraints.md` matches the new constraints body.
   - `cmds-test.tsk/progress.md` matches the new progress body.

#### Example prompt (one send; not strict)

```text
In one response, do these steps in order:
1) Update the task doc goals via @change_mind !goals to:
- Confirm teammate routing works under mixed actions.
- Confirm task-doc updates work under mixed actions.
2) Update constraints via @change_mind !constraints to:
- Use one selector per call.
- No direct user-initiated @pangu call.
3) Update progress via @change_mind !progress to:
- Started mixed-action verification.
4) Then delegate to @pangu (no !topic): run exactly one shell_cmd command="echo $HOME" and reply with HOME only.
```

**Pass Criteria (A2):**

- [ ] UI shows 3 successful `@change_mind` tool executions (Goals/Constraints/Progress) from the same send
- [ ] UI shows a responder-initiated `@pangu` teammate call and a `shell_cmd` execution for `echo $HOME`
- [ ] All three task-doc files updated correctly (`cmds-test.tsk/goals.md`, `constraints.md`, `progress.md`)
- [ ] Subdialog hierarchy returns to 1 level (transient complete)
- [ ] No console errors

---

## Part B: Topic-Based Teammate Call (TYPE B - Registered Subdialog)

### Before You Begin

Create a fresh dialog for this test:

```javascript
const baseline = await snapshotDomindsUI();
await createDialog('topic-test.tsk');
await waitForInputEnabled();
const snap = await snapshotDomindsUI();
const delta = snap.reportDeltaTo(baseline);

const ready = {
  dialogTitle: snap.currentDialog?.title,
  inputEnabled: snap.input?.textareaEnabled,
};
```

**You should see:**

- `ready.dialogTitle` includes `topic-test.tsk`
- `ready.inputEnabled === true`

---

### Scenario B1: Establish Registered Subdialog Context

**Goal:** Test TYPE B teammate call (`@pangu !topic env-check`)

```javascript
// 1. Verify input ready
const pre = await snapshotDomindsUI();
const preState = {
  inputEnabled: pre.input?.textareaEnabled,
  hasDialog: pre.currentDialog?.hasRealDialog,
};
const teammateStart = getTeammateMessageCount();
const callSiteBefore = getLatestTeammateCallSiteId();
```

```javascript
// 2. Send the prompt
const msgId = await fillAndSend(
  'Use the pangu teammate with topic env-check (mention `@pangu !topic env-check`) to establish a registered subdialog context. ' +
    'Roles: root dialog responder instructs pangu; pangu runs shell_cmd; tester/human runs nothing. ' +
    'In that call, instruct pangu to run shell_cmd command="echo $USER" (no @ prefix). ' +
    'Only pangu should execute the tool; you must not run shell_cmd yourself. ' +
    'Do NOT ask the tester/human to run anything. ' +
    'Wait for pangu’s reply and report the USER value you receive.',
);

const callSiteId = await waitForTeammateCallSiteId({
  after: callSiteBefore,
  firstMention: '@pangu',
});
let pendingDone = await waitForPendingTeammateCalls();
let responseReady = await waitForTeammateResponse({
  initialCount: teammateStart,
  callSiteId: callSiteId ?? undefined,
});
const lingering = !noLingering();
if ((!pendingDone || !responseReady) && lingering) {
  pendingDone = await waitForPendingTeammateCalls(120000);
  responseReady = await waitForTeammateResponse({
    initialCount: teammateStart,
    callSiteId: callSiteId ?? undefined,
    timeoutMs: 120000,
  });
}
await waitForInputEnabled();
```

```javascript
// 3. Capture post-action state
const post = await snapshotDomindsUI();
const delta = post.reportDeltaTo(pre);

// 4. Verify subdialog was created
const hierarchy = getSubdialogHierarchy();
const teammateMessages = (post.chat?.visibleMessages || []).filter((m) => m.type === 'teammate');
const latestTeammate = teammateMessages[teammateMessages.length - 1] || null;
const postState = {
  visibleMessageCount: post.chat?.visibleMessageCount,
  teammateAuthor: latestTeammate?.author,
  teammatePreview: latestTeammate?.preview,
  hierarchyLevels: hierarchy.length,
  pendingDone,
  responseReady,
};
const errors = checkConsoleErrors();
const hierarchyExpected = hierarchy.length >= 2;
```

**UI observation (post-call):**

- Sidebar visible list adds a `Subdialog: ...` entry under the root (root expanded)
- Chat shows a teammate call section transitioning to a response
- Pending teammate calls returns to 0

**Pass Criteria (B1):**

- [ ] `@pangu !topic env-check` visible in response
- [ ] USER environment variable value retrieved
- [ ] Sidebar shows a new `Subdialog: ...` row under the root dialog
- [ ] No console errors

---

### Scenario B2: Resume Registered Subdialog (Second Query)

**Goal:** Verify the SAME subdialog is RESUMED (not recreated)

```javascript
// 1. Observe current state
const beforeB2 = await snapshotDomindsUI();
const beforeState = {
  visibleMessageCount: beforeB2.chat?.visibleMessageCount,
  hierarchyLevels: getSubdialogHierarchy().length,
};
const teammateStart = getTeammateMessageCount();
const callSiteBefore = getLatestTeammateCallSiteId();
```

**UI observation (pre-send):**

- Sidebar visible list already includes the existing `Subdialog: ...` row
- No new subdialog rows should appear yet

```javascript
// 2. Send second query in same topic
const msgId2 = await fillAndSend(
  'Again use the pangu teammate with topic env-check (mention `@pangu !topic env-check`) to query the PATH environment variable. ' +
    'Roles: root dialog responder instructs pangu; pangu runs shell_cmd; tester/human runs nothing. ' +
    'In that call, instruct pangu to run shell_cmd command="echo $PATH" (no @ prefix). ' +
    'Only pangu should execute the tool; you must not run shell_cmd yourself. ' +
    'Do NOT ask the tester/human to run anything. ' +
    'Report the PATH value you receive, and confirm this is the SAME subdialog context.',
);

const callSiteId = await waitForTeammateCallSiteId({
  after: callSiteBefore,
  firstMention: '@pangu',
});
let pendingDone = await waitForPendingTeammateCalls();
let responseReady = await waitForTeammateResponse({
  initialCount: teammateStart,
  callSiteId: callSiteId ?? undefined,
});
const lingering = !noLingering();
if ((!pendingDone || !responseReady) && lingering) {
  pendingDone = await waitForPendingTeammateCalls(120000);
  responseReady = await waitForTeammateResponse({
    initialCount: teammateStart,
    callSiteId: callSiteId ?? undefined,
    timeoutMs: 120000,
  });
}
await waitForInputEnabled();
```

```javascript
// 3. Capture
const afterB2 = await snapshotDomindsUI();
const deltaB2 = afterB2.reportDeltaTo(beforeB2);

// 4. Key verification - subdialog resumed vs recreated
const hierarchy = getSubdialogHierarchy();
const teammateMessages = (afterB2.chat?.visibleMessages || []).filter((m) => m.type === 'teammate');
const latestTeammate = teammateMessages[teammateMessages.length - 1] || null;
const verificationB2 = {
  hierarchyLevels: hierarchy.length,
  visibleMessageCount: afterB2.chat?.visibleMessageCount,
  teammateAuthor: latestTeammate?.author,
  teammatePreview: latestTeammate?.preview,
  pendingDone,
  responseReady,
};
const errorsB2 = checkConsoleErrors();
```

**UI observation (post-call):**

- `deltaB2` should not add a new `Subdialog: ...` row in `Sidebar visible`
- Sidebar still shows the same subdialog entry (no duplicates)
- Pending teammate calls returns to 0

**Pass Criteria (B2):**

- [ ] `deltaB2` does not add a new `Subdialog: ...` row (same subdialog reused)
- [ ] PATH environment variable value retrieved (non-empty, typically contains `:`)
- [ ] Both USER and PATH visible in the dialog history
- [ ] No console errors

---

### Scenario B3: Third Query - Verify Context Preservation

**Goal:** Verify context persists across multiple calls in same registered subdialog

```javascript
// 1. Send third query
const teammateStart = getTeammateMessageCount();
const callSiteBefore = getLatestTeammateCallSiteId();
const msgId3 = await fillAndSend(
  'Query the SHELL environment variable using the pangu teammate with topic env-check (mention `@pangu !topic env-check`). ' +
    'Roles: root dialog responder instructs pangu; pangu runs shell_cmd; tester/human runs nothing. ' +
    'In that call, instruct pangu to run shell_cmd command="echo $SHELL" (no @ prefix). ' +
    'Only pangu should execute the tool; you must not run shell_cmd yourself. ' +
    'Do NOT ask the tester/human to run anything. ' +
    'Use exactly one tool call. ' +
    'Summarize all three environment variables you have queried (USER, PATH, SHELL) using the values returned by pangu. ' +
    'Formatting is flexible, but include all three values clearly.',
);

const callSiteId = await waitForTeammateCallSiteId({
  after: callSiteBefore,
  firstMention: '@pangu',
});
let pendingDone = await waitForPendingTeammateCalls();
let responseReady = await waitForTeammateResponse({
  initialCount: teammateStart,
  callSiteId: callSiteId ?? undefined,
});
const lingering = !noLingering();
if ((!pendingDone || !responseReady) && lingering) {
  pendingDone = await waitForPendingTeammateCalls(120000);
  responseReady = await waitForTeammateResponse({
    initialCount: teammateStart,
    callSiteId: callSiteId ?? undefined,
    timeoutMs: 120000,
  });
}
await waitForInputEnabled();

const afterB3 = await snapshotDomindsUI();
const deltaB3 = afterB3.reportDeltaTo(afterB2);

// 2. Verify context is preserved
const visibleMessages = afterB3.chat?.visibleMessages || [];
const messageSummary = visibleMessages.map((m, i) => ({
  index: i + 1,
  author: m.author,
  type: m.type,
  preview: m.preview?.slice(0, 80),
}));
const teammateMessages = visibleMessages.filter((m) => m.type === 'teammate');
const latestTeammate = teammateMessages[teammateMessages.length - 1] || null;

// 3. Verify subdialog still active
const hierarchy = getSubdialogHierarchy();
const verificationB3 = {
  visibleMessageCount: visibleMessages.length,
  teammateAuthor: latestTeammate?.author,
  teammatePreview: latestTeammate?.preview,
  hierarchyLevels: hierarchy.length,
  pendingDone,
  responseReady,
};
const errorsB3 = checkConsoleErrors();
```

**UI observation (post-call, diagnostic only):**

- Sidebar visible list still shows the same `Subdialog: ...` entry
- `deltaB3` should not introduce a new subdialog row
- Pending teammate calls is 0 and input is enabled

**Pass Criteria (B3):**

- [ ] SHELL environment variable value retrieved
- [ ] Testee summarizes USER, PATH, and SHELL with correct semantics (formatting can vary)

---

## Part C: Type A Supdialog Suspension (Subdialog → Parent)

### Before You Begin

Create a fresh dialog for this test:

```javascript
const baseline = await snapshotDomindsUI();
await createDialog('supcall-test.tsk');
await waitForInputEnabled();
const snap = await snapshotDomindsUI();
const delta = snap.reportDeltaTo(baseline);
const ready = {
  dialogTitle: snap.currentDialog?.title,
  inputEnabled: snap.input?.textareaEnabled,
  visibleMessageCount: snap.chat?.visibleMessageCount,
};
const bootErrors = checkConsoleErrors();
```

**You should see:**

- `ready.dialogTitle` includes `supcall-test.tsk`
- `ready.inputEnabled === true`
- `ready.visibleMessageCount === 0`
- `bootErrors.length === 0`

---

### Scenario C1: Create a Registered Subdialog for Doc Scan (Type B)

**Goal:** Create a `@pangu !topic` subdialog, instruct it to list document files, and explicitly
encourage a clarification supcall about file extensions (do not guess).

```javascript
const pre = await snapshotDomindsUI();
const teammateStart = getTeammateMessageCount();
const callSiteBefore = getLatestTeammateCallSiteId();

const msgId = await fillAndSend(
  'Follow the task doc strictly. Create the registered pangu subdialog with topic "doc-scan" using only `@pangu !topic doc-scan`. ' +
    'Pangu must ask the parent for extensions via a Type A supcall using `@super` (NO `!topic`) before listing (no guessing), then list files using those extensions. ' +
    'Only the call line should contain the teammate handle. ' +
    'Roles: root dialog responder issues the pangu call; pangu runs tools; tester/human runs nothing. ' +
    'Use exactly one tool call. Do not run tools yourself.',
);

const callSiteId = await waitForTeammateCallSiteId({
  after: callSiteBefore,
  firstMention: '@pangu',
});
let pendingDone = await waitForPendingTeammateCalls();
let responseReady = await waitForTeammateResponse({
  initialCount: teammateStart,
  callSiteId: callSiteId ?? undefined,
});
const lingering = !noLingering();
if ((!pendingDone || !responseReady) && lingering) {
  pendingDone = await waitForPendingTeammateCalls(120000);
  responseReady = await waitForTeammateResponse({
    initialCount: teammateStart,
    callSiteId: callSiteId ?? undefined,
    timeoutMs: 120000,
  });
}
await waitForInputEnabled();

const post = await snapshotDomindsUI();
const delta = post.reportDeltaTo(pre);
const errors = checkConsoleErrors();

const dialogs = getAllDialogs();
const rootInfo = getCurrentDialogInfo();
const cmdrSubdialogs = dialogs.filter(
  (d) => d.supdialogId === rootInfo.rootId && d.agentId === 'pangu',
);
const cmdrSubdialog = cmdrSubdialogs
  .slice()
  .sort((a, b) => (a.lastModified || '').localeCompare(b.lastModified || ''))
  .pop();
const cmdrSubdialogCount = cmdrSubdialogs.length;
```

**Pass Criteria (C1):**

- [ ] `@pangu !topic doc-scan` visible in response
- [ ] Subdialog established and ready to proceed
- [ ] Sidebar shows a single `Subdialog: ...` row for `@pangu` (no duplicates)
- [ ] `cmdrSubdialogCount === 1` (if >1, record infra failure but continue with latest for C2)
- [ ] `cmdrSubdialog?.selfId` is defined (use the newest if duplicates exist)
- [ ] No console errors

---

### Scenario C2: Subdialog Requests Clarification (Type A)

**Goal:** Verify the subdialog requested extension clarification via a Type A supcall and listed
document files accordingly **without any tester messages inside the subdialog**. If the pangu testee
fails to do so, treat it as non-compliance and **only then** use a subdialog nudge (fallback). Ensure
the parent’s response is bridged back into the subdialog without creating a new subdialog.

```javascript
// 1. Open the pangu subdialog
const rootInfo = getCurrentDialogInfo();
const dialogs = getAllDialogs();
const cmdrSubdialogs = dialogs.filter(
  (d) => d.supdialogId === rootInfo.rootId && d.agentId === 'pangu',
);
const cmdrSubdialog = cmdrSubdialogs
  .slice()
  .sort((a, b) => (a.lastModified || '').localeCompare(b.lastModified || ''))
  .pop();
if (!cmdrSubdialog?.selfId) throw new Error('Missing pangu subdialog id');
await openSubdialog(rootInfo.rootId, cmdrSubdialog.selfId);
await waitForInputEnabled();

try {
  await waitUntil(
    () => {
      const nodes = Array.from(document.querySelectorAll('.message.teammate'));
      return nodes.some((node) => {
        const author =
          node.querySelector('.author-name')?.textContent?.trim() ||
          node.querySelector('.author')?.textContent?.trim() ||
          '';
        return author === '@fuxi';
      });
    },
    20000,
    200,
  );
} catch {
  // proceed even if the parent response hasn't arrived yet
}

const subSnap = await snapshotDomindsUI();
const sidebarBefore = subSnap.sidebar?.visibleNodeTitles || [];
const teammateStart = getTeammateMessageCount();
const callSiteBefore = getLatestTeammateCallSiteId();
let pendingDone = true;
let responseReady = true;

// 2. Ideal path: pangu already issued a Type A supcall; do NOT inject subdialog messages.
//    Fallback only: if pangu did not ask the parent, treat as non-compliance and use the formal nudge loop.
const subMessages = subSnap.chat?.visibleMessages || [];
const alreadyAsked = subMessages.some((m) => m.type === 'teammate' && m.author === '@fuxi');

const nudgeSubdialog = async (n, reason, correction) => {
  const nudgeStart = getTeammateMessageCount();
  const nudgeCallSiteBefore = getLatestTeammateCallSiteId();
  const msgId = await fillAndSend(
    `Correction #${n}: ${reason}. ${correction} ` +
      'Reply ONLY with the corrected response. No extra text.',
  );
  const callSiteId = await waitForTeammateCallSiteId({
    after: nudgeCallSiteBefore,
    firstMention: '@super',
  });
  let nudgePendingDone = await waitForPendingTeammateCalls();
  let nudgeResponseReady = await waitForTeammateResponse({
    initialCount: nudgeStart,
    callSiteId: callSiteId ?? undefined,
  });
  const lingering = !noLingering();
  if ((!nudgePendingDone || !nudgeResponseReady) && lingering) {
    nudgePendingDone = await waitForPendingTeammateCalls(120000);
    nudgeResponseReady = await waitForTeammateResponse({
      initialCount: nudgeStart,
      callSiteId: callSiteId ?? undefined,
      timeoutMs: 120000,
    });
  }
  await waitForInputEnabled();
  return { pendingDone: nudgePendingDone, responseReady: nudgeResponseReady };
};

if (!alreadyAsked) {
  for (let i = 1; i <= 3; i += 1) {
    const nudgeState = await nudgeSubdialog(
      i,
      'Missing Type A supdialog call',
      'Reply ONLY with a Type A supdialog call using the primary syntax (NO `!topic`). ' +
        'Call format: `@super Which document file extensions should I include? I assume .md; should I include others like .txt or .rst?`',
    );
    pendingDone = nudgeState.pendingDone;
    responseReady = nudgeState.responseReady;
    const nudgeSnap = await snapshotDomindsUI();
    const nudgeMessages = nudgeSnap.chat?.visibleMessages || [];
    const askedNow = nudgeMessages.some((m) => m.type === 'teammate' && m.author === '@fuxi');
    if (askedNow) break;
  }
}

const subPost = await snapshotDomindsUI();
const delta = subPost.reportDeltaTo(subSnap);
const sidebarAfter = subPost.sidebar?.visibleNodeTitles || [];
const errors = checkConsoleErrors();

const subMessagesPost = subPost.chat?.visibleMessages || [];
const parentResponseMsg = subMessagesPost.find(
  (m) => m.type === 'teammate' && m.author === '@fuxi',
);
const parentResponseDetails =
  getTeammateResponseDetails()
    .slice()
    .reverse()
    .find((m) => m.authorName === '@fuxi') || null;
const responseNarrative = parentResponseDetails?.narrativeLine || '';
const responseCallHeadLine = parentResponseDetails?.callHeadLine || '';
const responseBody = parentResponseDetails?.responseBody || '';
const parentResponseLine =
  responseBody
    .split('\n')
    .map((line) => line.trim())
    .find((line) => line.length > 0) || '';
const responseNarrativeHasRoles =
  responseNarrative.startsWith('Hi @') && responseNarrative.includes('provided response');
const responseNarrativeHasHeadLine = responseCallHeadLine !== '';
const pendingDoneOk = pendingDone && (subPost.chat?.pendingTeammateCalls ?? 0) === 0;
const responseReadyOk = responseReady && Boolean(parentResponseMsg);

// 3. Ideal path: pangu already listed document files. Fallback only if missing.
const hasDocList = subMessagesPost.some(
  (m) =>
    (m.preview || '').includes('.md') ||
    (m.preview || '').includes('.txt') ||
    (m.preview || '').includes('.rst'),
);

let done = hasDocList;
let last2 = null;
let docListMsg = null;
if (!hasDocList) {
  for (let i = 1; i <= 3; i += 1) {
    await nudgeSubdialog(
      i,
      'Missing document list',
      'List the document files in the workspace using the extensions just clarified. ' +
        'Use exactly one tool call. Reply with the list only.',
    );
    const subPost2 = await snapshotDomindsUI();
    const subMessages2 = subPost2.chat?.visibleMessages || [];
    last2 = subMessages2[subMessages2.length - 1] || null;
    docListMsg =
      subMessages2
        .slice()
        .reverse()
        .find(
          (m) =>
            (m.preview || '').includes('.md') ||
            (m.preview || '').includes('.txt') ||
            (m.preview || '').includes('.rst'),
        ) || null;
    if (docListMsg) {
      done = true;
      break;
    }
  }
} else {
  docListMsg =
    subMessagesPost
      .slice()
      .reverse()
      .find(
        (m) =>
          (m.preview || '').includes('.md') ||
          (m.preview || '').includes('.txt') ||
          (m.preview || '').includes('.rst'),
      ) || null;
}

// Optional: persist key data for later scenarios when running in separate console evals.
window.__scenarioC = window.__scenarioC || {};
window.__scenarioC.c2 = {
  parentResponseLine,
  docListMsg,
};
```

**If the `@super` call site does NOT appear**, treat as testee non-compliance and use the
_Compliance Nudge Loop_ (up to 3 nudges). Example correction:

```
Correction: Reply ONLY with a Type A supdialog call (NO `!topic`): `@super Which document file extensions should I include? I assume .md; should I include others like .txt or .rst?` No other text.
```

**Pass Criteria (C2):**

- [ ] A teammate call site appears for `@super`
- [ ] `parentResponseMsg` exists in subdialog timeline (response bridged back)
- [ ] Parent response includes extension guidance (at least `.md`, optionally others)
- [ ] `responseNarrativeHasRoles === true` and `responseNarrativeHasHeadLine === true`
- [ ] `sidebarAfter` does **not** add a new `Subdialog:` row (Type A should not create one)
- [ ] Subdialog lists document files and `done === true` (visible output includes `.md` or specific extensions; use compliance nudges if needed)
- [ ] `pendingDoneOk === true` and `responseReadyOk === true`
- [ ] No console errors

**Note:** Keep `parentResponseLine` from C2 for C3, and `docListMsg` for C4.

**If the call site appears but `parentResponseMsg` is missing** after the extended wait,
treat as **infrastructure failure** (Type A response bridge broken).

**If the document list is missing** after the parent response, use the _Compliance Nudge Loop_ with:

```
Correction: List document files using the clarified extensions. Reply with the list only. No other text.
```

---

### Scenario C3: Verify the Parent Dialog Also Advanced

**Goal:** Ensure the supdialog produced a real assistant response and it matches what the subdialog received.

```javascript
// 1. Navigate back to supdialog
await navigateToParent();
await waitForInputEnabled();

const supSnap = await snapshotDomindsUI();
const supMessages = supSnap.chat?.visibleMessages || [];
const supdialogPromptMsg = findVisibleMessageContainingAll(
  ['during processing your original assignment', '@pangu', '@fuxi'],
  { caseInsensitive: true },
);
const supdialogPromptOk = Boolean(supdialogPromptMsg);

// 2. Basic consistency check
const storedLine =
  window.__scenarioC && window.__scenarioC.c2 ? window.__scenarioC.c2.parentResponseLine : '';
const responseDetails = getTeammateResponseDetails();
const parentResponseDetails = responseDetails
  .slice()
  .reverse()
  .find((m) => m.authorName === '@fuxi');
const subResponsePreview = parentResponseDetails?.responseBody || '';
const derivedLine =
  subResponsePreview
    .split('\n')
    .map((line) => line.trim())
    .find((line) => line.length > 0) || '';
const subResponseLine = storedLine || derivedLine;
const normalizedLine = subResponseLine.replace(/`/g, '');
const extTokens = normalizedLine.match(/\.[a-z0-9]+/gi) || [];
const matchTokens = extTokens.length > 0 ? extTokens : [];
const supMatchMsg =
  matchTokens.length > 0
    ? findVisibleMessageContainingAll(matchTokens, { caseInsensitive: false })
    : null;
const supMatchPreview = supMatchMsg?.preview?.slice(0, 60) || '';
const previewsMatch = matchTokens.length > 0 && Boolean(supMatchMsg);

const errors = checkConsoleErrors();
```

**Pass Criteria (C3):**

- [ ] `supdialogPromptOk === true` (subdialog prompt present with `@pangu requests:`)
- [ ] `supMatchMsg` exists (parent response visible somewhere in the timeline)
- [ ] `previewsMatch === true` (subdialog received the same parent response text)
- [ ] No console errors

---

### Scenario C4: Parent Receives Subdialog Result and Continues

**Goal:** After the pangu subdialog uses the parent's clarification and emits the final doc list,
verify the supdialog receives that subdialog response and continues the original request using it.

```javascript
// 1. Ensure supdialog is active (C3 already navigated here)
await navigateToParent();
await waitForInputEnabled();

const supBefore = await snapshotDomindsUI();
const beforeCount = supBefore.chat?.visibleMessageCount || 0;
const storedDocListMsg =
  window.__scenarioC && window.__scenarioC.c2 ? window.__scenarioC.c2.docListMsg : null;
const resolvedDocListMsg = storedDocListMsg || docListMsg;
const docPreviewLine =
  (resolvedDocListMsg?.preview || '')
    .split('\n')
    .map((line) => line.trim())
    .find((line) => /\.[a-z0-9]+$/i.test(line)) || '';

// 2. Wait for the subdialog completion message to surface in the parent
await waitUntil(async () => {
  const snap = await snapshotDomindsUI();
  const messages = snap.chat?.visibleMessages || [];
  const hasCmdrResult = messages.some((m) => m.type === 'teammate' && m.author === '@pangu');
  const countIncreased = (snap.chat?.visibleMessageCount || 0) > beforeCount;
  return hasCmdrResult || countIncreased;
}, 60000);

const supPost = await snapshotDomindsUI();
const supMessages = supPost.chat?.visibleMessages || [];
const cmdrResultMsg = supMessages.find((m) => m.type === 'teammate' && m.author === '@pangu');
const cmdrResultMatch =
  docPreviewLine.length > 0
    ? findVisibleMessageContainingAll([docPreviewLine], {
        caseInsensitive: false,
      })
    : null;
const cmdrResultOk = Boolean(cmdrResultMatch);

// 3. Verify the parent continues using the subdialog result
const cmdrIndex = cmdrResultMatch ? cmdrResultMatch.index : -1;
const visibleTexts = getVisibleMessageTexts();
const followupText =
  cmdrIndex >= 0
    ? visibleTexts.slice(cmdrIndex + 1).find((text) => text.includes(docPreviewLine))
    : '';
const usesDocInfo = docPreviewLine.length > 0 ? Boolean(followupText) : cmdrIndex >= 0;

const errors = checkConsoleErrors();
```

**Pass Criteria (C4):**

- [ ] `cmdrResultMsg` exists (parent received the subdialog response)
- [ ] `cmdrResultOk === true` (parent shows at least one line from `docListMsg`)
- [ ] `supFollowupMsg` exists and `usesDocInfo === true` (parent is driven further using subdialog info)
- [ ] No console errors

**If `cmdrResultMsg` is missing** after the wait, treat as **infrastructure failure**
(subdialog completion not bridged to parent).

**If the parent does not continue** after receiving the result, use the _Compliance Nudge Loop_:

```
Correction: Use the pangu subdialog's document list to answer the original request. Reply with the list only.
Do NOT create any new teammate calls (do not call `@pangu` again) and do NOT run tools. Use the already-visible `@pangu` response bubble above as the source of truth, and output only the file list.
```

---

## Quick Reference: The Standard Pattern

```javascript
// OBSERVE → ACT → REPEAT
const baseline = await snapshotDomindsUI();
const teammateStart = getTeammateMessageCount();
const callSiteBefore = getLatestTeammateCallSiteId();

// ACT
const msgId = await fillAndSend('prompt here');
const callSiteId = await waitForTeammateCallSiteId({
  after: callSiteBefore,
  firstMention: '@pangu',
});
let pendingDone = await waitForPendingTeammateCalls();
let responseReady = await waitForTeammateResponse({
  initialCount: teammateStart,
  callSiteId: callSiteId ?? undefined,
});
const lingering = !noLingering();
if ((!pendingDone || !responseReady) && lingering) {
  pendingDone = await waitForPendingTeammateCalls(120000);
  responseReady = await waitForTeammateResponse({
    initialCount: teammateStart,
    callSiteId: callSiteId ?? undefined,
    timeoutMs: 120000,
  });
}
await waitForInputEnabled();

// OBSERVE
const post = await snapshotDomindsUI();
const delta = post.reportDeltaTo(baseline);

// VERIFY
const state = {
  inputEnabled: post.input?.textareaEnabled,
  visibleMessageCount: post.chat?.visibleMessageCount,
  pendingCalls: post.chat?.pendingTeammateCalls,
  pendingDone,
  responseReady,
};

// CHECK ERRORS
const errors = checkConsoleErrors();
```

---

## Teardown / Cleanup

Always finish with a deterministic cleanup check:

```javascript
const lingering = !noLingering();
const pendingCalls = getPendingTeammateCalls();
const errors = checkConsoleErrors();
```

**Expected:**

- `lingering === false`
- `pendingCalls.length === 0`
- `errors.length === 0`

If any of these fail, treat as infrastructure failure.

---

## Success Criteria Summary

| Scenario            | What Dominds Must Do                                               |
| ------------------- | ------------------------------------------------------------------ |
| A1 (TYPE C)         | Create transient subdialog, complete immediately, return to parent |
| B1 (TYPE B)         | Create registered subdialog, register with topic key               |
| B2 (TYPE B resume)  | Resume same subdialog (not recreate), preserve context             |
| B3 (TYPE B context) | Maintain context across all calls, testee can reference history    |
| C1–C4 (Type A)      | Subdialog calls parent, response bridged, no extra subdialog       |
| Teardown            | `noLingering()` true and `pendingTeammateCalls === 0`              |

---

## What Constitutes Infrastructure Failure

| Symptom                                 | Likely Cause                       |
| --------------------------------------- | ---------------------------------- |
| Dialog title never changes after create | Dialog not selected                |
| Input stays disabled                    | Dialog not fully loaded            |
| Subdialog hierarchy keeps growing       | Transient subdialog not completing |
| Messages don't appear after send        | WebSocket/routing issue            |
| Console errors appear                   | Protocol/infrastructure bug        |

**Rule of thumb:** If the UI doesn't reflect what should happen → dominds bug. If the testee gives wrong answer → testee issue (not a bug).
