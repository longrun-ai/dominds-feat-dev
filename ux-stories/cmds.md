# Dominds WebUI E2E: Shell Commands via @pangu - For e2e-browser-tester Agent

You are the **tester agent** standing in for a human user. Your role is to validate that **dominds** provides flawless agentic infrastructure for shell command execution and daemon tracking. The testee should **cooperate** with your directions to help validate dominds features.

## The Test Purpose

This test validates **dominds infrastructure**, not the testee agent's performance.

- The testee (typically `@pangu`) is a reasonable LLM-powered AI agent. It should **cooperate with your instructions** to exercise dominds features, but may still make mistakes, miss tool calls, or deviate (as all LLMs do).
- **Dominds must work flawlessly** regardless of testee behavior - providing reliable tool routing, proper daemon tracking, and UX that lets YOU guide the testee to success
- Your job: verify dominds enables you to nudge, correct, and guide the testee toward achieving business goals

## Business Goal

**Fluent autonomous OS process management via shell process control.**

The testee, when properly guided, must be able to:

- Execute foreground shell commands and get immediate output
- Start long-running processes that become tracked daemons
- Verify daemon output in real-time
- Terminate tracked daemons cleanly

## Your Tester Agent Principles

1. **Test dominds, not the testee** - The testee should cooperate; if it errs, verify dominds infrastructure handles it
2. **Observe like a human** - Don't poll, don't guess; look at what the UI shows and reason about it
3. **Diagnose before acting** - Check console errors, then verify tool calls and UI state
4. **Fail fast** - Detect infrastructure issues immediately; testee errors are expected

---

## Tester Hardening Rules

- **Assert infra, not prose** - Pass/fail must be based on UI state + tool-call bubbles, not the testee’s summary.
- **Time-bound every step** - If `waitStreamingComplete()` does not resolve within the allowed timeout, treat as infra failure.
- **One retry, tool-formatted only** - If the tool call is missing or wrong, immediately send the explicit tool-formatted prompt and move on.
- **Check console errors after every action** - Catch silent UI/protocol breakage early.
- **Control noise** - Exclude `node_modules` and limit output size to keep results stable.
- **Always teardown** - Confirm `noLingering()` and `getRemindersCount() === 0` before finishing.
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
  visibleSidebar: snap.sidebar?.visibleNodeTitles,
};

// 4. ACT - send prompt or click
const msgId = await fillAndSend('your prompt here');

// 5. WAIT - when you expect a response
let completed = await waitStreamingComplete(msgId);
const lingering = !noLingering();
if (!completed && lingering) {
  completed = await waitStreamingComplete(msgId, 120000);
}
await waitForInputEnabled();
// If completed is false, treat as infra failure.

