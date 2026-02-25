# WebUI E2E: Work Language vs UI Language

Scope: WebUI UI-language dropdown behavior and persistence.

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

- WebUI reachable (e.g. `http://localhost:<DOMINDS_FRONTEND_PORT>/`).
- Start from a fresh browser session (close the current browser window and reopen the WebUI).
- Header UI language dropdown is visible.
- Connection status shows connected.
- This test validates UI language switching and persistence only (no server work-language verification under the no-script rule).

## Minimal Flow

1. Observe the current UI language label in the header dropdown.
   - Expect: a visible label (e.g. English or Chinese).

2. Open the UI language dropdown and switch to the other language.
   - Expect: dropdown closes and the header label updates.

3. Verify visible UI copy changes language (e.g. connection status text).
   - Expect: at least one visible label reflects the new language.

4. Refresh the page.
   - Expect: selected UI language persists after reload.

5. Create or select a dialog and send a short message.
   - Expect: reply renders and the UI remains in the selected language.

## Failure Recovery

- If the dropdown does not open, refresh once and retry.
- If language does not change, switch twice (A->B->A) and retry once.
- If the page fails to load after refresh, reload once and continue.

## Optional Evidence (Fail/Blocked only)

- For Pass: no evidence required.
- For Fail/Blocked: attach 1~2 screenshots that best explain the failure/blocked state.

## Binary Pass/Fail Gates

- UI language dropdown opens and shows choices.
- Selecting a different language updates the header label.
- At least one visible UI label updates to the selected language.
- Selected language persists after refresh.
- Sending a message does not revert UI language.

Pass rule: all gates must pass. Any failure => Fail.

Note: this story validates **UI language** only. Work-language correctness is out of scope under the no-script/no-API rule.
