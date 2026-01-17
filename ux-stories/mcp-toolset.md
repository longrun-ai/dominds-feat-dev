# Dominds WebUI E2E: MCP Toolsets + Tools Registry (Hot Reload + Problems)

You are the **tester agent** standing in for a human operator. Your role is to validate that
**Dominds MCP integration** works end-to-end and remains stable under **runtime config changes**.

This UX story is intended to be **re-used for regression detection**. Prefer **observable UI
invariants** (counts, button states, visible lists, toolset/tool names, no console errors, correct
Problems entries) over “agent prose quality”.

Reference design doc: `docs/mcp-support.md`

---

## The Test Purpose

This test validates Dominds infrastructure, not MCP server business logic and not LLM “smartness”.

Pass/fail is based on:

- Hot reload correctness (add/update/remove servers without restart)
- Tool(set) registration correctness (grouping, collisions, naming transforms)
- Problems correctness (clear messages, server/tool identification, auto-clear)
- Tools panel correctness (shows currently registered toolsets/tools; refreshes when switched)
- Best-effort behavior (Dominds keeps running even when MCP is broken)

---

## Business Goal

Enable operators to safely wire in external tool sources (MCP servers) at runtime:

- Add an MCP server and immediately see its toolset + tools in the WebUI
- Fix mistakes quickly (config edits take effect without restarting Dominds)
- Avoid risky availability regressions (last-known-good servers stay working until replaced)
- Understand failures via a first-class Problems surface

---

## Tester Hardening Rules

- **Assert infra, not tool output quality.**
- **Time-bound UI transitions** (unless noted otherwise):
  - Tools panel refresh visible within **5s** (once MCP is already connected/healthy)
  - First-time MCP server registration may take up to **30s** (server process start / connect +
    initial tool listing)
  - Problems panel updates within **5s**
- **One retry only** for suspected websocket/network lag; second failure = infra bug.
- **Check console errors after every action**: any new errors after a step = fail (unless explicitly
  allowed).
- **Don’t depend on caches:** always re-open the Tools activity and/or hit its refresh button for a
  fresh snapshot.

---

## Setup

### S0) Start Dominds

From repo root:

```bash
./dev-server.sh restart
```

### S0b) Optional: prepare `.env.local` for stdio env-mapping test

This enables verifying `{ env: SOME_HOST_VAR }` mappings for stdio MCP servers.

Create `.env.local` in the **rtws repo root**:

```dotenv
UX_RENAME_SOURCE=renamed_from_env_local
UX_HOST_SECRET=host_secret_from_env_local
```

If Dominds is already running, restart it after creating `.env.local`:

```bash
./dev-server.sh restart
```

### S0c) Team config note (T1c needs tool access)

T1c requires the testee agent to have access to:

- the stdio MCP server toolset (`sdk_stdio`, created at runtime from `.minds/mcp.yaml`)
- `mcp_admin` (contains `mcp_restart`)
- `env` (optional, only needed for the `env_set` hot-edit step)

This UX story must be runnable with the **ad-hoc team** (no `.minds/team.yaml`).

If you do provide `.minds/team.yaml`, make sure it grants the toolsets above to the selected
teammate. `team.yaml` changes are picked up the next time Dominds reloads team config (e.g., on the
next model generation cycle / request that calls `Team.load()`, and on API refresh), but the WebUI
may not live-update team info until you refresh/reopen the relevant panel.

### S1) Ensure the workspace has no leftover MCP config (baseline)

Ensure `.minds/mcp.yaml` is absent (or empty) in the **rtws repo root** (not `dominds/.minds/`).
Deletion must be treated as “clear all servers”.

### S2) Streamable HTTP MCP server (recommended)

This uses the locally installed `@modelcontextprotocol/sdk` example server as a stable tool source.
It listens on `http://127.0.0.1:$MCP_PORT/mcp` and exposes tools like `greet`, `multi-greet`, and
`collect-user-info`.

From repo root:

```bash
MCP_PORT=3000 node dominds/node_modules/@modelcontextprotocol/sdk/dist/esm/examples/server/simpleStreamableHttp.js
```

Leave it running for the rest of this test. (Stop it only when a scenario explicitly asks you to.)

### S3) Stdio MCP server (spawned by Dominds)

For stdio transport, Dominds spawns the server process based on `.minds/mcp.yaml`. A small stdio
test server is included at `ux-stories/fixtures/mcp-stdio-server.mjs:1`.

Important: stdio transport uses **stdout** for the MCP protocol. The test server writes readiness
to **stderr** only.

### S3) Calibration gate: ensure E2E helpers are loaded

