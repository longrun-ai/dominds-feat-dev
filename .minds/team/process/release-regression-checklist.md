# 发布前回归清单（人工执行）

说明：发布由人类手工执行。本清单用于发布前把关；QA 域维护，其他域补充回归点。

## 0. 硬性 Gate（必须通过）

- `pnpm -C dominds run lint`（含 typecheck/format 检查，具体以脚本为准）
- `pnpm -C dominds/tests <对应脚本>`（按 `dominds/tests/README.md` 与 scripts 选择最小集合；至少覆盖 S1-S6）

## 1. 最小冒烟集（S1-S6，must-pass）

> 目标：用最小成本覆盖“能跑起来 + 能连上 + 能走一条最小流程”。

| ID  | 旅程                                                                     |   Scriptable | Manual | Owner                   | Evidence（必填）                                        |
| --- | ------------------------------------------------------------------------ | -----------: | -----: | ----------------------- | ------------------------------------------------------- |
| S1  | 安装/依赖就绪：`pnpm -C dominds install`                                 |           ✅ |      - | @tooling                | 终端输出（最后 20 行）                                  |
| S2  | 构建成功：`pnpm -C dominds run build`                                    |           ✅ |      - | @runtime/@server/@webui | 终端输出（最后 20 行）+ 产物目录快照（`dominds/dist/`） |
| S3  | 后端健康检查：启动 server 后 `GET /api/health` 返回 200 且包含 `version` | 部分（curl） |     ✅ | @server                 | curl 输出 + server 日志片段                             |
| S4  | WebUI 可用：页面加载成功且无阻断性错误（控制台 0 error）                 |            - |     ✅ | @webui/@ux              | 截图 + Console 截图                                     |
| S5  | WS 连接：WebUI 与 `/ws` 建立连接（握手成功/无重复断连）                  |            - |     ✅ | @server/@webui          | Network/WS 截图或日志片段                               |
| S6  | CLI 最小流程：执行一条最小命令链路（启动/连接/执行一次）且 exit code=0   |           ✅ |     ✅ | @cli                    | 命令行 transcript（含退出码）                           |

## 2. 回归表（R1-R10）

> 目标：把“发布前要验什么”收敛为可打勾条目；每条必须有证据与归属。

| ID  | 回归点                                                              |   Scriptable | Manual | Owner          | Evidence（必填）                      |
| --- | ------------------------------------------------------------------- | -----------: | -----: | -------------- | ------------------------------------- |
| R1  | TypeScript 类型检查通过（来自 `pnpm -C dominds run lint`）          |           ✅ |      - | @tooling       | CI/终端输出（最后 50 行）             |
| R2  | Prettier 格式检查通过（来自 `pnpm -C dominds run lint`）            |           ✅ |      - | @tooling       | CI/终端输出（最后 50 行）             |
| R3  | `dominds/tests` 最小集合通过（与本次改动相关的脚本）                |           ✅ |      - | @qa            | `pnpm -C dominds/tests <script>` 输出 |
| R4  | Server API 兼容：关键路由不破坏（至少 `/api/health`、核心业务路由） | 部分（curl） |     ✅ | @server        | curl 输出 + 变更说明（若有 breaking） |
| R5  | WS schema/事件语义不回退（连接、进度、错误）                        |            - |     ✅ | @server/@webui | WS 抓包截图或日志                     |
| R6  | Runtime：核心状态机不回退（关键事件序列可完成）                     |            - |     ✅ | @runtime       | 日志片段（关键事件序列）              |
| R7  | WebUI 关键旅程可完成（输入→执行→展示结果/错误）                     |            - |     ✅ | @webui/@ux     | 录屏/截图 + Console 截图              |
| R8  | CLI UX 不回退：帮助/退出码/可脚本化输出稳定                         |           ✅ |     ✅ | @cli           | `--help` 输出 + 示例命令 transcript   |
| R9  | Tools registry/guardrails 不回退：关键工具仍可调用且权限边界生效    |         部分 |     ✅ | @tooling       | 审计/日志片段 + 失败示例（拒绝时）    |
| R10 | MCP（若本次涉及）：最小 MCP 集成用例可跑通                          |         部分 |     ✅ | @mcp           | 运行 transcript + 版本信息            |

## 3. 结果记录（人工）

- 版本号：
- 执行人：
- 执行时间：
- 通过/失败：
- 失败项与日志链接：

## 4. TODO（各域 owner 补齐）

- @qa：把 `dominds/tests` 最小集合固化为脚本名（映射到 S1-S6/R3），并补一键运行入口（README 或 script）。
- @server：列出“关键 API/WS”清单（路由 + WS 事件）与兼容性承诺；给出最小 curl/WS 验证步骤。
- @webui：定义“关键旅程”列表与验收点（页面路径/状态）；补手工验收步骤与截图证据规范。
- @cli：定义“最小流程命令链路”（含参数/期望输出/退出码），保证可脚本化复现。
- @tooling：列出关键工具与 guardrails（允许/拒绝）用例；给出审计证据的获取方式。
- @runtime：定义关键状态机事件序列与日志锚点，便于 QA 验证。
- @mcp：提供最小 MCP 回归用例（何时必跑、如何跑、如何采集证据）。
