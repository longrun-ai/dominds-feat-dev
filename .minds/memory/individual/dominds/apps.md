# Dominds：Apps（kernel/app）相关索引（@fullstack）

## 代码落点

- Apps 核心：`dominds/main/apps/**`
- Apps host（IPC/host/client）：`dominds/main/apps-host/**`

## Workspace override（read-time path 解析）

- 实现文件：`dominds/main/apps/override-paths.ts`
- 入口函数：`resolveAppOverrideFileAbs({ rtwsRootAbs, appId, appRelPath })`
- 约束：`appRelPath` 必须是相对路径且禁止 `..` traversal（内部会 normalize；不合法则返回 `kind:'none'`）
- 读取优先级：
  1. `<rtws>/.apps/override/<app-id>/<rel>`（source=`override`）
  2. `<rtws>/.apps/<app-id>/<rel>`（legacy；source=`legacy_override`）
- 返回类型：discriminated union：`{kind:'none'}` | `{kind:'found', filePathAbs, source}`

## 相关 docs（RFC-ish / 注意区分 planned vs implemented）

- `dominds/docs/app-constitution.zh.md` / `dominds/docs/app-constitution.md`
- `dominds/docs/kernel-app-architecture.zh.md` / `dominds/docs/kernel-app-architecture.md`
