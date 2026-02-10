# WebUI E2E: Setup Page Smoke (/setup)

Scope: Setup route wiring + key setup controls + basic state readability.

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

- Setup page reachable: `http://localhost:5555/setup`.
- Start from a fresh browser session (close the current browser window and reopen the WebUI).

## Minimal Flow

1. Navigate to `/setup`.
   - Expect: the page renders (not a blank page).

2. Confirm the UI language dropdown exists: `#setup-lang-select`.
   - Expect: it is clickable and shows language options.

3. Click Refresh: `#refresh-btn`.
   - Expect: no crash; status re-renders.

4. Observe the primary CTA: `#go-btn`.
   - Expect: it is either enabled (setup OK) or disabled (setup not OK). Both are acceptable.

5. If the page is in “auth required” mode, confirm auth controls exist.
   - Expect: `#auth-key` and `#auth-submit` exist.
   - Note: in dev no-auth mode, auth may not be required.

## Failure Recovery

- If the page does not render, refresh once.
- If `/setup` redirects or renders the main app instead, record as routing bug.
- If key IDs are missing (e.g. `#setup-lang-select`, `#refresh-btn`, `#go-btn`), treat as **environment build mismatch** and mark `Blocked`.

## Optional Evidence (Fail/Blocked only)

- For Pass: no evidence required.
- For Fail/Blocked: attach 1~2 screenshots that best explain the failure/blocked state.

## Binary Pass/Fail Gates

- Setup route `/setup` renders.
- `#setup-lang-select` exists.
- `#refresh-btn` exists and is clickable.
- `#go-btn` exists.
- If auth is required, `#auth-key` + `#auth-submit` exist.

Pass rule: all gates must pass. Any failure => Fail.

## Notes

- This story is primarily a **routing + surface readability** check, not a full setup correctness verification.
