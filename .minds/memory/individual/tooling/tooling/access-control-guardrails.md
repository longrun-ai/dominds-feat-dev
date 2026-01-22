# Access Control / Guardrails（权限、拒绝、审计）
关键词：`access-control` `require_escalated` `approval_policy` `sandbox_mode` `network_access` `deny` `audit`

- 权限模型入口：
  - `dominds/main/access-control.ts`：实现对 tool 调用的权限判定与“需要提升权限”的拒绝语义（供 CLI/webui 上层提示）。
- 关键语义：
  - “沙箱模式”与“网络访问”是两条独立维度：文件系统 write 与 network 是否需要 approval 分开判定。
  - 典型拒绝：当 tool 调用需要更高权限时，返回结构化拒绝信息（包含需要的权限类型与简短 justification）。
- 审计/日志：
  - `dominds/main/log.ts`：记录 tool 调用、拒绝、错误；上层可将 audit 事件呈现给用户（UX 上需区分：用户拒绝 vs policy 拒绝 vs 运行时错误）。
- 常见坑：
  - 文档里出现的 `sandbox_permissions` / `justification` 等字段必须与实现一致；若 contract 变化，需同步 `dominds/docs/cli-usage.md` 与 `dominds/docs/mcp-support.md`。
