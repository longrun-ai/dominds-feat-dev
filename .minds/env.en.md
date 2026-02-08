**Important**: the current runtime environment is not the "genuine" Codex CLI runtime environment; it is the Dominds runtime.

This rtws is used for Dominds self-development.

### Execution Policy (Default)

- Dominds is a full-stack integrated repo; design and implementation should be coordinated across `dominds/main`, `dominds/webapp`, and shared contracts.
- Default execution policy: **full-stack integrated, one-shot done-right, no compatibility layer**.
- Unless @human explicitly requires it, do not introduce transitional paths, dual-track logic, backward-compatibility shims, or legacy baggage.

### Error Handling Policy (Default)

- **No silent failures**: do not silently swallow exceptions, silently deduplicate, silently downgrade, or silently rewrite critical behavior.
- **When the program encounters unreasonable scenarios, it must fail fast instead of being covered by fallback**: for example duplicate IDs, duplicate call correlation, or stream ordering violations must raise explicit errors and stop unsafe execution paths.
- **Errors must be loud and observable**: besides structured logs, emit runtime-visible signals (for example `stream_error_evt`) with stable correlation fields (`rootId`, `selfId`, `course`, `genseq`, `callId`, `questionId` when applicable).
- Unless @human explicitly authorizes graceful degradation, do not add silent fallback paths; even with degradation, keep explicit warning/error signals for root-cause debugging.

### Dominds program source

This Dominds environment uses a “globally installed/linked” `dominds` WebUI, and the version is built from the `./dominds/` directory in this repository:

1. In the repository root, run: `pnpm -C dominds link -g` (link `./dominds/` as the global `dominds` command)
2. Then run: `pnpm -C dominds build` (build backend + webapp)
3. Afterwards, in the repository root, run: `dominds` (use repo root as the rtws)

### WebUI development (avoid polluting the root workspace)

`./dev-server.sh` starts the dev servers with `ux-rtws/` as the rtws (for UX testing, without polluting the root workspace’s `.minds/` and `.dialogs/`).

**Note**: the current environment is not an instance started by `./dev-server.sh`.

### Team Collaboration Guardrails (WebUI E2E / dev-server)

- **Hot reload / passive-change risk**: while `./dev-server.sh` is running, `@fullstack` changes under `dominds/**` may be picked up by Vite/backend hot reload and can invalidate `@browser_tester`’s in-flight regression runs.
  - Recommendation: when `@browser_tester` is running the “2 consecutive rounds” acceptance runs, `@fullstack` should avoid landing/enabling changes that trigger hot reload; if changes are necessary, announce in the mainline, pause the acceptance run, then do a “prep restart” and restart the rounds.

- **Owner responsibility for typecheck/build**: commands like `pnpm -C dominds run lint:types` / build / tests are the change owner’s self-check.
  - Do not push these back to the tellask requester (tellaskee should not ask the tellasker to run them).
  - If shell execution is needed, you may ask `@cmdr` to run them as a proxy for the owner’s self-check; this must not be used to offload responsibility.
