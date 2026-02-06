# New Dialog / Create Dialog Modal — Regression Checklist

Scope: `dominds/webapp` toolbar `New Dialog` button + Create Dialog modal.

## Preconditions

- WebUI reachable (typically `http://localhost:5555/`).

## Checks

### 1) Loading state

- Reload page.
- Immediately click toolbar `New Dialog`.
- Expect: button is clickable; shows an info toast like “Loading team members…”, no modal stacks.

### 2) No team members configured

- Ensure team config returns zero members.
- Click `New Dialog`.
- Expect: warning toast “No team members available…”, switches activity view to **Team Members**, no modal shown.

### 3) Create modal single-instance + close gestures

- With ≥1 team member, click `New Dialog` repeatedly.
- Expect: at most one modal exists; input is focused.
- Click modal backdrop.
- Expect: modal closes.
- Re-open; press `Escape`.
- Expect: modal closes.

### 4) Taskdoc autocomplete empty state (i18n)

- Type a query that has no matches.
- Expect: empty state text is localized (not hardcoded English).

### 5) Double-submit prevention

- In modal, double-click `Create Dialog`.
- Expect: only one dialog is created; button becomes disabled and label changes to “Creating…/创建中…”.

### 6) Create failure is modal-local

- Force a create failure (e.g. auth rejected / backend error).
- Expect: error is shown inside the modal (inline red block), not behind the modal.
