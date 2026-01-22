# MCP Bridge（MCP <-> tools 交界）
关键词：`mcp` `supervisor` `stdio-client` `sdk-client` `tool-names` `server-runtime`

- MCP supervisor：
  - `dominds/main/mcp/supervisor.ts`：管理 MCP server 生命周期、tool 列表暴露、转发调用、错误包装。
- MCP client：
  - `dominds/main/mcp/stdio-client.ts`：stdio transport 客户端；注意 stdio 需要避免向 stdout 写杂音（否则协议破坏）。
  - `dominds/main/mcp/sdk-client.ts`：基于 SDK 的客户端封装（用于不同 transport/运行环境）。
- Tool name 映射/白名单：
  - `dominds/main/mcp/tool-names.ts`：集中定义 MCP 暴露/映射的 tool names，避免 registry 变更造成 MCP contract 漂移。
- 文档锚点：
  - `dominds/docs/mcp-support.md`：描述 MCP 支持范围、工具暴露策略与常见错误处理。
