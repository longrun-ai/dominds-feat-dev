# Kimi Code Coding Plan 接入设计记录

本文记录 Dominds 引入 Kimi Code / Kimi For Coding 套餐能力的调研结论、当前代码差距、设计决策和后续实施清单。

调研日期：2026-05-08

## 背景

Kimi Code 的 Coding Plan 与普通 Moonshot Open Platform API 不是同一条集成路径。对 coding agent 来说，关键差异不只是模型名，还包括：

- 专用 Base URL：`https://api.kimi.com/coding/v1`
- 专用模型入口：`kimi-for-coding`
- OpenAI Chat Completions 兼容请求形态
- Kimi 扩展字段：`prompt_cache_key`、`thinking`、`reasoning_effort`
- Kimi Code 账号权益与 API Key / OAuth 凭据路径
- 客户端身份标识要求，包括真实 `User-Agent`

Kimi CLI 源码显示，Kimi Code 默认不是 OpenAI Responses，也不是 Anthropic Messages，而是通过 OpenAI SDK 调用 Chat Completions 兼容接口：

```text
Kimi provider -> OpenAI SDK -> client.chat.completions.create(...)
```

Dominds 现有 `apiType: openai-compatible` 也走 Chat Completions，因此首期接入应基于现有 OpenAI-compatible wrapper，而不是新建 Anthropic-compatible wrapper。

## 资料与参考

官方资料：

- Kimi Code third-party tools / other coding agents：`https://www.kimi.com/code/docs/en/third-party-tools/other-coding-agents.html`
- Kimi CLI provider 配置文档：`https://moonshotai.github.io/kimi-cli/en/configuration/providers.html`
- Kimi Code Overview：`https://www.kimi.com/code/docs/en/`
- Kimi Code FAQ / feedback contact：`https://www.kimi.com/code/docs/en/kimi-code/faq.html`
- Kimi Help Center contact：`https://www.kimi.com/help/membership/membership-contact`
- Moonshot AI company contact：`https://www.moonshot.ai/about`
- Kimi CLI 源码中 `src/kimi_cli/llm.py`
- Kimi CLI 源码中 `packages/kosong/src/kosong/chat_provider/kimi.py`

社区与相关实现：

- OpenCode Kimi OAuth 插件：`https://github.com/lemon07r/opencode-kimi-full`
- models.dev Kimi For Coding 模型列表调整讨论：`https://github.com/anomalyco/models.dev/issues/1441`
- Kimi-K2 issue：`kimi-for-coding` temperature 校验：`https://github.com/MoonshotAI/Kimi-K2/issues/124`
- OpenClaw Kimi For Coding 社区配置记录：`https://chris.engineering/blog/03-kimi-coding-setup/`

Dominds 当前相关代码：

- `main/llm/defaults.yaml`
- `main/llm/client.ts`
- `main/llm/gen.ts`
- `main/llm/gen/openai-compatible.ts`
- `main/llm/kernel-driver/drive.ts`
- `main/team.ts`

## 非目标

首期不做：

- 不伪装成 `kimi-cli` 或 OpenCode。
- 不默认复用 `kimi-cli` 的 OAuth token 文件。
- 不把 Kimi Code 的行为泛化成所有 OpenAI-compatible provider 的默认行为。
- 不把普通 Moonshot Open Platform provider 与 Kimi Code provider 混在一起。
- 不支持动态模型池或非官方别名作为首期稳定配置。
- 不把 OAuth login 或 `/models` discovery 放进长期运行关键路径。
- 不通过篡改 `User-Agent` 绕过权益或套餐校验。

首期目标是：用 Dominds 真实客户端身份，合规接入 Kimi Code 官方 API Key 路径。

## 当前 Dominds 状态

### OpenAI-compatible wrapper

Dominds 已有 OpenAI-compatible Chat Completions wrapper：

```text
main/llm/gen/openai-compatible.ts
```

当前 wrapper 已支持：

- `baseURL`
- `apiKey`
- streaming Chat Completions
- `messages`
- `tools`
- `tool_choice`
- `parallel_tool_calls`
- `temperature`
- `top_p`
- `service_tier`
- `safety_identifier`
- `response_format`
- `thinking`
- `reasoning_effort`

`thinking` / `reasoning_effort` 通过 `model_params.openai-compatible.*` 透传：

```yaml
model_params:
  openai-compatible:
    thinking: true
    reasoning_effort: high
```

`thinking: true` 会转成：

```json
{ "thinking": { "type": "enabled" } }
```

`thinking: false` 会转成：

```json
{ "thinking": { "type": "disabled" } }
```

如果 `thinking` 为 object，则按 provider-specific object 透传。

### prompt_cache_key

Dominds kernel driver 已经生成 `promptCacheKey`，并放进 `LlmRequestContext`：

```text
${dlg.id.selfId}:c${dlg.currentCourse}
```

相关位置：

```text
main/llm/kernel-driver/drive.ts
main/llm/gen.ts
```

但是当前 `main/llm/gen/openai-compatible.ts` 没有把 `requestContext.promptCacheKey` 写入 Chat Completions payload。