// 6. REPEAT - capture post-action state
const post = await snapshotDomindsUI();
const postDelta = post.reportDeltaTo(snap);
```

**Generation completion rule:** rely on `.generation-bubble.completed` markers (via
`waitStreamingComplete()` / `noLingering()`). Only extend waits when incomplete
generation bubbles remain.

**Per-step UI observations to capture:**

- Sidebar visible nodes from `snap.sidebar.visibleNodeTitles` (prefixed with `Task:`/`Dialog:`/`Subdialog:`)
- Sidebar selection from `snap.sidebar.selectedDialogTitle`
- Pending teammate tellasks from `snap.chat.pendingTeammateCalls`
- Input enabled state from `snap.input.textareaEnabled`
- Visible message count from `snap.chat.visibleMessageCount`
- Visible chat timeline from `snap.chat.visibleMessages`

`reportDeltaTo()` will include `Sidebar visible: ...` and `Visible messages: ...` when those counts change.

**Fallback: No Responder Message**

If the responder never appears and `noLingering()` shows no active generation, send a
short retry with an explicit tool-formatted prompt. If the retry also yields no response
and there are no console errors, treat it as an infrastructure failure.

```javascript
const retryId = await fillAndSend('shell_cmd command="..." ...');
let retryDone = await waitStreamingComplete(retryId);
const retryLingering = !noLingering();
if (!retryDone && retryLingering) {
  retryDone = await waitStreamingComplete(retryId, 120000);
}
await waitForInputEnabled();
```

**Fallback: Missing or Wrong Tool Call**

If the testee responds without the correct tool call, do **one** immediate retry using
the explicit tool-formatted prompt and then proceed. Do not keep prompting.

```javascript
const toolCall = detectFuncCall('shell_cmd');
if (!toolCall.hasFuncCall) {
  const retryId = await fillAndSend('shell_cmd command="..."');
  let retryDone = await waitStreamingComplete(retryId);
  const retryLingering = !noLingering();
  if (!retryDone && retryLingering) {
    retryDone = await waitStreamingComplete(retryId, 120000);
  }
  await waitForInputEnabled();
}
```

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

---

## Essential Helper Reference

| Helper                          | Purpose                                                     |
| ------------------------------- | ----------------------------------------------------------- |
| `snapshotDomindsUI()`           | Returns `DomindsUI` snapshot instance (shorthand)           |
| `DomindsUI.reportDeltaTo(prev)` | Compare snapshots, returns delta string                     |
| `fillAndSend(msg)`              | Send prompt to testee                                       |
| `waitStreamingComplete(id)`     | Waits for the response bubble to complete                   |
| `waitForInputEnabled()`         | Optional: wait when dialog selection is uncertain           |
| `detectFuncCall(toolName)`      | Detect the most recent tool call bubble                     |
| `noLingering()`                 | True when no incomplete generation bubbles remain           |
| `waitForRemindersCount(n)`      | Wait until reminders count matches `n`                      |
| `getRemindersCount()`           | Get current reminders count                                 |
| `waitUntil(fn, timeoutMs)`      | Poll until condition is true (use for daemon timeouts)      |
| `createDialog(taskDoc, agent?)` | Create new dialog (agent optional - uses default responder) |
| `checkConsoleErrors()`          | Check for infrastructure errors                             |
| `selectDialog(title)`           | Select dialog from sidebar (await this; handles lazy loads) |

---

## Part A: Foreground Shell Commands

### Before You Begin

Create a fresh dialog with `@pangu` as the responder:

```javascript
const baseline = await snapshotDomindsUI();
await createDialog('cmds-test.tsk', '@pangu');
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

- `ready.dialogTitle` includes `cmds-test.tsk`
- `ready.inputEnabled === true`
- `ready.visibleMessageCount === 0`
- `bootErrors.length === 0`

If these conditions aren't met -> dominds infrastructure bug, stop.

**UI observation (post-create):**

- Sidebar visible list includes `Task: cmds-test.tsk` and a single `Dialog: @...` row
- Sidebar selection matches `snap.currentDialog.title`
- Chat area shows no pending teammate tellasks and no messages

---

## Calibration Gate: Explain the Test Setup Before Running Scenarios

**Goal:** Ensure the testee understands that it should cooperate and use shell tool calls exactly as instructed.

**Important:** Avoid starting a line at column 0 with `!?@` here to prevent unintended teammate tellasks. Use words like “Pangu” instead of `!?@pangu`.

```javascript
const msgId = await fillAndSend(
  'Calibration: You are the testee in a dominds shell-command infrastructure test. ' +
    'Reply ONLY with the three bullets below, verbatim. Do not add anything else. ' +
    'Do not call any teammates or tools. Avoid the !?@ prefix.\n' +
    '- I will follow the test instructions exactly.\n' +
    '- I will only run shell commands when explicitly instructed.\n' +
    '- I will use exactly one shell command when requested.',
);
let completed = await waitStreamingComplete(msgId, 120000);
const lingering = !noLingering();
if (!completed && lingering) {
  completed = await waitStreamingComplete(msgId, 120000);
}
await waitForInputEnabled();
const preflightPost = await snapshotDomindsUI();
const preflightErrors = checkConsoleErrors();
```

**Pass Criteria (Calibration):**

- [ ] Response explicitly acknowledges cooperation with test instructions
- [ ] Response mentions “one shell command only” (or equivalent) and no extra steps
- [ ] Response avoids teammate tellasks (no new `Subdialog:` rows added)
- [ ] `preflightErrors.length === 0` and `completed === true`

