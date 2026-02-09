# WebUI Testing Guide

This guide defines how we run end-to-end (E2E) checks against the Dominds WebUI, with a strong bias toward repeatability, clean reproduction steps, and easy handoff.

The goal is not “automation for automation’s sake”. The goal is to validate real user journeys while keeping the process lightweight and stable enough to run repeatedly.

## 1) Scope and non-negotiable rules

### 1.1 Scope

- Target UI: Dominds WebUI on `http://localhost:5555`.
- Target journeys: creating dialogs, sending messages, error visibility, refresh recovery, tool call visibility.
- Audience: `@browser_tester`, `@ux`, `@fullstack`, and anyone who will take over regression runs later.

### 1.2 Hard rules

- No direct HTTP/WS API calls.
- No scripts (no browser-console helpers, no shell scripts, no test-driver scripts).
- All actions must be performed as “human UI interactions” (keyboard/mouse/touch). Playwright MCP is allowed only as the _driver_ that performs those interactions.
- Results must be reproducible. For each story, report `Pass` / `Fail` / `Blocked` + a small set of key findings (plain text is enough).

### 1.3 Run policy (don’t stop halfway)

- Run `ux-stories/*.md` **serially** (one story at a time).
- If a story is `Fail`, you still run the remaining stories and report them separately.
- You may end the round early only if:
  - the environment is `Blocked` (WebUI unreachable, toolset not connected, macOS permission dialogs, etc.), or
  - the testee refuses to cooperate (non-cooperation), and you can’t continue meaningfully.

## 2) Environment and where state lives

### 2.1 Services

- Frontend: `http://localhost:5555`
- Backend: `http://localhost:5556`
- Dev startup: `./dev-server.sh`

`./dev-server.sh` runs the backend with `ux-rtws/` as its runtime workspace (rtws). Seeing a banner like “Backend Runtime Workspace: .../ux-rtws” is expected in this dev setup.

### 2.2 Who runs from where (important)

- The **runner agent** (e.g. `@browser_tester`) runs from the repo root so it uses the repo-root `./.minds/**` (team members + Playwright MCP toolset).
- The **WebUI backend** uses `ux-rtws/` as its rtws when started via `./dev-server.sh`.
  - Keep `ux-rtws/.minds/team.yaml` minimal.
  - The backend loads MCP toolsets from `ux-rtws/.minds/mcp.yaml` (so the Tools panel is testable in the same environment).

### 2.3 macOS permissions (if applicable)

Browser automation may trigger macOS permission prompts (TCC / Gatekeeper). If this blocks progress, treat it as `Blocked` (environment issue), record it, and do not mislabel it as a product bug.

## 3) Standard round prep (required)

Each round must start from a clean state. This prevents old dialog records from contaminating runs and makes debugging much easier.

### 3.1 Required prep step

Before the first story of a round, ask `@cmdr` to run:

- `./dev-server.sh prep`

`prep` is the standard “round prep” command. It does:

- stop backend/frontend dev processes
- clear `ux-rtws/.dialogs/` (dialog records)
- start backend/frontend again

### 3.2 Ops-only recovery actions (allowed; must be recorded)

These actions are allowed because they are _operational recovery_, not “UI shortcuts”:

- `./dev-server.sh prep` (preferred)
- `./dev-server.sh restart` (emergency recovery)
- `mcp_release({"serverId":"<your-playwright-serverId>"})` / `mcp_restart({"serverId":"<your-playwright-serverId>"})`
  - Use the real `serverId` from your setup (e.g. `playwright`, `playwright2`).
  - Always record what you ran and why.

Important: if you repeatedly need recovery actions in the middle of a round to finish all stories, that round does **not** count as “stable”. Fix the underlying issue and rerun.

### 3.3 Mid-round recovery budget (what counts as a “surprise”)

To keep acceptance runs comparable across rounds, we treat recovery actions as budgeted events:

- Allowed at the **start of a round** (prep window):
  - `./dev-server.sh prep` (required)
  - at most **one** `mcp_restart({"serverId":"<your-playwright-serverId>"})` if the Playwright driver is stuck before story execution
- Allowed **during** story execution:
  - at most **one** page refresh per story (only after a clear UI failure)
- Not allowed during story execution (counts as “unexpected recovery”):
  - additional `./dev-server.sh prep/restart`
  - repeated `mcp_restart`

If you exceed the budget (or need the same recovery repeatedly), the round does not qualify for “2 consecutive stable rounds”.

## 4) How to run a round (high level)

### Phase A: Prepare

0. Round prep: `@cmdr` runs `./dev-server.sh prep`.
1. Start from a fresh browser session (close the browser window and reopen).
2. Open `http://localhost:5555` and confirm the UI is usable and “connected”.
3. Open DevTools (Console + Network) for _observation only_ (no scripts, no manual requests).

### Phase B: Execute

Run the four stories in `ux-stories/*.md` in order. Follow each story’s constraints, steps, and binary gates.

### Phase C: Report

For each story, report:

- Result: `Pass` / `Fail` / `Blocked`
- Key findings: 1–5 bullets (include anything about flakiness, focus issues, permission prompts, recovery steps)

Add evidence only when useful:

- 1–2 screenshots for Fail/Blocked
- up to ~3 relevant Console lines and up to ~3 relevant Network entries (no full dumps)

### Phase D: Cleanup

If you used a Playwright MCP lease, release it:

- `mcp_release({"serverId":"<your-playwright-serverId>"})`