也就是说：

- Dominds 当前有 request context 层面的 prompt cache key。
- Codex wrapper 已经会使用 `prompt_cache_key`。
- OpenAI-compatible wrapper 当前不支持发送 `prompt_cache_key`。
- Kimi Code 首期接入需要补这个能力。

建议补成 wrapper 能力，但只在 provider/model 明确允许时发送，避免污染普通 OpenAI-compatible provider。

### User-Agent

Dominds 当前 OpenAI-compatible wrapper 创建 client 时是：

```ts
new OpenAI({
  apiKey,
  baseURL: providerConfig.baseUrl,
});
```

没有设置 `defaultHeaders`。

Dominds 当前依赖：

```json
{
  "openai": "^6.35.0"
}
```

OpenAI Node SDK 6.35.0 默认 `User-Agent` 为：

```text
OpenAI/JS 6.35.0
```

同时 SDK 会自动发送 `X-Stainless-*` headers，例如：

- `X-Stainless-Lang: js`
- `X-Stainless-Package-Version: 6.35.0`
- `X-Stainless-OS`
- `X-Stainless-Arch`
- `X-Stainless-Runtime`
- `X-Stainless-Runtime-Version`

OpenAI SDK 支持通过 `defaultHeaders` 自定义/覆盖 `User-Agent`：

```ts
const client = new OpenAI({
  apiKey,
  baseURL,
  defaultHeaders: {
    'User-Agent': `Dominds/${version}`,
  },
});
```

也支持单次请求通过 request options 覆盖：

```ts
await client.chat.completions.create(payload, {
  headers: {
    'User-Agent': `Dominds/${version}`,
  },
});
```

首期建议在 provider profile 或 wrapper 层为 Kimi Code 设置真实 Dominds UA，例如：

```text
Dominds/1.22.0
```

不要设置成：

```text
KimiCLI/<version>
```

原因：Kimi 官方文档提醒第三方工具应保持真实客户端身份标识，篡改 User-Agent 可能导致权益暂停。

## Kimi CLI 行为摘要

Kimi CLI 中 provider type 包括：

```text
kimi
openai_legacy
openai_responses
anthropic
google_genai
```

其中 `type="kimi"` 使用 `kosong.chat_provider.kimi.Kimi`，底层请求：

```python
client.chat.completions.create(...)
```

Kimi CLI 为 Kimi provider 设置默认 headers：

```python
{
  "User-Agent": USER_AGENT,
  ...oauth.common_headers(),
  ...provider.custom_headers,
}
```

`USER_AGENT` 形如：

```text
KimiCLI/<version>
```

OAuth common headers 包括：

```text
X-Msh-Platform: kimi_cli
X-Msh-Version: <kimi-cli version>
X-Msh-Device-Name: <hostname>
X-Msh-Device-Model: <device model>
X-Msh-Os-Version: <os version>
X-Msh-Device-Id: <stable id>
```

Kimi CLI 在有 `session_id` 时会发送：

```json
{ "prompt_cache_key": "<session_id>" }
```

thinking 逻辑大致为：

- `off` -> `thinking.type=disabled`
- `low|medium|high` -> `thinking.type=enabled` + `reasoning_effort`
- `xhigh|max` 在 Kimi API 上 clamp 到 `high`

这些行为可以作为 Dominds 接入 Kimi Code 的技术参考，但客户端身份不应照搬。

## OpenCode 社区实现的参考价值

`opencode-kimi-full` 插件做了比普通 provider 配置更完整的 Kimi Code 路径：

- 走 Kimi device flow，scope 为 `kimi-code`
- 使用 `https://api.kimi.com/coding/v1`
- 使用 `@ai-sdk/openai-compatible`
- 添加 `prompt_cache_key`
- 添加 `thinking` / `reasoning_effort`
- 调 `/coding/v1/models` 发现 wire model slug、display name、context length、image input 能力
- 处理 access token refresh
- 401 后刷新 token 并重试
- 避免与 kimi-cli 共享 refresh token 文件，防止 refresh-token chain 竞争

这些机制对 Dominds 有参考价值。

但该插件还会模拟 Kimi CLI 的 `User-Agent` 和 `X-Msh-*` 指纹。Dominds 不应默认这样做。更合适的策略是：

- 默认 API Key provider 使用真实 `Dominds/<version>` UA。
- 如果未来做 OAuth provider，也使用 Dominds 自己的 OAuth/storage/UA 策略。
- 如需发送额外 Kimi 识别 headers，应走官方授权或明确 provider profile，而不是伪装成 kimi-cli。

## 总体设计决策

### 1. 首期新增 API Key provider

首期新增内置 provider：

```yaml
providers:
  kimi-code:
    name: Kimi Code
    apiType: openai-compatible
    baseUrl: https://api.kimi.com/coding/v1
    apiKeyEnvVar: KIMI_CODE_API_KEY
    models:
      kimi-for-coding:
        name: Kimi For Coding
```

建议 API Key 环境变量使用 `KIMI_CODE_API_KEY`，避免与普通 Moonshot API 的 `MOONSHOT_API_KEY` / `KIMI_API_KEY` 混淆。

