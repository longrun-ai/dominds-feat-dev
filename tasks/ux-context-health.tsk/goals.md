Validate Dominds “context health monitor” end-to-end:

- After every LLM generation, Dominds records token usage stats (or reports “unavailable”).
- WebUI shows a small, always-visible context health indicator:
  - prompt tokens (or “unknown”),
  - percent of model context limit, and
  - percent of effective optimal max tokens.
- When prompt tokens exceed 50% of the model limit (or exceed the configured optimal ceiling),
  Dominds emits a single “clear your mind” reminder via the `context_health` ReminderOwner.
- The reminder automatically clears once a subsequent generation’s prompt tokens are below
  `effectiveOptimalMaxTokens`.