**If the calibration fails:** **STOP** the test run and write a short advisory (see below). Do not proceed to Part A.

**Advisory template (use if calibration fails):**

- Suggest stronger prompt constraints, e.g. “Do not call any teammates or tools unless explicitly asked; never emit the !?@ prefix or !topic.”
- Suggest a single-sentence checklist that the testee must repeat verbatim before proceeding.
- Suggest adding a final confirmation question: “Do you agree? Reply only with ‘YES’.”

---

### Scenario A1: `ls -la`

**Goal:** Validate `shell_cmd` for a foreground command. Instruct the testee to cooperate and use the exact tool call.

```javascript
const pre = await snapshotDomindsUI();
const msgId = await fillAndSend(
  'Cooperate with the test: use shell_cmd with command="ls -la" to list all files. ' +
    'Use only one shell_cmd call, no extra commands. Then summarize the output.',
);

let completed = await waitStreamingComplete(msgId);
const lingering = !noLingering();
if (!completed && lingering) {
  completed = await waitStreamingComplete(msgId, 120000);
}
await waitForInputEnabled();

const post = await snapshotDomindsUI();
const delta = post.reportDeltaTo(pre);
const errors = checkConsoleErrors();
const toolCall = detectFuncCall('shell_cmd');

if (!toolCall.hasFuncCall) {
  const retryId = await fillAndSend('shell_cmd command="ls -la"');
  let retryDone = await waitStreamingComplete(retryId);
  const retryLingering = !noLingering();
  if (!retryDone && retryLingering) {
    retryDone = await waitStreamingComplete(retryId, 120000);
  }
  await waitForInputEnabled();
}
```

**Verification:**

```javascript
const toolMessages = (post.chat?.visibleMessages || []).filter((m) => m.hasFuncCall);
const lastTool = toolMessages[toolMessages.length - 1] || null;
const verification = {
  completed,
  toolCall,
  lastToolFunc: lastTool?.funcName,
  genPreview: post.chat?.latestMessage?.markdownPreview?.slice(0, 120),
};
```

**Expected verification values:**

- `completed === true`
- `toolCall.hasFuncCall === true` or `lastToolFunc === 'shell_cmd'`
- `errors.length === 0`
- Output summary visible in chat (file listing)

If `hasFuncCall === false`, immediately send the explicit tool-formatted prompt (`shell_cmd command="ls -la"`). Do not keep re-prompting.

---

### Scenario A2: `find ... "*.md"` (noise-controlled)

**Goal:** Validate `shell_cmd` with escaped quotes while limiting output noise. Instruct the testee to cooperate and use the exact tool call.

```javascript
const pre = await snapshotDomindsUI();
const msgId = await fillAndSend(
  'Cooperate with the test: use shell_cmd with command="find dominds ux-stories -type f -name \\"*.md\\" -not -path \\"*/node_modules/*\\" | head -n 40" ' +
    'to find markdown files (exclude node_modules) and limit output. Use only one shell_cmd call.',
);

let completed = await waitStreamingComplete(msgId);
const lingering = !noLingering();
if (!completed && lingering) {
  completed = await waitStreamingComplete(msgId, 120000);
}
await waitForInputEnabled();

const post = await snapshotDomindsUI();
const errors = checkConsoleErrors();
const toolCall = detectFuncCall('shell_cmd');
const toolMessages = (post.chat?.visibleMessages || []).filter((m) => m.hasFuncCall);
const lastTool = toolMessages[toolMessages.length - 1] || null;

if (!toolCall.hasFuncCall) {
  const retryId = await fillAndSend(
    'shell_cmd command="find dominds ux-stories -type f -name \\"*.md\\" -not -path \\"*/node_modules/*\\" | head -n 40"',
  );
  let retryDone = await waitStreamingComplete(retryId);
  const retryLingering = !noLingering();
  if (!retryDone && retryLingering) {
    retryDone = await waitStreamingComplete(retryId, 120000);
  }
  await waitForInputEnabled();
}
```

**Expected:**

- `completed === true`
- `toolCall.hasFuncCall === true` or `lastTool?.funcName === 'shell_cmd'`
- Markdown file paths appear in the response (limited output, no node_modules)
- `errors.length === 0`

