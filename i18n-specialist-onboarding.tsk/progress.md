## Progress
- [owner:@ux] 创建并注册 `i18n` 团队成员（国际化专员），用于 Dominds 的文档/代码/资源 i18n 维护。

- [owner:@i18n] 已修复 Q4H 术语定义错误：
  - 标题从 "Q4H（每四小时对话）" 改为 "Q4H（Question for Human）"
  - 英文定义从 "A forced human check-in mechanism triggered every 4 hours" 改为 "A mechanism for raising questions to humans, initiated via `!?@human`"
  - 中文定义从 "持续对话每 4 小时触发一次强制人工介入机制" 改为 "一种通过 `!?@human` 向人类提问的机制"
- [owner:@i18n] 已将 "清空思路" 统一改为 "清理头脑"：
  - `dominds/docs/dominds-terminology.md` 标题："clear_mind（清空思路）" → "clear_mind（清理头脑）"
  - `dominds/main/tools/ctrl.ts` 中文描述："清空思路并开始新一轮" → "清理头脑并开始新一轮"
- [owner:@i18n] 已完成术语表文档多项修正：
  - **团队成员定义**：从"后者可包含人类用户"改为"后者用于谈论组织结构架设话题"
  - **Memory（记忆层）**：英文从 "Mind" 改为 "Memory"，定义相应调整
  - **Tellask 定义**："一个对对话参与方发出的结构化请求" → "一个对智能体发出的结构化请求"
  - **Fresh Boots Reasoning（扪心自问）**：中文从"赤足推理"改为"扪心自问"，允许使用 FBR 缩写
  - **会话键指令 → 会话 Slug**：所有 `<key>` 改为 `<slug>`，相关标题和说明同步更新
  - **删除 Teammate Tellask 章节**：因 tellask 语法仅用于队友诉请，该定义冗余已删除
- [owner:@i18n] 已完成 Keep-Going → Diligence Push 重命名：
  - `dominds/docs/dominds-terminology.md`：术语 "Keep-Going（鞭策）" → "Diligence Push（鞭策）"
  - `dominds/docs/keep-going.md`：文档标题与内容同步更新
- [owner:@i18n] 已完成 Fresh Boots Reasoning → 扪心自问 中文用户可见内容更新：
  - `dominds/docs/dialog-system.zh.md`：4 处更新（标题与正文中 "Fresh Boots Reasoning" → "扪心自问"）
  - `dominds/main/shared/i18n/driver-messages.ts`：中文消息 "Fresh Boots Reasoning 通常应使用" → "扪心自问 通常应使用"
  - `dominds/main/minds/system-prompt.ts`：中文描述 "Fresh Boots Reasoning（FBR）自诉请" → "扪心自问（FBR）自诉请"
- [owner:@i18n] 已完成 Memory（记忆层）→ Memory（分层记忆）术语更新：
  - `dominds/docs/dominds-terminology.md`：术语从 "Memory（记忆层）" 改为 "Memory（分层记忆）"
- [owner:@i18n] 已完成 Fresh Boots Reasoning → 扪心自问 英文保留、中文替换验证：
  - 验证英文内容保留 "Fresh Boots Reasoning"，中文内容统一为 "扪心自问"
- [owner:@i18n] **已修复 i18n 不一致问题**：
  - `dominds/main/shared/i18n/tool-result-messages.ts` 第31行：`已清理思路` → `已清理头脑`（与 `ctrl.ts` 中 "清理头脑并开始新一轮" 保持一致）
  - 第33行 `已更新思路` 保持不变（"更新思路" 是自然表达，无需强行改成 "头脑已更新"）
- [owner:@i18n] **已修复 webapp UI 翻译术语不一致问题**：
  - `dominds/webapp/src/i18n/ui.ts` 英文翻译更新：将所有 "keep-going" 替换为 "Diligence Push"（共16处修改），与术语表保持一致
  - 中文翻译保持 "鞭策" 不变
- [owner:@i18n] **已修复 docs-panel 组件术语不一致问题**：
  - `dominds/webapp/src/components/dominds-docs-panel.ts`：将 docs panel 中 "Keep-going" tab 的英文标题从 "Keep-going" 改为 "Diligence Push"
- [owner:@i18n] **已修复 main 代码注释中的术语不一致问题**：
  - `dominds/main/team.ts` 第120行：注释 "Keep-going: per-member cap..." → "Diligence Push: per-member cap..."
  - `dominds/main/dialog.ts` 第203行：注释 "Keep-going (diligence auto-continue) budget counter..." → "Diligence Push (diligence auto-continue) budget counter..."
  - `dominds/main/dialog.ts` 第207行：注释 "Keep-going disable switch..." → "Diligence Push disable switch..."
  - `dominds/main/llm/driver.ts` 第1964行：注释 "Keep-going (root dialog only)..." → "Diligence Push (root dialog only)..."
  - `dominds/main/llm/driver.ts` 第2359行：注释 "Keep-going (root dialog only)..." → "Diligence Push (root dialog only)..."
- [owner:@i18n] **已修复 README 链接文本术语不一致问题**：
  - `dominds/README.md` 第232行：`Keep-going` → `Diligence Push`
  - `dominds/README.zh.md` 第143行：`Keep-going` → `鞭策`
