# Dominds WebUI E2E: Work Language (env) vs UI Language (dropdown) - For e2e-browser-tester Agent

You are the **tester agent** standing in for a human user. Your role is to validate that **dominds**
supports **two independent language dimensions**:

- **Work language (server-wide)**: derived from standard locale environment variable (`LANG`).
- **UI language (per WebUI client)**: selectable in the WebUI header dropdown; affects WebUI copy + user-visible replies.

This test focuses on **infrastructure correctness** (protocol + UI wiring), not on the LLM’s prose quality.

## The Test Purpose

This test validates:

- The server derives working language from locale env vars and reports it to the client via `welcome.serverWorkLanguage`.
- The WebUI dropdown sends `set_ui_language` and receives `ui_language_set`.
- The WebUI language dropdown **visibly indicates** whether the selected UI language matches the server working language,
  and the custom menu shows an **indented explanation block under each choice** (in the associated language).
- The UI language change persists in `localStorage` and re-applies after refresh/reconnect.
- Each user prompt sent to backend bears `userLanguageCode`, and the frontend can observe it via `data-user-language-code` on the corresponding generation bubble.
- Inter-dialog narrative formatting stays in **working language** even when UI language changes.

## Business Goal

Operators can run dominds in one internal working language while letting end-users choose a different UI reply language.

---

## Setup

Start the dev servers with a deterministic locale so the test is stable:

```bash
# Optional: wipe prior dialog records for deterministic UI state
./clear-records.sh

# Work language = zh (Simplified Chinese)
LANG=zh_CN.UTF-8 ./dev-server.sh restart
```

Open: `http://127.0.0.1:5555/`

---

## Standardized Observation Pattern

Use the same observation skeleton as other E2E stories:

```javascript
const baseline = await snapshotDomindsUI();
await waitForInputEnabled();
const snap = await snapshotDomindsUI();
const delta = snap.reportDeltaTo(baseline);
```

After every action:

- `checkConsoleErrors()` must be empty (or only known benign warnings)
- `snap.connection.connected` should remain `true`

---

## Essential Helper Reference

| Helper                                              | Purpose                                                                                 |
| --------------------------------------------------- | --------------------------------------------------------------------------------------- |
| `window.__e2e__.snapshotDomindsUI()`                | Take a full UI snapshot (includes `header.uiLanguage` + `header.serverWorkLanguage`) |
| `window.__e2e__.waitUntil(fn, timeoutMs)`           | Poll until a condition is true                                                          |
| `window.__e2e__.waitForInputEnabled()`              | Ensure a dialog is selected and input is usable                                         |
| `window.__e2e__.createDialog(taskDoc, agent?)`      | Create a new dialog via UI                                                              |
| `window.__e2e__.fillAndSend(msg)`                   | Send a message to the current dialog                                                    |
| `window.__e2e__.waitForPendingTeammateCalls()`      | Wait for teammate/subdialog calls to settle                                             |
| `window.__e2e__.getLatestTeammateResponseDetails()` | Inspect teammate-response narrative prefix (`narrativeLine`)                            |

---

## Scenario A — Server working language = `zh`, UI language = `en`

### A0) Calibration gate: ensure E2E helpers are loaded

In `NODE_ENV=dev`, the WebUI should auto-inject the helpers. If missing, load them from the app’s static assets:

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

### A0.1) UX verification: language selector match indicator + tooltips

This verifies the UX described in `docs/language.md`:

- Work language (server-wide) is reported by `welcome.serverWorkLanguage`
- UI language (per client) is selected in the header dropdown
- The dropdown UI should clearly indicate whether the two are equal, and explain the implications via an indented block under each choice

