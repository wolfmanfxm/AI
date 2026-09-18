# Skill Atlas

> **本页是人类导航页，不是契约。** 权威定义在 `skills/*/skill.yaml`；机器可读视图由
> `shared/scripts/generate-registry.mjs` 生成为 `runtime/registry/skills.generated.yaml`
> 与 `capability-routing.yaml`。
>
> ⚠️ **本页不复制** stages / produces / consumes / dependencies / templates —— 旧版此页重复了这些字段，
> 结果与 skill.yaml 漂移（漏掉 analyzer/generator 的 `Recommendation`、documenter 的 `Context`，
> 且质量门计数停在 G12 而实际已有 G18）。要查 I/O 与依赖，看 skill.yaml 或生成的 registry。

## Atlas

后三列是 `skill.yaml` 的 `description` / `boundary` 的人类摘要；**如有出入以 skill.yaml 为准**。

| # | Skill | 职责 | 适用场景 | 边界 |
|---|-------|------|---------|------|
| 1 | [analyzer](../skills/project-analyzer/SKILL.md) | 分析项目结构、组件、API、模式，生成结构化知识库 | 首次接入项目；知识库过期需刷新；只想了解现状、不改代码 | 只分析并生成知识文件，不修改源码 |
| 2 | [planner](../skills/project-planner/SKILL.md) | 需求收敛 → 完整性检查 → 自适应访谈 → 9 模块执行契约 | 需求模糊需先拆解；任务较大，想先出计划再动手 | 只做计划不写代码，发现问题记录在风险矩阵 |
| 3 | [architect](../skills/project-architect/SKILL.md) | 技术选型 + 模块设计 + API 契约，ADR 格式决策记录 | 需要选型对比；模块/接口边界设计；架构评审 | 只做设计不写代码，不符记录在 ARCHITECTURE.md |
| 4 | [generator](../skills/project-generator/SKILL.md) | 按项目规范生成生产级代码，Execute → Verify | 实现功能；新增页面/组件/API；修改既有代码 | 只写代码不做设计，缺上游产物时提示先跑 planner/architect |
| 5 | [tester](../skills/project-tester/SKILL.md) | AC 驱动测试生成 + 执行，自动检测测试框架 | 补测试；验证实现是否满足验收标准 | 只写测试不修被测代码，失败记录报告 |
| 6 | [reviewer](../skills/project-reviewer/SKILL.md) | 五轴审查，BLOCKER → PRAISE 分级 | 合并前审查；怀疑有 bug / 安全问题 | 只审查不修代码，问题带 file:line + 修复方案 |
| 7 | [refactorer](../skills/project-refactorer/SKILL.md) | 安全重构，行为不变，指标量化 | 结构难维护需重构；消除重复；迁移 | 只改善结构不改行为，没测试保护不重构 |
| 8 | [documenter](../skills/project-documenter/SKILL.md) | 代码 → 可溯源技术文档，自动匹配风格 | 补 API/组件文档；生成或更新 README | 只生成文档不改代码 |
| 9 | [releaser](../skills/project-releaser/SKILL.md) | 版本 bump + Changelog + 发布检查 | 准备发版；写 Changelog；发布前检查 | 只检查与推荐，不执行发布命令（不 npm publish / git push --tags） |
| 10 | [orchestrator](../skills/pipeline-orchestrator/SKILL.md) | 跨 Skill Pipeline 编排（协议 + 决策边界，非执行引擎） | 想端到端跑一遍；不确定该按什么顺序调 skill | 只出编排建议（供 Host 参考），不替代任何单个 Skill |

## I/O 与依赖

见 `skills/<name>/skill.yaml` 的 `produces` / `consumes` / `interface`，或生成的：

