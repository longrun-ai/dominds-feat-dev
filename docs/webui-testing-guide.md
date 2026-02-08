# WebUI Testing Guide

本指南定义 Dominds WebUI 的 E2E 测试机制，目标是让测试方式长期可复用、可交接、可回归。

## 1. 适用范围与硬约束

### 1.1 适用范围

- 目标系统：`http://localhost:5555` 上的 Dominds WebUI。
- 目标测试：端到端用户旅程（创建对话、发送消息、错误可见、刷新恢复等）。
- 目标读者：`@browser_tester`、`@ux`、`@fullstack` 及后续接手回归人员。

### 1.2 硬约束（必须遵守）

- 禁止直接调用 HTTP/WS API。
- 禁止运行脚本（包括浏览器控制台脚本、shell 脚本、测试驱动脚本）。
- 所有操作必须通过浏览器中的“模拟人类交互”完成（键盘、鼠标、触控）。
- 结果必须可复现；逐轮回贴结论（`Pass`/`Fail`/`Blocked`）+ 关键发现（纯文本即可）。

> 说明：本约束用于保证“测试结果反映真实用户体验”，避免脚本捷径掩盖真实交互缺陷。

补充澄清（避免误解）：

- 允许使用 Playwright MCP 工具来“代替人手”完成点击/输入/刷新等浏览器操作。
- 但仍禁止任何形式的自写脚本/console helper 注入，以及绕过 UI 的 API/WS 直连。

补充澄清（恢复/排障步骤的合法性）：

- 为保证“测试流程能完整跑通并可复现”，允许使用以下**运维型恢复步骤**（不属于产品交互捷径）：
  - `mcp_release({"serverId":"playwright"})` / `mcp_restart({"serverId":"playwright"})`（来自 `mcp_admin`，用于回收/重启 MCP 租约资源）。
  - `./dev-server.sh restart`（仅由 `@cmdr` 执行，用于恢复 dev-server 环境）。
- 这些恢复动作必须在回贴中明确记录（做了什么 + 结果）。
- 每轮开始时允许做一次“整备重启”（例如先 `./dev-server.sh restart`、必要时 `mcp_restart({"serverId":"playwright"})`），以获得干净环境；这类整备不视为“意外”。
- 若测试中途需要频繁/重复依赖恢复动作才能继续推进（例如反复 `mcp_restart` / 反复重启 dev-server 才能跑完），该轮**不计入达标**；应协调 `@fullstack`/`@cmdr` 做永久修复后再复跑。

## 2. 运行环境

- 前端地址：`http://localhost:5555`
- 后端地址：`http://localhost:5556`
- 开发启动方式：`./dev-server.sh`
- WebUI Dev/UX 运行时工作区（rtws）：`ux-rtws/`
- 日志目录：`logs/`

说明：当 WebUI 由 `./dev-server.sh` 启动时，页面顶部 banner 可能显示 `Backend Runtime Workspace: .../ux-rtws`；这表示“被测 WebUI 后端”的 rtws 位置，属于预期现象，不应作为该轮回归的阻塞条件。

补充约束（测试执行侧）：

- WebUI E2E 的**执行智能体**必须从 repo root（外层 rtws）运行，以使用 `./.minds/` 下的 MCP toolset 与 `browser_tester` 成员配置。
- `ux-rtws/` 仅用于承载 WebUI dev/UX 运行时数据（`./dev-server.sh` 的 backend rtws）。
  - `ux-rtws/.minds/team.yaml`：保持最小化；禁止在此定义 `browser_tester`（成员与权限以 repo root 的 `.minds/team.yaml` 为准）。
  - `ux-rtws/.minds/mcp.yaml`：为使 `./dev-server.sh` 环境下的 Tools panel 可回归，允许在此配置 Playwright MCP（被测后端将从该 rtws 加载 MCP toolsets）。

并行测试说明（避免 profile data dir 冲突）：

- 默认要求：`ux-stories/*.md` 串行执行（同一时间只跑一个 story / 一个 Playwright MCP 实例）。
- 如确需并行：必须配置多套 Playwright MCP toolset（不同 `serverId` + `transform` 前缀区分工具名），并确保每套使用隔离的浏览器 profile data dir；每个并行测试只使用其绑定的那一套 toolset。

Story4（MCP 支持功能性测试）的约束：

- `ux-stories/mcp-toolset.md` 不应以 Playwright 等重量级 MCP server 作为测试目标。
- 优先使用一个“轻量 MCP server”验证 Dominds 的 MCP 支持链路（Tools 面板/Problems/对话内 tool call 可见性/完成态）。

### 2.1 macOS 权限前置（如适用）

