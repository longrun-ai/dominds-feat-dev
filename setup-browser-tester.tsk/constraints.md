## Constraints

- [owner:@ux] MCP 服务器以租约方式使用：测试完必须调用 `mcp_release({"serverId":"playwright"})` 释放。
- [owner:@ux] browser_tester 只做浏览器端 E2E 走查与缺陷复现：不直接改代码、不跑需要 `os`/shell 的命令。