```javascript
const appShadow = window.__e2e__.getAppShadow();
const button = appShadow.querySelector('#ui-language-menu-button');
const menu = appShadow.querySelector('#ui-language-menu');
if (!(button instanceof HTMLButtonElement)) throw new Error('Missing #ui-language-menu-button');
if (!(menu instanceof HTMLElement)) throw new Error('Missing #ui-language-menu');

// Pre-welcome, work language may not be known yet. Accept either state to avoid flakiness.
const pre = button.dataset.langMatch;
if (pre !== 'unknown' && pre !== 'match' && pre !== 'mismatch') {
  throw new Error(`Unexpected button.dataset.langMatch: ${String(pre)}`);
}

// Wait for welcome to arrive, then assert menu content + labels/tips.
await waitUntil(
  () => typeof window.__e2e__.snapshotDomindsUI().header.serverWorkLanguage === 'string',
  15000,
);
const serverLang = window.__e2e__.snapshotDomindsUI().header.serverWorkLanguage;
if (serverLang !== 'zh') throw new Error(`Expected serverWorkLanguage=zh, got: ${String(serverLang)}`);

// Open the menu so the per-choice explanation blocks are visible.
button.click();
await waitUntil(() => menu.hidden === false, 2000);

const itemEn = menu.querySelector('button[data-language="en"]');
const itemZh = menu.querySelector('button[data-language="zh"]');
if (!(itemEn instanceof HTMLButtonElement)) throw new Error('Missing menu item en');
if (!(itemZh instanceof HTMLButtonElement)) throw new Error('Missing menu item zh');

const labelEn = itemEn.querySelector('.ui-language-menu-item-label')?.textContent || '';
const labelZh = itemZh.querySelector('.ui-language-menu-item-label')?.textContent || '';
if (!labelEn.includes('Not Work Language')) {
  throw new Error(`Expected en label to include 'Not Work Language', got: ${JSON.stringify(labelEn)}`);
}
if (!labelZh.includes('工作语言')) {
  throw new Error(`Expected zh label to include '工作语言', got: ${JSON.stringify(labelZh)}`);
}

const tipEn = itemEn.querySelector('.ui-language-menu-item-tip')?.textContent || '';
const tipZh = itemZh.querySelector('.ui-language-menu-item-tip')?.textContent || '';
if (!tipEn.includes('Affects:') || !tipEn.includes('Does NOT affect:')) {
  throw new Error(`Expected en tip block to be English and structured, got: ${JSON.stringify(tipEn)}`);
}
if (!tipZh.includes('影响：') || !tipZh.includes('不影响：')) {
  throw new Error(`Expected zh tip block to be Chinese and structured, got: ${JSON.stringify(tipZh)}`);
}

// Close menu
button.click();
```

### A1) Verify `welcome.serverWorkLanguage` is `zh`

```javascript
await waitUntil(() => window.__e2e__.snapshotDomindsUI().connection.connected === true, 15000);
const snap = window.__e2e__.snapshotDomindsUI();
if (snap.header?.serverWorkLanguage !== 'zh') {
  throw new Error(
    `Expected serverWorkLanguage === 'zh', got: ${String(snap.header?.serverWorkLanguage)}`,
  );
}
```

### A2) Switch UI language dropdown to English and verify persistence + WS ack

