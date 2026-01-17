- This is an infrastructure test. Prefer deterministic inputs and explicit checks.
- Prefer the `mock` provider to avoid reliance on external LLM APIs/credentials.
- Keep workspace mutations under `.minds/**` only, and clean up `.minds/team.yaml` + `.minds/llm.yaml` at the end.
- Avoid depending on “LLM smartness”; only validate protocol/state/UX behavior.

