# ctrl（intrinsic）工具：reminders / clear_mind / change_mind
关键词：`add_reminder` `update_reminder` `delete_reminder` `clear_mind` `change_mind` `task-package`

- `dominds/main/tools/ctrl.ts`
  - 文件头声明：ctrl 工具是 “INTRINSIC dialog control tools - ALWAYS AVAILABLE TO ALL AGENTS”，并在 `builtins.ts` 里也会注册（双保险）。
  - reminder 工具：
    - `add_reminder`：允许追加或插入指定位置（1-based）；内容来自 body。
    - `update_reminder` / `delete_reminder`：按编号（1-based）操作。
  - `clear_mind`：
    - 可选 body 写入 reminder，然后 `dlg.startNewRound(...)` 开新一轮并清理消息（但 reminders 保留）。
  - `change_mind`（Task Doc 专用更新，不开新 round）：
    - 仅支持 `!?@change_mind !goals|!constraints|!progress`，且禁止额外 token（`tooManyArgsChangeMind`）。
    - `dlg.taskDocPath` 必须存在且必须是 `*.tsk/` 目录（`isTaskPackagePath`），否则失败。
    - 实际写入走 `updateTaskPackageSection(...)`（`dominds/main/utils/task-package.ts`），参数含 `updatedBy: caller.id`。