```javascript
// Switch via custom menu
const appShadow = window.__e2e__.getAppShadow();
const button = appShadow.querySelector('#ui-language-menu-button');
const menu = appShadow.querySelector('#ui-language-menu');
if (!(button instanceof HTMLButtonElement)) throw new Error('Missing #ui-language-menu-button');
if (!(menu instanceof HTMLElement)) throw new Error('Missing #ui-language-menu');

button.click();
await waitUntil(() => menu.hidden === false, 2000);
const itemEn = menu.querySelector('button[data-language="en"]');
if (!(itemEn instanceof HTMLButtonElement)) throw new Error('Missing menu item en');
itemEn.click();

// Persistence
const stored = localStorage.getItem('dominds-ui-language');
if (stored !== 'en')
  throw new Error(`Expected localStorage dominds-ui-language=en, got: ${String(stored)}`);

// UI reflects selection
if (window.__e2e__.snapshotDomindsUI().header.uiLanguage !== 'en')
  throw new Error('UI language did not update to en');

// Snapshot reflects selection
await waitUntil(() => window.__e2e__.snapshotDomindsUI().header.uiLanguage === 'en', 5000);
const snap2 = window.__e2e__.snapshotDomindsUI();
if (snap2.header?.uiLanguage !== 'en') {
  throw new Error(
    `Expected snapshotDomindsUI().header.uiLanguage === 'en', got: ${String(
      snap2.header?.uiLanguage,
    )}`,
  );
}

// Glitch radar: UI copy should ALSO be English (even though working language is zh).
const appShadow = window.__e2e__.getAppShadow();
const connEl = appShadow.querySelector('dominds-connection-status');
const connText = (connEl?.shadowRoot?.querySelector('#status-text')?.textContent || '').trim();
if (connText !== 'Connected')
  throw new Error(`Expected connection label 'Connected', got: ${JSON.stringify(connText)}`);

const title = (appShadow.querySelector('#current-dialog-title')?.textContent || '').trim();
if (title !== 'Select or create a dialog to start') {
  throw new Error(`Expected toolbar placeholder in English, got: ${JSON.stringify(title)}`);
}

const dlgList = appShadow.querySelector('running-dialog-list');
const empty = (dlgList?.shadowRoot?.querySelector('.empty')?.textContent || '').trim();
if (empty !== 'No dialogs yet.')
  throw new Error(`Expected sidebar empty state in English, got: ${JSON.stringify(empty)}`);

const q4h = appShadow.querySelector('dominds-q4h-input');
const q4hPlaceholder =
  q4h?.shadowRoot?.querySelector('.message-input')?.getAttribute('placeholder') || '';
if (q4hPlaceholder !== 'Type your answer...') {
  throw new Error(
    `Expected Q4H input placeholder in English, got: ${JSON.stringify(q4hPlaceholder)}`,
  );
}
const q4hFooter = (
  q4h?.shadowRoot?.querySelector('.question-footer-label')?.textContent || ''
).trim();
if (!q4hFooter.startsWith('Pending Questions')) {
  throw new Error(`Expected Q4H footer label in English, got: ${JSON.stringify(q4hFooter)}`);
}

// Glitch radar: switching UI language must NOT mutate working language.
if (window.__e2e__.snapshotDomindsUI().header.serverWorkLanguage !== 'zh') {
  throw new Error('serverWorkLanguage changed unexpectedly after UI language switch');
}
```

### A3) Refresh page and verify UI language re-applies

```javascript
location.reload();
await waitUntil(
  () => window.__e2e__?.getAppShadow()?.querySelector('#ui-language-menu-button'),
  15000,
);
await waitUntil(() => window.__e2e__.snapshotDomindsUI().header.uiLanguage === 'en', 15000);

// Glitch radar: UI copy should remain English after reload.
const titleAfter = (
  window.__e2e__.getAppShadow().querySelector('#current-dialog-title')?.textContent || ''
).trim();
if (titleAfter !== 'Select or create a dialog to start') {
  throw new Error(
    `Expected toolbar placeholder to remain English after reload, got: ${JSON.stringify(
      titleAfter,
    )}`,
  );
}

// Glitch radar: wait for WS reconnect + welcome, then ensure working language is still zh.
await waitUntil(() => window.__e2e__.snapshotDomindsUI().connection.connected === true, 15000);
await waitUntil(
  () => typeof window.__e2e__.snapshotDomindsUI().header.serverWorkLanguage === 'string',
  15000,
);
if (window.__e2e__.snapshotDomindsUI().header.serverWorkLanguage !== 'zh') {
  throw new Error('serverWorkLanguage did not restore to zh after reload');
}
```

### A4) Create a dialog and trigger an inter-dialog formatted response (teammate call)

This step checks **working-language formatting** (stable) rather than user-facing prose (LLM-dependent).

