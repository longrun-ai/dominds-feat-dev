# Dominds WebUI E2E: `change_mind` (Task Doc Update) — Brainstorming UX

Validate that Dominds’ function tool `change_mind` behaves correctly for the **testee agent** during exploratory work (brainstorming / ideation), where requirements evolve quickly and task-doc edits are frequent.

This story is **semantic** (human judgment + UI observation). No strict text equality checks are required, but the tester and testee should verify that the behavior matches the intent.

## Key Semantics Under Test

1. **No round reset**: `change_mind` must **not** start a new dialog round and must **not** clear messages/Q4H/reminders by itself.
2. **Encapsulated task packages (`*.tsk/`)**:
   - The task doc lives in a directory ending in `.tsk/`.
   - `change_mind` must target **exactly one** section: `!goals | !constraints | !progress`.
   - A successful call replaces the entire target section contents (no patch semantics).
3. **Safety**:
   - Missing/invalid selector is rejected for `*.tsk/`.
   - Empty body is rejected (to prevent accidental clearing).
   - General file tools must not read/write/list/delete anything under `*.tsk/` (encapsulation policy).

## Setup

- Create a fresh dialog using a dedicated task package:
  - `brainstorming-test.tsk/`
- Ensure the testee is in the **root dialog** (not a subdialog), since `change_mind` is root-only.

## Observations to Capture (Human-Readable)

After each step, the tester should note:

- Current round indicator did/did not change.
- Whether earlier chat messages are still visible (no timeline wipe).
- Whether the task doc changed **in the right section**.
- Whether the tool bubble shows success/failure appropriately.
- If multiple `change_mind` calls were issued in a single turn: verify there is one tool bubble per call, and that each updated section matches its corresponding content (no “cross-write” between sections).

Note: The current WebUI does not render `*.tsk/` task-doc panes (Goals/Constraints/Progress). For now, validate section
updates by inspecting the workspace files (e.g., `brainstorming-test.tsk/goals.md`, `constraints.md`, `progress.md`).

If you run with the E2E helpers, keep the evidence lightweight:

- Confirm round string before/after.
- Confirm task doc content visible contains the new ideas (not exact match).
- Confirm constraints/progress unchanged when only goals were edited (and vice versa).

## Scenario 1: Update Goals (Happy Path)

**Intent**: During brainstorming, you refine _what you want_ (Goals) without changing constraints or wiping the conversation.

### Steps

1. Tester: Instruct the testee to call `change_mind` with a short “brainstormed” goals list.
2. Testee: Issues exactly one `change_mind` function tool call with non-empty `content`.
3. Tester: Verify in UI:
   - Round did **not** change.
   - Messages were **not** cleared.
   - Task doc “Goals” content is replaced and reflects the new goals semantically.
   - “Constraints” and “Progress” still reflect their previous state.

### Example (not strict)

```text
Call the function tool `change_mind` with:
{ "selector": "!goals", "content": "- Explore 3 product directions.\\n- Pick 1 direction with clear success criteria.\\n" }
```

### Pass Conditions (semantic)

- Task doc “Goals” clearly reflects the new list.
- No round reset / no prompt injection / no timeline wipe.

## Scenario 2: Update Constraints (Happy Path)

**Intent**: You discover hard constraints during brainstorming (e.g., “no web browsing”, “must be under 10 lines”, “must not touch prod”).

### Steps

1. Tester: Instruct the testee to call `change_mind` with 3–6 crisp constraints.
2. Verify:
   - Round did not change.
   - Task doc “Constraints” is replaced.
   - Goals/Progress remain unchanged.

## Scenario 3: Update Progress (Happy Path)

**Intent**: You record decisions made so far without rewriting the plan or constraints.

### Steps

1. Tester: Instruct the testee to call `change_mind` to record 2–5 bullet updates.
2. Verify:
   - Round did not change.
   - Progress is replaced.
   - Goals/Constraints remain unchanged.

