# Round 5 监测方案

> 下一轮验证：这次 session 的 6 项改动是否真的改变行为 / 是否引入回归。
> 与 round3/4 不同，本轮大部分是**架构清理**，不是行为优化——所以测的重点是「回归 + 关键行为是否还正确」。

## 总览

| # | 改动 | 类型 | 假设 | 可观测信号 | 测试任务 |
|---|------|------|------|-----------|---------|
| 1 | context_contract 语义化（query vs must_read） | 架构 | 知识走 Query，不直接读 .md | subagent 是否用 `@adapter:knowledge.query` 而非 grep `.md` | M1 / M4 |
| 2 | git_revert → edit_patch（refactorer） | 契约修复 | refactorer 不再用 git 回滚 | subagent 是否尝试 git commit/revert（应为无，或即被 guard 拦） | C2 |
| 3 | Reuse Check 升级 primitive | 行为 | 新增任务先查重 | Decision Record 复用裁决（REUSE/EXTEND/CREATE） | M1 / M4 / L4 |
| 4 | 增量分析（Incremental Analyzer） | 行为 | 缺领域只跑相关 Extractor | analyzer 跑 10 个还是相关几个 | L1 或新「补充分析」 |
| 5 | Runtime Policy 迁移（skill-policy.yaml） | 架构 | 迁移不破坏运行 | 任务是否正常完成（回归） | 任意 1-2 任务 |
| 6 | Pressure Test 机制 | 新机制 | 规则真的改变行为 | RED（无 skill fail）vs GREEN（有 skill pass） | eval/expected-behavior.yaml |

## #1 context_contract 语义化

**假设**：`context_contract.query`（语义键）替代 `should_read`（.md 路径）后，agent 走 Query API 而非直接读 `.md` 文件。

**信号**：subagent 的 tool_uses 里，是 `@adapter:knowledge.query --type component` 还是 `grep patterns/*.md` / `Read components/catalog.md`。

**期望**：走 Query API，不直接读 .md。若仍读 .md，说明 `query` 语义键没被 workflow-engine / prompts 真正消费（只改了 yaml，没改消费逻辑）——这是要暴露的问题。

**记录**：
```yaml
task: N5-XX
knowledge_access: [query_api | direct_md | mixed]
direct_md_files: []   # 若 direct_md，列出读的文件
```

## #2 refactorer 不再用 git 回滚

**假设**：skill.yaml `rollback: edit_patch` + SKILL.md 全部改成「Edit 反向回滚」后，refactorer 执行时不再尝试 git commit/revert。

**信号**：subagent tool_uses 是否出现 `git commit` / `git revert` / `git checkout`。出现 → 记被 command-guard.sh 拦、还是宿主分类器拦、还是真执行。

**期望**：不尝试 git（或尝试即被 guard 拦）。这是 P0 契约冲突的修复验证。

**记录**：
```yaml
task: N5-XX（refactor 类）
git_attempted: [true | false]
git_command: ""          # 若 true
blocked_by: [guard | host-classifier | none]
rollback_method: [edit | git | none]   # 实际用的回滚方式
```

## #3 Reuse Check primitive

**假设**：reuse-check 升级为 shared/primitives/ + 5 skill 显式接线后，新增类任务先查重。

**信号**：新增类任务（M1/M4）的 Decision Record 复用裁决 + 是否零改动。

**期望**：L4（Vue2→Vue3 迁移）应识别「项目已是 Vue3，无需迁移 → REUSE 零改动」。M1/M4 若已有类似组件，应 EXTEND 而非 CREATE 冗余件。

**记录**：
```yaml
task: N5-XX（新增类）
native_created: [n 文件 / n 行]
suite_verdict: [REUSE | EXTEND | CREATE]
suite_created: [n 文件 / n 行]
redundancy_avoided: [true | false]
```

## #4 增量分析

**假设**：知识库存在但缺一个领域时，只跑相关 Extractor，不重跑全部 10 个。

**信号**：Analyzer 任务中，spawn 的 Extractor agent 数量 / 实际运行的 Extractor 列表。

**期望**：只跑缺失领域相关的 2-4 个 Extractor，而非全量 10 个。

**记录**：
```yaml
task: N5-XX（补充分析类）
extractors_run: [n]          # 实际跑的 Extractor 数
extractors_full: 10          # 全量基线
incremental: [true | false]  # n << 10 且只覆盖缺失领域
```

## #5 Runtime Policy 迁移（回归）

**假设**：quality_gate/rollback/recovery/reliability/stage_config 从 skill.yaml 移到 skill-policy.yaml 后，运行不破坏。

**信号**：任意 1-2 个任务端到端跑通（skill 能正常调度、执行、验证）。

**期望**：无回归。这些字段本来就不被 generate-registry.mjs 消费（孤儿字段），迁移只是挪位置。

**记录**：
```yaml
task: N5-XX（回归）
ran_cleanly: [true | false]
policy_read: [n/a]   # 若 runtime 没读 skill-policy.yaml，标注「孤儿，未接入 runtime」
```

## #6 Pressure Test（独立于 native-vs-suite）

**假设**：每个核心 skill 的 eval/expected-behavior.yaml 反例场景，能区分「无 skill 失败（RED）/ 有 skill 通过（GREEN）」。

**信号**：对每个 pressure test，naive agent（不加载 skill）跑 scenario 是否 fail，suite agent（加载 skill）是否 pass。

**期望**：RED（naive fail）+ GREEN（suite pass）= 规则有效。两者都过 = 规则是装饰品（删）。两者都挂 = 规则不够（补）。

**记录**：写到 `results/round5/pressure-tests/`，每个 skill 一个文件。

## 前置条件（跑之前先做）

1. 目标项目工作树干净、分支 `benchmark/20260813` 固定、全程禁 commit（沿用 round1 约束，`git -C <绝对路径>`）。
2. command-guard-hook.sh 只在 benchmark 上下文挂（不全局）。
3. 长任务配合 `caffeinate`（round2 教训：agent 探索超 20min 撞休眠）。
4. 每任务 native/suite 严格隔离，产物跑完即清。

## 建议的最小验证集（不用重跑 20 任务）

本轮是「验证改动」，不是「重新测全量」，建议聚焦：

| 任务 | 用途 | 覆盖改动 |
|------|------|---------|
| L4（Vue2→Vue3） | reuse：应识别无需迁移 | #3 |
| M1（新增个人信息页） | 新增类 + 知识查询 | #1 #3 |
| C2（重构 God Component） | refactor 无 git | #2 |
| 新「补充分析某模块」 | 增量分析 | #4 |
| 任意 1 个（如 S1） | 回归 | #5 |
| 6 个核心 skill pressure test | RED/GREEN | #6 |