| 想看什么 | 看哪 |
|---|---|
| stages / 失败模式 / interface | `runtime/registry/skills.generated.yaml` |
| 能力依赖图（`needs` / `needs_advisory`） | `runtime/registry/capability-routing.yaml` 的 `dependency_graph` |
| 产物类型（数据流视角） | `runtime/artifacts/artifact-types.yaml` |
| 调度顺序 / 策略 | `runtime/config/scheduler.yaml` / `skill-policy.yaml` |

## 质量门与治理就绪

> 门定义与 pass/fail **以脚本为准**——本页不复制度量数值（旧版把 G1–G12 抄在这里，实际已有 G18）。

| 检查 | 入口 |
|------|------|
| 结构门 G1–G18 | `shared/scripts/check-conformance.sh` |
| 声明链一致性（skill.yaml ↔ skill-ir ↔ registry ↔ compatibility） | `shared/scripts/check-consistency.sh` |
| 知识链闭环（compiler → index → resolver → package） | `shared/scripts/check-knowledge-pipeline.sh` |
| YAML 可解析 | `shared/scripts/check-yaml.sh` |
| 产物写入路径 / 契约 | `shared/scripts/check-artifacts.sh` |
| E2E 主链 wiring | `shared/scripts/check-e2e-smoke.sh` |

| Requirement | Status |
|-------------|--------|
| owner | ✅ `project-suite` |
| review cadence | ✅ 90-day，`last_reviewed` 已写入 10/10 `skill.yaml` |
| input_files (file-backed fixture) | ✅ 10/10 skills `interface.inputs[].fixture` |
| output contract | ✅ `skill.yaml` `interface.outputs` |
| rollback boundary | ✅ `skill-policy.yaml` rollback（10/10） |
| trust report | ✅ 见 [eval-contract.md](eval-contract.md)——报告在外部 eval 仓库，不在 suite 内 |
| output_quality_scorecard | ✅ [../reports/output-quality-scorecard.md](../reports/output-quality-scorecard.md) |
| telemetry | ✅ `shared/scripts/collect-metrics.sh`（local aggregation） |
| cross-run reliability | ✅ [cross-run-reliability.md](cross-run-reliability.md) + `check-reliability.sh` + 10/10 `skill-policy.yaml` reliability |
| drift detection | ⚠️ `missing evidence` |

## Skill 准入（这张表何时该变长）

> 本文档的 Atlas 表**默认不变**。新增一行 = 新建一个 skill，是 ADR 级别的作者决策，不是每次分析都要走的流程。
> 完整判据与成本见 [ADR-005](decisions/ADR-005-skill-admission.md)。

准入五问，**全部为「是」**才考虑新建（任一为「否」→ 留在知识层）：

| # | 判据 | 为「否」时 |
|---|------|-----------|
| A1 | 有用户会用一句话直接要求它，且不落进任何现有 capability 的 intent 集 | 扩展现有 skill |
| A2 | 有明确的「不做」，且与现有 `boundary.md` 不重叠 | 合并而非新建 |
| A3 | 存在独立的输入/输出边界，且有独立消费场景（下游 Skill **或用户直接消费**） | 加一个 stage/prompt |
| A4 | 有稳定、可识别的独立用户意图，值得拥有独立可发现入口（判**入口价值**，不判调用频率） | 并入现有 intent 集 |
| A5 | 能被独立验证（有可判定的 assertion） | 留在知识层——无法验证的能力进不了压力测试 |

> A3 / A4 的措辞是刻意这么写的：按「必须有下游 skill 消费」会否决现役的 releaser/refactorer
> （实测它们的产物在 `needs` 里无下游消费者）；按「必须高频」则会否决 releaser/refactorer/documenter，
> 且在 skill 存在前无法测量。详见 [ADR-005](decisions/ADR-005-skill-admission.md)。

**成本**：新增一行要同步 `skill.yaml` / `skill-ir.yaml` / `compatibility.yaml` / `scheduler.yaml` /
`skill-policy.yaml` + 重新生成 registry，并由 [check-consistency.sh](../shared/scripts/check-consistency.sh)
L3 / L3.5 硬校验（非警告）。
