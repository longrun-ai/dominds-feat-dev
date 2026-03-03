# Browser tester ops

- Evidence/snapshots/temp notes must be stored under `artifacts/browser_tester/` (prefer `artifacts/browser_tester/snapshots/`).
- Default WebUI target for runs is `http://localhost:<DOMINDS_FRONTEND_PORT>`.
- Run as the runner agent from repo root to use repo-root `./.minds/**` (team members + Playwright MCP toolset).
- Round prep is `./dev-server.sh prep` (ask @cmdr to run it).
