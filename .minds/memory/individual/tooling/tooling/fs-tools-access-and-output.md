# fs texting 工具（list_dir/rm_dir/rm_file）访问控制与输出
关键词：`list_dir` `rm_dir` `rm_file` `hasReadAccess` `hasWriteAccess`

- `dominds/main/tools/fs.ts`
  - `list_dir`：
    - 解析 `@list_dir [path]`，默认 `.`；`dir.startsWith(cwd)` 校验 workspace。
    - `hasReadAccess(caller, rel)`：失败返回 `getAccessDeniedMessage('read', rel, language)`（包含对 `*.tsk/` 的封装提示）。
    - 输出 markdown 表格：类型 icon + size +（若文本文件）行数 + symlink target。
  - `rm_dir` / `rm_file`：
    - 执行前都会做 workspace 前缀校验 + `hasWriteAccess`（因此可阻止 `.minds/**` 之外删除，亦阻止 `*.tsk/`）。
    - `rm_dir` 支持 `!recursive true|false`（默认 false），属于潜在破坏性操作，依赖 team.yaml 的 write_dirs/no_write_dirs 做安全边界。
