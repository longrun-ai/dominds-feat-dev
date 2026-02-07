# Dominds WebUI E2E: Dialog Stop / Resume (Per-dlg + Global Operator Controls)

Scope: WebUI dialog stop/resume controls and cross-tab sync.
Hard constraints: NO API/WS direct calls, NO scripts, NO console helper injection. Only keyboard/mouse/touch.

## Preconditions

- WebUI reachable (e.g. http://127.0.0.1:5555/).
- Start from a fresh browser session (close the current browser window and reopen the WebUI).
- At least one team member is available so a dialog can be created.
- Connection status shows connected.
- If you will check cross-tab sync, open a second tab to the same WebUI.

## Minimal Flow

1. Create a new dialog via toolbar New Dialog.
   - Expect: a dialog is selected and input is enabled.

2. Send a prompt to force a long response (ask for a long list, no tools).
   - Expect: primary action switches to Stop and input becomes disabled while streaming.

3. Click Stop.
   - Expect: streaming stops and a resume/continue panel appears in the dialog.

4. Click Continue/Resume in the dialog.
   - Expect: response continues or resumes; input is disabled during resume and re-enables when done.

5. Start another long response, then click toolbar Emergency Stop.
   - Expect: streaming stops and the global resume count increases.
   - Note: click the icon inside the button; clicking the count text may not trigger the action.
   - Emergency Stop only works when proceeding count > 0.
   - Confirm the Emergency Stop dialog; cancel is a no-op.
   - If output continues beyond ~5s after confirm and resume count stays 0, treat as a bug.
   - No toast is expected; confirmation appears only when clicking the icon and proceeding count > 0.
   - If streaming is visible but proceeding count stays 0, treat as run-state update issue.

6. Click toolbar Resume All.
   - Expect: the interrupted dialog resumes and the resume count decreases to 0.
   - Resume All only works when resumable count > 0 and dialogs are in interrupted state.

7. In the second tab, observe stop/resume state.
   - Expect: within 5s, stop/resume state and counts match the first tab.

## Failure Recovery

- If the model does not stream a long response, retry once with a stricter prompt.
- If the testee refuses or calls tools instead, mark as testee non-cooperation (not a UI defect) and stop this story.
- If Stop/Resume controls do not appear, refresh once and repeat steps 1-4.
- If cross-tab state does not update, wait 5s and refresh the second tab once.

## Optional Evidence (Fail/Blocked only)

- For Pass: no evidence required.
- For Fail/Blocked: attach 1~2 screenshots that best explain the failure/blocked state.

## Binary Pass/Fail Gates

- After sending a long prompt, primary action switches to Stop within 2s.
- Clicking Stop halts streaming within 2s and shows a resume/continue panel.
- Clicking Continue/Resume resumes output and input re-enables after completion.
- Emergency Stop halts streaming and increases the resume count.
- Resume All reduces the resume count to 0 and resumes output.
- Second tab reflects stop/resume state within 5s.