```javascript
// Create dialog using the helper UI flow.
// Use any existing task doc in the outer workspace (rtws).
await window.__e2e__.createDialog('cmds-test.tsk');

// Glitch radar: per-prompt userLanguageCode should be recorded on each user message bubble.
// Send one prompt in English, then switch to zh and send another.
const msgIdEn = await window.__e2e__.fillAndSend('Reply with a short sentence.');
const container = window.__e2e__.getAppShadow().querySelector('dominds-dialog-container');
const containerShadow = container?.shadowRoot;
if (!containerShadow) throw new Error('Missing dominds-dialog-container shadowRoot');
await window.__e2e__.waitUntil(
  () =>
    !!containerShadow.querySelector(`.generation-bubble[data-user-msg-id="${msgIdEn}"]`),
  15000,
);
const bubbleEn = containerShadow.querySelector(`.generation-bubble[data-user-msg-id="${msgIdEn}"]`);
const langEn = bubbleEn?.getAttribute('data-user-language-code') || '';
if (langEn !== 'en') {
  throw new Error(
    `Expected data-user-language-code=en for msgId ${msgIdEn}, got: ${JSON.stringify(langEn)}`,
  );
}

// Switch UI language to zh and send another prompt (same client).
const appShadow = window.__e2e__.getAppShadow();
const button = appShadow.querySelector('#ui-language-menu-button');
const menu = appShadow.querySelector('#ui-language-menu');
if (!(button instanceof HTMLButtonElement)) throw new Error('Missing #ui-language-menu-button');
if (!(menu instanceof HTMLElement)) throw new Error('Missing #ui-language-menu');
button.click();
await window.__e2e__.waitUntil(() => menu.hidden === false, 2000);
const itemZh = menu.querySelector('button[data-language="zh"]');
if (!(itemZh instanceof HTMLButtonElement)) throw new Error('Missing menu item zh');
itemZh.click();
await window.__e2e__.waitUntil(
  () => window.__e2e__.snapshotDomindsUI().header.uiLanguage === 'zh',
  5000,
);

const msgIdZh = await window.__e2e__.fillAndSend('请用简体中文回复一句话。');
await window.__e2e__.waitUntil(
  () =>
    !!containerShadow.querySelector(`.generation-bubble[data-user-msg-id="${msgIdZh}"]`),
  15000,
);
const bubbleZh = containerShadow.querySelector(`.generation-bubble[data-user-msg-id="${msgIdZh}"]`);
const langZh = bubbleZh?.getAttribute('data-user-language-code') || '';
if (langZh !== 'zh') {
  throw new Error(
    `Expected data-user-language-code=zh for msgId ${msgIdZh}, got: ${JSON.stringify(langZh)}`,
  );
}

// Ensure previous bubble keeps its own language code (no retroactive mutation).
const langEnAfter = bubbleEn?.getAttribute('data-user-language-code') || '';
if (langEnAfter !== 'en') {
  throw new Error(
    `Expected prior bubble to keep data-user-language-code=en, got: ${JSON.stringify(langEnAfter)}`,
  );
}

// Restore UI language to en for the rest of Scenario A.
button.click();
await window.__e2e__.waitUntil(() => menu.hidden === false, 2000);
const itemEn = menu.querySelector('button[data-language="en"]');
if (!(itemEn instanceof HTMLButtonElement)) throw new Error('Missing menu item en');
itemEn.click();
await window.__e2e__.waitUntil(
  () => window.__e2e__.snapshotDomindsUI().header.uiLanguage === 'en',
  5000,
);

const teammateStart = window.__e2e__.getTeammateMessageCount();
const callSiteBefore = window.__e2e__.getLatestTeammateCallSiteId();

await window.__e2e__.fillAndSend(
  'Please do a self-call with @self to test inter-dialog formatting. ' +
    'In the subdialog, just reply with a short sentence.',
);

const callSiteId = await window.__e2e__.waitForTeammateCallSiteId({
  after: callSiteBefore,
  firstMention: '@self',
});
await window.__e2e__.waitForPendingTeammateCalls(120000);
await window.__e2e__.waitForTeammateResponse({
  initialCount: teammateStart,
  callSiteId: callSiteId ?? undefined,
  timeoutMs: 120000,
});
await window.__e2e__.waitForInputEnabled();

// Assert: the teammate-response narrative prefix uses working language (zh).
const detail = window.__e2e__.getLatestTeammateResponseDetails();
const narrative = detail?.narrativeLine || '';
if (!narrative.includes('你好 @')) {
  throw new Error(
    `Expected inter-dialog narrative to be in zh (contains \"你好 @...\"), got: ${String(
      narrative,
    )}`,
  );
}
```