Run in browser console:

```javascript
if (typeof window.__e2e__?.snapshotDomindsUI !== 'function') {
  const ts = String(Date.now());

  if (typeof window.__domObservation__ !== 'object') {
    const obs = document.createElement('script');
    obs.src = `/testing/dom-observation-utils.js?ts=${ts}`;
    document.head.appendChild(obs);
    await waitUntil(() => typeof window.__domObservation__ === 'object', 5000);
  }

  const helper = document.createElement('script');
  helper.src = `/testing/e2e-test-helper.js?ts=${ts}`;
  document.head.appendChild(helper);
  await waitUntil(() => typeof window.__e2e__?.snapshotDomindsUI === 'function', 5000);
}
```

### S4) Baseline UI health

```javascript
window.__e2e__.checkConsoleErrors({ clear: true, threshold: 0 });
const baseline = window.__e2e__.snapshotDomindsUI();
```

---

## Helper Snippets (Tools + Problems)

```javascript
function getAppShadow() {
  const s = window.__e2e__?.getAppShadow?.();
  if (!s) throw new Error('Missing dominds-app shadow root');
  return s;
}

function clickActivity(name /* 'tools' | 'team-members' | ... */) {
  const s = getAppShadow();
  const btn = s.querySelector(`.activity-button[data-activity="${name}"]`);
  if (!(btn instanceof HTMLButtonElement)) throw new Error(`Missing activity button: ${name}`);
  btn.click();
}

function getToolsPanelState() {
  const s = getAppShadow();
  const view = s.querySelector(`.activity-view[data-activity-view="tools"]`);
  if (!(view instanceof HTMLElement)) throw new Error('Missing tools activity view');

  const hidden = view.classList.contains('hidden');
  const ts = s.querySelector('#tools-registry-timestamp');
  const list = s.querySelector('#tools-registry-list');
  const refresh = s.querySelector('#tools-registry-refresh');

  if (!(list instanceof HTMLElement)) throw new Error('Missing #tools-registry-list');
  if (!(refresh instanceof HTMLButtonElement)) throw new Error('Missing #tools-registry-refresh');

  const toolsets = [...list.querySelectorAll('details.toolset')].map((d) => {
    const title = d.querySelector('summary.toolset-title')?.textContent?.trim() || '';
    const tools = [...d.querySelectorAll('.tool-item .tool-name')].map((n) =>
      (n.textContent || '').trim(),
    );
    return { title, tools };
  });

  return {
    visible: !hidden,
    timestamp: (ts?.textContent || '').trim(),
    toolsets,
    refresh,
  };
}

function toggleProblemsPanel(open /* boolean */) {
  const s = getAppShadow();
  const btn = s.querySelector('#toolbar-problems-toggle');
  if (!(btn instanceof HTMLButtonElement)) throw new Error('Missing #toolbar-problems-toggle');
  const panel = s.querySelector('#problems-panel');
  if (!(panel instanceof HTMLElement)) throw new Error('Missing #problems-panel');
  const isHidden = panel.classList.contains('hidden');
  if (open && isHidden) btn.click();
  if (!open && !isHidden) btn.click();
  const finalHidden = panel.classList.contains('hidden');
  if (open && finalHidden) throw new Error('Problems panel did not open');
  if (!open && !finalHidden) throw new Error('Problems panel did not close');
}

function getProblemsState() {
  const s = getAppShadow();
  const btn = s.querySelector('#toolbar-problems-toggle');
  if (!(btn instanceof HTMLButtonElement)) throw new Error('Missing #toolbar-problems-toggle');
  const count = Number.parseInt(btn.querySelector('span')?.textContent || '0', 10) || 0;
  const severity = btn.getAttribute('data-severity') || '';
  const list = s.querySelector('#problems-list');
  if (!(list instanceof HTMLElement)) throw new Error('Missing #problems-list');
  const items = [...list.querySelectorAll('.problem-item')].map((el) => {
    const msg = el.querySelector('.problem-message')?.textContent?.trim() || '';
    const detail = el.querySelector('.problem-detail')?.textContent?.trim() || '';
    return { msg, detail, severity: el.getAttribute('data-severity') || '' };
  });
  return { count, severity, items };
}
```

---

## Test Cases

### T0) Baseline: no MCP config ⇒ no MCP toolsets; Dominds still healthy

1. Ensure `.minds/mcp.yaml` does not exist (or is empty).
2. Open Tools activity:

   ```javascript
   clickActivity('tools');
   const t0 = getToolsPanelState();
   ```

Expected:

