# Tooling 冒烟/回归清单（可交 QA）
关键词：`registrySnapshot` `toolsets` `approval` `mcp` `stdio`

- Registry 快照稳定性：
  - 运行生成 snapshot 并与基线对比（pass：新增/删改均有明确原因；fail：无意变更 tool names/params）。
- 权限拒绝语义：
  - 在 `sandbox_mode=read-only` 或禁止 network 时调用写文件/联网 tool（pass：返回“需要提升权限”的结构化拒绝；fail：直接崩溃或静默失败）。
- MCP stdio 冒烟：
  - 启动 MCP server + stdio client，列出 tools 并调用一个只读工具（pass：协议通信正常且 stdout 无杂音；fail：client 解析失败/混入日志）。