### 2. 模型只声明 `kimi-for-coding`

首期只内置：

```text
kimi-for-coding
```

不内置：

- `kimi-k2`
- `kimi-k2.5`
- `kimi-k2.6`
- `kimi-k2-thinking`
- `k2p5`
- `moonshot-v1-*`

原因：

- Kimi Code 官方第三方工具配置使用 `kimi-for-coding`。
- Kimi CLI 默认显示也围绕 `kimi-for-coding`。
- OpenCode / models.dev 社区讨论倾向将 Kimi For Coding 收敛成单模型 provider。
- 后端实际 wire slug 可以后续通过 `/models` 发现再改写，不应首期暴露多个猜测模型。
- Kimi Code Overview 明确说明 `kimi-for-coding` 是稳定模型 ID，底层会自动映射到新的 Kimi Code 模型。

### 3. 不把 Kimi Code 接入普通 Moonshot provider

普通 Moonshot Open Platform 与 Kimi Code 的 base URL、权益、模型命名和计费路径不同。

Dominds 应分成两个 provider：

```text
moonshot-ai       -> 普通 Open Platform
kimi-code         -> Kimi Code Coding Plan
```

### 4. 使用真实 Dominds User-Agent

首期应覆盖 OpenAI SDK 默认 UA：

```text
Dominds/<package version>
```

原因：

- 当前默认 `OpenAI/JS 6.35.0` 对 Kimi Code 侧可观测性不友好。
- 官方要求第三方工具保持真实身份。
- 不应伪装成 Kimi CLI。
- 如果 Dominds 希望被 Kimi 官方识别为编程工具，应通过官方渠道申请认可或 allowlist，而不是靠 header 伪装。

实现方式：

```ts
const options: ConstructorParameters<typeof OpenAI>[0] = {
  apiKey,
  baseURL: args.providerConfig.baseUrl,
  defaultHeaders: {
    'User-Agent': `Dominds/${resolveDomindsVersion()}`,
  },
};
```

该能力可以先做成 provider config 字段：

```yaml
userAgent: Dominds/${version}
```

或 Kimi profile 固定逻辑。若做成通用字段，需要在 `ProviderConfig` 中新增受控字段，例如：

```ts
default_headers?: Record<string, string>
```

但不建议首期开放任意 headers 到内置 defaults，避免用户误用敏感/伪装 headers。

### 5. prompt_cache_key 作为 Kimi-specific request extension

Kimi Code 首期应发送：

```json
{
  "prompt_cache_key": requestContext.promptCacheKey
}
```

建议发送条件：

- 当前 provider profile 为 `kimi-code`，或
- `providerConfig.apiQuirks` 包含 `kimi-code`，或
- provider config 明确声明 `supports_prompt_cache_key: true`

不要对所有 `openai-compatible` provider 默认发送。

### 6. OAuth 和 /models discovery 不进入默认路线

Dominds 的目标是面向长期自主运行。对这类运行形态，稳定凭据和可复现模型声明优先于交互式授权便利性。

公开文档中，Kimi Code 当前更像是把两类接入明确分工：

- 官方客户端如 Kimi CLI / VS Code extension：OAuth 自动登录，不需要手动管理 API Key。
- 第三方工具或自建应用：使用 Kimi Code Console API Key。

没有看到官方公开表达“第三方工具应从 API Key 迁移到 OAuth”的要求。相反，官方第三方工具文档当前给出的配置路径是 API Key。

因此 Dominds 的默认路线应保持：

```text
API Key + static kimi-for-coding + real Dominds User-Agent + prompt_cache_key
```

OAuth 不适合作为默认或近期二期：

- refresh token chain 会引入长期运行中的状态漂移。
- token refresh 失败通常需要人介入重新授权，不适合无人值守保活。
- 多 workspace / 多进程并发 refresh 会带来 refresh token 轮换竞争。
- 共享 kimi-cli token 会破坏双方登录状态，独立 token store 又会增加实现和运维复杂度。
- 商业上 OAuth 更适合官方客户端体验，不一定适合第三方长期运行服务。

`/models` discovery 也不应进入默认关键路径：

- `kimi-for-coding` 是稳定模型入口，官方承诺后端自动映射更新模型。
- Dominds 不预期在运行中发现新模型并自动切换。
- 动态 discovery 会让上下文长度、能力表、模型显示名在长期任务中漂移。
- discovery 的 401/5xx/网络错误不应影响一次本可继续的长期任务。

如果未来实现 `/models`，应定位为安装/诊断工具，而不是每次启动或运行中必经步骤。

### 7. thinking / reasoning_effort 使用现有 openai-compatible namespace

Dominds 现有底层 wire 配置可复用：

```yaml
model_params:
  openai-compatible:
    thinking: true
    reasoning_effort: high
```

但对 Kimi Code 的 provider defaults / setup UI，不建议把 `thinking` 和 `reasoning_effort` 暴露成两个 prominent 参数。Kimi Code 更适合把它们合并为一个用户可理解的 prominent knob：