---

### Scenario A3: `rg -n Truncate dominds/webapp/src`

**Goal:** Validate `shell_cmd` search command output. Instruct the testee to cooperate and use the exact tool call.

```javascript
const pre = await snapshotDomindsUI();
const msgId = await fillAndSend(
  'Cooperate with the test: use shell_cmd with command="rg -n Truncate dominds/webapp/src" to search for Truncate. ' +
    'Use only one shell_cmd call. Summarize the results.',
);

let completed = await waitStreamingComplete(msgId);
const lingering = !noLingering();
if (!completed && lingering) {
  completed = await waitStreamingComplete(msgId, 120000);
}
await waitForInputEnabled();

const post = await snapshotDomindsUI();
const errors = checkConsoleErrors();
const toolCall = detectFuncCall('shell_cmd');
const toolMessages = (post.chat?.visibleMessages || []).filter((m) => m.hasFuncCall);
const lastTool = toolMessages[toolMessages.length - 1] || null;

if (!toolCall.hasFuncCall) {
  const retryId = await fillAndSend('shell_cmd command="rg -n Truncate dominds/webapp/src"');
  let retryDone = await waitStreamingComplete(retryId);
  const retryLingering = !noLingering();
  if (!retryDone && retryLingering) {
    retryDone = await waitStreamingComplete(retryId, 120000);
  }
  await waitForInputEnabled();
}
```

**Expected:**

- `completed === true`
- `toolCall.hasFuncCall === true` or `lastTool?.funcName === 'shell_cmd'`
- Search results visible in the response (or explicit "no matches" summary; exit code 1 is acceptable)
- `errors.length === 0`

---

### Scenario A4: Negative Path (missing daemon)

**Goal:** Validate error surfacing and UI responsiveness when a valid tool call fails.

```javascript
const pre = await snapshotDomindsUI();
const msgId = await fillAndSend(
  'Cooperate with the test: stop_daemon pid=999999. Use only one stop_daemon call and report the error.',
);

let completed = await waitStreamingComplete(msgId);
const lingering = !noLingering();
if (!completed && lingering) {
  completed = await waitStreamingComplete(msgId, 120000);
}
await waitForInputEnabled();

const post = await snapshotDomindsUI();
const errors = checkConsoleErrors();
const toolCall = detectFuncCall('stop_daemon');
```

**Expected:**

- `completed === true`
- `toolCall.hasFuncCall === true`
- Tool result indicates no daemon found (error bubble is visible)
- Input remains enabled
- `errors.length === 0`

---

## Part B: Daemon Lifecycle

### Scenario B0: Create Daemon Source File

**Goal:** Ensure `/tmp/msgque.txt` exists before tailing.

```javascript
const pre = await snapshotDomindsUI();
const msgId = await fillAndSend(
  'Cooperate with the test: shell_cmd command=": > /tmp/msgque.txt && ls -la /tmp/msgque.txt". ' +
    'Use only one shell_cmd call and confirm the file exists.',
);

let completed = await waitStreamingComplete(msgId);
const lingering = !noLingering();
if (!completed && lingering) {
  completed = await waitStreamingComplete(msgId, 120000);
}
await waitForInputEnabled();

const post = await snapshotDomindsUI();
const errors = checkConsoleErrors();
const toolCall = detectFuncCall('shell_cmd');

if (!toolCall.hasFuncCall) {
  const retryId = await fillAndSend(
    'shell_cmd command=": > /tmp/msgque.txt && ls -la /tmp/msgque.txt"',
  );
  let retryDone = await waitStreamingComplete(retryId);
  const retryLingering = !noLingering();
  if (!retryDone && retryLingering) {
    retryDone = await waitStreamingComplete(retryId, 120000);
  }
  await waitForInputEnabled();
}
```

**Expected:**

- `completed === true`
- `toolCall.hasFuncCall === true`
- `errors.length === 0`

---

### Scenario B1: Start Long-Running Daemon

**Goal:** Start `tail -f /tmp/msgque.txt` as a tracked daemon.

