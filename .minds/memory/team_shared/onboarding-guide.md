# Team Member Onboarding Checklist (Dominds)

This is a practical checklist for team members (and contributors) to quickly build an accurate mental model of Dominds and produce shippable feature briefs with clear QA gates.

## 0) Guiding constraints (read first)
- Dominds is **pre-release (Alpha/preview)**: see [`release-status.md`](./release-status.md).
- Dominds is **dogfooding-first**: optimize real agent/operator experience; remove sharp edges even if it needs refactors.
- Prefer **root-cause fixes** and remove obsolete compatibility paths (“no compatibility baggage”).
- Conclusions must be **anchored to docs + code** (file paths / symbols / message types), not memory.
- Encapsulated task docs (`*.tsk/`) are **not** editable via generic file tools; only update via `!?@change_mind`.

## 1) Read these docs (in this order)
1. [`design.md`](./design.md) — Why the system exists; Fresh Boots Reasoning; task-centered architecture.
2. [`dialog-system.md`](./dialog-system.md) — Backend-driven driver; teammate calls; Q4H; suspension/resumption.
3. [`encapsulated-task-doc.md`](./encapsulated-task-doc.md) — `*.tsk/` rules; why “single source of truth” matters.
4. [`keep-going.md`](./keep-going.md) — Root dialog auto-continue; budget; when forced to Q4H.
5. [`auth.md`](./auth.md) — Dev/prod auth modes; HTTP/WS auth propagation; WebUI behavior.
6. [`team-tools-view.md`](./team-tools-view.md) — Tools registry + Problems view (WebUI expectations).
7. [`mcp-support.md`](./mcp-support.md) — MCP semantics; tool name constraints; hot-reload + last-known-good behavior.
8. [`interruption-resumption.md`](./interruption-resumption.md) — Stop/Resume semantics; blocked vs interrupted UX requirements.

## 2) “Reality check” against code (minimum set)
When writing or reviewing any spec, confirm these implementation anchors exist and match the doc:

**Runtime & dialogs**
- Dialog runtime & driver loop: `dominds/main/dialog.ts`
- Run state semantics (idle/proceeding/blocked/etc): `dominds/main/dialog-run-state.ts`
- Registries (global/local/subdialog): `dominds/main/dialog-global-registry.ts`, `dominds/main/dialog-instance-registry.ts`

**Persistence**
- Dialog persistence implementation: `dominds/main/persistence.ts` (cross-check with `dominds/docs/dialog-persistence.md`)

**Task Doc (`*.tsk/`) encapsulation**
- Path detection + general-file-tool bans: `dominds/main/access-control.ts`
- Task package helpers: `dominds/main/utils/task-package.ts`, `dominds/main/utils/taskdoc-search.ts`
- Task doc rendering + warnings: `dominds/main/utils/task-doc.ts`
- `!?@change_mind` (no round reset): `dominds/main/tools/ctrl.ts`

**Minds & tools**
- Minds loader: `dominds/main/minds/load.ts`
- Memory tools: `dominds/main/tools/mem.ts`
- Tool registry snapshot: `dominds/main/tools/registry.ts`, `dominds/main/tools/registry-snapshot.ts`
- Problems active set: `dominds/main/problems.ts`

**Server contracts**
- HTTP routes: `dominds/main/server/api-routes.ts`
- WS message handling: `dominds/main/server/websocket-handler.ts`
- Auth middleware: `dominds/main/server/auth.ts`

**WebUI contracts (where UX meets protocol)**
- HTTP client surfaces: `dominds/webapp/src/services/api.ts`, `dominds/webapp/src/services/auth.ts`
- WS client + packets: `dominds/webapp/src/services/websocket.ts`
- Q4H presentation/input: `dominds/webapp/src/components/dominds-q4h-panel.ts`, `dominds/webapp/src/components/dominds-q4h-input.ts`
- Tools/Problems/overall app wiring: `dominds/webapp/src/components/dominds-app.tsx`

If docs and code disagree, treat it as **P0**: fix docs or code quickly.

## 3) How to write a PRD-lite (Dominds style)
Use the “four-piece set”:
- Ownership / scope: which domain owns which change (docs/runtime/server/webui/cli/tooling/qa)
- Contracts / data flow: HTTP/WS messages, file layouts, state semantics
- Acceptance criteria: user-visible behavior + error/edge behavior + observability
- Regression checklist: add a small, runnable smoke list (hand to QA)

## 4) Handoff to QA (gate-ready)
A feature is “handoff-ready” when:
- Acceptance criteria are **binary** (pass/fail) and mention the exact surfaces (CLI flags, WS msg types, file paths).
- Regression points are explicit (auth on/off, Q4H, keep-going budget exhaustion, `*.tsk/` restrictions, Problems view).
- The change has a rollback/cleanup story if it touches persistence or tool registration.

## 5) Default escalation path (who owns what)
- Docs/spec alignment: `@pm`
- Runtime/dialog engine semantics: `@runtime`
- HTTP/WS API + server behavior: `@server`
- Web UI UX + presentation: `@webui`
- CLI/TUI UX + command contract: `@cli`
- Tools registry + guardrails: `@tooling`
- Regression gate definitions: `@qa`
