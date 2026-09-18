# Round 11 监测方案

> 验证 2026-09-17 一批改动（YAML 修复 + 声明收口 + compiler change-detection + 触发词收紧）的真实效果。
> 本轮性质：**suite-only 轻量回归 + 路由行为验证**（不跑 native 对比）。
> 相比 round8/9 多一项：R1–R7 的**跨 skill 路由落点**观测——这是台账里唯一 `untested` 的条目。

## 本轮改动清单

| # | 改动 | 类型 | 验证点 |
|---|------|------|--------|
| 1 | knowledge-compiler change-detection：摘要 = 编译器身份 + 每源 `<路径, 内容摘要>` 折叠；`.hash` 只存最终摘要 | 行为（脚本） | 真实项目里重命名是否触发重扫、index 的 source 是否跟随、产物是否都在 `.project-knowledge/` 内 |
| 2 | verifier V2：REUSE 裁决必须附 `命中` + `依据`；明确「REUSE 且证据成立 → **零改动**是合法产出」 | 行为 | generator 的 REUSE 裁决是否带证据；需求已覆盖时是否零改动而非造近重复件 |
| 3 | pipeline-orchestrator `consumes`：8 个能力 → `[]` | 声明（DAG） | agent 读 `dependency_graph` 是否理解它在 pipeline **前**运行；是否被 `needs` 误导 |
| 4 | generator 删裸触发词 `开发`（skill.yaml + SKILL.md）+ trigger-eval EN 改词边界 + 严重度分层 | 声明（路由） | R1–R7 路由落点 |
| 5 | artifact-types 补 `recommendation` 类型 + mapping | 声明 | 静态（check-io-connectivity ✅） |
| 6 | 3 个不可解析 YAML 修复 + 新增 check-yaml 门禁（接为 check-consistency L0） | 静态 | 静态（check-yaml 44/44 ✅） |
| 7 | skill-atlas 收缩为导航页（不再复制 I/O/stages/dependencies） | 声明 | 静态 |

> #5/#6/#7 为纯静态改动，已由 check 脚本验证，本轮不单独跑 agent（与 round9 对 #3 的处理一致）。

## 最小验证集

| 任务 | 用途 | 关键信号 | 执行方式 |
|------|------|---------|---------|
| **K1** | #1 compiler change-detection（真实项目） | 重命名 knowledge 源后重跑：`.hash` 变化 → 重扫；index 的 `source` 跟随新路径、旧路径消失；两个产物都在 `.project-knowledge/` 内 | bash 直跑（脚本行为，直接跑脚本才是忠实验证） |
| **G1** | #2 REUSE 证据 + 零改动 | `decision_record` 含复用裁决 + `命中` + `依据`（不是只写 REUSE）；需求已覆盖时文件变更为 0 或仅 import；无近重复组件 | suite agent |
| **O1** | #3 orchestrator 依赖图可读性 | agent 从 `dependency_graph` + `skill.yaml` 读出的运行时机是「pipeline 前」；不产出现「等 8 个上游能力都产出后才能跑」类结论 | agent（只读） |
| **R1–R7** | #4 路由落点 | 每个 prompt 的 top-1 skill 是否 = 预期；同时记 top-2 观察歧义 | 7 个独立 agent |

### 路由测试集

| # | 用户措辞 | 预期 top-1 | 本轮关注 |
|---|---------|-----------|---------|
| R1 | 分析这个项目并告诉我哪里应该修改 | project-analyzer | 「修改」是否把 generator 拉走 |
| R2 | 帮我判断这个模块应该怎么设计 | project-architect | 是否落到 generator/analyzer |
| R3 | 帮我拆解需求和任务 | project-planner | 是否落到 generator |
| R4 | 帮我检查这段实现有没有问题 | project-reviewer | 是否落到 analyzer |
| R5 | 帮我做个开发计划 | project-planner | **本轮的 改动的直接验证**：删裸 `开发` 后是否还落 generator |
| R6 | 从分析到发布帮我跑一遍 | pipeline-orchestrator | **该 skill 未被装载**——观测实际落点（可能是路由缺口） |
| R7 | 更新一下 changelog | project-releaser | EN 词边界修正：`change` 不应再吸引 generator |

## 前置约束（沿用 round1–10）

1. 目标项目 `/Users/fangxiangming/Work/Ly/东风汽金/code/afc-newcore-web-code`，分支 **`benchmark/20260813`**，全程**禁 commit**。
2. suite agent prompt 含「绝对禁止运行任何 git 命令」+「只在目标项目目录内读写」+ 显式绝对路径。
3. 代码产物跑完即清；`.project-knowledge/` 的改动跑完恢复（该目录 gitignored）。
4. 路由测试不改任何文件，只做判定。

## 判定口径

- **K1 生效** = 重命名后重跑，`.hash` 内容变化 **且** index 的 `source` 跟随新路径、旧路径消失；两个产物均在 `.project-knowledge/` 顶层（不在项目根）。
- **G1 生效** = 复用裁决附 `命中` + `依据`；需求已覆盖时改动文件数为 0（或仅 import 已有组件）。**失败** = 只写 REUSE 无证据，或造出近重复组件。
- **O1 生效** = agent 表述 orchestrator 在 pipeline 执行前运行、`needs` 为空；**失败** = 声称它依赖/消费 8 个上游能力。
- **R 判定** = top-1 命中数 / 7。R6 若观测到「无对应 skill」，记为**路由缺口**（skill 未装载），不计入命中率分母的失败。
- 台账 `pass_fail` 只在本轮跑完后填，不预设结论。

## 已知前置事实（跑前记录，供判定参考）

- 目标项目**没有** `.claude/`，suite 未以项目级 skill 形式装载；agent 通过显式路径读 skill 定义（沿用前几轮做法）。
- 参考装载（前端 workspace）有 9 个 skill：analyzer / architect / documenter / generator / planner / refactorer / releaser / reviewer / tester —— **无 pipeline-orchestrator**。
- 跑前目标仓库分支 `feature/develop_930`（工作树干净），已切至 `benchmark/20260813`（`0a4bab0b9`），跑完切回。
