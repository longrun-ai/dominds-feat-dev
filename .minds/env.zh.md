**重要**： 当前运行的环境不是 "genuine" Codex CLI 运行环境，而是 Dominds 运行时。

当前 rtws 性质为 Dominds 软件自我开发。

### 执行口径（默认）

- Dominds 为前后端一体仓库，默认按整体方案设计与实现（`dominds/main` + `dominds/webapp` + shared 契约同步）。
- 默认执行原则：**前后端一体、一次性改到位、无兼容层**。
- 除非 @human 明确要求，否则不引入过渡路径、双轨逻辑、向后兼容垫片或历史包袱。

### 异常处理口径（默认）

- **严禁吞错**：禁止静默吞掉异常、静默去重、静默降级或静默改写关键行为。
- **程序遇到不合理情景，应该 fail-fast，而不是为其兜底**：例如重复 ID / 重复 call 关联 / 流顺序违规，必须明确报错并中止不安全路径。
- **异常必须“响亮发声”**：除结构化日志外，需发出可观测信号（如 `stream_error_evt`），并携带稳定关联字段（`rootId`、`selfId`、`course`、`genseq`、`callId`、`questionId` 等适用字段）。
- 非经 @human 明确授权，不得以“容错”为由引入静默兜底；即使做降级，也必须保留明确告警/错误信号，便于排查根因。

### Dominds 程序来源

当前 Dominds 环境使用的是“本机全局安装/链接”的 `dominds` WebUI，并且该软件版本由本仓库内的 `./dominds/` 目录构建得到：

1. 在本仓库根目录执行：`pnpm -C dominds link -g`（把 `./dominds/` 链接为全局 `dominds` 命令）
2. 然后执行：`pnpm -C dominds build`（构建 backend + webapp）
3. 之后在本仓库根目录运行：`dominds`（使用 repo root 作为 rtws）

### WebUI 开发（避免污染根工作区）

`./dev-server.sh` 会以 `ux-rtws/` 作为 rtws 启动开发服务器（便于 UX 测试，不污染根工作区的 `.minds/` 与 `.dialogs/`）。

**注意**： 当前环境并非由 `./dev-server.sh` 启动的实例。

### 团队协作护栏（WebUI E2E / dev-server）

- **dev-server 热重载/被动变更风险**：`./dev-server.sh` 运行期间，`@fullstack` 对 `dominds/**` 的改动可能被 Vite/后端热重载吸收，从而影响 `@browser_tester` 的进行中回归。
  - 建议：当 `@browser_tester` 正在做“连续 2 轮”验收跑时，`@fullstack` 应避免合入/启用会触发热重载的变更；必须改动时，先在主线明确宣告并暂停该轮验收，改动后重新做“整备重启”再重新计轮次。

- **构建/类型检查责任边界**：诸如 `pnpm -C dominds run lint:types` / build / tests 属于“改动 owner”的自检责任。
  - 禁止把这类命令通过 tellask 回推给诉请者（tellaskee 不应要求 tellasker 代为执行）。
  - 若需要 shell 执行，仅可诉请 `@cmdr`，并明确这是“owner 自检的代跑”，不得作为把责任转移给他人的手段。
