## Project Overview

This is an **in-tree development setup** for `dominds` — an AI-powered DevOps framework. The source code lives in a local checkout at `dominds/`.

The repo root is the **DevOps runtime workspace (rtws)** for feat-dev work: `.minds/` is the agent team definition and workspace memory used when you run Dominds/agents against this repo.

For WebUI dev/UX testing, `./dev-server.sh` runs Dominds with `ux-rtws/` as the rtws, so dev/UX runs don’t pollute the root workspace.

- **dominds/** — Local checkout of the main framework source (TypeScript backend + Vite webapp); intentionally gitignored here
- **.minds/** — Team definition + workspace memory for DevOps/feat-dev runs in the repo root rtws
- **ux-rtws/** — Dedicated rtws for WebUI dev/UX testing (`.minds/`, `.dialogs/`, `.env.local`, fixtures, helper scripts)

---

## TypeScript Purist Principles

### Zero Tolerance for `any`

- Every `any` is a critical violation requiring remediation
- Use specific narrow types or `unknown` with type guards
- Enforce `unknown` in catch blocks and external data

### Discriminated Unions Excellence

- Required for ALL state representations
- Every union variant MUST have unique literal discriminant
- Reject helper functions - use direct property checks
- Enforce exhaustive switch statements

### Static Property Verification

- ALWAYS stick to statically verifiable existing properties
- Treat runtime guarding or guessing property existence as an anti-pattern
- If runtime narrowing or optional chaining (`?.`) is truly unavoidable, provide a documented rationale in comments

---

## Common Commands

All commands run from the root directory unless otherwise noted.

### Bootstrapping (DevOps)

Prefer installing the **released** `dominds` CLI globally (stable versions from the registry), then run it from the repo root to use root `.minds/` as the team definition/workspace memory:

```bash
# Option A (preferred): stable release from npm registry
npm install -g dominds

# Option B (emergency only): if the released CLI is broken, link a clean checkout of `main`
# from a different directory (do NOT link the same `./dominds` checkout you are editing for PRs).
git clone https://github.com/longrun-ai/dominds.git ~/src/dominds-main
pnpm -C ~/src/dominds-main install
pnpm -C ~/src/dominds-main run build:backend
pnpm -C ~/src/dominds-main link --global
```

Then:

```bash
dominds           # default = webui, rtws = repo root
dominds read      # inspect team config from ./ .minds/
dominds tui --help
```

### Development

```bash
# Start both backend (5556) and frontend (5555) dev servers
./dev-server.sh

# Server management commands
./dev-server.sh status   # Check if servers are running
./dev-server.sh stop     # Stop all servers
./dev-server.sh restart  # Force restart servers
```

All development servers are managed by `dev-server.sh`.

### Build

```bash
cd dominds
pnpm run build              # Build both backend and frontend
pnpm run build:backend      # TypeScript compile backend to dist/
pnpm run build:frontend     # Vite build webapp to dist/static
```

### Linting & Formatting

```bash
cd dominds
pnpm run lint:types         # TypeScript type checking
pnpm run format             # Prettier format (code + markdown)
```

### Testing

```bash
# Run tests using pnpm
pnpm -C dominds/tests run parsing
pnpm -C dominds/tests run realtime
```

### CLI Tools

**CAVEATS: they are not well implemented yet, avoid using them**

```bash
# Terminal UI for dialogs
# - DevOps/feat-dev: run in repo root (uses ./ .minds/)
npx tsx dominds/main/cli.ts tui
# - WebUI dev/UX: run against ux-rtws/
npx tsx dominds/main/cli.ts tui -C ux-rtws

# Read team member configurations
npx tsx dominds/main/cli.ts read
npx tsx dominds/main/cli.ts read -C ux-rtws
```

All CLI tools operate on the current working directory as the rtws by default; use repo root for DevOps/feat-dev (`./.minds/**`), and `-C ux-rtws` (or run from `ux-rtws/`) for WebUI dev/UX (`ux-rtws/.minds/**`).

## Architecture

### Backend (`dominds/main/`)

- **server.ts** — HTTP/WebSocket server entry point (port 5556 dev, 5666 prod)
- **dialog.ts** — Dialog state machine (user ↔ agent conversations)
- **llm/** — LLM integration layer (OpenAI, Anthropic)
- **tools/** — Tool system with fs, os, mem (workspace memory), txt
- **persistence.ts** — Dialog and workspace state storage

### Frontend (`dominds/webapp/`)

- **src/components/** — React components (dialog, input, team members, Q4H panel)
- **src/services/** — WebSocket client and API layer
- **src/main.ts** — SPA entry point

### Wire Protocol

WebSocket communication uses a simple message protocol defined in `main/shared/types/wire.ts`. The frontend connects to `/ws` for real-time dialog updates.

### Streaming Substream Ordering (Thinking / Saying)

- Within a single generation (`genseq`), thinking and saying may alternate any number of times as segments: `start → chunk* → finish`.
- Segments MUST NOT overlap: a new `start` MUST NOT occur before the previous segment has `finish`ed (at most one active substream at a time).
- The UI MUST render sections in event arrival order (do not reorder DOM to “fix” ordering).
- If overlap/out-of-order is detected, the backend should emit a loud `stream_error_evt` to make the issue debuggable across the stack.

### Workspace Context

This repo uses two runtime workspaces:

- **DevOps rtws (repo root)**: use `./.minds/**` for the feat-dev agent team definition + workspace memory.
- **WebUI dev/UX rtws (`ux-rtws/`)**: used by `./dev-server.sh`; safe to wipe/reset; E2E stories in `ux-stories/` assume this.

## Key Conventions

- **Node.js version**: 22.x required (>=22 <23 in package.json engines)
- **TypeScript**: Strict mode with no `any` allowed
- **i18n (中文语义基准)**: Treat `zh` text as the canonical source of semantics. Never update `zh` content by translating from `en`; instead, update `en` to match `zh` when needed.
- **Terminology (Context Matters)**:
  - **User-facing context (WebUI copy / prompts / examples)**: follow the terminology glossary. Prefer “Mainline dialog / Sideline dialog” (ZH: `主线对话 / 支线对话`) and avoid implementation terms like `root/main/subdialog/supdialog`, as well as hierarchy-implying phrasing (e.g. ZH: `父对话/子对话`). If you must describe relationships, prefer “requester/responder” or “upstream/downstream”.
  - **Implementation context (code / logs / wire / storage)**: it’s OK to use `root dialog / main dialog / subdialog / supdialog`, but do not surface these terms directly into user-facing copy.
  - Reference: `dominds/docs/dominds-terminology.md`, especially **“Dialog Terms（主线对话 / 支线对话）”** and **“Supdialog / 上游对话”** (and the cross-note about implementation terms vs user-facing terms).
- **Logs**: `./dev-server.sh` redirects stdout/stderr to `logs/` (wrapper logs)
- **Dialogs**: persisted under the chosen rtws (repo root `./.dialogs/` for DevOps; `ux-rtws/.dialogs/` for WebUI dev/UX)

## Git Policy (Humans Manage Commits)

- **Do not create or rewrite commits**: never run `git commit`, `git merge`, `git rebase`, `git cherry-pick`, `git reset`, or `git push` unless explicitly instructed.
- **Do not add `dominds/` to this repo**: `dominds/` is intentionally gitignored; changes to `dominds` should go through PRs in the `dominds` repo.
- Read-only git commands (`git status`, `git diff`, `git log`, `git show`, `git blame`) are allowed.
- **Parallel worktree edits are normal**: assume humans and other agents may modify the same worktree concurrently. Do not assume exclusive control or that the working tree stays stable during a task.
- **Monitor diffs to avoid clobbering**: re-check `git status` / `git diff` (and `git -C dominds status` / `git -C dominds diff` when working in `dominds/`) before making edits to files, and especially before any “cleanup” actions.
- **Never revert unrelated changes by default**: do not discard/revert/overwrite unstaged changes from other ongoing tasks unless explicitly asked. If you detect unrelated diffs, call them out and ask how to proceed.
