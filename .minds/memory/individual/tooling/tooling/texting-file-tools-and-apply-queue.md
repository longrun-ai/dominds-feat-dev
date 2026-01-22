# Texting 文件工具（read/overwrite/plan/apply）与并发语义
关键词：`read_file` `overwrite_file` `plan_file_modification` `apply_file_modification` `PLANNED_MOD_TTL_MS` `fileApplyQueues`

- `dominds/main/tools/txt.ts`
  - 提供 4 个 texting tool：`read_file` / `overwrite_file` / `plan_file_modification` / `apply_file_modification`（在 `builtins.ts` 注册）。
  - 访问控制：
    - 统一走 `hasReadAccess` / `hasWriteAccess` + `getAccessDeniedMessage`（间接继承对 `*.tsk/` 的封装拒绝）。
    - `ensureInsideWorkspace(rel)` 也做一次 workspace 前缀校验（抛错 "Path must be within workspace"）。
  - 规划/应用模型：
    - `plan_file_modification`：读取文件 -> 解析行号范围（`parseLineRangeSpec` 支持 `N~M`, `~N`, `N~`, `~`, `N`，以及 `N=last+1` 表示 append） -> 生成 unified diff（`buildUnifiedSingleHunkDiff`）-> 存入 `plannedModsById`。
    - TTL：`PLANNED_MOD_TTL_MS = 60*60*1000`，`pruneExpiredPlannedMods(nowMs)` 定期清理。
    - `apply_file_modification`：按 hunk id 应用；同一文件的 apply 会通过 `fileApplyQueues` + `drainFileApplyQueue` 串行化，且队列有 priority/tieBreaker，避免并发写导致竞态。
  - 失败判定包装：
    - `wrapTextingResult(language, messages)` 用启发式 regex/关键字判断成功/失败（例如出现 `**Access Denied**`、`路径必须位于工作区内` 等即标 failed）。