```yaml
model_params:
  openai-compatible:
    thinking: medium
```

其中 `thinking` 接受：

```text
auto|off|low|medium|high
```

含义与 wire payload 映射：

| 用户选择 | wire payload                                                  |
| -------- | ------------------------------------------------------------- |
| `auto`   | 省略 `thinking` 和 `reasoning_effort`                         |
| `off`    | `thinking: { type: "disabled" }`                              |
| `low`    | `thinking: { type: "enabled" }`, `reasoning_effort: "low"`    |
| `medium` | `thinking: { type: "enabled" }`, `reasoning_effort: "medium"` |
| `high`   | `thinking: { type: "enabled" }`, `reasoning_effort: "high"`   |

当前 Dominds 的 `openai-compatible.reasoning_effort` enum 是：

```text
none|minimal|low|medium|high|xhigh
```

Kimi Code 更接近：

```text
auto|off|low|medium|high
```

因此实现时不应要求用户同时填写：

```yaml
thinking: true
reasoning_effort: medium
```

而应由 Kimi Code quirk 将 `thinking: low|medium|high` 展开成：

```json
{
  "thinking": { "type": "enabled" },
  "reasoning_effort": "<low|medium|high>"
}
```

如果用户显式使用底层 `reasoning_effort` 字段，`apiQuirks: kimi-code` 仍应做 fail-fast 校验，避免把不被 Kimi Code 接受的通用 enum 送到上游。

建议首期采用保守方案：

- docs/defaults 中只把 `thinking` 展示为 prominent enum：`auto|off|low|medium|high`，默认建议值 `medium`。
- `reasoning_effort` 保留为非 prominent 的底层 advanced 字段，主要用于兼容现有 `openai-compatible` namespace 和手写配置。
- wrapper 层对 Kimi Code 禁止 `minimal|xhigh`。
- `none` 不直接映射为 `reasoning_effort=none`，而是建议用户用 `thinking: off`。

#### `thinking` 复合档位是否设为 prominent

进一步调研结论：应把复合 `thinking` 档位设为 `prominent: true`，而不是另设独立的 prominent `reasoning_effort`；默认建议值应是 `medium`，不要默认 `high`。

依据：

- Kimi 官方第三方工具文档在 Roo Code 配置示例中明确要求开启 reasoning effort，并给出 `Medium` 作为配置值。这说明 reasoning effort 对 Kimi Code 编程体验是官方认为需要显式配置的能力。
- Kimi CLI 文档把 thinking mode 作为模型能力和用户可切换模式描述，但没有把 effort level 作为单独的一等用户选项暴露。因此不能把 Kimi CLI 行为解读为“高 effort 是默认最佳实践”。
- `opencode-kimi-full` 社区插件暴露 `off/auto/low/medium/high` variants，并把 `low|medium|high` 映射到 `thinking.enabled + reasoning_effort`。插件文档也提醒：`low/medium/high` 的精确行为由 Kimi 后端控制，应视为 server hint，而不是稳定承诺的延迟/质量阶梯。
- OpenClaw 社区配置记录使用 `thinkingDefault: low`，说明真实用户会基于延迟、吞吐和成本偏好选择低 effort；这与官方 Roo Code 示例的 `Medium` 并不冲突，但说明没有足够社区证据支持强行默认 `high`。
- models.dev 讨论显示 `kimi-for-coding` 是稳定入口但后端映射模型会演进；不同 effort 的效果也可能随后端模型变化而漂移。Dominds 不应把当前社区体感固化成隐式默认。

对 Dominds 的产品含义：

- Kimi Code 的“是否思考 / 思考强度”会影响长期 autonomous coding 的成本、延迟、输出稳定性和复杂任务表现，属于初始化/团队管理时应该显式讨论并选定的参数，符合 prominent 语义。
- 单一 `thinking` enum 比 `thinking + reasoning_effort` 两个字段更符合用户心智，也能避免 `thinking: false` 搭配 `reasoning_effort: high` 这类无效组合进入团队配置。
- `medium` 是最适合作为默认建议的折中：与官方 Roo Code 示例一致，避免 `low` 在复杂重构中推理不足，也避免 `high` 在长期任务中无证据地放大延迟和成本。
- `low` 适合快速迭代、低风险编辑、批量小修；`high` 适合架构变更、跨栈 refactor、复杂 bug root-cause、一次性迁移等高风险任务。
- `auto/off` 应通过 `thinking` 表达，不应作为 `reasoning_effort` enum value 暴露给 Dominds 的 Kimi Code provider。

### 7. temperature 处理

社区 issue 显示 `kimi-for-coding` 可能对 temperature 有严格约束，例如只接受 `0.6` 或要求省略。

Kimi CLI 默认不发送 temperature，只有 `KIMI_MODEL_TEMPERATURE` 设置时才发送。

Dominds 首期建议：

- 默认不发送 `temperature`。
- 如果用户配置了 `temperature`，不要自动改写。
- 如实测确认 Kimi Code 只接受 `0.6`，则为 `apiQuirks: kimi-code` 增加 fail-fast 校验：只允许省略或 `0.6`。

