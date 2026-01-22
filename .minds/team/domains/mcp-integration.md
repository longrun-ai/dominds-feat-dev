# 域：MCP Integration（低频维护）

## 覆盖范围（路径）

- `dominds/main/mcp/**`（若存在；按实际目录结构延伸）
- 与 MCP server/client/协议适配相关代码（按现有 import 关系延伸）

## 职责

- MCP 相关协议适配、兼容性与集成稳定性
- 作为跨域顾问：当 Runtime/Tooling/Server 触及 MCP 接口时参与评审
- 维护 MCP 的最小回归用例（交给 QA）

## 交付物

- MCP 集成说明与契约（面向内部/外部调用者）
- MCP 变更的兼容性评估
- 低频但关键的回归点与故障排查线索
