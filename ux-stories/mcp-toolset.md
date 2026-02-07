# Dominds WebUI E2E: MCP Toolsets + Tools Registry

Scope: Tools panel, toolset grouping, Problems panel, and tool call visibility.
Hard constraints: NO API/WS direct calls, NO scripts, NO console helper injection. Only keyboard/mouse/touch.

## Preconditions

- WebUI reachable (e.g. http://127.0.0.1:5555/).
- Start from a fresh browser session (close the current browser window and reopen the WebUI).
- At least one MCP toolset is already configured and connected (pre-arranged).
- Connection status shows connected.
- You can access the Tools activity and Problems panel from the UI.
- If no MCP toolset is configured/connected, mark the test as blocked (not a product defect).

## Minimal Flow

1) Open the Tools activity panel.
   - Expect: toolsets list is visible and grouped by toolset.

2) Refresh the Tools registry (use the UI refresh button if available).
   - Expect: registry timestamp updates or list refreshes.

3) Expand a toolset and confirm tools are listed.
   - Expect: tool names are visible under the toolset.

4) Open the Problems panel.
   - Expect: panel opens and shows current problems count.

5) Create a dialog and ask the testee agent to call one MCP tool.
   - Expect: tool call appears in the dialog UI and completes.

6) Re-open Tools panel and confirm toolsets remain listed.
   - Expect: toolset list still present after tool call.

## Failure Recovery

- If Tools panel is empty, refresh once and reopen.
- If Problems panel does not open, refresh page once and retry.
- If tool call fails, retry once with a different tool or a simpler instruction.
- If the tool call fails with `browserType.launchPersistentContext` (Chrome "existing session"), close all Playwright-controlled Chrome windows, call `mcp_release({"serverId":"playwright"})`, then `mcp_restart({"serverId":"playwright"})`, and retry once. If it still fails, mark as blocked and attach the error log screenshot.

## Evidence Minimal Set

- Screenshot: Tools panel showing toolset grouping.
- Screenshot: one expanded toolset with tools listed.
- Screenshot: Problems panel open (even if count is 0).
- Screenshot: dialog showing a successful MCP tool call.

## Binary Pass/Fail Gates

- Tools panel opens and displays toolsets.
- Toolset can be expanded and shows tool names.
- Tools registry refresh updates timestamp or list.
- Problems panel opens and is readable.
- An MCP tool call can be triggered from the dialog and completes.
- Toolsets remain visible after the tool call.