```javascript
const pre = await snapshotDomindsUI();
const msgId = await fillAndSend(
  'Cooperate with the test: shell_cmd command="tail -f /tmp/msgque.txt" timeoutSeconds=30. ' +
    'Use only one shell_cmd call and report the PID you receive.',
);

let completed = await waitStreamingComplete(msgId);
const lingering = !noLingering();
if (!completed && lingering) {
  completed = await waitStreamingComplete(msgId, 120000);
}
await waitForInputEnabled();
const remindersReady = await waitUntil(() => getRemindersCount() === 1, 45000);

const post = await snapshotDomindsUI();
const errors = checkConsoleErrors();
const toolCall = detectFuncCall('shell_cmd');
const toolMessages = (post.chat?.visibleMessages || []).filter((m) => m.hasFuncCall);
const lastTool = toolMessages[toolMessages.length - 1] || null;

if (!toolCall.hasFuncCall) {
  const retryId = await fillAndSend(
    'shell_cmd command="tail -f /tmp/msgque.txt" timeoutSeconds=30',
  );
  let retryDone = await waitStreamingComplete(retryId);
  const retryLingering = !noLingering();
  if (!retryDone && retryLingering) {
    retryDone = await waitStreamingComplete(retryId, 120000);
  }
  await waitForInputEnabled();
}
```

**Expected:**

- `completed === true`
- `toolCall.hasFuncCall === true` or `lastTool?.funcName === 'shell_cmd'`
- Response includes a PID
- If the testee does not report a PID, read it from the tool-call result or reminders widget
- `errors.length === 0`
- `remindersReady === true`

**UI observation (daemon tracking):**

- Toolbar reminders badge increments (non-zero)
- Reminders widget shows a daemon entry with the PID you received

If the reminders widget does not update after a daemon is started, treat it as infrastructure failure.

---

### Scenario B2: Append to the Daemon Source File

```javascript
const pre = await snapshotDomindsUI();
const msgId = await fillAndSend(
  'Cooperate with the test: shell_cmd command="echo hello 12345 >> /tmp/msgque.txt". ' +
    'Use only one shell_cmd call and confirm the write completed.',
);

let completed = await waitStreamingComplete(msgId);
const lingering = !noLingering();
if (!completed && lingering) {
  completed = await waitStreamingComplete(msgId, 120000);
}
await waitForInputEnabled();

const post = await snapshotDomindsUI();
const errors = checkConsoleErrors();
const toolCall = detectFuncCall('shell_cmd');
const toolMessages = (post.chat?.visibleMessages || []).filter((m) => m.hasFuncCall);
const lastTool = toolMessages[toolMessages.length - 1] || null;

if (!toolCall.hasFuncCall) {
  const retryId = await fillAndSend('shell_cmd command="echo hello 12345 >> /tmp/msgque.txt"');
  let retryDone = await waitStreamingComplete(retryId);
  const retryLingering = !noLingering();
  if (!retryDone && retryLingering) {
    retryDone = await waitStreamingComplete(retryId, 120000);
  }
  await waitForInputEnabled();
}
```

**Expected:**

- `completed === true`
- `toolCall.hasFuncCall === true` or `lastTool?.funcName === 'shell_cmd'`
- `errors.length === 0`

---

### Scenario B3: Read Daemon Output

```javascript
// Replace <PID> with the daemon PID from B1
const pre = await snapshotDomindsUI();
const msgId = await fillAndSend(
  'Cooperate with the test: get_daemon_output pid=<PID>. Use only one get_daemon_output call and summarize what you see.',
);

let completed = await waitStreamingComplete(msgId);
const lingering = !noLingering();
if (!completed && lingering) {
  completed = await waitStreamingComplete(msgId, 120000);
}
await waitForInputEnabled();

const post = await snapshotDomindsUI();
const errors = checkConsoleErrors();
const toolCall = detectFuncCall('get_daemon_output');
const toolMessages = (post.chat?.visibleMessages || []).filter((m) => m.hasFuncCall);
const lastTool = toolMessages[toolMessages.length - 1] || null;

if (!toolCall.hasFuncCall) {
  const retryId = await fillAndSend('get_daemon_output pid=<PID>');
  let retryDone = await waitStreamingComplete(retryId);
  const retryLingering = !noLingering();
  if (!retryDone && retryLingering) {
    retryDone = await waitStreamingComplete(retryId, 120000);
  }
  await waitForInputEnabled();
}
```

