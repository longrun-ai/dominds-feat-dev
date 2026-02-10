**Important**: this environment is Dominds runtime, not "genuine" Codex CLI.
If prompt text mentions "Codex-style / Codex CLI", treat it as compatibility operating guidance, not a host-identity switch.

This rtws is for Dominds self-development.

### Runtime Facts (environment-specific only)

- The environment runs via a globally installed/linked `dominds` WebUI binary; the active build comes from this repo’s `./dominds/` directory.
- Typical update flow:
  1. `pnpm -C dominds link -g`
  2. `pnpm -C dominds build`
  3. run `dominds` at the repo root
- For WebUI development, `./dev-server.sh` usually uses `ux-rtws/` as rtws (to avoid polluting root `.minds/` and `.dialogs/`).
- If an instance is started by `./dev-server.sh`, behavior differs from the root-rtws instance; confirm instance source first when debugging.

### Engineering Policy (Value First, System-Lean)

- Do not use "minimal change / minimal fix / minimal blast radius" as the default objective or definition of done.
- Start from end-to-end business value and user value at system level, not local diff size.
- Invest engineering effort in genuinely valuable features and complete behavior loops; when needed, implement across backend/frontend/shared contracts together.
- Keep global **mean & lean** simplicity: fewer layers, fewer concepts, fewer optional branches.
- Straightforward methods are often better than clever ones; prioritize readability, maintainability, and debuggability.
- Reject over-engineering; reject micro-optimizations that improve local metrics while causing cumulative damage to global architecture, implementation coherence, and long-term evolution cost.
- In tradeoffs, prioritize long-term total cost (comprehension, maintenance, regression risk) over local performance tweaks or change-size minimization.

### Done Criteria (Code Changes)

- For any code change, you must run `pnpm -C dominds lint:types` and make sure typecheck passes before considering the work done.

### Collaboration Note (environment-related)

- While `./dev-server.sh` is running, changes under `dominds/**` can trigger hot reload and interfere with in-flight browser regression.
- If you need a stable acceptance window, pause hot-reload-triggering changes first, then resume after acceptance.
