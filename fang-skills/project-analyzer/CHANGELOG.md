# Changelog

本文件记录 project-analyzer skill 的所有版本变更。格式遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)。

## [1.2.0] — 2026-07-27 · 评分 92.2

### Added
- `agents/interface.yaml` — 8 agent 类型定义（权限/超时/输入输出契约/失败模式/并行策略）
- `reports/trust-report.md` — yao-meta-skill Governed Package 信任报告（7保证+5不保证+5限制+4缺失证据）
- `SKILL.md` frontmatter 补充 Governed 声明：mode/owner/review/input_files/output_contract/rollback_boundary
- `SKILL.md` References 补全：agents/、test-prompts.json、trigger_eval.py、trust-report.md、CHANGELOG.md

### Changed
- 产出质量评分更新至 92.2（结构 92 + 触发 95 + 产出 92 + 容错 92 + 可维护 88）

## [1.1.1] — 2026-07-27 · 评分 92.2

### Changed
- `prompts/patterns.md`：Analysis 从模式名列表升级为 4 步具体操作（抽样→统计→交叉验证→提取模板）
- `protocol/phase-2-execution.md`：CHECKPOINT 增加「预执行清单」模板（项目/模式/范围/预计产出/耗时）
- `prompts/change-analysis.md`：Evidence 从硬编码 Vault 改为本地优先→Vault 其次→均无则标记首轮
- `protocol/phase-2-finish.md`：新增步骤 7「产出验证」（Evidence Header / file:line / schema / 链接可达性）
- `protocol/runtime-protocol.md`：项目规模阈值明确定义（小型<200 / 中型200-800 / 大型>800 源文件）
- `prompts/observations.md`：重复代码检测「大项目」阈值明确为 >1000 源文件
- `references/capability-matrix.md`：修复 Prompt Capability Matrix 重复表头行

### Reverted
- `SKILL.md`：回退 darwin-skill 优化中塞入的冗余内容（故障恢复表/操作红线/展开步骤），恢复 50 行纯路由器设计。这些内容在 protocol/references 已有权威版本，SKILL.md 内联造成维护双写风险。

## [1.1.0] — 2026-07-27 · 评分 ~87

### Added
- `trigger_eval.py` — 触发词准确率批量验证脚本，支持详细/CI 两种输出模式
- `protocol/knowledge-protocol.md` — 知识版本控制、固定产出字段定义、生命周期引用
- `protocol/knowledge-lifecycle.md` — 文档生命周期状态机（draft → confirmed → deprecated → archived）

### Changed
- `SKILL.md` frontmatter description：`7 个维度` → `8 个维度（标准模式 7 个 + 详尽模式 +1）`，追加 `不做` 能力边界
- `references/trigger-words.md`：歧义词标注上下文条件，新增 6 类排除场景防误触发
- `test-prompts.json`：3 → 10 个用例，覆盖 resume/refresh/vault/deep-mode/not-trigger/missing-knowledge
- `templates/metadata/analysis-config.json`：扁平化字段结构对齐 Phase 1 规范，补全 `schemaVersion`、`createdAt`
- `protocol/phase-2-finish.md`：统一编号列表风格，消除 `###` 标题/`>` 块引用/表格混合格式

### Fixed
- 修复 `capability-matrix.md` 引用 `protocol/knowledge-protocol.md` 不存在的断裂引用
- 修复 `prompts/output-format.md` 引用 `protocol/knowledge-lifecycle.md` 不存在的断裂引用

## [1.0.0] — 2026-07-25 · 评分 ~88

### Added
- 初始发布版本：完整的 Phase 1 发现 + Phase 2 执行/收尾 + Development Flow 三阶段协议
- 8 维度并行分析架构（architecture/components/coding-style/ui-pattern/api-pattern/patterns/observations/change-analysis）
- manifest 状态机：confirmed → in_progress → completed，含中断恢复（interrupted/partial）
- Knowledge Vault 单向同步策略（本地权威源 → Vault）
- 覆盖策略：自动覆盖（机器生成）vs 永不覆盖（人工维护目录）
- 反例清单（7 通用 + 7 操作黑名单）
- 异常处理表（6 类异常 + 一线修复 + 兜底）
- 并行执行策略（Wave 0 → Wave 1 → Wave 2 → Wave 3）
- Evidence Header 强制规范（sources + confidence + lifecycle）
- 固定产出：manifest.json / statistics.json / graph.json / search-index.json / index.md
- Analysis Config 交互式确认流程（项目名/深度/范围/输出位置）
- Development Flow 开发前检查模式
- Schema 定义：graph / analysis-config / statistics / manifest

---

## 当前评分（v1.2.0）

yao-meta-skill Production 模式五维评估：

| 维度 | 得分 | 权重 | 加权 |
|------|------|------|------|
| 结构完整性 | 92 | 25% | 23.0 |
| 触发精度 | 95 | 20% | 19.0 |
| 产出质量 | 92 | 25% | 23.0 |
| 容错恢复 | 92 | 20% | 18.4 |
| 可维护性 | 88 | 10% | 8.8 |
| **总分** | | | **92.2** |

> 缺失证据：真实 agent 执行测试、跨项目回归、token 消耗基准、用户满意度指标。详见 [reports/trust-report.md](reports/trust-report.md)。
> Governed Package 评分卡：[reports/output_quality_scorecard.md](reports/output_quality_scorecard.md)。

---

## 版本号规则

- **主版本号**（X.0.0）：破坏性变更（schemaVersion 递增，产出格式不兼容）
- **次版本号**（0.X.0）：新功能、新维度、新协议文件
- **修订号**（0.0.X）：bug 修复、文档修正、格式统一

`schemaVersion` 主版本号变化 → 需全量重新分析。
`knowledgeVersion` 仅在全量刷新时递增。