### 8. tool_choice 与 parallel_tool_calls

Dominds OpenAI-compatible wrapper 当前默认：

```json
{
  "parallel_tool_calls": true
}
```

并会根据模型能力发送 `tool_choice`。

Kimi CLI 对 Kimi provider 会发送 `tools`，不显式展示 `tool_choice` 默认行为。

首期建议：

- `kimi-for-coding.supports_tool_choice` 先设置为 `false`，避免 Kimi Code 若不接受 `tool_choice` 时直接拒绝。
- `parallel_tool_calls` 首期可以保留 Dominds 默认，也可以在实测失败时设为 false。
- 如 Kimi Code 对 parallel tool calls 有明确行为，再写入模型能力。

## Provider 配置草案

```yaml
providers:
  kimi-code:
    name: Kimi Code
    apiType: openai-compatible
    apiQuirks:
      - kimi-code
    baseUrl: https://api.kimi.com/coding/v1
    apiKeyEnvVar: KIMI_CODE_API_KEY
    tech_spec_url: https://www.kimi.com/code/docs/en/third-party-tools/other-coding-agents.html
    api_mgmt_url: https://www.kimi.com/code
    model_param_options:
      openai-compatible:
        thinking:
          prominent: true
          default: medium
          type: enum
          values: [auto, off, low, medium, high]
          description: Kimi Code thinking mode. auto leaves thinking/reasoning_effort unset; off sends thinking.type=disabled; low/medium/high send thinking.type=enabled plus the matching reasoning_effort.
        reasoning_effort:
          type: enum
          values: [low, medium, high]
          description: Advanced Kimi Code wire-level reasoning effort override. Prefer the prominent thinking enum for normal setup; do not combine with auto/off/disabled thinking.
    models:
      kimi-for-coding:
        name: Kimi For Coding
        supports_thinking: true
        default_thinking: true
        supports_tool_choice: false
        supports_image_input: true
        context_length: 262144
        input_length: 262144
        output_length: 32768
        context_window: '262K'
```

字段说明：

- `context_length` / `output_length` 参考 Kimi 官方第三方工具配置建议。
- `supports_image_input: true` 需要实测确认 Dominds 的 image projection 能否被 Kimi Code 接受。
- `supports_tool_choice: false` 是保守首期设置，避免发送 `tool_choice`。
- `apiQuirks: kimi-code` 用于绑定 Kimi-specific request shaping。

## Request Shaping 要求

### Base URL

必须使用：

```text
https://api.kimi.com/coding/v1
```

不要把 Kimi Code 配到：

```text
https://api.moonshot.ai/v1
https://api.moonshot.cn/v1
```

### Path

通过 OpenAI SDK Chat Completions 调用时，实际请求路径应为：

```text
POST /chat/completions
```

完整 URL：

```text
https://api.kimi.com/coding/v1/chat/completions
```

### Model

首期发送：

```json
{ "model": "kimi-for-coding" }
```

后续若支持 `/models` discovery，可将 Dominds UI model key 固定为 `kimi-for-coding`，但 wire `model` 按 Kimi 服务端返回的 authoritative slug 改写。

### Headers

首期建议：

```text
Authorization: Bearer <KIMI_CODE_API_KEY>
User-Agent: Dominds/<version>
Accept: application/json
Content-Type: application/json
```

OpenAI SDK 还会自动附加 `X-Stainless-*` headers。

不建议首期发送：

```text
X-Msh-Platform: kimi_cli
X-Msh-Version: <kimi-cli version>
X-Msh-Device-Id: <kimi-cli device id>
```

如果 Kimi 官方后续为 Dominds 分配集成身份，可以新增真实 Dominds headers，例如：

```text
X-Msh-Platform: dominds
X-Msh-Version: <dominds version>
```

但不应自行伪造 kimi-cli 平台。

### Body

基础 payload：

```json
{
  "model": "kimi-for-coding",
  "messages": [],
  "tools": [],
  "stream": true,
  "stream_options": { "include_usage": true },
  "prompt_cache_key": "<dialog-id>:c<course>",
  "thinking": { "type": "enabled" },
  "reasoning_effort": "medium"
}
```

上例对应用户配置：

```yaml
model_params:
  openai-compatible:
    thinking: medium
```

如果用户选择 `thinking: auto` 或不配置 `thinking`：

```json
{
  "model": "kimi-for-coding",
  "messages": [],
  "tools": [],
  "stream": true,
  "stream_options": { "include_usage": true },
  "prompt_cache_key": "<dialog-id>:c<course>"
}
```

如果用户选择 `thinking: off`：

```json
{
  "thinking": { "type": "disabled" }
}
```

如果用户选择 `thinking: high`：

```json
{
  "thinking": { "type": "enabled" },
  "reasoning_effort": "high"
}
```

不要同时发送：

```json
{
  "thinking": { "type": "disabled" },
  "reasoning_effort": "high"
}
```

