# Dominds WebUI E2E: Work Language vs UI Language

Scope: WebUI UI-language dropdown behavior and persistence.
Hard constraints: NO API/WS direct calls, NO scripts, NO console helper injection. Only keyboard/mouse/touch.

## Preconditions

- WebUI reachable (e.g. http://127.0.0.1:5555/).
- Start from a fresh browser session (close the current browser window and reopen the WebUI).
- Header UI language dropdown is visible.
- Connection status shows connected.
- This test validates UI language switching and persistence only (no server work-language verification under the no-script rule).

## Minimal Flow

1) Observe the current UI language label in the header dropdown.
   - Expect: a visible label (e.g. English or Chinese).

2) Open the UI language dropdown and switch to the other language.
   - Expect: dropdown closes and the header label updates.

3) Verify visible UI copy changes language (e.g. connection status text).
   - Expect: at least one visible label reflects the new language.

4) Refresh the page.
   - Expect: selected UI language persists after reload.

5) Create or select a dialog and send a short message.
   - Expect: reply renders and the UI remains in the selected language.

## Failure Recovery

- If the dropdown does not open, refresh once and retry.
- If language does not change, switch twice (A->B->A) and retry once.
- If the page fails to load after refresh, reload once and continue.

## Evidence Minimal Set

- Screenshot: header language before switching.
- Screenshot: header language after switching.
- Screenshot: header language after refresh (persistence).

## Binary Pass/Fail Gates

- UI language dropdown opens and shows choices.
- Selecting a different language updates the header label.
- At least one visible UI label updates to the selected language.
- Selected language persists after refresh.
- Sending a message does not revert UI language.
