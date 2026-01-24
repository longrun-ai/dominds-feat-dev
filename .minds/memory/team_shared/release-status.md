# Release Status & Dogfooding Policy

## TL;DR
Dominds is currently **pre-release (Alpha/preview quality)** and **dogfooding-first**. Expect breaking changes across docs, APIs, storage layout, and UX. When in doubt, **the code and the latest `dominds/docs/**` win**.

## Target environment
- Small-scale **LAN** usage (typically up to ~3 concurrent users).
- Optimize for correctness and agent/operator experience over enterprise-grade performance tuning.

## What “Alpha/preview” means in Dominds
- **No stability guarantees**: contracts, file layouts, and UI/CLI surfaces may change without notice.
- **Breaking changes are acceptable** when they improve correctness, safety, or agent/operator experience.
- **Docs may lag** briefly; treat any docs↔code mismatch as a bug and fix it quickly.

## Dogfooding-first priorities
Dominds is built for agent/operator work and must **eat its own dog food** (dogfooding):
- Prioritize real usage experience over theoretical completeness.
- Prefer root-cause fixes over incremental patches.
- Keep behavior **predictable, observable, and easy to recover** (clear errors, clear next steps).

## Compatibility & cleanup policy
- We intentionally avoid long-lived compatibility layers (“no compatibility baggage”).
- Refactors should **delete** outdated paths and **update docs** to match.
- If a doc becomes inaccurate, fix it immediately (or remove it).

## Reporting a breakage or mismatch
Include:
- the command/UI path you used,
- the dialog/root id (if applicable),
- relevant logs/output,
- expected vs actual behavior,
- and links to the doc/code sections you believe are inconsistent.
