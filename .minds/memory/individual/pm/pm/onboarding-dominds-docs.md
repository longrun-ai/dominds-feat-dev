# Dominds PM 上岗记忆（docs 摘要）

## 我（pm）的责任边界
- 默认 scope：`dominds/docs/**`（机制/设计/规范）+ 与其直接相关的跨域接口描述（用于需求分流、依赖矩阵、验收口径）。
- 不直接 owner 代码实现（runtime/server/webui/cli），除非人类明确授权；需要时用队友诉请分派（@runtime/@server/@webui/@cli/@tooling/@qa）。

## 核心设计哲学（design.md / mottos.md）
- 根因：LLM“迷失”通常是**关注点过多/认知过载**而非 token 不够。
- 关键策略：**主动心智卫生**（频繁清噪/重置），而非依赖“压缩总结”。
- 中枢结构：Task-centered focus（任务文档为单一真相源），将长期稳定信息沉淀到 task doc / reminders，必要时用 `!!@clear_mind` 清理对话噪声。
- Fresh Boots Reasoning（FBR）要点：
  - 默认用 `!!@self`（TYPE C transient）做一次性“新靴子推理”，只带 task doc + 子问题。
  - `!!@self !topic <topic-id>`（TYPE B 注册型）应少用，仅当明确需要可恢复的长期 workspace。

## 对话系统：驱动/协作/挂起（dialog-system.md）
- Backend-driven：对话驱动是**后端协程**的唯一职责；前端只订阅事件/发布通道，不负责驱动状态机。
- 三层 registry：
  - Global（server-scoped）`rootId → RootDialog`
  - Local（per root）`selfId → Dialog`（root + loaded subdialogs）
  - Subdialog registry（per root）`agentId!topicId → Subdialog`（仅 TYPE B 注册型）
- 每个 Dialog 有 mutex，保证同一时刻只有一个协程驱动，避免竞态。
- Teammate call 三类型：
  - TYPE A：`!!@super`（子对话呼叫直接父对话；禁止 `!topic`）
  - TYPE B：`!!@agentId !topic topicId`（注册型，可恢复；key=`agentId!topicId`）
    - 复用时会更新“当前 caller dialog id + callInfo”，保证回传路由到**最新 caller**
    - 每次 TYPE B 调用都会把 parent 的 `headLine/callBody` 作为新 user msg 追加进 subdialog
  - TYPE C：`!!@agentId`（临时子对话，不注册）
- Q4H：
  - 通过 `!!@human`/`!!@ask_human` 触发；driver 检测到首个 mention 为 `human/ask_human` 就 suspend
  - 索引在 `q4h.yaml`（仅索引，source-of-truth 在消息记录）
  - UI 通过 `questions_count_update` 事件获知，并读取 q4h.yaml 展示
  - 用户答复用 WS 包 `drive_dialog_by_user_answer`（带 `questionId`；后端先清 q4h 再 resume）
  - `!!@clear_mind` 会清掉 Q4H 索引（但保留 reminders、保留 Type B registry）
- 典型存储路径（workspace 相对路径）：
  - `.dialogs/run/<root-id>/dialog.yaml`
  - `.dialogs/run/<root-id>/latest.yaml`
  - `.dialogs/run/<root-id>/reminders.json`
  - `.dialogs/run/<root-id>/q4h.yaml`
  - `.dialogs/run/<root-id>/round-001.jsonl` / `round-001.yaml`
  - `.dialogs/run/<root-id>/subdialogs/<sub-id>/...`（含 q4h）

## 封装差遣牒（encapsulated-task-doc.md）
- 任务文档是 `*.tsk/` 目录包：`goals.md` / `constraints.md` / `progress.md`（都要求存在）。
- `!!@change_mind`：一次只能替换**一个**分段的全文；不会触发 round reset。
- `**/*.tsk/` 对通用文件工具**完全禁止**读写/列目录；只能通过显式 task-doc 操作管理。

