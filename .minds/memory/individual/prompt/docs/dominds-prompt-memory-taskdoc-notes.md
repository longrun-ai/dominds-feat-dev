# Dominds：Prompt / Memory / `*.tsk/`（细节记忆）
（覆盖更新：补充本轮关于 tellask body 规则、错误成因、以及系统提示修复的事实锚点）

## tellask：解析规则（避免空 body / malformed）
- tellask 行：只有行首第 0 列以 `!?` 开头的行会进入诉请解析；任意非 `!?` 行会被当作普通 markdown，同时也会终止当前诉请块（`dominds/main/tellask.ts:9-13`）。
- 有效诉请头：一个诉请块第一行必须以 `!?@<mention-id>` 开头，否则会报 `ERR_MALFORMED_TELLASK`（`dominds/main/tellask.ts:15-20`）。
- headline/body 划分：第一行永远 headline；后续行若 `!?@` 则继续 headline，否则进入 body（`dominds/main/tellask.ts:18-21`、`dominds/main/tellask.ts:311-315`）。
- 典型报错链路：
  - `add_memory/replace_memory`：若 body 为空会报“需要在正文中提供记忆内容”（`dominds/main/tools/mem.ts:136-142` / `dominds/main/tools/mem.ts:286-292`）。
  - `change_mind`：若 body 为空会报“需要提供差遣牒内容”（`dominds/main/tools/ctrl.ts` 的 `taskDocContentRequired` 文案与校验逻辑）。

## Prompt 修复（降低 onboarding 踩坑率）
- 已在 `dominds/main/minds/system-prompt.ts` 的 tellask 语法段落中补充“关键易错点”：对 `!?@add_memory` / `!?@replace_memory` / `!?@change_mind` 等需要正文的工具，正文每行也必须以 `!?` 开头，否则会被当作普通 markdown 分隔符导致 body 为空（`dominds/main/minds/system-prompt.ts:77` 附近）。

## `**/*.tsk/`：封装策略与代码兜底（回指要点）
- 文档规范：通用文件工具必须拒绝 `**/*.tsk/` 下路径读/写/列目录/删除，且 prompt/工具文档必须明示（`dominds/docs/encapsulated-task-doc.md:131-146`）。
- 代码兜底：`hasReadAccess/hasWriteAccess` 对 `*.tsk` 路径硬拒绝（`dominds/main/access-control.ts:160-163`、`dominds/main/access-control.ts:214-217`）；`dominds/main/tools/fs.ts` 在执行前统一调用它们，从而一致阻止访问。
- 拒绝文案：`getAccessDeniedMessage` 对 `*.tsk/` 会提示只能用 `!?@change_mind` 更新分段（`dominds/main/access-control.ts:271-285`）。