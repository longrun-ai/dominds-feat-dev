# Dominds Feature Development

This repository is the **dev wrapper workspace** used to do **PR-based development** on `dominds`.

Key idea: the actual framework source lives in a local checkout at `dominds/` (a normal Git repo), while this repo provides the workspace layout, scripts, logs, and UX testing setup.

The repo root is also used as the **DevOps runtime workspace (rtws)** for feat-dev: `.minds/` is the agent team definition and workspace memory used when you run Dominds/agents against this repo.

For WebUI dev/UX testing, `./dev-server.sh` runs the Dominds backend + frontend with `ux-rtws/` as the rtws, so dev/UX runs don’t pollute the root workspace.

## Repository Layout

- `dominds/` — local checkout of the `dominds` source (TypeScript backend + Vite webapp), **gitignored by this repo**
- `.minds/` — team definition + workspace memory for DevOps/feat-dev runs in the repo root rtws
- `ux-rtws/` — dedicated rtws for dev/UX testing (`.minds/`, `.dialogs/`, `.env.local`, fixtures, helper scripts)
- `ux-stories/` — E2E/UX stories and checklists (assumes `ux-rtws/` is the rtws)
- `logs/` — `dev-server.sh` wrapper stdout/stderr logs (intentionally not tracked)

## Getting Started

Clone this repository:

```bash
git clone https://github.com/longrun-ai/dominds-feat-dev.git
cd dominds-feat-dev
```

Then create your local `dominds/` checkout (recommended: fork-based):

```bash
# 1) Fork https://github.com/longrun-ai/dominds to your account (example: YOUR_GH/dominds)
# 2) Clone your fork into ./dominds
git clone https://github.com/YOUR_GH/dominds.git dominds

# 3) Set upstream to the official repo
cd dominds
git remote add upstream https://github.com/longrun-ai/dominds.git
git fetch upstream --prune
```

## PR-Based Workflow (Recommended)

This project is designed so that **all code PRs happen in the `dominds` repo**.

- You work in `./dominds` like a normal repository (branches, commits, PRs).
- This outer repo intentionally does **not** track `./dominds` (it is gitignored), so there is **no extra PR here** just
  to “bump” `dominds`.

### Workflow: fork + feature branch + frequent rebase

1. Ensure you have both remotes:
   ```bash
   cd dominds
   git remote -v
   # origin   -> your fork (push target)
   # upstream -> https://github.com/longrun-ai/dominds.git
   ```
2. Create a feature branch based on `upstream/main`:
   ```bash
   git fetch upstream --prune
   git checkout -B feat/<short-name> upstream/main
   ```
3. Push to your fork and open a PR to `longrun-ai/dominds:main`:
   ```bash
   git push -u origin feat/<short-name>
   ```
4. Frequently rebase onto `upstream/main` while the PR is in flight:
   ```bash
   git fetch upstream
   git rebase upstream/main
   git push --force-with-lease
   ```
5. After your PR merges, bring your local `main` up to date:
   ```bash
   git checkout main
   git pull --ff-only upstream main
   ```

## Development

### Install `dominds` from this checkout (recommended)

For contributor development, the most reliable setup is to “dogfood” your in-tree PR checkout by installing `./dominds` as the global `dominds` CLI. This gives you a stable global CLI that only changes when you rebuild (normal source edits and `dev-server.sh` restarts won’t affect it until you run another build).

For day-to-day iteration, prefer the dev server (hot reload / fast feedback). Only rebuild when you explicitly want to refresh the “installed snapshot” you run via the `dominds` CLI.

First, remove any existing global `dominds` installs (npm and pnpm install to different locations and can shadow each other via `PATH`):

```bash
npm uninstall -g dominds
pnpm remove -g dominds

pnpm -C dominds install
pnpm -C dominds build
pnpm add -g ./dominds
```

Run it from this repo root (rtws = repo root):

```bash
dominds      # default = webui, rtws = repo root
```

To pick up your latest PR changes, rebuild (and reinstall to be safe across environments):

```bash
pnpm -C dominds build
pnpm add -g ./dominds
```

If you want to switch back to the released CLI:

```bash
pnpm remove -g dominds
npm uninstall -g dominds
npm install -g dominds
```

### WebUI Dev Server (Dev/UX)

Start dev servers (ports come from root `.env.local`:
`DOMINDS_BACKEND_PORT` / `DOMINDS_FRONTEND_PORT`):

```bash
# Example root .env.local
# DOMINDS_FRONTEND_PORT=<frontend_port>
# DOMINDS_BACKEND_PORT=<backend_port>

./dev-server.sh
```

Useful server commands:

```bash
./dev-server.sh status
./dev-server.sh stop
./dev-server.sh restart
```