当前 Dominds 已经对 disabled thinking + reasoning_effort 做冲突校验，应继续保留。Kimi Code 还应新增复合 `thinking` 与底层 `reasoning_effort` 的一致性校验：如果同时设置 `thinking: low|medium|high` 和 `reasoning_effort`，两者必须相同。

## 实现计划

### Step 1：新增 provider defaults

编辑：

```text
main/llm/defaults.yaml
```

新增 `kimi-code` provider。

### Step 2：扩展 ProviderConfig

可选新增字段：

```ts
supports_prompt_cache_key?: boolean;
default_headers?: Record<string, string>;
```

但首期更推荐新增 `apiQuirks: kimi-code` 并在 wrapper 中按 quirk 分支处理，减少泛化风险。

### Step 3：OpenAI-compatible wrapper 注入 User-Agent

编辑：

```text
main/llm/gen/openai-compatible.ts
```

在 `createOpenAiCompatibleClient` 中：

- 检测 `apiQuirks` 是否包含 `kimi-code`
- 为 Kimi Code 设置 `defaultHeaders.User-Agent = Dominds/<version>`
- 保留 SSE capture 的 custom fetch 逻辑

如果未来需要更多 headers，应封装成：

```ts
function buildOpenAiCompatibleDefaultHeaders(args): Record<string, string> | undefined;
```

### Step 4：OpenAI-compatible wrapper 发送 prompt_cache_key

编辑：

```text
main/llm/gen/openai-compatible.ts
```

为 Kimi Code payload 增加：

```ts
...(shouldSendPromptCacheKey(providerConfig, requestContext)
  ? { prompt_cache_key: requestContext.promptCacheKey }
  : {})
```

注意 TypeScript 类型：

当前 `ChatCompletionCreateParamsStreaming` 类型不一定包含 Kimi 扩展字段。应新增 wrapper-local extra type：

```ts
type OpenAiCompatibleChatExtraParams = {
  thinking?: boolean | 'auto' | 'off' | 'low' | 'medium' | 'high' | Record<string, unknown>;
  reasoning_effort?: ...;
  prompt_cache_key?: string;
};
```

并保持该字段只在 Kimi Code 或明确支持的 provider 上发送。

对 Kimi Code，wrapper 需要先把复合 `thinking` enum 展开为 wire 字段：

- `auto` / absent：不发送 `thinking` / `reasoning_effort`
- `off`：发送 `thinking: { type: "disabled" }`
- `low|medium|high`：发送 `thinking: { type: "enabled" }` 和同名 `reasoning_effort`

如果配置同时包含复合 `thinking: low|medium|high` 和底层 `reasoning_effort`，两者必须一致，否则 fail fast。

### Step 5：Kimi quirk 参数校验

新增 helper：

```ts
function validateKimiCodeOpenAiCompatibleParams(args): void;
```

建议校验：

- `reasoning_effort` 只允许 `low|medium|high`
- `thinking` 字符串只允许 `auto|off|low|medium|high`
- `thinking: low|medium|high` 与显式 `reasoning_effort` 同时出现时必须一致
- `thinking.type=disabled` 不允许搭配 `reasoning_effort`
- 如果实测需要，`temperature` 只允许省略或 `0.6`
- 如果 `tool_choice` 被禁用，payload 不应含 `tool_choice`

### Step 6：增加测试

新增或扩展 tests：

```text
tests/provider/openai-compatible-kimi-code.ts
```

测试点：

- Kimi Code provider 使用 `https://api.kimi.com/coding/v1`
- payload 包含 `prompt_cache_key`
- auto thinking 不发送 `thinking` / `reasoning_effort`
- thinking high 发送 `{type:"enabled"}` + `high`
- thinking off 发送 `{type:"disabled"}` 且不发送 `reasoning_effort`
- thinking medium 与显式 `reasoning_effort: high` 同时出现时 fail fast
- `User-Agent` 为 `Dominds/<version>`，不是 `OpenAI/JS ...`，也不是 `KimiCLI/...`
- `tool_choice` 在 `supports_tool_choice: false` 时不出现
- rejected request capture 中敏感 headers 被 redacted

如果不方便直接断言 OpenAI SDK 内部 headers，可以在测试中启用 `DOMINDS_OPENAI_COMPAT_CAPTURE_SSE` 或注入 mock fetch 捕获请求。

## 非默认扩展：/models discovery

Kimi Code `/models` 可以用于发现：

- authoritative wire model id
- display name
- context length
- image input capability
- video input capability
- reasoning capability

但对 Dominds 默认路线而言，它不是必要依赖。Kimi Code 官方已经把 `kimi-for-coding` 作为稳定入口，底层模型更新由后端映射完成。Dominds 面向长期自主运行，不应在运行中因为 discovery 结果变化而改变模型、上下文长度或能力表。

如果未来支持，应仅作为诊断/安装期能力：

```text
GET https://api.kimi.com/coding/v1/models
```

设计建议：