- [owner:@i18n] **已修复 driver.ts 注释和日志中的 keep-going 术语**：
  - 第143行：`// Existing empty file explicitly disables keep-going.` → `// Existing empty file explicitly disables Diligence Push.`
  - 第1946行：`// Q4H suspension resets keep-going budget...` → `// Q4H suspension resets Diligence Push budget...`
  - 第1951行：`log.warn('Failed to check Q4H state for keep-going reset'...` → `log.warn('Failed to check Q4H state for Diligence Push reset'...`
  - 第2344行：`// Q4H suspension resets keep-going budget...` → `// Q4H suspension resets Diligence Push budget...`
  - 第2349行：`log.warn('Failed to check Q4H state for keep-going reset'...` → `log.warn('Failed to check Q4H state for Diligence Push reset'...`
- [owner:@i18n] **已修复 storage.ts JSDoc 注释中的 keep-going 术语**：
  - 第121行：`Disable keep-going (diligence auto-continue) for this dialog.` → `Disable Diligence Push for this dialog.`
- [owner:@i18n] **已修复 api-routes.ts DOCS_WHITELIST 中的 keep-going 字符串字面量**：
  - 第415行：`'keep-going',` → `'diligence-push',`
  - 第427行：`'keep-going.md',` → `'diligence-push.md',`
- [owner:@i18n] **已修复 team-mgmt.ts 命令行帮助文本中的 keep-going 术语**：
  - 第2946行（中文）：`keep-going 上限` → `鞭策 上限`
  - 第2961行（英文）：`keep-going cap` → `Diligence Push cap`
- [owner:@i18n] **已完成 docs 目录文件重命名和 docs-panel 组件键值更新**：
  - `dominds/docs/keep-going.md` → `dominds/docs/diligence-push.md`
  - `dominds/docs/keep-going.zh.md` → `dominds/docs/diligence-push.zh.md`
  - `dominds/webapp/src/components/dominds-docs-panel.ts`：`key` 和 `docName` 从 'keep-going' 改为 'diligence-push'
- [owner:@i18n] **已修复 README 链接目标**：
  - `dominds/README.md` 第232行：`docs/keep-going.md` → `docs/diligence-push.md`
  - `dominds/README.zh.md` 第143行-going.md` → `docs/diligence-push.z：`docs/keeph.md`

### 已完成讨论的润色方案（第1-14组 + 专项目标）

| 组别 | 位置 | 原文 | 优化后 | 状态 |
|------|------|------|--------|------|
| **第1组** | ctrl.ts 第116行 | `"这是对话的第 #${nextRound} 轮，你刚清理了头脑，请继续执行任务。"` | `"你刚清理头脑，开启了第 ${nextRound} 程对话，请继续推进任务。"` | ✅ 已落实 |
| **第2组** | dialog-persistence.zh.md 第425行 | `"3. 如果开始新轮次则增加轮次计数器"` | `"对话进程计数 +1"` | ✅ 已落实 |
| **第4组** | dialog-system.zh.md 第673-674行 | `"系统生成的新程提示已排队并用作新程的**第一个 role=user 消息`**" / `"开始新的对话程"` | `"系统生成的新一程对话开启提示已排队，作为下一程对话的首个 role=user 消息"` / `"开启新一程对话"` | ✅ 已落实 |
| **第7组** | design.zh.md 第410-411行 | `"开始新程的函数工具"` / `"无对话程重置"` | `"开启新一程对话的函数工具（用于清除对话噪音）"` / `"不会开启新一程对话"` | ✅ 已落实 |
| **专项目标** | ctrl.ts clear_mind 工具提示词 | 无接续包定义 | 补充完整定义（4要素） | ✅ 已存在 |

### 无需修改的组别（已提前完成或无差异）

| 组别 | 位置 | 状态 |
|------|------|------|
| **第5组** | encapsulated-taskdoc.zh.md | ✅ 全部符合润色方案 |
| **第6组** | design.zh.md 第119行 | ✅ 已是"每程压缩丢失更多信息" |
| **第8组** | design.zh.md 第61行 | ✅ 已是"每个对话程添加新的约束..." |
| **第9组** | interruption-resumption.zh.md 第35行 | ✅ 已是"完成待处理的智能体对话进程" |
| **第10组** | README.zh.md 第101行 | ✅ 已是"对话分程"（关键润色已提前完成） |
| **第11组** | context-health.zh.md 第10行 | ✅ 已是"每次生成后计算并持久化" |
| **第12-13组** | context-health.zh.md | ✅ 倒计时相关"轮"保持不变，符合要求 |

### 验证结果

- ✅ **lint:types**: TypeScript 类型检查通过，无 TS errors/warnings

### 注意事项

- 磁盘存储格式（如 `round-001.jsonl`）保持不变
- 代码变量名（如 `startNewRound`）保持不变
- 英文文本中的 "round" 保持不变
- 只修改用户可见的中文提示和文档描述

### 下一步行动

1. ✅ 已完成：第1组（ctrl.ts）
2. ✅ 已完成：第2组（dialog-persistence.zh.md）
3. ✅ 已完成：第4组（dialog-system.zh.md）
4. ✅ 已完成：第7组（design.zh.md）
5. ✅ 无需修改：第5、6、8、9、10、11、12、13组
6. ✅ 已验证：lint:types 通过
7. ⏳ 待回归：与 @ux/@qa 确认验收清单