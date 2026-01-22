# Memory tools（个人/团队）路径规则与 guardrails
关键词：`.minds/memory` `individual` `team_shared` `path traversal` `hasWriteAccess`

- `dominds/main/tools/mem.ts`
  - 存储布局：
    - 个人：`.minds/memory/individual/<caller.id>/<relative-file-path>`
    - 团队共享：`.minds/memory/team_shared/<relative-file-path>`
    - 路径生成：`getMemoryPath({caller,filePath,isShared})`
  - 安全：
    - 禁止 `..`：只要 `filePath.includes('..')` 就拒绝（防路径穿越）。
    - 写权限：所有写操作都要 `hasWriteAccess(caller, memoryPath.rel)`；失败用 `getAccessDeniedMessage('write', ...)`（因此也间接阻断写入 `*.tsk/`）。
  - 语义：
    - `add_memory`：目标文件若已存在 => 要求用 `replace_memory`。
    - `replace_memory`：目标文件不存在 => 要求用 `add_memory`。
    - `clear_memory`：直接 `fs.rmSync(fullPath,{recursive:true,force:true})` 后 `mkdirSync` 重建目录（因此是破坏性工具，受 write_dirs/no_write_dirs 控制）。
