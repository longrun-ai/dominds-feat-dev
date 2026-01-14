## Project Overview

This is an **in-tree development setup** for `dominds` — an AI-powered DevOps framework. The source code lives in the `dominds/` subdirectory, and **this outer workspace is the primary runtime workspace (rtws)** for the development team.

- **dominds/** — The main framework source (TypeScript backend + Vite webapp)
- **.minds/** — Team memory for the outer workspace (rtws = runtime workspace)

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
# Run tests with tests/ as CWD for correct path resolution
cd dominds/tests
npx tsx texting/parsing.ts
```

### CLI Tools

**CAVEATS: they are not well implemented yet, avoid using the**

```bash
# Terminal UI for dialogs (operates on outer rtws)
npx tsx dominds/main/cli/tui.ts

# Read team member configurations (outer rtws)
npx tsx dominds/main/cli/read.ts
```

All CLI tools operate on the outer workspace (rtws) by default.

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

### Workspace Context

The outer workspace (`.minds/` in root) is the primary runtime workspace for the development team. All tool operations and dialogs operate on this workspace by default.

## Key Conventions

- **Node.js version**: 22.x required (>=22 <23 in package.json engines)
- **TypeScript**: Strict mode with no `any` allowed
- **Logs**: Written to outer workspace's `logs/` directory
- **Dialogs**: Persisted as YAML files in outer workspace's `.dialogs/` directory

## Git Policy (Humans Manage Commits)

- **Do not create or rewrite commits**: never run `git commit`, `git merge`, `git rebase`, `git cherry-pick`, `git reset`, or `git push` unless explicitly instructed.
- **Do not change submodule pointers by default**: avoid `git submodule update`, checking out a different submodule commit/branch, or otherwise changing the `dominds/` submodule HEAD unless explicitly instructed.
- Read-only git commands (`git status`, `git diff`, `git log`, `git show`, `git blame`) are allowed.
