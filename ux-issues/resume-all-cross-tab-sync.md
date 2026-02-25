# Global `Resume all` count: cross-tab convergence flake (story2)

## Status (updated: 2026-02-10)

- Direction corrected and implemented.
- Current state: **PR-1 code fix landed in workspace**, typecheck passed; gate re-validation pending manual 2-tab UX run.

## Direction correction

Previous document direction had a key mistake: it treated client-local cross-tab hints (`BroadcastChannel` / `localStorage`) as an equal candidate path.

For Dominds this state should be synchronized by backend to all connected clients, using shared wire packet types so frontend branch handling is statically checked.

Final direction:

- Backend emits and broadcasts a global run-control refresh packet.
- Frontend consumes that packet via shared `WebSocketMessage` discriminated union.
- Remove client-local tab-to-tab hint path.

## Implemented fix (latest)

1. Shared wire packet added

- File: `dominds/main/shared/types/wire.ts`
- Added:
  - `RunControlRefreshReason`
  - `RunControlRefreshMessage` (`type: 'run_control_refresh'`)
- Added to `WebSocketMessage` union.

2. Backend broadcast added

- File: `dominds/main/server/websocket-handler.ts`
- `handleEmergencyStop(...)` now emits `run_control_refresh` with reason `emergency_stop`.
- `handleResumeAll(...)` now emits `run_control_refresh` with reason `resume_all`.
- In `setupWebSocketServer(...)`, added broadcaster that sends this packet to **all connected WebSocket clients**.

3. Frontend switched to wire-driven handling

- File: `dominds/webapp/src/components/dominds-app.tsx`
- Removed local cross-tab sync design (`BroadcastChannel`/`localStorage` hint logic).
- Global controls (`emergency_stop` / `resume_all`) now only send WS command; refresh convergence is triggered by backend broadcast packet.
- Added global branch:
  - `case 'run_control_refresh': this.scheduleRunControlRefresh(message.reason)`
- `dlg_run_state_marker_evt` now uses typed branch (`message.kind`) and covers both:
  - `resumed -> run_state_marker_resumed`
  - `interrupted -> run_state_marker_interrupted`

## Why this is the correct fix

- Single source of truth: backend action completion emits global signal.
- No browser-local side channel dependency.
- Shared wire contract enforces compile-time branch consistency on frontend.
- Better multi-client behavior across tabs/windows/devices, not only same-browser tabs.

## Verification status

- Type check passed:
  - `pnpm -C dominds run lint:types`
- Remaining to close story2 gate:
  - Re-run 2-tab emergency-stop + resume-all scenario (3 repetitions).
  - Confirm convergence to `Resume all = 0` within 5s for both tabs.
  - Re-run story1/3/4 smoke for regression check.

## Repro (for final gate re-check)

1. Open Tab A `http://localhost:<DOMINDS_FRONTEND_PORT>/` (Connected).
2. Open Tab B same URL (Connected).
3. Trigger a proceeding dialog, use header `Emergency stop`.
4. Click header `Resume all`.
5. Observe both tabs for 5 seconds.

Expected:

- Both tabs converge to `Resume all = 0`.
- Resume-all button disabled consistently in both tabs.
