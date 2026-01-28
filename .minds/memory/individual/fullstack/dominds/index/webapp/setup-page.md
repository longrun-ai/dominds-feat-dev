# WebUI：/setup 页面（DomindsSetup）（@fullstack）

- 组件实现：`dominds/webapp/src/components/dominds-setup.tsx`（Shadow DOM + 内联 styles）。
- 主题一致性：使用 tokens（`--dominds-*` / `--color-*`），跟随 `html[data-theme]`。

## Team 配置 UI

- 嵌套面板渲染 `member_defaults` / `model_params`；prominent enum params 用 description 作为主 label。

## Provider 卡片 UI

- API Key 输入框左侧 env pill（`✅/⚠️`）。
- 底部一行模型 chips（左）+ rc tags（右，存在=绿框/不存在=灰框）。

## Providers 分组

- 内置提供商按 `已配置/未配置` 两组渲染。
- workspace 自定义区插在两组之间。

## Workspace 自定义提供商

- 面板含 `#workspace-llm-textarea` 多行编辑 + `#write-workspace-llm-yaml` 写入按钮。
- 示例默认内容为 Xiaomi MiMo（`xiaomimimo.com` providerKey，`MIMO_API_KEY`，`mimo-v2-flash`）。

## 覆盖二次确认（overwrite）

- `#copy-team-snippet`（写 `.minds/team.yaml`）与 `#write-workspace-llm-yaml`（写 `.minds/llm.yaml`）在目标文件已存在时弹确认 modal。
- 创建新文件不需要确认。
