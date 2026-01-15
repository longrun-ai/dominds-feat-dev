# Dominds WebUI E2E: `@change_mind` (Task Doc Update) — Brainstorming UX

Validate that Dominds’ `@change_mind` behaves correctly for the **testee agent** during exploratory work (brainstorming / ideation), where requirements evolve quickly and task-doc edits are frequent.

This story is **semantic** (human judgment + UI observation). No strict text equality checks are required, but the tester and testee should verify that the behavior matches the intent.

## Key Semantics Under Test

1. **No round reset**: `@change_mind` must **not** start a new dialog round and must **not** clear messages/Q4H/reminders by itself.
2. **Encapsulated task packages (`*.tsk/`)**:
   - The task doc lives in a directory ending in `.tsk/`.
   - `@change_mind` must target **exactly one** section: `!goals | !constraints | !progress`.
   - A successful call replaces the entire target section contents (no patch semantics).
3. **Safety**:
   - Missing/invalid selector is rejected for `*.tsk/`.
   - Empty body is rejected (to prevent accidental clearing).
   - General file tools must not read/write/list/delete anything under `*.tsk/` (encapsulation policy).

## Setup

- Create a fresh dialog using a dedicated task package:
  - `brainstorming-test.tsk/`
- Ensure the testee is in the **root dialog** (not a subdialog), since `@change_mind` is root-only.

## Observations to Capture (Human-Readable)

After each step, the tester should note:

- Current round indicator did/did not change.
- Whether earlier chat messages are still visible (no timeline wipe).
- Whether the task doc changed **in the right section**.
- Whether the tool bubble shows success/failure appropriately.

Note: The current WebUI does not render `*.tsk/` task-doc panes (Goals/Constraints/Progress). For now, validate section
updates by inspecting the workspace files (e.g., `brainstorming-test.tsk/goals.md`, `constraints.md`, `progress.md`).

If you run with the E2E helpers, keep the evidence lightweight:

- Confirm round string before/after.
- Confirm task doc content visible contains the new ideas (not exact match).
- Confirm constraints/progress unchanged when only goals were edited (and vice versa).

## Scenario 1: Update Goals (Happy Path)

**Intent**: During brainstorming, you refine *what you want* (Goals) without changing constraints or wiping the conversation.

### Steps

1. Tester: Instruct the testee to call `@change_mind !goals` with a short “brainstormed” goals list.
2. Testee: Issues exactly one `@change_mind !goals` call with non-empty body.
3. Tester: Verify in UI:
   - Round did **not** change.
   - Messages were **not** cleared.
   - Task doc “Goals” content is replaced and reflects the new goals semantically.
   - “Constraints” and “Progress” still reflect their previous state.

### Example (not strict)

```
@change_mind !goals
- Explore 3 product directions.
- Pick 1 direction with clear success criteria.
@/
```

### Pass Conditions (semantic)

- Task doc “Goals” clearly reflects the new list.
- No round reset / no prompt injection / no timeline wipe.

## Scenario 2: Update Constraints (Happy Path)

**Intent**: You discover hard constraints during brainstorming (e.g., “no web browsing”, “must be under 10 lines”, “must not touch prod”).

### Steps

1. Tester: Instruct the testee to call `@change_mind !constraints` with 3–6 crisp constraints.
2. Verify:
   - Round did not change.
   - Task doc “Constraints” is replaced.
   - Goals/Progress remain unchanged.

## Scenario 3: Update Progress (Happy Path)

**Intent**: You record decisions made so far without rewriting the plan or constraints.

### Steps

1. Tester: Instruct the testee to call `@change_mind !progress` to record 2–5 bullet updates.
2. Verify:
   - Round did not change.
   - Progress is replaced.
   - Goals/Constraints remain unchanged.

## Scenario 4: Failure Modes (Safety)

These should fail safely, with no partial edits.

### A) Missing selector on `*.tsk/`

- Testee attempts:
  - `@change_mind` (no selector) with a body
- Expect:
  - Tool call fails with a clear error
  - No task doc section changes
  - Round does not change

### B) Invalid selector

- Testee attempts:
  - `@change_mind !goalz` (typo) with a body
- Expect:
  - Tool call fails with “invalid selector”
  - No task doc section changes

### C) Empty body

- Testee attempts:
  - `@change_mind !goals` with an empty body (or whitespace)
- Expect:
  - Tool call fails (content required)
  - No task doc section changes

## Optional Scenario 5: Encapsulation Guardrail

This validates that the *only* way to edit `*.tsk/` is via `@change_mind` (not file tools).

### Steps

1. Tester: Ask the testee to try `@read_file brainstorming-test.tsk/goals.md` (or `@list_dir brainstorming-test.tsk`).
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

await fillAndSend([
  'Update goals with a brainstorming list.',
  '@change_mind !goals',
  '- Option A: ...',
  '- Option B: ...',
  '- Decide next: pick one and define success.',
].join('\\n'));

await waitForInputEnabled();
const snap2 = await snapshotDomindsUI();
const roundAfter = snap2.currentDialog?.round || '';

if (roundAfter !== roundBefore) throw new Error('Round changed unexpectedly');
// Then: visually confirm task doc Goals updated; Constraints/Progress unchanged.
```