Acceptance criteria:

- `app.serverWorkLanguage === 'zh'`
- UI language select is `en` and persists across reload
- Inter-dialog narrative formatting includes `你好 @...` regardless of UI language selection

### A5) Glitch radar: tool error UX uses per-prompt language (bubble), not current UI

This step validates two things at once:

- Backend emits stable error codes (`ERR_*`) for tool failures it owns (unknown call, tool exception).
- Frontend translates those codes using the **generation bubble’s `data-user-language-code`** (per prompt),
  so switching UI language *after sending* does not retroactively change prior results.

#### A5.1) Unknown call: `ERR_UNKNOWN_CALL` translated in English for an English bubble

```javascript
// Ensure UI language is en and send an unknown tool call from the user text.
const container = window.__e2e__.getAppShadow().querySelector('dominds-dialog-container');
const containerShadow = container?.shadowRoot;
if (!containerShadow) throw new Error('Missing dominds-dialog-container shadowRoot');

const appShadow = window.__e2e__.getAppShadow();
const button = appShadow.querySelector('#ui-language-menu-button');
const menu = appShadow.querySelector('#ui-language-menu');
if (!(button instanceof HTMLButtonElement)) throw new Error('Missing #ui-language-menu-button');
if (!(menu instanceof HTMLElement)) throw new Error('Missing #ui-language-menu');
button.click();
await window.__e2e__.waitUntil(() => menu.hidden === false, 2000);
const itemEn = menu.querySelector('button[data-language="en"]');
if (!(itemEn instanceof HTMLButtonElement)) throw new Error('Missing menu item en');
itemEn.click();
await window.__e2e__.waitUntil(() => window.__e2e__.snapshotDomindsUI().header.uiLanguage === 'en', 5000);

const msgIdUnknownEn = await window.__e2e__.fillAndSend('@no_such_tool hello');

// Switch UI language immediately (simulates user toggling quickly).
button.click();
await window.__e2e__.waitUntil(() => menu.hidden === false, 2000);
const itemZh = menu.querySelector('button[data-language="zh"]');
if (!(itemZh instanceof HTMLButtonElement)) throw new Error('Missing menu item zh');
itemZh.click();
await window.__e2e__.waitUntil(() => window.__e2e__.snapshotDomindsUI().header.uiLanguage === 'zh', 5000);

// Wait for the bubble to exist, then assert the tool result is still English (because bubble lang is en).
await window.__e2e__.waitUntil(
  () =>
    !!containerShadow.querySelector(
      `.generation-bubble[data-user-msg-id="${msgIdUnknownEn}"] .calling-result`,
    ),
  15000,
);
const bubble = containerShadow.querySelector(
  `.generation-bubble[data-user-msg-id="${msgIdUnknownEn}"]`,
);
const bubbleLang = bubble?.getAttribute('data-user-language-code') || '';
if (bubbleLang !== 'en') throw new Error(`Expected bubble lang=en, got: ${JSON.stringify(bubbleLang)}`);

const resultText = (
  bubble?.querySelector('.calling-result')?.textContent || ''
).trim();
if (!resultText.startsWith('Unknown call:')) {
  throw new Error(`Expected English unknown-call translation, got: ${JSON.stringify(resultText)}`);
}
```

#### A5.2) Tool exception: `ERR_TOOL_EXECUTION` translated in Chinese for a Chinese bubble

Trigger a real tool exception by passing a path-traversal value to `@add_memory` (it throws in backend).