## 5) Stability baseline (Round 1/2 reference)

Based on two “human-interaction-only” regression runs:

- Round 1: `9` minutes (prep `2` / execute `3` / evidence `3` / cleanup `1`), failures `1`, recovery `1` minute.
- Round 2: `8` minutes (prep `1` / execute `4` / evidence `2` / cleanup `1`), failures `1`, recovery `1` minute.
- Total: `17` minutes, failures `2`, recovery time `2` minutes.

Failure categories (both rounds):

- Page: `0`
- Connection: `0`
- Data contamination: `0`
- UI timing flake: `2`

## 6) Minimal stable flow (the “smoke”)

If you need the smallest reliable smoke check, use this sequence:

1. Open `http://localhost:5555` and confirm the UI is interactive.
2. Click `New Dialog`, create a dialog, and confirm input is available.
3. Send `ping`, explicitly wait for `pong` (or an equivalent success response).
4. Immediately take one screenshot at success (no fixed sleeps).
5. Refresh and confirm the history is still there.
6. After refresh, send one more probe and confirm a response.
7. Collect minimal evidence (only if needed).
8. Cleanup (release MCP lease if used).

## 7) Anti-patterns (must not do)

- Calling HTTP/WS APIs directly to simulate user behavior.
- Running scripts (console helpers, shell scripts, driver scripts).
- Using fixed sleep as the main waiting strategy.
- Collecting redundant evidence (too many screenshots of the same state).
- Creating unrelated new sessions just to “test refresh recovery”.

## 8) Recovery and risk notes

### 8.1 Page is broken

- Mitigation: refresh once and re-run the minimal flow; if still broken, record the key failure and stop.

### 8.2 Connection is broken

- Mitigation: one status re-check + one retry; if persistent, record as connection issue.

### 8.3 Data contamination

- Mitigation: re-select the target dialog and refresh; if still inconsistent, treat as high priority.

### 8.4 UI timing flake (main risk)

- Mitigation: rely on explicit “visible/interactive” states and keep recovery to “one re-check + one retry”.

## 9) Binary acceptance gates (G1–G8)

- G1: A new dialog can be created and becomes input-ready.
- G2: After sending `ping`, you receive `pong` (or an equivalent success response).
- G3: After refresh, the history is still visible.
- G4: After refresh, you can send another probe and receive a response.
- G5: No blocking Console errors.
- G6: No blocking Network failures/disconnects.
- G7: The report is complete (`Pass/Fail/Blocked` + key findings).
- G8: The process stayed compliant (UI interactions only; no API calls; no scripts).

Rule: if any gate fails, the round is `Fail`. All gates pass = `Pass`.

## 10) Minimal report requirements

At minimum, each round report should include:

- The final result: `Pass` / `Fail` / `Blocked`
- Key findings (1–5)
- Any retries/recovery actions taken
- macOS permission/focus issues (if any)
- MCP cleanup: confirm `mcp_release({"serverId":"<your-playwright-serverId>"})` (if MCP was used)

## 11) Suggested report template

Copy/paste and fill this in:

```md
### WebUI E2E Regression Report (date / runner)

- Environment: `http://localhost:5555` (browser: ...)
- Base URL used: `http://localhost:5555` / `http://127.0.0.1:5555` (if you had to switch, record why)
- Platform (`uname -a`): ...
- Runner agent rtws: repo root (outer rtws)
- WebUI backend rtws (banner): ... (e.g. `ux-rtws`)

#### Per-story results

- Story 1 (`ux-stories/new-dialog-create-modal-regression.md`): Pass / Fail / Blocked
- Story 2 (`ux-stories/dlg-stop-resume.md`): Pass / Fail / Blocked
- Story 3 (`ux-stories/mcp-toolset.md`): Pass / Fail / Blocked
- Story 4 (`ux-stories/work-ui-lang.md`): Pass / Fail / Blocked

#### Key findings (1–5)

- ...

#### Compliance (required)

- UI interactions only (keyboard/mouse/touch): Yes/No
- No direct HTTP/WS API calls: Yes/No
- No scripts (including console helper injection): Yes/No

#### macOS permissions/focus (if applicable)

- Permission prompts (TCC / Gatekeeper): Yes/No (attach 1 screenshot if Yes)
- Focus / foreground issues: Yes/No (what happened)

#### Retries / recovery (if any)

- Retried: Yes/No
- What you did: ...
- Outcome: ...

#### Recovery budget accounting (required)

- Did you restart dev-server mid-round (prep/restart after story start): Yes/No
- Did you run `mcp_restart` mid-story: Yes/No
- Page refreshes during stories (count): ...

#### MCP lease cleanup (if applicable)

- Ran `mcp_release({"serverId":"<your-playwright-serverId>"})`: Yes/No

#### Optional evidence (Fail/Blocked only)

- Screenshots (1–2): ...
- Console summary (0–3 lines): ...
- Network summary (0–3 lines): ...
```

## 12) Code anchors (for cross-checking)

- App shell: `dominds/webapp/src/components/dominds-app.tsx`
- Create dialog flow: `dominds/webapp/src/components/create-dialog-flow.ts`
- Input component: `dominds/webapp/src/components/dominds-q4h-input.ts`
- Q4H panel: `dominds/webapp/src/components/dominds-q4h-panel.ts`
- WS client: `dominds/webapp/src/services/websocket.ts`
- HTTP client: `dominds/webapp/src/services/api.ts`

---

Last Updated: 2026-02-09
