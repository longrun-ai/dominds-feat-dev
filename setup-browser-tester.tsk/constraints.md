## Constraints
## Constraints
- [owner:@ux] MCP 服务器以租约方式使用：测试完必须调用 `mcp_release({"serverId":"<serverId>"})` 释放。
- [owner:@ux] `browser_tester` 只做浏览器端 E2E 走查与缺陷复现：不直接改代码、不跑需要 `os`/shell 的命令。
- [owner:@ux] WebUI E2E 测试禁止直接调用 HTTP/WS API；不允许运行脚本；所有动作必须通过浏览器中的键盘、鼠标、触控等“模拟人类用户操作”完成。
- [owner:@ux] 新口径：不再使用 DoD/证据包口径。`@browser_tester` 逐篇回贴 `Pass/Fail/Blocked` + 关键发现（纯文本）即可；证据（截图/日志）仅在 Fail/Blocked 时可选最小化。
- [owner:@ux] `./dev-server.sh` 的 backend rtws 为 `ux-rtws/`：允许在 `ux-rtws/.minds/mcp.yaml` 配置“轻量 MCP server”（用于 `ux-stories/mcp-toolset.md` 的功能性测试）；禁止在 `ux-rtws/.minds/team.yaml` 定义 `browser_tester`（成员与授权以 repo root `.minds/team.yaml` 为准）。
- [owner:@ux] `ux-stories/mcp-toolset.md` 不得使用 Playwright 等重量级 MCP server 作为测试目标；应使用简单 MCP server 完成 Dominds MCP 支持的功能性测试（必要时可自制测试用 MCP server，落在 `ux-rtws/` 内）。
- [owner:@ux] 可测试性改造的 UX 钩子约束（不改变“像人一样操作”的前提）：
  - 优先通过 **可访问性语义** 提升可测性（稳定的 `aria-label`/`role`/可聚焦性/可键盘操作），其次才引入 `data-testid`（仅用于关键控件/关键状态节点）。
  - 禁止让测试依赖易变文案（尤其 i18n 文案）做唯一定位依据；定位应优先依赖语义/结构/稳定标识。
  - 不引入“仅测试可见”的后门交互（除非是明确的 operator 诊断面板/模式，并有 UI 内可见入口与回归 story 覆盖）。
- [owner:@ux] 证据/快照/临时笔记（`.md`/`.png` 等）必须写入 gitignored 目录：`artifacts/browser_tester/`（推荐 `artifacts/browser_tester/snapshots/`），禁止写到 repo root。