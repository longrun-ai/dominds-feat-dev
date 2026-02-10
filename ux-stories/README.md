# WebUI E2E Regression Suite (Manual, story-based)

This folder is the **single source of truth** for the manual, repeatable WebUI E2E regression suite.

Canonical run order (v1):

0. `ux-stories/setup-smoke.md` — Setup page smoke (route + key controls).
1. `ux-stories/new-dialog-create-modal-regression.md` — Create dialog modal + toast history regression.
2. `ux-stories/dlg-stop-resume.md` — Stop/Resume + global controls + cross-tab sync.
3. `ux-stories/mcp-toolset.md` — Tools registry + Problems panel + MCP tool call visibility.
4. `ux-stories/work-ui-lang.md` — UI language switch + persistence.
5. `ux-stories/q4h-panel-input.md` — Q4H panel + selection + answering flow.

Notes:

- All stories share the same **hard constraints**: no direct HTTP/WS API calls, no scripts, only human UI interactions. Playwright MCP is allowed only as the driver.
- Round-level rules and recovery budgets are defined in each story and in `docs/webui-testing-guide.md`.
