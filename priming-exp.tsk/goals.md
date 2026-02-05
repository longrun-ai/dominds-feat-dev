# Goals

- [owner:@ux] 明确本次 priming 实验的假设与目标（要改善的具体体验/失败模式）。
- [owner:@ux] 设计实验矩阵：`baseline` vs `variant(s)`（每个 variant 只改一个变量）。
- [owner:@ux] 定义可验收的指标与记录方式（例如：任务完成率/工具调用错误率/阻塞率/单轮对话平均步数/主观可用性反馈）。
- [owner:@prompt] 给出 priming 文案/系统提示词改动提案（含回滚方案与最小回归点）。
- [owner:@browser_tester] 在 WebUI 走关键旅程回归（启动→对话运行→失败恢复→完成），对比 baseline/variant 的可复现差异。