- Dominds UI/provider key 仍使用 `kimi-code/kimi-for-coding`。
- 默认请求仍发送 `model: kimi-for-coding`。
- discovery 结果只用于显示、诊断和人工确认。
- 不在长期运行中自动改写 wire model id。
- 不在长期运行中自动改写 context length、image/video 能力或 default thinking。
- 不因为 discovery 失败阻断普通 API Key 调用。
- 不在后台周期性轮询 discovery。
- 401 不在 API Key 路径自动刷新，只提示 API Key 无效。

可以考虑的命令形态：

```text
team_mgmt_probe_provider({ provider: "kimi-code" })
```

该工具可以临时请求 `/models` 并报告服务端能力，但不写入运行时状态。

## 非默认扩展：OAuth provider

OAuth 能让用户用 Kimi For Coding 订阅权益登录，但复杂度和保活风险显著高于 API Key。对 Dominds 的长期自主运行目标，OAuth 不应作为默认二期计划。

如果实现，应单独 provider id：

```text
kimi-code-oauth
```

不要与 API Key provider 共用 auth entry。

只有在以下条件之一满足时才考虑：

- Kimi 官方明确要求 Dominds 作为受支持工具必须走 OAuth。
- Kimi 官方提供 Dominds 专属 OAuth client / scope / 集成协议。
- 用户明确需要个人订阅 OAuth 登录，且接受长期运行中的重新授权风险。
- Dominds 增加了可靠的无人值守凭据恢复机制。

即便实现，也必须遵守：

- 独立 token store，不写入 `~/.kimi/credentials`。
- 不读取或复用 kimi-cli refresh token，避免 refresh-token chain 竞争。
- 支持 device flow。
- scope 使用 Kimi Code 官方要求的 scope。
- access token 过期前主动 refresh。
- 401 时 refresh 一次并重试一次。
- 并发 session 使用 provider-scoped refresh lock。
- `User-Agent` 仍使用 `Dominds/<version>`。
- refresh 失败必须显式停机/报警，不得无限重试消耗上下文或把任务拖入半活状态。

当前建议：把 OAuth 保持为官方合作后的可选插件方向，而不是主线功能。

## 申请 Kimi 官方认可工具的路径

### 当前公开渠道判断

截至本次调研，公开文档里没有看到专门的“第三方 coding agent 申请接入 / 提交工具到 supported list”的自助表单。

可用公开渠道主要有：

- Kimi Code FAQ 中的反馈邮箱：`support@moonshot.cn`
- Kimi Help Center 会员联系页：`https://www.kimi.com/help/membership/membership-contact`
- Moonshot AI company contact / business contact 页面：`https://www.moonshot.ai/about`
- Kimi Code 官方文档的 third-party tools 页面，可作为申请列入工具列表时的目标页面引用。

推荐路径：

1. 先发邮件到 `support@moonshot.cn`，标题明确写“Dominds 申请 Kimi Code 第三方编程工具支持/认可”。
2. 同时通过 Kimi Help Center 或 Moonshot AI business contact 提交合作/集成请求。
3. 在请求中明确 Dominds 不会伪装 `kimi-cli`、不会复用 kimi-cli token、会使用真实 UA。
4. 请求官方确认是否需要专属 User-Agent、专属 `X-Msh-Platform`、API Key allowlist、OAuth client，或提交到 supported tools 文档的流程。
5. 在获得官方确认前，Dominds 默认只走 API Key 静态 provider，不实现 OAuth 默认路径。

### 申请材料建议

申请时建议附上以下信息：

- 产品名称：Dominds
- 产品类型：长期自主运行的编程 agent / coding agent runtime
- 官网或仓库链接
- 预计用户群：个人开发者、团队内部研发、长期任务执行场景
- 计划接入方式：Kimi Code API Key + `https://api.kimi.com/coding/v1` + `kimi-for-coding`
- 客户端身份：`User-Agent: Dominds/<version>`
- 是否发送 Kimi CLI headers：否
- 是否复用 Kimi CLI OAuth token：否
- 是否默认 OAuth：否
- 是否运行中 `/models` discovery：否
- 是否支持 `prompt_cache_key`：是，使用 Dominds dialog/course 稳定 key
- 是否支持 thinking：是，显式 `thinking` / `reasoning_effort`
- 长期运行策略：静态 API Key、固定模型入口、失败显式报警，不做无人值守 OAuth refresh
- 合规承诺：不绕过订阅权益、不隐藏真实客户端、不共享用户凭据、不把 Kimi Code API Key 当普通开放平台 Key 滥用

可以附带技术摘要：

```text
Base URL: https://api.kimi.com/coding/v1
Endpoint: POST /chat/completions
Model: kimi-for-coding
Auth: Bearer KIMI_CODE_API_KEY
User-Agent: Dominds/<version>
Extensions: prompt_cache_key, thinking, reasoning_effort
No kimi-cli impersonation headers
```

### 希望官方确认的问题

需要向 Kimi 官方确认：

