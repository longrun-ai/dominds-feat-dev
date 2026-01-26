## Progress
- Added new doc `dominds/docs/memory-system.md` describing ideal memory layers: Taskdoc (`*.tsk/`), reminders as curated working set/worklog, personal/team memory, and tool-history as disposable.
- Updated reminder UX copy to reflect the intended model:
  - Non-owned reminders: guide now emphasizes reminders as curated working set; prefer update_reminder to compress/merge; delete only when obsolete.
  - Reminders intro: reframed reminders as cross-round working set; includes mandatory distill loop when context health is yellow/red.
- Strengthened context-health reminder copy in zh to enforce a hard stop at yellow/red: stop implementation/large reads; compress reminders (update_reminder) → change_mind(progress) → clear_mind.
- Strengthened context-health owned reminder header (zh) to reinforce the same hard-stop workflow.
- Began implementing new shell delegation policy foundation:
  - Team YAML now uses `shell_specialists` (string|string[]|null) and Team model stores normalized `shellSpecialists: string[]`.
  - (WIP) Need to finish wiring: enforce `shell_specialists` policy as error Problems (fail-open runtime), gate shell tools to specialists, and update tests expecting team.yaml parsing + validation.