- 风险：首次浏览器自动化可能触发系统权限（TCC / Gatekeeper）弹窗，导致步骤卡死或失败。
- 要求：若出现权限弹窗或系统阻止运行，按“环境阻塞（blocked）”记录，并附截图；不要把该类问题当作产品缺陷结论。

## 3. 第 1 轮方法盘点（保留 / 淘汰）

### 3.1 保留的方法（继续使用）

1. 浏览器内真实交互路径测试（点击 New Dialog、输入消息、发送、刷新页面）。
2. 关键流程观测（必要时仅在 Fail/Blocked 时附最小化截图）。
3. 轻量观测控制台与网络面板（仅观察，不注入脚本、不手工发包）。
4. 失败后重跑验证（同一旅程至少二次复核，确认非偶发）。

### 3.2 淘汰的方法（不再推荐）

1. `window.__e2e__` / `window.__domObservation__` 控制台 helper 驱动测试。
2. 通过脚本触发发送、等待、断言等“半自动 E2E”方式。
3. 直接调用 HTTP/WS 接口来模拟用户行为。
4. 依赖后端驱动脚本（例如 `tests/driving/*`）来替代 WebUI 交互验收。

淘汰原因：

- 与“仅人类交互”硬约束冲突。
- 容易产生“脚本通过但用户旅程失败”的假阳性。
- 对交接者门槛高，且复现路径不直观。

## 4. 新版流程草案（仅浏览器操作）

### Phase A：准备

1. 关闭当前浏览器窗口并重新打开 WebUI（确保全新会话），访问 `http://localhost:5555`。
2. 确认页面已连接（可见正常主界面，非错误占位）。
3. 打开浏览器 DevTools（Console + Network）用于观察（只读）。

### Phase B：执行核心旅程（推荐最小冒烟）

1. 点击左侧 `New Dialog`。
2. 在创建对话弹窗中完成必要项并点击创建。
3. 在输入框发送 `ping`。
4. 等待 agent 回复，确认出现 `pong` 或等价成功响应。
5. 刷新页面。
6. 验证刷新后：
   - 对话仍存在于列表中。
   - 历史消息仍可见。
   - 输入框可继续交互。

### Phase C：回贴记录（纯文本为主）

回贴内容建议包含（纯文本即可）：

- 结论：`Pass`/`Fail`/`Blocked`
- 关键发现：最重要的 1~5 条（包含任何“元素波动/焦点/权限弹窗/恢复步骤”等）

可选补充（仅在 Fail/Blocked 或需要说明恢复步骤时）：

- 截图：1~2 张即可（失败/阻塞/恢复的关键界面）
- Console 摘要：0~3 行（阻断性错误的关键行；不要全文 dump）
- Network 摘要：0~3 行（阻断性失败/断链的关键条目；不要全文 dump）

### Phase D：收尾

1. 若使用 MCP 租约：执行 `mcp_release({"serverId":"playwright"})` 释放。
2. 将步骤、结果、证据、异常点按模板回贴。

## 5. 稳定性与耗时（第 2 轮量化基线）

基于两轮“纯人类交互”回归实测：

- Round 1：总耗时 `9` 分钟（准备 `2` / 执行 `3` / 证据 `3` / 收尾 `1`），失败点 `1`，恢复耗时 `1` 分钟。
- Round 2：总耗时 `8` 分钟（准备 `1` / 执行 `4` / 证据 `2` / 收尾 `1`），失败点 `1`，恢复耗时 `1` 分钟。
- 两轮汇总：总耗时 `17` 分钟、失败点 `2`、恢复耗时 `2` 分钟。

失败分类计数（两轮汇总）：

- 页面：`0`
- 连接：`0`
- 数据污染：`0`
- 元素波动：`2`

### 5.1 跑法对比（旧法 vs 新法）

- 旧法（固定 sleep + 弱校验）：等待成本高，且容易“等过头/等错对象”。
- 新法（显式等待 `pong` + 关键节点截图）：耗时更短，失败定位更直接。

## 6. 最小稳定流程（最终草案）

每轮回归按以下顺序执行：

1. 打开 `http://localhost:5555` 并确认主界面可交互。
2. 点击 `New Dialog`，完成创建并确认进入可输入态。
3. 发送 `ping`，显式等待 `pong`（或等价成功响应）。
4. 收到响应后立即截图（不做固定长等待）。
5. 普通刷新页面，确认历史消息仍在。
6. 刷新后再发送 1 条最小探针并收到响应。
7. 采集证据（截图 + console/network 摘要）。
8. 完成收尾（如使用 MCP，释放租约）。

## 7. 反模式清单（必须禁止）