## Keep-going：根对话自动续航（keep-going.md）
- 仅 root/main dialog：当 driver 本该停止且**没有合法 suspend**（无 Q4H、无待回填子对话）时，注入“diligence prompt”（作为普通 user bubble）继续生成。
- budget 默认 30；耗尽后强制发起 Q4H 让人类决定继续/停止；Q4H 触发会重置计数。
- 配置优先级：`.minds/diligence.<lang>.md` → `.minds/diligence.md` → 内建 fallback；空文件或 `max-num-prompts<1` 可禁用。

## Auth（auth.md）
- Dev mode：始终禁用 auth（`DOMINDS_AUTH_KEY` 无效）。
- Prod mode：
  - `DOMINDS_AUTH_KEY` unset → 启用 auth 且随机生成 key
  - empty string → 禁用 auth
  - non-empty → 启用并使用该 key（不 trim，不规范化）
- 客户端传递：
  - HTTP：`Authorization: Bearer <key>`
  - WS：`Sec-WebSocket-Protocol: dominds-auth.<key>`
- WebUI key 优先级：URL `?auth=`（不读写 localStorage）> localStorage > 用户输入（成功后写回 localStorage）。
- CLI webui 在 prod 且启用 auth 时打印 auto-auth URL；auth 禁用时不得打印 key。

## Context health（context-health.md）
- 目标：从 provider usage stats 收集 token 用量，算健康信号（prompt tokens / model context limit），并用 owned reminder 提醒“该 clear mind 了”。
- 原则：不做本地 tokenizer 估算；provider 不给就显示 unknown。
- `optimal_max_tokens`（可选）缺省为 hard limit 的 50%；通过 ReminderOwner 自动 drop/keep/update 控制提醒生命周期。
- UI：常驻小指示器（prompt tokens + 百分比），unknown 友好处理。

## Dialog 持久化概览（dialog-persistence.md）
- 存储根：`.dialogs/run|done|archive`
- Root + subdialogs：root 下 `subdialogs/` 平铺；文件含 `dialog.yaml`、`latest.yaml`、`reminders.json`、`round-*.jsonl`、`round-*.yaml` 等。
- `latest.yaml`：`currentRound/lastModified/...` 用于 UI 列表展示与排序；更新应为原子操作。
- Stream error：不写入 JSONL（不复现到 UI）；仅在 backend logs（如 `logs/backend-stdout.log`）可见。
- task doc：对话引用的任务文档必须为 `*.tsk/`。

## MCP 支持要点（mcp-support.md）
- `.minds/mcp.yaml` loader + mandatory hot-reload；MCP server 映射为 toolset（`<serverId>`），工具注册进全局 registry；冲突要跳过并告警。
- 并发/租约：默认 `truely-stateless: false`（拼写如此）→ per-dialog lease + owned reminder；释放用 `mcp_release({"serverId":"..."})`；为 true 可共享。
- 工具过滤：`whitelist/blacklist`（黑名单存在时 whitelist 为 override-cherrypick 语义）。
- 名称约束：原始名与 transform 后名都必须匹配 `^[a-zA-Z0-9_-]{1,64}$`；不允许隐式重命名，只能靠显式 transform。
- Schema：先 passthrough（逐步补齐 JSON Schema 支持）；provider reject 必须入 Problems + logs；invalid request 不应自动重试，应停下等待用户修复后 resume。
- env/headers：支持 literal 或 `{ env: EXISTING_ENV }` 从宿主环境复制。
- Hot-reload 实践要点（设计）：
  - watch + poll + debounce
  - compute-then-swap；按 server 独立提交（失败保持 last-known-good）
  - 需要 registry ownership tracking（只卸载 MCP-owned）
  - in-flight 安全：先 unregister 阻止新调用，inFlight==0 再停 client（可超时强杀）

