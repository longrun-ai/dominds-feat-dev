# 域：QA / Regression Gate

## 覆盖范围（路径）

- `dominds/tests/**`（脚本式 QA）
- `pnpm -C dominds run lint`、format/typecheck 等质量门槛（以现状为准）

## 职责

- 维护“发布前回归清单”（人工执行场景）
- 将各域提供的回归点转成可执行脚本/命令与失败判定
- 发现高频问题后推动补最小自动化测试/脚本（仍属于测试脚本层面，不做自动发布流水线）

## 交付物

- `team/process/release-regression-checklist.md` 的维护与迭代
- 最小冒烟/回归脚本集合的运行说明
- 每次发布前的结果记录规范（人工填写即可）
