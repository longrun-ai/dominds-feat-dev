# Collaboration Guardrails (Dominds)

## Hot Reload / In-Flight E2E Risk (dev-server)
- While `./dev-server.sh` is running, changes under `dominds/**` may be picked up by Vite/backend hot reload and can invalidate `@browser_tester`’s in-flight regression runs.
- When `@browser_tester` is executing the “2 consecutive rounds” acceptance runs, `@fullstack` should avoid landing/enabling changes that trigger hot reload.
- If changes are necessary, announce in the mainline, pause the acceptance run, then do a “prep restart” and restart the rounds.

## Owner Responsibility for Typecheck/Build
- Commands like `pnpm -C dominds run lint:types` / build / tests are the change owner’s self-check.
- Do not push these back to the tellask requester (tellaskee should not ask the tellasker to run them).
- If shell execution is needed, ask `@cmdr` to run them as a proxy for the owner’s self-check; this must not be used to offload responsibility.
