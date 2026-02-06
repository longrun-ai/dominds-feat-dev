# Create Dialog Modal: enablement, stacking, and error surfacing (UX triage)

## Summary

The **New Dialog** entrypoint (`#new-dialog-btn`) and the **Create Dialog** modal have several small UX sharp edges that can make the UI feel flaky under fast clicks / slow initial data load.

This is currently **non-blocking** for the Playwright smoke checks, but worth addressing for dogfooding.

## Environment

- WebUI: `dominds/webapp`
- Relevant component: `dominds/webapp/src/components/dominds-app.tsx`

## Observations (suspected issues)

### 1) New Dialog button has no disabled/“loading” state

**Current behavior**

- Click handler for `#new-dialog-btn` calls `handleNewDialog()`.
- `handleNewDialog()` gates only on `this.teamMembers.length === 0`, but the button remains clickable and the failure path uses `showError('No team members available...')`.

**Why this is a UX issue**

- On a slow start (initial load, transient API failure), users can click a visible affordance and get an error that is not obviously tied to the button state.

**Code anchors**

- Delegated click handler: `dominds/webapp/src/components/dominds-app.tsx` (search `#new-dialog-btn`)
- Guard: `dominds/webapp/src/components/dominds-app.tsx` (search `handleNewDialog`)

**Expected**

- Button is disabled (or shows loading) until prerequisites are met (at least `teamMembers` loaded).
- Tooltip explains what it’s waiting for.

### 2) Modal can be stacked (no single-instance guard)

**Current behavior**

- `showCreateDialogModal()` always creates a new `.create-dialog-modal` element and appends it.
- No guard like “if modal already open, do nothing / bring to front”.

**Why this matters**

- Rapid clicks on **New Dialog** can create multiple overlays, leading to confusing focus and inconsistent close behavior.

**Code anchors**

- `dominds/webapp/src/components/dominds-app.tsx` (search `showCreateDialogModal(`)

**Expected**

- At most one create-dialog modal exists at a time.

### 3) Create action has no in-flight disable; can double-submit

**Current behavior**

- `#create-dialog-btn` handler calls `await this.createDialog(...)` with no “in progress” state.

**Impact**

- Double-click can issue duplicate create requests and create multiple dialogs.

**Expected**

- Disable `#create-dialog-btn` while request is in-flight; show spinner / “Creating…” label.

### 4) Error surfacing is not modal-local

**Current behavior**

- On create failure, `createDialog()` catches and calls `this.showError(...)`.
- `showError()` renders an error block into `#dialog-content`.

**Why this is a UX issue**

- If the modal is still open, users may not see the error immediately (it’s “behind” the overlay).

**Expected**

- Show inline error inside the modal (like auth modal’s `#auth-modal-error`) or show a toast.

### 5) Backdrop/Escape interactions (quality)

**Current behavior**

- Modal has a backdrop element (`.modal-backdrop`), but it does not close on backdrop click.
- There is no modal-level `Escape` close handler (except closing taskdoc suggestions).

**Expected**

- Clicking backdrop closes the modal.
- `Escape` closes the modal.

### 6) i18n gap: “No matching documents found” is hardcoded

**Current behavior**

- Autocomplete empty state uses hardcoded English string.

**Expected**

- Use `getUiStrings()` entry (zh/en) for this line.

## Suggested Fix (minimal)

1. Disable `#new-dialog-btn` until `teamMembers` is loaded (or show a toast “Loading team…”).
2. In `showCreateDialogModal()`, early-return if a modal already exists.
3. In `setupDialogModalEvents()`, disable `#create-dialog-btn` during `createDialog()`.
4. Surface create failures inside the modal (inline error div) and keep the modal open.
5. Add backdrop click + `Escape` close.
6. Add i18n key for autocomplete empty state.

## Acceptance Criteria

- Rapidly clicking **New Dialog** never produces multiple modals.
- Double-clicking **Create Dialog** produces at most one dialog.
- If team members are not loaded yet, the **New Dialog** button communicates “loading” clearly (disabled or toast).
- If create fails, the error is visible without closing/dismissing the modal.
- Backdrop click and `Escape` close the modal.
- Autocomplete empty state is translated.

## Status (local implementation)

- Implemented locally in `dominds/webapp/src/components/dominds-app.tsx` (single-instance modal, in-flight disable + inline error, backdrop/Escape close, New Dialog loading/empty handling).
- Implemented locally in `dominds/webapp/src/i18n/ui.ts` (i18n keys for empty autocomplete + creating state + New Dialog state).
