# WebUI E2E: MCP Toolsets + Tools Registry

Scope: Tools panel, toolset grouping, Problems panel, and tool call visibility.

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
- At least one MCP toolset is already configured and connected (pre-arranged).
- Connection status shows connected.
- You can access the Tools activity and Problems panel from the UI.
- If no MCP toolset is configured/connected, mark the test as blocked (not a product defect).

## Minimal Flow

1. Open the Tools activity panel.
   - Expect: toolsets list is visible and grouped by toolset.

2. Refresh the Tools registry (use the UI refresh button if available).
   - Expect: registry timestamp updates or list refreshes.

3. Expand a toolset and confirm tools are listed.
   - Expect: tool names are visible under the toolset.

4. Open the Problems panel.
   - Expect: panel opens and shows current problems count.

5. Create a dialog and ask the testee agent to call one MCP tool.
   - Use the lightweight MCP tool `env_echo` (do NOT use Playwright in this story).
   - Example instruction: "Call MCP tool `env_echo` with keys=[\"PATH\"] and payload=\"ping\"; reply done."
   - Expect: tool call appears in the dialog UI and completes.

6. Re-open Tools panel and confirm toolsets remain listed.
   - Expect: toolset list still present after tool call.

## Failure Recovery

- If Tools panel is empty, refresh once and reopen.
- If Problems panel does not open, refresh page once and retry.
- If tool call fails, retry once with a simpler instruction.
- If Playwright driver is stuck (cannot interact with the browser), use the ops-only recovery actions above, then retry once.

## Optional Evidence (Fail/Blocked only)

- For Pass: no evidence required.
- For Fail/Blocked: attach 1~2 screenshots that best explain the failure/blocked state.

## Binary Pass/Fail Gates

- Tools panel opens and displays toolsets.
- Toolset can be expanded and shows tool names.
- Tools registry refresh updates timestamp or list.
- Problems panel opens and is readable.
- An MCP tool call can be triggered from the dialog and completes.
- Toolsets remain visible after the tool call.

Pass rule: all gates must pass. Any failure => Fail.

Note: this story is a product-chain check (MCP toolset visibility + tool call in dialog). Do not substitute a heavyweight MCP server (e.g. Playwright) as the _test target_.
