# Access control 与 Task Doc 封装（*.tsk）
关键词：`hasReadAccess` `hasWriteAccess` `matchesPattern` `getAccessDeniedMessage` `*.tsk`

- `dominds/main/access-control.ts`
  - `isEncapsulatedTaskPath(targetPath)`：用正则 `/(^|\/)[^/]+\.tsk(\/|$)/` 判断路径位于封装差遣牒目录树中。
  - `matchesPattern(targetPath, dirPattern)`：面向“目录 scope”的 glob-like 匹配：
    - 支持 `*`（单段内任意子串）与 `**`（跨多段）。
    - 目录语义：pattern `src` 匹配 `src/file` 与 `src/sub/file`，不匹配 `src-backup/file`。
    - 对以 `/**` 结尾的 pattern：会剥离到目录本身，使 `.minds/**` 同时匹配 `.minds` 与 `.minds/team.yaml`。
  - `hasReadAccess(member, targetPath)` / `hasWriteAccess(member, targetPath)`
    - 先解析到 workspace 内相对路径；若不在 workspace，直接 deny。
    - 若命中 `isEncapsulatedTaskPath(relativePath)`：直接 deny（通用文件工具对 `*.tsk/` 读/写/列目录/删除都不可）。
    - 黑名单优先：`no_read_dirs` / `no_write_dirs` 命中则 deny。
    - 白名单：`read_dirs` / `write_dirs` 为空 => 默认 allow；不为空但都不命中 => deny。
  - `getAccessDeniedMessage(operation, targetPath, language)`
    - 统一格式化拒绝消息；当路径属于 `*.tsk/` 时，会追加引导：用 `!?@change_mind !goals|!constraints|!progress` 更新分段（见 `access-control.ts:249` 以后）。

- 具体工具使用：
  - `dominds/main/tools/fs.ts` / `dominds/main/tools/txt.ts` / `dominds/main/tools/mem.ts` 在执行前调用 `hasReadAccess`/`hasWriteAccess`，并用 `getAccessDeniedMessage` 产出用户可见错误文本。