```javascript
// Ensure UI language is zh before sending.
const container = window.__e2e__.getAppShadow().querySelector('dominds-dialog-container');
const containerShadow = container?.shadowRoot;
if (!containerShadow) throw new Error('Missing dominds-dialog-container shadowRoot');

const appShadow = window.__e2e__.getAppShadow();
const button = appShadow.querySelector('#ui-language-menu-button');
const menu = appShadow.querySelector('#ui-language-menu');
if (!(button instanceof HTMLButtonElement)) throw new Error('Missing #ui-language-menu-button');
if (!(menu instanceof HTMLElement)) throw new Error('Missing #ui-language-menu');
button.click();
await window.__e2e__.waitUntil(() => menu.hidden === false, 2000);
const itemZh = menu.querySelector('button[data-language="zh"]');
if (!(itemZh instanceof HTMLButtonElement)) throw new Error('Missing menu item zh');
itemZh.click();
await window.__e2e__.waitUntil(() => window.__e2e__.snapshotDomindsUI().header.uiLanguage === 'zh', 5000);

const msgIdExecZh = await window.__e2e__.fillAndSend('@add_memory ../oops.md\\nhello');
await window.__e2e__.waitUntil(
  () =>
    !!containerShadow.querySelector(
      `.generation-bubble[data-user-msg-id="${msgIdExecZh}"] .calling-result`,
    ),
  15000,
);
const bubble = containerShadow.querySelector(`.generation-bubble[data-user-msg-id="${msgIdExecZh}"]`);
const bubbleLang = bubble?.getAttribute('data-user-language-code') || '';
if (bubbleLang !== 'zh') throw new Error(`Expected bubble lang=zh, got: ${JSON.stringify(bubbleLang)}`);

const resultText = (
  bubble?.querySelector('.calling-result')?.textContent || ''
).trim();
if (!resultText.startsWith('执行 @')) {
  throw new Error(`Expected zh tool-execution translation, got: ${JSON.stringify(resultText)}`);
}
```

Acceptance criteria:

- For A5.1: bubble lang stays `en` and inline tool error starts with `Unknown call:`
- For A5.2: bubble lang is `zh` and inline tool error starts with `执行 @`

---

## Scenario B — Server working language = `en`, UI language = `zh`

Restart servers with English locale:

```bash
LANG=en_US.UTF-8 ./dev-server.sh restart
```

### B0) Post-restart stabilization gate (avoid false positives)

During server restarts, the browser console may briefly show fetch/proxy/ws errors while the backend and Vite proxy settle.
Before asserting anything, wait for the WebUI to reconnect and then clear console errors once.

```javascript
location.reload();
await waitUntil(() => window.__e2e__?.snapshotDomindsUI?.().connection.connected === true, 20000);
await waitUntil(
  () => typeof window.__e2e__.snapshotDomindsUI().header.serverWorkLanguage === 'string',
  20000,
);

// Clear any transient restart noise; from here on, console errors are infra failures.
window.__e2e__.checkConsoleErrors({ clear: true, threshold: 9999 });
```

Repeat A1–A4, but:

- Expect `app.serverWorkLanguage === 'en'`
- Set UI language dropdown to `zh`
- For the teammate-response narrative prefix, expect it to start with `Hi @...`

### B1) UX verification: language selector match indicator + per-choice tips

This is the mirror of A0.1, but for `serverWorkLanguage=en` and `uiLanguage=zh`.

