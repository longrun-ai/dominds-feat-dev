# Tellasker Terms Refactor Plan

Status: draft
Owner: @prompt
Date: 2026-02-13

## Decisions (confirmed)

- Standard terms: "tellasker dialog / 诉请者对话" and "tellaskee dialog / 被诉请者对话".
- Hierarchy terms remain: supdialog/subdialog (ZH: 上位对话/子对话) are for structural parent-child only.
- "Sideline dialog" can be nested; it is not synonymous with "mainline". The tellasker can be any dialog.
- tellaskBack is documented in glossary/collaboration/interaction protocols, but hidden from the mainline tool list.
- Mainline calling tellaskBack should surface as a generic "function not found" (no custom error).
- FBR self-subdialog must remain a special mechanism with its own prompt handling.
- Sideline system prompt must enforce: only report final completion when all objectives are done; otherwise use tellaskBack.
- Teammate phase contract must enforce: if tellaskee reports intermediate status without tellaskBack, tellasker must immediately remind compliance.

## Terminology

- tellasker dialog (诉请者对话): the dialog that issued the current tellask; caller for the current assignment.
- tellaskee dialog (被诉请者对话): the dialog that is handling the current tellask (this dialog).
- supdialog/subdialog (上位对话/子对话): structural parent-child in dialog hierarchy; not necessarily the caller.
- mainline dialog (主线对话): root dialog owning shared Taskdoc.
- sideline dialog (支线对话): any subdialog, including nested subdialogs.

## Subdialog course header (new requirement)

Add a role header at the start of every subdialog course:

- ZH: "你是当前被诉请者对话的主理人；诉请者对话为 @xxx（当前发起本次诉请）。"
- EN: "You are the responder (tellaskee) for this dialog; the tellasker dialog is @xxx (the current caller)."

Placement:

- Prepend to the assignment prompt for every subdialog course.
- Prefer a single insertion point by updating formatAssignmentFromSupdialog() (covers dialog.ts, tellask-bridge, agent-priming).
  - Frontend twin must stay in sync: dominds/webapp/src/shared/utils/inter-dialog-format.ts

### FBR special handling

- FBR is a self-subdialog with strict tool/tellask restrictions.
- Header must remain present but use FBR-specific wording to avoid confusion:
  - ZH (example): "这是一次 FBR 支线对话；诉请者对话为 @xxx（可能与当前对话同一 agent）。"
  - EN (example): "This is an FBR sideline dialog; the tellasker dialog is @xxx (may be the same agent)."
- FBR special rules remain unchanged and must not be weakened.

## Sideline completion rule (system prompt)

Add a sideline-only rule block (non-FBR) in system prompt:

- ZH:
  - "支线对话交付规则：仅当你确认已完成全部目标时，才可直接回贴最终结果。"
  - "若仍有未完成目标/不确定项/阻塞/待确认事项，必须使用 tellaskBack 回问诉请者，不得直接给最终结果。"
  - "例外：FBR 支线为工具禁用模式（不得调用 tellaskBack），请直接给出推理与摘要。"
- EN:
  - "Sideline completion rule: only respond with a final answer when you are certain all objectives are completed."
  - "If any objective is unfinished/uncertain/blocked, you must use tellaskBack to ask the tellasker; do not return a final result."
  - "Exception: FBR sideline is tool-less (no tellaskBack); provide reasoning and a summary instead."

## Teammate phase contract reinforcement (system prompt)

Add a tellasker-side reminder rule (applies to any dialog acting as tellasker):

- ZH:
  - "若被诉请者未使用 tellaskBack 而直接叙述中间状态，诉请者必须立即提醒其遵守协议。"
  - "仅在确认最终完成时，允许不通过 tellaskBack 直接回贴完成结果。"
- EN:
  - "If the tellaskee reports intermediate status without using tellaskBack, the tellasker must immediately remind them to follow the protocol."
  - "Only when final completion is confirmed may the tellaskee report completion directly without tellaskBack."

## tellaskBack detection (content-only)

Detection must rely only on exchanged content (no shared tool receipts):

- ZH:
  - "被诉请者必须在消息首行明确标注：`【tellaskBack】` 或 `【最终完成】`；无标注视为未遵守协议。"
  - "若未完成目标/存在不确定/阻塞，必须使用 `【tellaskBack】` 并提出具体问题；不得直接给结果。"
  - "仅当已完成全部目标，才可使用 `【最终完成】` 直接回贴。"
  - "FBR 例外：仍需显式标注，例如 `【FBR‑直接回复】` / `【FBR‑仅推理】`。"
- EN:
  - "The tellaskee must put an explicit first-line header: `【tellaskBack】` or `【Final】`. No header = non‑compliant."
  - "If any objective is unfinished/uncertain/blocked, use `【tellaskBack】` and ask concrete questions; do not give a final result."
  - "Only when all objectives are completed may `【Final】` be used to deliver the result."
  - "FBR exception: still label explicitly, e.g. `【FBR‑Direct】` / `【FBR‑Reasoning Only】`."

## Tool visibility

- Mainline tool list: do NOT include tellaskBack (hidden).
- Sideline tool list: include tellaskBack.
- Mainline tellaskBack call should fail as "function not found" without custom error text.

## Docs to update (zh/en sync)

- dominds/docs/dominds-terminology.md
- dominds/docs/dialog-system.md
- dominds/docs/dialog-system.zh.md
- dominds/docs/tellask-collab.md
- dominds/docs/tellask-collab.zh.md
- dominds/docs/fbr.md
- dominds/docs/fbr.zh.md

Key doc edits:

- Replace "upstream" or "mainline" references with "tellasker dialog" where appropriate.
- Clarify tellaskBack usage: request clarification OR iterative exchange with tellasker.
- Clarify that tellasker can be any dialog, not only mainline.

## Refactor exploration (with @fullstack)

Goal: simplify subdialog course-start composition and reduce duplication.
Questions to explore:

- Can all subdialog course headers be injected from a single path (e.g., formatAssignmentFromSupdialog)?
- Are there redundant code paths in dialog.ts, tellask-bridge.ts, agent-priming.ts that could be unified?
- Should we centralize "course start" assembly into a shared helper to reduce future maintenance?
- How to keep FBR special handling isolated while still sharing the common header logic?

## Fullstack review notes (2026-02-13)

- Recommend keeping formatAssignmentFromSupdialog() as the single insertion point.
- Add a helper like buildSubdialogRoleHeader({ callName, fromAgentId, toAgentId, language }) to keep role header logic isolated.
- FBR header should only convey role + FBR identity; technical no-tools limits stay in driver-v2/policy.ts.
- Hide tellaskBack from mainline tool list by gating mergeTellaskSpecialVirtualTools in driver-v2/core.ts (only include in SubDialog).
- Prefer tool visibility control in core.ts over custom error paths in tellask-bridge.

## Acceptance criteria

- Mainline system prompts still document tellaskBack, but the tool is not visible in mainline tool list.
- Mainline tellaskBack call fails as missing function (no custom "not in sideline" error).
- All subdialog course starts include the new role header once.
- FBR course start uses the FBR-specific header wording.
- Docs updated in zh/en with "tellasker dialog" terminology and corrected semantics.