- 直接调用 HTTP/WS API 模拟用户行为。
- 运行脚本（含控制台 helper、shell 脚本、测试驱动脚本）。
- 固定 sleep 作为主等待策略。
- 同一轮重复抓取同类冗余证据（同视角多张截图）。
- 为“刷新恢复验证”额外新开无关会话。

## 8. 失败恢复策略与风险缓解

### 8.1 页面异常

- 风险：页面空白或不可交互。
- 缓解：手动刷新后重走最小链路；仍失败则记录关键错误并上报。

### 8.2 连接异常

- 风险：请求/连接异常导致响应中断。
- 缓解：执行一次状态复核 + 一次重试；若持续失败，归类连接问题并上报。

### 8.3 数据污染/恢复异常

- 风险：刷新后消息或对话状态不一致。
- 缓解：先重选目标对话，再刷新复核；仍异常按高优先级缺陷处理。

### 8.4 元素波动（本轮主风险）

- 风险：元素时序波动导致点击/等待超时。
- 缓解：采用显式可见状态等待，保留“一次状态复核 + 一次重试”的最小恢复链路。

## 9. 最终二值化验收 Gate（G1~G8）

- G1（创建可用）：可成功创建新对话并进入可输入态。
- G2（首轮往返）：发送 `ping` 后收到 `pong`（或等价成功响应）。
- G3（刷新恢复）：刷新后历史消息仍可见。
- G4（恢复后可交互）：刷新后再次发送最小探针并收到响应。
- G5（Console 门禁）：无阻断性 error。
- G6（Network 门禁）：无阻断性失败请求/连接中断。
- G7（回贴完整）：已回贴结论（`Pass`/`Fail`/`Blocked`）+ 关键发现（纯文本即可）。
- G8（流程合规）：全程仅人类交互，无 API 直连、无脚本。

判定规则：任一 Gate 失败即该轮 `Fail`；全部通过为 `Pass`。

## 10. 回贴要求（最小化）

每轮回归至少回贴：

- 结论：`Pass`/`Fail`/`Blocked`
- 关键发现：最重要的 1~5 条（文本即可）
- 若有重试/恢复：做了什么 + 结果
- macOS 权限/焦点：是否出现 + 如何处理（只要文本说明即可）
- MCP 收尾：若使用过 MCP，确认已执行 `mcp_release({"serverId":"playwright"})`

可选（仅在 Fail/Blocked 或需要解释恢复步骤时）：

- 截图 1~2 张（失败/阻塞/恢复的关键界面）
- Console/Network 摘要 0~3 行（关键行即可；不要全文 dump）

## 11. 回贴模板（建议）

复制以下结构回贴：

```md
### WebUI E2E 回归回贴（日期/执行人）

- 环境：`http://localhost:5555`（浏览器：xxx）
- 平台：`uname -a` 输出：xxx
- 执行智能体 rtws：repo root（外层 rtws）
- WebUI backend rtws（banner）：xxx（例如 `ux-rtws`；若由 `./dev-server.sh` 启动属于预期）

#### 结论

- 本轮结论：Pass / Fail / Blocked
- 关键发现（1~5 条）：
  - ...

#### 合规声明（必填）

- 仅通过浏览器键盘/鼠标/触控模拟人类交互：是/否
- 未直连 HTTP/WS API：是/否
- 未运行脚本（含 console helper 注入）：是/否

#### macOS 权限/焦点（如适用）

- 是否出现系统权限弹窗（TCC / Gatekeeper 等）：是/否（仅在出现时可选附 1 张截图）
- 是否出现焦点异常/前台切换导致卡住：是/否（处理方式）

#### 重试/恢复（如发生）

- 是否重试：是/否
- 做了什么：...
- 结果：...

#### MCP 租约收尾（如适用）

- 是否执行 `mcp_release({"serverId":"playwright"})`：是/否

#### 可选：最小化证据（仅 Fail/Blocked 或需说明恢复步骤时）

- 截图：1~2 张（失败/阻塞/恢复的关键界面）
- Console/Network 摘要：0~3 行（关键行即可；不要全文 dump）
```

## 12. 代码锚点（便于 cross-check）

- 主应用容器：`dominds/webapp/src/components/dominds-app.tsx`
- 创建对话流：`dominds/webapp/src/components/create-dialog-flow.ts`
- 输入组件：`dominds/webapp/src/components/dominds-q4h-input.ts`
- Q4H 面板：`dominds/webapp/src/components/dominds-q4h-panel.ts`
- WS 客户端：`dominds/webapp/src/services/websocket.ts`
- HTTP 客户端：`dominds/webapp/src/services/api.ts`

---

Last Updated: 2026-02-06 (v2: quantified baseline + G1~G8 gates)
