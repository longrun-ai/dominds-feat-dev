# WebUI Testing Guide

This guide covers the Dominds WebUI end-to-end (E2E) testing approach, including real-time LLM streaming, dialog persistence, and helper utilities for browser automation.

## Quick Start

1. Start the dev server: `./dev-server.sh`
2. Open frontend: `http://localhost:5555` (wait for "Connected" status)
3. Create a dialog: `New Dialog` → Create
4. Send messages and observe streaming behavior

## Architecture Overview

| Concept                    | Description                                                                                      |
| -------------------------- | ------------------------------------------------------------------------------------------------ |
| **Restoration API**        | `restoreDialogHierarchy()` restores full dialog trees on page reload                             |
| **Implicit Serialization** | All state changes persist automatically (no manual save calls)                                   |
| **File Persistence**       | Append-only JSONL rounds; Q4H/reminders use overwrite mode                                       |
| **Event Delivery**         | Backend emits LLM lifecycle events via (Pub/Sub)Chan; frontend updates per chunk                 |
| **UI Generation**          | Tracking begins on `dlg_generating_start`; phases (thinking/saying/calling) update incrementally |

### Generation Lifecycle Events

```
dlg_generating_start
  → dlg_thinking_start / chunk / finish
  → dlg_saying_start / chunk / finish
  → dlg_calling_start / headline_chunk / body_chunk / finish
→ dlg_generating_finish
```

## Runtime Environment

- **Frontend**: `http://localhost:5555`
- **Backend**: `http://localhost:5556`
- **Logs**: `logs/` directory (dev-server wrapper stdout/stderr)
- **Workspace (rtws)**: `ux-rtws/` (dev-server runs processes with this as cwd)
- **Persistence**: `ux-rtws/.dialogs/run/<dialogId>/round-*.jsonl`

Note: the repo root has its own `.minds/` for DevOps/feat-dev work; WebUI dev/UX uses `ux-rtws/.minds/` instead.

## Project Structure

| Layer    | Location                                   | Purpose                                     |
| -------- | ------------------------------------------ | ------------------------------------------- |
| Backend  | `dominds/main/`                            | WebSocket server, dialog logic, persistence |
| Frontend | `dominds/webapp/`                          | React WebUI components                      |
| Testing  | `webapp/static/testing/e2e-test-helper.js` | Browser-based test utilities                |

## Shadow DOM Structure

The DOM uses Shadow DOM extensively for component encapsulation:

```
document.querySelector('dominds-app')           // Light DOM host
  └── .shadowRoot                               // Shadow DOM root
      ├── .header
      ├── .main-content
      │   ├── .sidebar
      │   │   ├── .sidebar-header
      │   │   │   ├── #new-dialog-btn
      │   │   │   └── dominds-team-members (right side)
      │   │   └── .sidebar-content
      │   │       └── dominds-dialog-list
      │   └── .content-area
      │       ├── .toolbar
      │       ├── .dialog-section
      │       │   ├── .conversation-scroll-area
      │       │   ├── .q4h-panel-container (inline, collapsible)
      │       │   │   ├── .q4h-toggle-bar (clickable, triangle arrow leftmost)
      │       │   │   └── .q4h-content (scrollable)
      │       │   └── .input-section (sticky bottom)
      │       │       └── .q4h-input-container
      │       │           └── .shadowRoot → textarea, send button
      └── dominds-dialog-list
          └── .shadowRoot → dialog items
```

### Quick Selector Reference

| Target            | Selector                                                            |
| ----------------- | ------------------------------------------------------------------- |
| App host          | `document.querySelector('dominds-app')`                             |
| Q4H toggle bar    | `app.shadowRoot.querySelector('.q4h-toggle-bar')`                   |
| Q4H resize handle | `app.shadowRoot.querySelector('.q4h-resize-handle')`                |
| Q4H panel         | `app.shadowRoot.querySelector('.q4h-panel-container')`              |
| Input area        | `app.shadowRoot.querySelector('dominds-q4h-input')`                 |
| Textarea          | `inputArea.shadowRoot.querySelector('[data-testid="chat-input"]')`  |
| Send button       | `inputArea.shadowRoot.querySelector('[data-testid="send-button"]')` |
| Dialog container  | `app.shadowRoot.querySelector('[data-testid="chat-thread"]')`       |
| Sidebar           | `app.shadowRoot.querySelector('dominds-dialog-list')`               |

## E2E Helper API

