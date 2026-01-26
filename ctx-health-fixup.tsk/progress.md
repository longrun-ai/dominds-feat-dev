## Progress
- [owner:@fullstack] In this round: fixed stale guidance that suggested `clear_mind({"reminder_content":""})`.
  - Updated `dominds/docs/encapsulated-taskdoc.md` to recommend a non-empty re-entry package when starting a new round.
  - Updated `dominds/main/tools/txt.ts` “large file strategy” hints (zh/en) to use `clear_mind({"reminder_content":"<re-entry package>"})` and explain why.
- [owner:@fullstack] Environment gates: **pending** (must not claim passed until @cmdr posts results)
  - Need: `./dev-server.sh status` and `pnpm -C dominds run lint:types`.
- [owner:@fullstack] Next steps (after gates): run `pnpm -C dominds/tests run realtime`, then do a manual WebUI check for Q4H send gating (`kind=context_health_critical`) and confirm context-health guidance injection is non-persisted.