**Expected:**

- `completed === true`
- `toolCall.hasFuncCall === true` or `lastTool?.funcName === 'get_daemon_output'`
- Response includes the appended `hello 12345` line
- `errors.length === 0`

---

### Scenario B4: stop_daemon

```javascript
// Use the same PID from B1
const pre = await snapshotDomindsUI();
const msgId = await fillAndSend(
  'Cooperate with the test: stop_daemon pid=<PID>. Use only one stop_daemon call and confirm it was terminated.',
);

let completed = await waitStreamingComplete(msgId);
const lingering = !noLingering();
if (!completed && lingering) {
  completed = await waitStreamingComplete(msgId, 120000);
}
await waitForInputEnabled();

const post = await snapshotDomindsUI();
const errors = checkConsoleErrors();
const toolCall = detectFuncCall('stop_daemon');
const toolMessages = (post.chat?.visibleMessages || []).filter((m) => m.hasFuncCall);
const lastTool = toolMessages[toolMessages.length - 1] || null;

if (!toolCall.hasFuncCall) {
  const retryId = await fillAndSend('stop_daemon pid=<PID>');
  let retryDone = await waitStreamingComplete(retryId);
  const retryLingering = !noLingering();
  if (!retryDone && retryLingering) {
    retryDone = await waitStreamingComplete(retryId, 120000);
  }
  await waitForInputEnabled();
}
```

**Expected:**

- `completed === true`
- `toolCall.hasFuncCall === true` or `lastTool?.funcName === 'stop_daemon'`
- `errors.length === 0`

**UI observation (daemon tracking):**

- Reminders widget is empty (no daemon reminders)
- Toolbar reminders badge returns to 0

---

## Teardown / Cleanup

Always finish with a deterministic cleanup check:

```javascript
const lingering = !noLingering();
const remindersLeft = getRemindersCount();
const errors = checkConsoleErrors();
```

**Expected:**

- `lingering === false`
- `remindersLeft === 0`
- `errors.length === 0`

If any of these fail, treat as infrastructure failure.

---

## Quick Reference: The Standard Pattern

```javascript
// OBSERVE -> ACT -> REPEAT
const baseline = await snapshotDomindsUI();

// ACT
const msgId = await fillAndSend('prompt here');
let completed = await waitStreamingComplete(msgId);
const lingering = !noLingering();
if (!completed && lingering) {
  completed = await waitStreamingComplete(msgId, 120000);
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
  completed,
};

// CHECK ERRORS
const errors = checkConsoleErrors();
```

---

## Success Criteria Summary

| Scenario          | What Dominds Must Do                                                |
| ----------------- | ------------------------------------------------------------------- |
| A1-A3             | Execute `shell_cmd` and return output reliably                      |
| A4 (negative)     | Surface clear error bubble, keep input enabled                      |
| B1 (start daemon) | Track daemon, show PID, update reminders widget                     |
| B2 (append)       | Accept writes that feed the daemon output stream                    |
| B3 (output)       | Return live daemon output via `get_daemon_output`                   |
| B4 (stop daemon)  | Terminate daemon and clear reminders tracking                       |
| Teardown          | `noLingering()` true and `getRemindersCount() === 0` with no errors |

---

## What Constitutes Infrastructure Failure

| Symptom                                 | Likely Cause                    |
| --------------------------------------- | ------------------------------- |
| Dialog title never changes after create | Dialog not selected             |
| Input stays disabled                    | Dialog not fully loaded         |
| Messages don't appear after send        | WebSocket/routing issue         |
| Reminders widget does not update        | Daemon tracking UI not updating |
| Console errors appear                   | Protocol/infrastructure bug     |
| `waitStreamingComplete()` times out     | Streaming/completion regression |

**Rule of thumb:** If the UI doesn't reflect what should happen -> dominds bug. If the testee gives wrong answer -> testee issue (not a bug).