- Tools panel renders without crashing; no console errors.
- Toolsets list contains only built-in toolsets/tools (or is empty depending on baseline registry).
- Problems count is stable and does not show MCP server errors.

### T1) Add one `streamable_http` MCP server; tools appear and are grouped by toolset

Create `.minds/mcp.yaml`:

```yaml
version: 1
servers:
  sdk_http:
    transport: streamable_http
    url: http://127.0.0.1:3000/mcp
    headers: {}
    tools:
      whitelist: []
      blacklist: []
    transform: []
```

Then in UI:

```javascript
clickActivity('tools');
getToolsPanelState().refresh.click();
await waitUntil(() => {
  const t = getToolsPanelState();
  return t.toolsets.some((ts) => ts.title.startsWith('sdk_http '));
}, 30000);
```

Expected:

- A toolset titled like `sdk_http (N)` exists.
- It includes tool names like `greet` and `multi-greet` (exact set depends on server version).
- Problems does not show `mcp_server_*` error for `sdk_http`.

### T1b) Add one `stdio` MCP server; tools appear and are grouped by toolset

Edit `.minds/mcp.yaml`:

```yaml
version: 1
servers:
  sdk_stdio:
    transport: stdio
    command: node
    args: ['ux-stories/fixtures/mcp-stdio-server.mjs']
    env: {}
    tools:
      whitelist: []
      blacklist: []
    transform:
      - prefix: 'stdio_'
```

Then in UI, refresh Tools activity and wait (first-time spawn + list can take a bit longer):

Expected:

- A toolset titled like `sdk_stdio (3)` exists.
- It includes `stdio_greet`, `stdio_echo`, and `stdio_env_report`.
- Problems does not show a per-server error for `sdk_stdio`.

### T1c) Stdio env passing + env rename mapping

Edit `.minds/mcp.yaml` to include env mappings for the stdio server:

```yaml
version: 1
servers:
  sdk_stdio:
    transport: stdio
    command: node
    args: ['ux-stories/fixtures/mcp-stdio-server.mjs']
    env:
      MCP_DIRECT: direct_literal_from_mcp_yaml
      MCP_RENAMED: { env: UX_RENAME_SOURCE }
      MCP_HOST_SECRET: { env: UX_HOST_SECRET }
    tools:
      whitelist: []
      blacklist: []
    transform: []
```

Expected:

- `sdk_stdio` is still registered and contains tools (`greet`, `echo`, `env_report`).
- Create the dialog using a `.tsk/` task package directory (e.g. `tasks/ux-dlg-stop-resume.tsk/`),
  since Dominds dialog task-doc paths are required to end with `.tsk/`.
- Create a dialog and ask the testee agent to call MCP tool `env_report` (no args). The returned JSON must include:
  - `MCP_DIRECT: "direct_literal_from_mcp_yaml"`
  - `MCP_RENAMED: "renamed_from_env_local"` (from `.env.local`)
  - `MCP_HOST_SECRET: "host_secret_from_env_local"` (from `.env.local`)

Hot-change invariant (do not restart Dominds):

1. Edit `.minds/mcp.yaml` to change `MCP_DIRECT` (e.g. `direct_literal_from_mcp_yaml_v2`).
2. Ask the testee agent to call `mcp_restart` with `{ serverId: 'sdk_stdio' }`.
3. Ask the testee agent to call `env_report` again; `MCP_DIRECT` must reflect the new value.

Optional (host env hot-edit):

1. Ask the testee agent to call `env_set` with `{ key: 'UX_RENAME_SOURCE', value: 'renamed_hot' }`.
2. Call `mcp_restart` again for `sdk_stdio`.
3. `env_report` must return `MCP_RENAMED: "renamed_hot"`.

### T2) Hot reload: editing `.minds/mcp.yaml` updates tool registration without restart

Edit `.minds/mcp.yaml` to whitelist-only mode (since blacklist is empty):

```yaml
version: 1
servers:
  sdk_http:
    transport: streamable_http
    url: http://127.0.0.1:3000/mcp
    tools:
      whitelist: ['greet']
      blacklist: []
    transform: []
```

Then:

1. Open Tools activity and refresh.
2. Open Problems panel.

Expected:

- Tools list for `sdk_http` now only includes `greet` (or the subset matching whitelist).
- Problems includes entries indicating tools were excluded by whitelist-only mode, with **serverId**
  and **toolName** in the detail.
- When you revert whitelist back to `[]`, the excluded tools return and those Problems auto-clear.

### T3) Whitelist + blacklist mode: whitelist overrides blacklist; neither-listed tools are accepted

Edit `.minds/mcp.yaml`:

