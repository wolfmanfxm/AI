# Trust Report

> yao-meta-skill Governed Package 要求 · project-dissection v1.1.1
> 评估日期: 2026-07-27 · 评估框架: yao-meta-skill Production mode

## 保证 (Guarantees)

| # | 保证项 | 证据 |
|---|--------|------|
| 1 | 不修改任何业务源码 | anti-patterns.md #1 明确禁止，SKILL.md description 声明「仅写知识文件」 |
| 2 | 产出格式稳定 | output-format.md 定义 Evidence Header schema，schema/ 目录 4 个 JSON Schema |
| 3 | 中断可恢复 | runtime-protocol.md manifest 状态机：confirmed→in_progress→partial/interrupted→completed |
| 4 | 增量不破坏人工内容 | capability-matrix.md 明确 4 个人工维护目录永不覆盖 |
| 5 | 触发准确率 100% | trigger_eval.py 10/10 通过，precision=100% recall=100% |
| 6 | 并行执行不阻塞 | agents/interface.yaml 定义 failure_isolation: true，单 agent 失败不影响其他 |
| 7 | Vault 同步不丢数据 | phase-2-finish.md 步骤 6a：本地权威源→单向同步，保留 Vault 独有文件 |

## 不保证 (Non-Guarantees)

| # | 不保证项 | 原因 |
|---|---------|------|
| 1 | 100% 准确的组件引用计数 | 依赖 grep，PascalCase/kebab-case 变体可能漏计 |
| 2 | 所有边缘情况的编码规范 | 基于抽样分析，小概率遗漏非主流写法 |
| 3 | 实时反映最新代码 | 分析是快照，代码变更后需重新运行 |
| 4 | 跨语言项目的完整分析 | 当前 prompts 针对 JS/TS 生态（Vue/React），其他语言需适配 |
| 5 | Agent 执行时间严格可控 | 受项目规模、网络、token 限制影响 |

## 已知限制 (Known Limitations)

| # | 限制 | 影响 | 缓解措施 |
|---|------|------|---------|
| 1 | 大项目 (>800 源文件) 需增量模式 | 全量扫描可能超时 | runtime-protocol 自适应策略：>800 自动采用增量 |
| 2 | observations 重复代码检测 >1000 文件跳过 | 超大型项目缺失此项 | 标注 ⚠️ 已跳过 |
| 3 | change-analysis 依赖上轮数据 | 首轮无法对比 | Evidence 三级 fallback：本地→Vault→标记首轮 |
| 4 | Agent 仅 dry_run 验证 | 产出质量未经真实 agent 测试 | trigger_eval 验证触发准确性，结构评分 90%+ |
| 5 | 依赖 git 获取 commit hash | 非 git 项目 manifest 该字段为空 | 标注 N/A |

## 可靠性证据 (Reliability Evidence)

### 触发准确性
- trigger_eval.py: 51 触发词 + 6 排除规则
- test-prompts.json: 10 用例，覆盖 analysis/development/resume/not-trigger/vault/deep/missing-knowledge
- 结果: 10/10 PASS, Precision 100%, Recall 100%, F1 100%

### 结构完整性
- 引用完整性: 13 项 SKILL.md References 全部可达（已验证）
- Schema 覆盖: 4 个 JSON Schema（graph/analysis-config/statistics/manifest）
- 协议覆盖: 7 protocol 文件覆盖完整生命周期

### 架构一致性
- Router→Contracts→Prompts→References 四层无循环依赖
- config/manifest 分离：用户配置只写一次，执行状态持续更新
- 8 维度 prompts 统一 Goal/Context/Evidence/Analysis/Output 格式

## 缺失证据 (Missing Evidence)

| # | 缺失项 | yao-meta-skill 要求 | 状态 |
|---|--------|-------------------|------|
| 1 | 真实 agent 执行测试 | dim8 full_test | ⚠️ dry_run only |
| 2 | 跨项目回归测试 | 多项目验证产出质量 | ⚠️ 未执行 |
| 3 | Token 消耗基准 | 各模式实际 token 消耗数据 | ⚠️ 未测量 |
| 4 | 用户满意度指标 | 实际使用反馈 | ⚠️ 未采集 |