- Dominds 是否可以列入 Kimi Code supported coding agents / third-party tools 页面。
- Dominds 是否应使用 `User-Agent: Dominds/<version>`，或官方希望使用指定格式。
- 是否可以/应该发送真实平台标识，例如 `X-Msh-Platform: dominds`。
- Kimi Code API Key path 是否适合长期自主运行场景。
- OAuth 是否仅推荐给官方客户端，还是第三方工具也可以申请专属 OAuth client。
- `prompt_cache_key` 是否推荐第三方工具使用，key 的稳定性和长度是否有限制。
- `kimi-for-coding` 是否应始终作为 wire model id，还是需要调用 `/models` 获取账号级 slug。
- `temperature` 是否应省略，或是否有固定允许值。
- `tool_choice` / `parallel_tool_calls` 是否支持。
- 图片输入在 Kimi Code API Key path 上是否正式支持。

### 邮件模板草案

```text
Subject: Dominds 申请 Kimi Code 第三方编程工具支持/认可

Kimi Code 团队您好，

我们正在为 Dominds 接入 Kimi Code Coding Plan。Dominds 是一个面向长期自主运行的软件工程 agent runtime，希望通过官方认可、合规且可长期稳定运行的方式支持 Kimi Code。

计划接入方式：
- Base URL: https://api.kimi.com/coding/v1
- API: OpenAI-compatible Chat Completions
- Model: kimi-for-coding
- Auth: 用户自行配置 Kimi Code API Key
- User-Agent: Dominds/<version>
- Request extensions: prompt_cache_key, thinking, reasoning_effort

我们不会伪装 kimi-cli 或 OpenCode，不会复用 kimi-cli OAuth token，不会发送 kimi-cli 的 X-Msh-* 指纹 headers。Dominds 的默认路线也不会依赖 OAuth refresh 或运行中 /models discovery，以避免长期任务中的凭据和模型漂移。

想请确认：
1. Dominds 是否可以申请列入 Kimi Code supported coding agents / third-party tools 列表？
2. 是否有推荐的 User-Agent 或平台标识 header？
3. Kimi Code API Key path 是否适合 Dominds 这种长期自主运行工具？
4. 第三方工具是否推荐使用 prompt_cache_key？是否有 key 长度/格式限制？
5. kimi-for-coding 是否应作为稳定 wire model id，还是需要调用 /models 获取账号级 slug？
6. 是否需要申请专属 OAuth client 或 allowlist？

谢谢。
```

## 风险

### 客户端身份校验

Kimi Code 服务端可能基于 UA、headers、OAuth client、API Key 类型或路径做权益校验。

Dominds 应优先走官方文档允许的 API Key path，并保持真实 UA。不要通过模拟 kimi-cli headers 规避校验。

### prompt_cache_key 类型支持

`prompt_cache_key` 是 Kimi Code/Kimi CLI 侧扩展字段，不是标准 OpenAI Chat Completions 字段。其他 OpenAI-compatible provider 可能拒绝。

所以必须用 provider-specific 条件发送。

### 参数组合拒绝

Kimi Code 可能对 `temperature`、`reasoning_effort`、`thinking` 组合更严格。实现应优先 fail fast 或捕获 400 debug payload，而不是静默重试。

### OpenAI SDK headers

即使 Dominds 覆盖 `User-Agent`，OpenAI SDK 仍会发送 `X-Stainless-*` headers。通常这不是问题，但如果 Kimi Code 对未知 headers 敏感，需要实测确认。

### tool_choice

如果 Kimi Code 不支持 `tool_choice`，Dominds 需要通过 `supports_tool_choice: false` 禁止发送。首期应保守禁用，实测通过后再调整。

## 验证清单

本地单测：

- provider config parse 通过
- team.yaml `model_params.openai-compatible` 校验通过
- Kimi Code request payload snapshot
- Kimi Code headers snapshot
- Kimi Code prompt_cache_key snapshot
- Kimi Code rejected request debug capture redaction

集成冒烟：

```text
KIMI_CODE_API_KEY=... dominds ...
```

建议 prompts：

1. 无工具简单问答，验证 streaming text。
2. 需要读文件的任务，验证 tool call。
3. 需要多轮工具调用的任务，验证 tool call history。
4. 开启 thinking high，验证 `reasoning_content` 是否能进入 thinking stream。
5. 关闭 thinking，验证不发送 `reasoning_effort`。
6. 同一 dialog 多轮，验证 `prompt_cache_key` 稳定为同一 course key。
7. 图片输入任务，验证 `supports_image_input` 是否真实可用。

线上观测：

- 400 rejected payload
- 401 API Key 错误提示
- 429/rate limit 分类
- 5xx retry 行为
- usage token 统计
- empty response deadlock 是否需要复用 `same-context-empty-response`

## 首期最小改动摘要

最小可交付切片：

1. `defaults.yaml` 新增 `kimi-code` provider。
2. `openai-compatible.ts` 对 `apiQuirks: kimi-code` 设置真实 Dominds UA。
3. `openai-compatible.ts` 对 `apiQuirks: kimi-code` 发送 `prompt_cache_key`。
4. `openai-compatible.ts` 对 Kimi Code 做 reasoning/thinking 基础校验。
5. 增加 payload/header 单测。
6. 手动 API Key 冒烟。

这个切片不需要 OAuth、不需要 `/models` discovery，也不需要模拟 kimi-cli headers。