```yaml
version: 1
servers:
  sdk_http:
    transport: streamable_http
    url: http://127.0.0.1:3000/mcp
    tools:
      whitelist: ['greet'] # cherry-pick allow even if blacklisted
      blacklist: ['greet', 'multi-*']
    transform: []
```

Expected:

- `greet` is still registered (whitelist overrides blacklist).
- `multi-greet` is not registered (blacklisted and not whitelisted).
- Any tool that matches neither list remains registered (whitelist does not restrict when a
  blacklist is present).
- Problems include clear entries for blacklisted tools (with serverId + toolName).

### T4) Name transform collisions: within-server collision is detected and reported

Edit `.minds/mcp.yaml` to force a within-server collision (`multi-greet` becomes `greet`):

```yaml
version: 1
servers:
  sdk_http:
    transport: streamable_http
    url: http://127.0.0.1:3000/mcp
    tools:
      whitelist: []
      blacklist: []
    transform:
      - prefix:
          remove: 'multi-'
          add: ''
```

Expected:

- Only one of the colliding tools is registered under the collided name.
- Problems includes a collision warning identifying the server and the collided tool name.
- After removing the transform, the collision Problem auto-clears and both tools can appear again.

### T5) Reject invalid Dominds tool names after transforms

Edit `.minds/mcp.yaml` to introduce an invalid tool name (contains `:`):

```yaml
version: 1
servers:
  sdk_http:
    transport: streamable_http
    url: http://127.0.0.1:3000/mcp
    tools:
      whitelist: []
      blacklist: []
    transform:
      - prefix: 'bad:'
```

Expected:

- Tools are rejected (not registered) due to invalid name rule.
- Problems include entries that identify server + tool and mention the validity rule.
- Removing the invalid transform restores tool registration.

### T6) Per-server independent commit + last-known-good behavior

Create `.minds/mcp.yaml` with **two** servers pointing at the same MCP endpoint:

```yaml
version: 1
servers:
  good_a:
    transport: streamable_http
    url: http://127.0.0.1:3000/mcp
    tools: { whitelist: [], blacklist: [] }
    transform:
      - prefix: 'a_'
  broken_b:
    transport: streamable_http
    url: http://127.0.0.1:3000/mcp
    headers:
      Authorization:
        env: THIS_ENV_SHOULD_NOT_EXIST
    tools: { whitelist: [], blacklist: [] }
    transform:
      - prefix: 'b_'
```

Expected:

- `good_a` is registered and contains tools like `a_greet`.
- `broken_b` surfaces a server error Problem (missing required host env var), but **does not**
  prevent `good_a` from functioning.
- Fix `broken_b` (remove the missing env header mapping) and confirm it becomes registered without
  restarting Dominds.

Last-known-good invariant to verify:

- Make `broken_b` succeed once (remove the missing env mapping), confirm `broken_b` is present.
- Then re-introduce the missing env mapping and confirm `broken_b` **remains** present (stays on
  the last-known-good runtime) while a Problem indicates reload failed.

### T7) Deleting `.minds/mcp.yaml` clears MCP registrations

Delete `.minds/mcp.yaml` while Dominds is running.

Expected:

- All MCP server toolsets (e.g. `sdk_http`, `good_a`, `broken_b`) disappear from Tools panel after refresh.
- (`mcp_admin` is built-in and is expected to remain.)
- MCP Problems for removed servers auto-clear (workspace becomes clean).
- Dominds remains usable (no crash, no dead UI).

### T8) Invalid YAML does not evict last-known-good; shows workspace-level Problem

Precondition: `sdk_http` is currently registered and visible in Tools panel.

1. Edit `.minds/mcp.yaml` into an invalid YAML (syntax error), e.g.:

   ```yaml
   version: 1
   servers:
     sdk_http:
       transport: streamable_http
       url: http://127.0.0.1:3000/mcp
       tools:
         whitelist: []
         blacklist: []
       transform: [
   ```

2. Refresh Tools activity, open Problems.

Expected:

- Existing `sdk_http` toolset stays present (last-known-good preserved).
- Problems includes a workspace config error referencing `.minds/mcp.yaml`.
- Fix YAML back to valid and confirm the workspace config error auto-clears.

---

## Evidence Checklist (Regression Notes)

For each test run, capture:

- A Tools panel snapshot showing toolsets grouped (`details.toolset`), and timestamp changes after
  refresh.
- A Problems panel snapshot showing at least one MCP problem with serverId + toolName in detail.
- Confirmation that issues auto-clear when config is fixed or servers removed.
- Confirmation that tool list reflects hot reload without restarting Dominds.
