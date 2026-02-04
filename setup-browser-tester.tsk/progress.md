## Progress

- [owner:@ux] 已新增 `.minds/mcp.yaml`：注册 MCP serverId `playwright`（stdio），命令 `npx -y @playwright/mcp@latest`，并统一加前缀 `playwright_`。
- [owner:@ux] 已更新 `.minds/team.yaml`：新增成员 `browser_tester`，授予 toolsets：`memory`、`playwright`、`mcp_admin`。
- [owner:@ux] 已新增/更新 `.minds/team/browser_tester/persona.zh.md` 与 `.minds/team/browser_tester/checklist.zh.md`：默认只测 `./dev-server.sh` 启动的 `http://localhost:5555`（通常无鉴权）；不可访问时先提醒 @human 确认 dev server 状态。
- [owner:@ux] 已运行 `team_mgmt_validate_team_cfg()`：`.minds/team.yaml` ✅ 无问题。
- [owner:@ux] @browser_tester 已完成最小 E2E 冒烟（tellaskSession: `setup-browser-tester-smoke-5555`）：通过 ✅
  - 1) 首页可加载：`http://localhost:5555/` 可打开；`console red error = 0`。
  - 2) 创建/进入 dialog + `ping`：输出 `pong ✅ ...` 可见；证据：`smoke-5555-rerun-step2-ping-pong.png`。
  - 3) 可控错误：对话内可见“非法参数”错误块（`ripgrep_files` 的 `case` 枚举值提示 `smart|sensitive|insensitive`）；未观察到独立 toast；`console red error = 0`；network 均为 `200/201`。
  - 4) 刷新恢复：刷新后历史仍在且可继续输入。
  - 收尾：已执行 `mcp_release({"serverId":"playwright"})`。
- [owner:@ux] @browser_tester 已完成重复冒烟 rerun1/rerun2（tellaskSession: `setup-browser-tester-smoke-5555-rerun`）：两次均通过 ✅
  - rerun1：新建 @pangu 对话 `50/aa/27aeec20`；`console red error = 0`；network 均为 `200/201`（无 `4xx/5xx`）；截图 `smoke-5555-rerun1-step2-ping-pong.png`、`smoke-5555-rerun1-step3-ripgrep-invalid-case.png`、`smoke-5555-rerun1-step4-after-refresh.png`；收尾已 `mcp_release({"serverId":"playwright"})`。
  - rerun2：新建 @pangu 对话 `d0/bf/27bcd191`；`console red error = 0`；network 均为 `200/201`（无 `4xx/5xx`）；截图 `smoke-5555-rerun2-step2-ping-pong.png`、`smoke-5555-rerun2-step3-ripgrep-invalid-case.png`、`smoke-5555-rerun2-step4-after-refresh.png`；收尾已 `mcp_release({"serverId":"playwright"})`。

Next:
- [owner:@ux] 将“创建新对话”弹窗按钮 enabled 条件/overlay 动画稳定性问题记录为 UX 改进点（非本次冒烟阻塞），并请 @fullstack 评估修复优先级。