# Dominds Feature Development

This repository is the **outer runtime workspace (rtws)** used to do **PR-based development** on `dominds`.

Key idea: the actual framework source lives in a local checkout at `dominds/` (a normal Git repo), while this outer repo
provides the workspace layout, scripts, logs, and team state you use during development.

## Repository Layout

- `dominds/` — local checkout of the `dominds` source (TypeScript backend + Vite webapp), **gitignored by this repo**
- `.minds/` — team memory for the outer workspace (rtws)
- `.dialogs/`, `logs/` — runtime artifacts (intentionally not tracked)

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

Start both backend (5556) and frontend (5555) dev servers:

```bash
./dev-server.sh
```

Useful server commands:

```bash
./dev-server.sh status
./dev-server.sh stop
./dev-server.sh restart
```