## Scenario 4: Update Multiple Sections in One Message (Batch Happy Path)

**Intent**: In a single turn, the testee updates **multiple** task-doc sections by issuing multiple `change_mind` calls (one per section). This validates the WebUI/tooling behavior when the user wants to “batch apply” a set of edits without multiple sends.

Important: `*.tsk/` still enforces **one selector per `change_mind` call**. This scenario is about issuing multiple calls in a single turn, not adding a multi-selector feature to the tool.

### Steps

1. Tester: Ask the testee to perform **three** `change_mind` calls in a single turn: `!goals`, `!constraints`, and `!progress`.
2. Verify in UI:
   - Round did **not** change.
   - Messages were **not** cleared.
   - There are **three** tool bubbles (one per `change_mind` call), and all are successful.
3. Verify in workspace files:
   - `brainstorming-test.tsk/goals.md` reflects the new goals body.
   - `brainstorming-test.tsk/constraints.md` reflects the new constraints body.
   - `brainstorming-test.tsk/progress.md` reflects the new progress body.
   - No cross-writes (e.g., constraints text ending up in goals).

### Example (one message; not strict)

```text
Call the function tool `change_mind` with:
{ "selector": "!goals", "content": "- Explore 3 product directions.\\n- Pick 1 direction with clear success criteria.\\n" }

Call the function tool `change_mind` with:
{ "selector": "!constraints", "content": "- No web browsing.\\n- Keep changes under 10 lines per file.\\n- Don’t touch prod.\\n" }

Call the function tool `change_mind` with:
{ "selector": "!progress", "content": "- Chose Option B as the leading direction.\\n- Defined success criteria draft.\\n" }
```

### Pass Conditions (semantic)

- All three sections are updated to the intended content, and the UI shows three successful tool executions.
- No round reset / no timeline wipe.

## Scenario 5: Failure Modes (Safety)

These should fail safely, with no partial edits.

### A) Missing selector on `*.tsk/`

- Testee attempts:
  - `change_mind({ "content": "..." })` (missing selector)
- Expect:
  - Tool call fails with a clear error
  - No task doc section changes
  - Round does not change

### B) Invalid selector

- Testee attempts:
  - `change_mind({ "selector": "!goalz", "content": "..." })` (invalid selector)
- Expect:
  - Tool call fails with “invalid selector”
  - No task doc section changes

### C) Empty body

- Testee attempts:
  - `change_mind({ "selector": "!goals", "content": "" })` (empty body)
- Expect:
  - Tool call fails (content required)
  - No task doc section changes

## Optional Scenario 6: Encapsulation Guardrail

This validates that the _only_ way to edit `*.tsk/` is via `change_mind` (not file tools).

### Steps

1. Tester: Ask the testee to attempt a file-tool read/list on `*.tsk/` (e.g., call function tool `read_file` with `{ "path": "brainstorming-test.tsk/goals.md" }`, or call `list_dir` with `{ "path": "brainstorming-test.tsk" }`).
2. Expect:
   - Access denied (encapsulation policy)
   - No task doc changes

## Scripted Run (Pseudo-JS, Not Strict)

Use this only if you’re running the story via WebUI E2E helpers; the core checks are semantic.

```js
const snap0 = await snapshotDomindsUI();
await createDialog('brainstorming-test.tsk');
const snap1 = await snapshotDomindsUI();
const roundBefore = snap1.currentDialog?.round || '';

await fillAndSend(
  'Call the function tool `change_mind` with {\"selector\":\"!goals\",\"content\":\"- Option A: ...\\\\n- Option B: ...\\\\n- Decide next: pick one and define success.\\\\n\"}.',
);

await waitForInputEnabled();
const snap2 = await snapshotDomindsUI();
const roundAfter = snap2.currentDialog?.round || '';

if (roundAfter !== roundBefore) throw new Error('Round changed unexpectedly');
// Then: visually confirm task doc Goals updated; Constraints/Progress unchanged.
```
