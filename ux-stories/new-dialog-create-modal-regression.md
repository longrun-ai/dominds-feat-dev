# New Dialog / Create Dialog Modal - Regression Checklist

Scope: `dominds/webapp` toolbar `New Dialog` button + Create Dialog modal.

Hard rules: no API/WS direct calls, no scripts, no helper injection. Use only browser UI interactions.

## Preconditions

- WebUI reachable (typically `http://localhost:5555/`).
- Start from a fresh browser session (close the current browser window and reopen the WebUI).
- At least 1 team member configured for create-success steps.
- To test the "no team members" path, ensure the team list is empty, then restore it after.
- Create-failure path is optional: only if you can trigger a backend/auth rejection safely.

## Minimal Flow

1. Loading state

- Reload page and immediately click `New Dialog`.
- Expect: button remains clickable, shows a loading/info toast, and no stacked modals.

2. Modal single-instance + close gestures

- With >=1 team member, click `New Dialog` repeatedly.
- Expect: at most one modal; input becomes usable after click (caret/focus ring visible; auto-focus is not required).
- Click backdrop; expect modal closes.
- Re-open; press `Escape`; expect modal closes.

3. Taskdoc autocomplete empty state + arbitrary path allowed

- Type a gibberish query with no matches.
- Expect: empty state text is localized (not hardcoded English).
- Enter a taskdoc path that does not exist.
- Expect: creation is still allowed (nonexistent taskdoc path is valid by design).

4. Double-submit prevention

- Double-click `Create Dialog`.
- Expect: only one dialog created; button disabled; label shows "Creating..."/"\u521b\u5efa\u4e2d...".

5. Create success

- After creation, ensure a dialog is selected and input is usable.

6. Create failure handling (optional)

- If a create failure occurs (auth/backend rejection),
- Expect: error appears inside the modal (inline), not behind the modal.

## Failure Recovery

- If modal fails to open or duplicates, refresh once and retry; second failure = bug.
- If a create failure occurs without modal-local error, capture evidence and stop run.

## Optional Evidence (Fail/Blocked only)

- For Pass: no evidence required.
- For Fail/Blocked: attach 1~2 screenshots that best explain the failure/blocked state.

## Binary Pass/Fail Gates

- G1: Loading click yields toast and no stacked modals.
- G2: Modal is single-instance; input can be focused by click; backdrop + Escape close it.
- G3: Empty state text is localized and arbitrary taskdoc path is allowed.
- G4: Double-submit does not create duplicates.
- G5: Create success selects a dialog and input is usable.
- G6: If a create failure occurs, error is modal-local.

Pass rule: all gates must pass. Any failure => Fail.
