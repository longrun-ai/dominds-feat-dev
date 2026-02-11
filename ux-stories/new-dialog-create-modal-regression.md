# WebUI E2E: New Dialog / Create Dialog Modal (Regression)

Scope: toolbar `New Dialog` button + Create Dialog modal + notification/toast UX around this flow.

Hard constraints:

- NO HTTP/WS API direct calls.
- NO scripts (browser console helpers, shell scripts, test drivers).
- Only “human UI interactions” (keyboard/mouse/touch). Playwright MCP is allowed as the _driver_.

Round rules:

- If this is the first story of the round: ask `@cmdr` to run `./dev-server.sh prep` (clear-records + restart) before testing.
- Continue policy: even if this story is **Fail**, continue running the remaining stories; stop the _round_ only if the environment is **Blocked**.
- Report format: reply `Pass` / `Fail` / `Blocked` + 1~5 key findings (text). Evidence (1~2 screenshots) is optional and only recommended for Fail/Blocked.

Ops-only recovery actions (allowed; record if used):

- Standard round prep (recommended before each round): `./dev-server.sh prep` (via `@cmdr`) to `clear-records + restart`.
- `./dev-server.sh restart` (via `@cmdr`) for a clean dev environment.
- `mcp_release({"serverId":"<your-playwright-serverId>"})` / `mcp_restart({"serverId":"<your-playwright-serverId>"})` to recover a stuck Playwright lease.

## Preconditions

- WebUI reachable (typically `http://localhost:5555/`).
- Start from a fresh browser session (close the current browser window and reopen the WebUI).
- At least 1 team member configured for create-success steps.
- To test the "no team members" path, ensure the team list is empty, then restore it after.
- Create-failure path is optional: only if you can trigger a backend/auth rejection safely.

## Minimal Flow

1. Loading state (optional; non-gate observation)

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

6. Toast + notification history (note: some toasts are not persisted by design)

- Trigger a deterministic toast: in the dialog list row, click the share/copy-link icon button.
  - Preferred stable locator: the icon button with `data-action="dialog-share-link"`.
  - If you cannot find any `data-action="dialog-share-link"` button in the dialog list, treat it as **environment build mismatch** (or missing testability hook) and mark `Blocked`.
- Expect: a toast appears (`Link copied` / `链接已复制` OR `Copy failed` / `复制失败`).
- Open notification history (header button tooltip `Notification history` / `通知历史`).
- Expect: the notification history panel opens and renders (it may be empty).
- Note: the `Link copied` / `链接已复制` toast is **not required** to be persisted into notification history.

7. Create failure handling (optional)

- If a create failure occurs (auth/backend rejection),
- Expect: error appears inside the modal (inline), not behind the modal.

## Failure Recovery

- If modal fails to open or duplicates, refresh once and retry; second failure = bug.
- If a create failure occurs without modal-local error, capture evidence and stop run.
- If clipboard permissions block copy, that is not a product defect; the toast should still show `Copy failed`.

## Optional Evidence (Fail/Blocked only)

- For Pass: no evidence required.
- For Fail/Blocked: attach 1~2 screenshots that best explain the failure/blocked state.

## Binary Pass/Fail Gates

- G1: Modal is single-instance; input can be focused by click; backdrop + Escape close it.
- G2: Empty state text is localized and arbitrary taskdoc path is allowed.
- G3: Double-submit does not create duplicates.
- G4: Create success selects a dialog and input is usable.
- G5: If a create failure occurs, error is modal-local.
- G6: Notification history opens and renders (empty is OK).

Pass rule: all gates must pass. Any failure => Fail.

Known behavior: some toasts (including `Link copied`) are intentionally not persisted into notification history.