Testing utilities are available in the browser console:

- **Core functions**: `window.__e2e__`
- **DOM utilities**: `window.__domObservation__`

### Messaging

| Function                    | Returns                                     | Description                             |
| --------------------------- | ------------------------------------------- | --------------------------------------- |
| `fillAndSend(msg)`          | `Promise<string>`                           | Sends message, returns msgId            |
| `waitStreamingComplete(id)` | `Promise<boolean>`                          | Waits for generation bubble to complete |
| `snapshot()`                | Object                                      | Returns full chat state                 |
| `counts()`                  | `{userCount, bubbleCount, incompleteCount}` | Returns message/bubble counts           |
| `noLingering()`             | `boolean`                                   | True if no incomplete bubbles           |

**Example:**

```javascript
const msgId = await fillAndSend('your message here');
await waitStreamingComplete(msgId);
const state = await snapshot();
```

### Dialog Management

| Function                              | Description                     |
| ------------------------------------- | ------------------------------- |
| `createDialog(callsign, taskDocPath)` | Creates a new dialog            |
| `selectDialog(text)`                  | Selects dialog by text or ID    |
| `selectDialogById(rootId)`            | Selects dialog by root ID       |
| `getCurrentDialogInfo()`              | Returns current dialog metadata |

### Subdialog Navigation

| Function                             | Description                          |
| ------------------------------------ | ------------------------------------ |
| `openSubdialog(rootId, subdialogId)` | Opens a subdialog via call site link |
| `getSubdialogHierarchy()`            | Returns parent-to-current path       |
| `navigateToParent()`                 | Navigates back to supdialog          |

### State Inspection

| Function                                 | Description                   |
| ---------------------------------------- | ----------------------------- |
| `waitUntil(fn, timeoutMs?, intervalMs?)` | Polls until condition is true |
| `checkConsoleErrors(options?)`           | Checks for console errors     |
| `getQ4HCount()`                          | Gets current Q4H count        |
| `openQ4HPanel()`                         | Opens Q4H panel via toggle    |
| `waitForQ4HBadge(timeoutMs)`             | Waits for Q4H badge to appear |
| `waitForQ4HClear(timeoutMs)`             | Waits for Q4H badge to clear  |

### Console Error Tracking

`fillAndSend()` and `waitStreamingComplete()` automatically check for console errors (threshold: 0).

```javascript
// Manual error check
const errors = checkConsoleErrors({ clear: true, threshold: 0 });
```

## Testing Patterns

### Deterministic Input

Use exact message texts for reproducible results. LLM behavior varies with phrasing:

```javascript
// Avoid - non-deterministic
await fillAndSend('analyze this please');

// Use - exact text
await fillAndSend('COPY-PASTE EXACTLY: analyze the requirements');
```

### Bubble Lifecycle Verification

```javascript
const msgId = await fillAndSend(message);
await waitStreamingComplete(msgId);

const state = await snapshot();
assert(state.incompleteCount === 0); // All bubbles completed
assert(state.bubbleCount === expectedCount);
```

### Stream Error Handling

Errors during streaming appear only in the active session (not persisted):

```javascript
await waitStreamingComplete(msgId);
const errors = await checkConsoleErrors();
assert(state.incompleteCount === 0); // Stream still completes
```

### Persistence Reload Verification

After switching dialogs, verify restored state:

```javascript
const counts = await counts();
assert(counts.incompleteCount === 0); // No live streaming
assert(counts.bubbleCount === 2); // Previous messages restored

// Full parity check
const before = await snapshot();
const after = await snapshot();
assert(JSON.stringify(before) === JSON.stringify(after));
```

### Three-Retry Pattern for LLM Behavior

LLMs may describe actions without executing them:

```javascript
let attempts = 0;
while (attempts < 3) {
  await fillAndSend(message);
  await waitStreamingComplete();
  if (checkCondition()) break;
  attempts++;
}
// Document as known LLM issue if all retries fail
```

### Failure Classification

| Symptom                  | Check          | Type         | Resolution      |
| ------------------------ | -------------- | ------------ | --------------- |
| No event emitted         | Backend logs   | Code Bug     | → wpe           |
| Event logged, UI missing | DOM query      | Code Bug     | → coder         |
| LLM describes, no action | Events in logs | LLM Behavior | Refine prompts  |
| WebSocket disconnects    | Console + logs | Environment  | Restart servers |

### Q4H Testing with Mocks

