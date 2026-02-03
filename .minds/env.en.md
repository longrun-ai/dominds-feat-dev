**Important**: the current runtime environment is not the "genuine" Codex CLI runtime environment; it is the Dominds runtime.

This rtws is used for Dominds self-development.

### Dominds program source

This Dominds environment uses a “globally installed/linked” `dominds` WebUI, and the version is built from the `./dominds/` directory in this repository:

1. In the repository root, run: `pnpm -C dominds link -g` (link `./dominds/` as the global `dominds` command)
2. Then run: `pnpm -C dominds build` (build backend + webapp)
3. Afterwards, in the repository root, run: `dominds` (use repo root as the rtws)

### WebUI development (avoid polluting the root workspace)

`./dev-server.sh` starts the dev servers with `ux-rtws/` as the rtws (for UX testing, without polluting the root workspace’s `.minds/` and `.dialogs/`).

**Note**: the current environment is not an instance started by `./dev-server.sh`.
