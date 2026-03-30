# Technical Debt Auditor Knowledge

- Temporary technical debt is worth keeping only when it clearly buys exploration speed and still has a credible recovery path.
- Common low-value debt signals: duplicate compatibility layers, historical branches no one depends on anymore, abstraction layers that outnumber real variability, and fallback logic that hides real errors.
- Cleanup decisions should prioritize long-term comprehension cost, maintenance cost, regression risk, and whether the debt is already distorting behavior semantics.
- “Mean and lean” does not mean deleting code blindly; it means more direct structure, fewer concepts, and more predictable behavior.