Agent-initiated Q4H is testable with two-response mocks:

```json
{
  "responses": [
    {
      "message": "analyze requirements",
      "role": "user",
      "response": "I need to ask about budget. @human: What's the budget?"
    },
    {
      "message": "what's the budget?",
      "role": "user",
      "response": "With $50k budget, I recommend..."
    }
  ]
}
```

### Q4H Panel Testing

The Q4H panel is an inline, collapsible section in the dialog area:

```javascript
// Get current Q4H count
const count = await getQ4HCount();

// Open the Q4H panel by clicking the toggle bar
await openQ4HPanel();

// Wait for Q4H badge to appear (when agent requests Q4H)
await waitForQ4HBadge();

// Wait for Q4H badge to clear (after human responds)
await waitForQ4HClear();
```

## State Machines

### Dialog State

```
active → suspended (waiting) → resumed
```

### Q4H State

```
No Q4H → Pending (suspend) → Answered (resume) → Cleared
```

The Q4H panel displays inline between the conversation area and input section. When a Q4H request is pending, the toggle bar shows a badge indicator. Clicking the toggle bar opens/collapses the Q4H content area.

**Resize & State Memory:**

- The Q4H panel features a resize handle (`.q4h-resize-handle`) at the top.
- Users can drag the handle to adjust the panel's expanded height.
- The panel's expanded height is preserved in `lastQ4HExpandedHeight` state.
- When collapsed and then re-expanded, it restores the previous height.
- Layout uses flexbox; the input section has `flex-shrink: 0` to maintain visibility during resizing.

## DOM Observation Utilities

Available via `window.__domObservation__`:

### Shadow DOM Waiting

```javascript
waitForShadowElement(host, selector, opts); // Wait for element
waitForShadowElementHidden(host, selector, opts); // Wait for removal
```

### Light DOM Waiting

```javascript
waitForElement(selector, opts); // Wait for element
waitForElementGone(selector, opts); // Wait for removal
```

### Mutation-Based Waiting

```javascript
waitForDomChange(fn, opts); // Wait until condition met
```

## Validation Checklist

- [ ] Frontend shows LLM generation lifecycle events
- [ ] Streaming element removed when complete
- [ ] Messages persist in `ux-rtws/.dialogs/run/<dialogId>/`
- [ ] No blocking errors in backend logs
- [ ] Per-chunk updates visible without bubble flash
- [ ] Dialog hierarchy restores on page reload
- [ ] Q4H panel opens/closes via toggle bar
- [ ] Q4H badge appears and clears appropriately

## Troubleshooting

| Issue               | Solution                                                      |
| ------------------- | ------------------------------------------------------------- |
| Not connected       | Verify ports 5555/5556 free, dev server running               |
| No streaming chunks | Verify provider keys; run `llm-streaming.ts`                  |
| Persistence gaps    | Check JSONL files in `ux-rtws/.dialogs/run/<dialogId>/`       |
| Restoration fails   | Refresh browser; check `restoreDialogHierarchy()`             |
| Q4H panel not found | Verify `.q4h-toggle-bar` and `.q4h-panel-container` selectors |

### Diagnostic Commands

```bash
# Server status
./dev-server.sh status

# Backend logs
tail -n 200 logs/backend-stdout.log
tail -n 80 logs/backend-stderr.log

# Round events
cat ux-rtws/.dialogs/run/*/round-*.jsonl | head -n 50

# Stream verification
pnpm -C dominds tsx tests/driving/llm-streaming.ts --agent=gd --prompt="check"

# Event dispatch check
pnpm -C dominds tsx tests/driving/dialog-driving.ts --agent=gd --task=test-tracks.md
```

## Code References

| Component          | Path                                                        |
| ------------------ | ----------------------------------------------------------- |
| Driver streaming   | `dominds/main/llm/driver.ts`                                |
| Persistence        | `dominds/main/persistence.ts`                               |
| Event registry     | `dominds/main/evt-registry.ts`                              |
| Frontend WebSocket | `dominds/webapp/src/services/websocket.ts`                  |
| Streaming UI       | `dominds/webapp/src/components/dominds-dialog-container.ts` |
| Q4H Panel UI       | `dominds/webapp/src/components/dominds-q4h-panel.ts`        |
| Test helper        | `dominds/webapp/static/testing/e2e-test-helper.js`          |

---

Last Updated: 2025-12-31 (updated Q4H UI structure - inline panel with toggle bar)
