# Backend：LLM 配置与 defaults（@fullstack）

- 默认 providers 配置：`dominds/main/llm/defaults.yaml`
- 工作区覆盖：`.minds/llm.yaml`（由 `dominds/main/llm/client.ts#LlmConfig.load()` 读取并与 defaults 合并）
- ProviderConfig 类型与 model params：`dominds/main/llm/client.ts`（`ProviderConfig`/`ModelParamOption`/`model_param_options`）
