# WebUI E2E: Q4H Panel + Input (Ask → Select → Answer)

Scope: Q4H (Questions for Human) panel visibility, question selection behavior, and answering via the Q4H input component.

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
- Connection status shows connected.

## Minimal Flow

1. Create a new dialog via toolbar New Dialog.
   - Expect: a dialog is selected and input is enabled.

2. Ask the testee agent to ask exactly **one** Q4H question.
   - Example instruction to the agent (in the chat input):
     - “Before answering, ask me 1 clarification question using Q4H (Questions for Human). Then wait.”
   - Expect: Q4H panel becomes visible (`#q4h-panel` is not hidden).

3. In the Q4H panel (`#q4h-panel`), locate the newly created question card.
   - Expect: there is at least one `.q4h-question-card[data-question-id]`.

4. Click the question title area (or checkbox/title) to select it.
   - Expect: the question becomes selected (visual highlight) and remains expanded/readable.

5. Click into the Q4H input area (`#q4h-input`) and type an answer.
   - Expect: caret visible; typing works.

6. Send the answer via the primary action in Q4H input (Send).
   - Expect: send action is accepted (button disables briefly or a visible state change occurs).
   - Expect: the Q4H question count decreases (panel hides if it reaches 0).

## Failure Recovery

- If no Q4H question appears, retry once with a stricter instruction: “Ask me 1 Q4H question now. Do not answer yet.”
- If the agent refuses or answers directly without Q4H, mark as testee non-cooperation (not a UI defect) and stop this story.
- If `#q4h-panel` / `#q4h-input` cannot be found, treat as **environment build mismatch** and mark `Blocked`.
- If selection clicks do nothing, refresh once and retry step 4.

## Optional Evidence (Fail/Blocked only)

- For Pass: no evidence required.
- For Fail/Blocked: attach 1~2 screenshots that best explain the failure/blocked state.

## Binary Pass/Fail Gates

- After the agent asks a Q4H question, `#q4h-panel` is visible.
- Q4H question card exists with `data-question-id`.
- Clicking the question selects it (visual selection state) and the question body is readable.
- Q4H input (`#q4h-input`) accepts typing.
- Sending an answer reduces pending Q4H count (panel hides when count reaches 0).

Pass rule: all gates must pass. Any failure => Fail.
