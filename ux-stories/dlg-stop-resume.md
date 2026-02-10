# WebUI E2E: Dialog Stop / Resume (Per-dialog + Global Controls)

Scope: dialog Stop/Resume controls + global operator controls + cross-tab sync.

Note (Dominds sync model): cross-client consistency must be achieved via backend event push only.
Do not add or rely on any browser-local tab-to-tab communication mechanisms.

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

- WebUI reachable (e.g. `http://localhost:5555/`).
- Start from a fresh browser session (close the current browser window and reopen the WebUI).
- At least one team member is available so a dialog can be created.
- Connection status shows connected.
- If you will check cross-tab sync, open a second tab to the same WebUI.

## Minimal Flow

1. Create a new dialog via toolbar New Dialog.
   - Expect: a dialog is selected and input is enabled.

2. Send a prompt to force a long response (ask for a long list, no tools).
   - Expect: primary action switches to Stop and input becomes disabled while streaming.

3. Click Stop.
   - Expect: streaming stops and a resume/continue panel appears in the dialog.

4. Click Continue/Resume in the dialog.
   - Expect: response continues or resumes; input is disabled during resume and re-enables when done.

5. Start another long response, then click toolbar Emergency Stop.
   - Expect: streaming stops and the global resume count increases.
   - Note (click target semantics): click the **icon button** `#toolbar-emergency-stop`.
     - Do NOT click the pill container `#toolbar-emergency-stop-pill` (display-only).
     - Do NOT click the count text `#toolbar-emergency-stop-count` (display-only).
   - Keyboard spot-check (do once per round): Tab focus to `#toolbar-emergency-stop`, then press Enter/Space to open the confirm dialog.
   - Emergency Stop only works when proceeding count > 0.
   - Confirm the Emergency Stop dialog; cancel is a no-op.
   - If output continues beyond ~5s after confirm and resume count stays 0, treat as a bug.
   - No toast is expected; confirmation appears only when clicking the icon and proceeding count > 0.
   - If streaming is visible but proceeding count stays 0, treat as run-state update issue.

6. Click toolbar Resume All.
   - Expect: the interrupted dialog resumes.
   - Expect: resumable count decreases; **should** reach 0 when all dialogs are resumed.
   - Note (click target semantics): click the **icon button** `#toolbar-resume-all`.
     - Do NOT click the pill container `#toolbar-resume-all-pill` (display-only).
     - Do NOT click the count text `#toolbar-resume-all-count` (display-only).
   - Keyboard spot-check (do once per round): Tab focus to `#toolbar-resume-all`, then press Enter/Space.
   - Resume All only works when resumable count > 0 and dialogs are in interrupted state.

7. In the second tab, observe stop/resume state.
   - Expect: within 5s, stop/resume state and counts match the first tab.

## Failure Recovery

- If the model does not stream a long response, retry once with a stricter prompt.
- If the testee refuses or calls tools instead, mark as testee non-cooperation (not a UI defect) and stop this story.
- If Stop/Resume controls do not appear, refresh once and repeat steps 1-4.
- If cross-tab state does not update, wait 5s and refresh the second tab once.
- If you cannot find/click `#toolbar-emergency-stop` / `#toolbar-resume-all` (or the new `*-pill` / `*-count` IDs), treat it as **environment build mismatch** (outdated UI build not yet effective). Record as `Blocked` and stop this story.

## Optional Evidence (Fail/Blocked only)

- For Pass: no evidence required.
- For Fail/Blocked: attach 1~2 screenshots that best explain the failure/blocked state.

## Binary Pass/Fail Gates

- After sending a long prompt, primary action switches to Stop within 2s.
- Clicking Stop halts streaming within 2s and shows a resume/continue panel.
- Clicking Continue/Resume resumes output and input re-enables after completion.
- Emergency Stop halts streaming and increases the resume count.
- Resume All resumes output.
- Resume count reaches 0 after all resumable dialogs are resumed.
- Emergency Stop / Resume All icon buttons are keyboard accessible: Tab focuses `#toolbar-emergency-stop` / `#toolbar-resume-all`, Enter/Space activates (Emergency Stop shows confirm).
- Second tab reflects stop/resume state within 5s.

Pass rule: all gates must pass. Any failure => Fail.

Known issue (historical; observed 2026-02-09): global `Resume all / 全部继续` count may not return to 0 even though the dialog resumes. If observed, mark **Fail (resume count gate)** and continue to the next story.
