# Benchmark Metrics v1.0

> 8 个指标，对比 native Claude Code（baseline）vs project-suite。

## 指标定义

| # | 指标 | 含义 | 怎么测 |
|---|------|------|--------|
| 1 | **Planning Accuracy** | 计划与最终实现的吻合度 | 对比 PLAN.md 的 Task 与实际提交的 commit |
| 2 | **Requirement Coverage** | 需求覆盖完整度 | 需求点中实现了几个 / 总需求点 |
| 3 | **Context Tokens** | 消耗的 context token | 记录每个 Skill 的 context 大小 |
| 4 | **Interview Questions** | 问用户的问题数 | 记录 Interview 提出的问题数 |
| 5 | **Human Interventions** | 需要人工介入的次数 | CHECKPOINT 次数 + 用户修正次数 |
| 6 | **Task Success** | 任务是否成功完成 | 最终结果是否满足需求 |
| 7 | **Review Defects** | Reviewer 发现的问题数 | REVIEW.md 的 BLOCKER/HIGH 计数 |
| 8 | **Knowledge Reuse** | 知识复用率 | 生成时复用了多少已有组件/API（vs 重新造） |

## Requirement Coverage Rubric（统一评分标准）

> 指标 #2 的口径统一。v1.0 的 20 个任务用 agent 自报值（native 常报 0 即使任务完成、suite 在 0~1 波动），不可靠。
> 本 rubric 定义客观评分，未来重跑由事后 reviewer 逐点核对，不依赖 agent 自报。

### 评分公式

```
requirement_coverage = 满足的显式需求点 / 总显式需求点
```

需求点 = 从 task prompt **显式**提取的可验证要求（字段/功能/步骤），不包含 agent 自认为的隐含需求。

### 评分步骤

1. 从 task prompt 拆出显式需求点列表。
2. reviewer 逐点核对实际产物是否满足。
3. coverage = 满足数 / 总数。

### 示例（M1 "新增个人信息登记页面，字段：姓名/手机/邮箱"）

需求点：① 有独立页面 ② 姓名字段 ③ 手机字段 ④ 邮箱字段
- 4 点全满足 → coverage = 1.0
- 缺邮箱字段 → coverage = 0.75

### 边界规则

- **不看 agent 自报，只看实际产物**：coverage 由 reviewer 核对产物，不采信 agent 声明的数字。
- **"需求已存在"算满足**：如 M2 的搜索+分页已由标准组件实现，agent 正确识别"无需新增" → 满足（而非 native 自报的 0）。
- **domain 命名漂移扣分**：如 M1 用 personInfo 而非 customerIndividual，功能满足但命名漂移 → 该需求点按 0.5 计。

## 对比方法

每个任务跑两遍：

```
native（baseline）:   不带任何 skill，直接用 Claude Code 完成任务
project-suite:        带对应 profile（minimal/standard/full）完成任务
```

## 结果记录

每个任务产生一条记录：

```yaml
task: M1
category: medium
native:
  planning_accuracy: null    # native 无 PLAN，不适用
  requirement_coverage: 0.8
  context_tokens: 8500
  interview_questions: 0
  human_interventions: 1
  task_success: true
  review_defects: 3          # 事后用 reviewer 审查发现的缺陷
  knowledge_reuse: 0.2       # 凭记忆，复用率低
project_suite:
  planning_accuracy: 0.9
  requirement_coverage: 0.95
  context_tokens: 6200       # Context Resolver 只注入相关，更省
  interview_questions: 2
  human_interventions: 2     # CHECKPOINT ×2
  task_success: true
  review_defects: 1
  knowledge_reuse: 0.85      # Query API 复用已有组件
```

## 汇总

`benchmark/compare.sh` 汇总所有任务，输出对比表：

| 指标 | native 平均 | suite 平均 | Δ |
|------|------------|-----------|-----|
| Requirement Coverage | 0.75 | 0.92 | +0.17 |
| Context Tokens | 9000 | 6500 | -2500 |
| Review Defects | 2.5 | 0.8 | -1.7 |
| Knowledge Reuse | 0.2 | 0.8 | +0.6 |
| ... | | | |

## 目标

证明 Knowledge-driven Runtime 有实际收益：**更高的需求覆盖 + 更少的缺陷 + 更高的复用率**，代价是"多几个 CHECKPOINT + 多几个 Interview 问题"（这是可接受的 trade-off）。