```javascript
const appShadow = window.__e2e__.getAppShadow();
const button = appShadow.querySelector('#ui-language-menu-button');
const menu = appShadow.querySelector('#ui-language-menu');
if (!(button instanceof HTMLButtonElement)) throw new Error('Missing #ui-language-menu-button');
if (!(menu instanceof HTMLElement)) throw new Error('Missing #ui-language-menu');

await waitUntil(
  () => typeof window.__e2e__.snapshotDomindsUI().header.serverWorkLanguage === 'string',
  15000,
);
const serverLang = window.__e2e__.snapshotDomindsUI().header.serverWorkLanguage;
if (serverLang !== 'en') throw new Error(`Expected serverWorkLanguage=en, got: ${String(serverLang)}`);

// Set UI language to zh to create a mismatch with server en.
button.click();
await waitUntil(() => menu.hidden === false, 2000);
const itemZh = menu.querySelector('button[data-language="zh"]');
if (!(itemZh instanceof HTMLButtonElement)) throw new Error('Missing menu item zh');
itemZh.click();
await waitUntil(() => window.__e2e__.snapshotDomindsUI().header.uiLanguage === 'zh', 5000);
await waitUntil(() => button.dataset.langMatch === 'mismatch', 5000);

// Open menu and verify per-choice explanation blocks.
button.click();
await waitUntil(() => menu.hidden === false, 2000);
const itemEn = menu.querySelector('button[data-language="en"]');
if (!(itemEn instanceof HTMLButtonElement)) throw new Error('Missing menu item en');

const labelEn = itemEn.querySelector('.ui-language-menu-item-label')?.textContent || '';
const labelZh = itemZh.querySelector('.ui-language-menu-item-label')?.textContent || '';
if (!labelEn.includes('Work Language')) {
  throw new Error(`Expected en label to include 'Work Language', got: ${JSON.stringify(labelEn)}`);
}
if (!labelZh.includes('非工作语言')) {
  throw new Error(`Expected zh label to include '非工作语言', got: ${JSON.stringify(labelZh)}`);
}

const tipEn = itemEn.querySelector('.ui-language-menu-item-tip')?.textContent || '';
const tipZh = itemZh.querySelector('.ui-language-menu-item-tip')?.textContent || '';
if (!tipEn.includes('Affects:') || !tipEn.includes('Does NOT affect:')) {
  throw new Error(`Expected en tip block to be English and structured, got: ${JSON.stringify(tipEn)}`);
}
if (!tipZh.includes('影响：') || !tipZh.includes('不影响：')) {
  throw new Error(`Expected zh tip block to be Chinese and structured, got: ${JSON.stringify(tipZh)}`);
}

// Close menu
button.click();
```

### B2) Glitch radar: UI copy should honor UI language (zh)

Before creating/selecting any dialog, verify the toolbar placeholder is localized:

```javascript
const title = window.__e2e__.getAppShadow().querySelector('#current-dialog-title');
const text = (title?.textContent || '').trim();
if (text !== '选择或创建一个对话以开始') {
  throw new Error(`Expected zh toolbar placeholder, got: ${JSON.stringify(text)}`);
}

// Also verify the sidebar and Q4H panel aren't stuck in English.
const appShadow = window.__e2e__.getAppShadow();
const dlgList = appShadow.querySelector('running-dialog-list');
const empty = (dlgList?.shadowRoot?.querySelector('.empty')?.textContent || '').trim();
if (empty !== '还没有对话。')
  throw new Error(`Expected zh sidebar empty state, got: ${JSON.stringify(empty)}`);

const q4h = appShadow.querySelector('dominds-q4h-input');
const q4hPlaceholder =
  q4h?.shadowRoot?.querySelector('.message-input')?.getAttribute('placeholder') || '';
if (q4hPlaceholder !== '输入你的回答…') {
  throw new Error(`Expected zh Q4H input placeholder, got: ${JSON.stringify(q4hPlaceholder)}`);
}
const q4hFooter = (
  q4h?.shadowRoot?.querySelector('.question-footer-label')?.textContent || ''
).trim();
if (!q4hFooter.startsWith('待处理问题')) {
  throw new Error(`Expected zh Q4H footer label, got: ${JSON.stringify(q4hFooter)}`);
}

// Glitch radar: switching UI language must NOT mutate working language.
if (window.__e2e__.snapshotDomindsUI().header.serverWorkLanguage !== 'en') {
  throw new Error('serverWorkLanguage changed unexpectedly after UI language switch');
}
```

---

## Infra Failure Checklist

Treat as **dominds infrastructure failure** if any occurs:

- `app.serverWorkLanguage` is missing or not `en`/`zh`
- Dropdown exists but does not persist to `localStorage`
- WebSocket disconnects when switching language
- No teammate response bubble appears within timeouts (after one explicit retry)
- Console shows protocol errors or uncaught exceptions