## WebUI Tools/Problems 合同（team-tools-view.md）
- Team Members：`GET /api/team/config`；支持 Refresh/Search/显示 hidden；提供插入/复制 `@mention`。
- Tools registry：Refresh 拉 snapshot（且清掉旧数据避免误判）；按注册顺序展示；MCP toolset 顺序尽量跟随 `.minds/mcp.yaml`。
- Problems：workspace-level “active set”；WS `problems_snapshot`（connect）+ `get_problems`（按需）；提供稳定 DOM hooks（含 shadow DOM 选择器）。

## 中断与续跑（interruption-resumption.md）
- Run state 心智模型：Idle(wait user)/Proceeding/Interrupted(resumable)/Blocked(needs user action)/Terminal。
- Stop/Emergency stop/Continue/Resume all：要求后端提供 proceeding/idle/interrupted/blocked + reason；Resume 应幂等；若可能重复 side effects，UI 需显式确认或标记不 eligible。

## CLI 要点（cli-usage.md）
- 命令空间：dominds 子命令；强调“用户优先命令空间”——dominds 自己的开关/子命令尽量用 `--` 前缀，裸参数留给用户文件/任务。
- `dominds tui/run`：支持 `--list`、`-C/--cwd`、`-m/--member`、`-i/--id`；CI 环境自动非交互输出。
- `dominds read`：用于读取/验证 minds（`--validate` 等），可 `--only-prompt/--only-mem`。
- dialogs 存储：`.dialogs/run|done|archive`；并有基本错误处理/命令校验（unknown command 提示等）。

## `.minds/` 安全管理与权限语义（team-mgmt-toolset.md）
- 目标：提供专用 `team-mgmt` 工具集，只允许管理 `.minds/**`（而非广泛 rtws 读写），避免 `.minds/team.yaml`（权限面）成为“全仓写”升级面。
- 关键建议：
  - `member_defaults.provider` / `member_defaults.model` 必填；成员对象用 prototype fallback（`Object.setPrototypeOf`）继承 defaults。
  - 目录规则由 `matchesPattern()`（`dominds/main/access-control.ts`）评估，支持 `*`、`**`；deny-list（`no_*`）优先于 allow-list（`*_dirs`）。
  - 普通成员默认 deny `.minds/**` 写（`no_write_dirs: ['.minds/**']`），团队管理交给 `team-mgmt` 工具与 `!!@team_mgmt_manual`。
  - minds 文件：`.minds/team/<id>/{persona,knowledge,lessons}.md` 由 `dominds/main/minds/load.ts` 读取。
- Bootstrap：shadow `fuxi` 负责 team-mgmt（不应给 broad `ws_mod`），shadow `pangu` 给 broad workspace toolsets（不应给 team-mgmt）。

## Dev 原则（dev-principles.md）
- 小规模 LAN（~3 用户）优先：可读性、单一职责、避免过度工程；优雅错误处理。
- “不提供稳定性保证，API 随时变更”；重构要彻底清理旧实现并同步文档（不被兼容性包袱拖累）。

## OEC（OEC-philosophy.md）
- 日事日毕、日清日高：闭环（PDCA）、对比分析、持续优化；可映射到“对话轮次清理/当日问题闭环/可追责与可观测”。

## PM 默认“四件套模板”（PRD-lite 骨架）
- 需求分流：变更落在哪些域（docs/runtime/server/webui/cli/tooling/qa）？owner 是谁？不在 owner 域的点如何移交？
- 依赖矩阵：接口/事件/配置依赖（HTTP/WS/文件/registry）；前后端对齐点；schema/命名/权限约束。
- 验收口径：用户可见行为 + API/WS contract + 错误/进度语义 + 安全/权限（auth、tsk 封装、tools scope）。
- 回归点：冒烟清单（root/subdialog、Q4H、keep-going budget、auth on/off、tsk 禁读写、Problems active set、MCP lease/reload、context health unknown/known）。
