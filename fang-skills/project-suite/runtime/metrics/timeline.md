# Timeline Protocol v2.0.0

> 执行链路可观测。记录每个 Skill 的运行指标，解决"哪个 Skill 最慢？哪个最容易失败？"只能凭感觉的问题。
>
> 📖 **人类读这里** · ⚙️ **Schema: [timeline.schema.json](timeline.schema.json)** · 📍 **输出: `.project-knowledge/runtime/metrics/timeline.jsonl`**

## 定位

```
state.json     → 项目当前状态（现在到哪了）
knowledge.json → 知识生命周期（哪些知识可信）
timeline.jsonl → 执行历史指标（每次运行花了多久、产出多少、成功还是失败）
                  ↑ 本协议定义
```

## 文件位置

`.project-knowledge/runtime/metrics/timeline.jsonl`

## 为什么是 JSONL（v1 → v2）

v1 的写入流程是 **读 `timeline.json` → 追加 `runs[]` → 增量更新 `aggregates` → 写回**。
两个并发 Skill（或同任务的两个会话）同时执行时，后写者会覆盖先写者 —— **丢 run 记录，且
`aggregates` 变成不可信的脏数据**。这不是性能问题，是正确性问题。

v2 改为 **append-only JSONL**：

| | v1 `timeline.json` | v2 `timeline.jsonl` |
|---|---|---|
| 形态 | 单个 JSON 对象（`runs[]` + `aggregates`） | 一行一个 run 记录 |
| 写入 | 读改写整文件 | `O_APPEND` 追加一行（不读旧内容） |
| 并发 | 丢更新 | 追加不丢（见 [single-writer.md](../mechanisms/single-writer.md) 的边界） |
| 聚合 | 写入时维护 `aggregates` | **不存储**，读取时按行计算 |

> **聚合不再落盘**：任何"写完再更新汇总"的字段都会重新引入读改写竞态。`collect-metrics.sh`
> 读取时自行聚合，数据永远从唯一事实（行记录）推导。

> **执行指标也以 timeline 为准**：执行次数、completed/degraded/blocked/failed、平均 confidence、
> skills used 全部由行记录聚合（`timeline-stats.mjs --shell`）。只有 timeline 不存在或没有有效
> 记录时，才回退到 `state.json` 的 legacy 解析。报告中的 `Execution metrics source` 行显式标注
> 本次来源（`timeline` / `state.json` / `none`），避免出现「Executions 0 而 Timeline entries 1」
> 这种自相矛盾的假绿。报告写到**项目**的 `.project-knowledge/reports/telemetry-report.md`，
> 不进 project-suite 包。

### 与旧文件的兼容

- **新写入一律进 `timeline.jsonl`**，禁止再写 `timeline.json`。
- 读取方（`collect-metrics.sh`）按顺序探测：`metrics/timeline.jsonl` → `metrics/timeline.json`（v1）→
  `runtime/timeline.json`（更早的 collector 路径）。命中 v1 时按 `{runs:[]}` 或顶层数组解析。
- 旧项目迁移：保留 `timeline.json` 只读，新记录继续写 `timeline.jsonl`。读取时按上述顺序
  **命中即用、不合并**——因此迁移应把旧记录逐行追加到 `.jsonl` 后删除旧文件（**先备份**），
  否则命中 `.jsonl` 后旧 `timeline.json` 的记录不会被计入。

## 一行记录

```json
{"schemaVersion":"2.0.0","project":"my-web-app","taskId":"task-20261109-user-approval","runId":"task-20261109-user-approval/project-analyzer/2026-11-09T14:00:00Z","skill":"project-analyzer","wave":1,"status":"completed","timing":{"startedAt":"2026-11-09T14:00:00Z","finishedAt":"2026-11-09T14:03:22Z","durationMs":202000},"input":{"scope":"full","mode":"standard","filesScanned":2260,"dimensions":["architecture","components","coding-style","ui-pattern","api","patterns","observations"],"contextSizeEstimate":"~80k tokens"},"output":{"filesGenerated":18,"artifacts":["context.json","graph.json","knowledge-index.json","index.md","overview.md"],"approxTokens":45000},"quality":{"confidence":92,"warnings":0,"errors":0,"degradedDimensions":[]},"dependencies":{"upstreamSkills":[],"knowledgeFilesRead":[],"knowledgeCapabilitiesUsed":[]}}
```

```json
{"schemaVersion":"2.0.0","project":"my-web-app","taskId":"task-20261109-user-approval","runId":"task-20261109-user-approval/project-generator/2026-11-09T14:10:00Z","skill":"project-generator","wave":4,"status":"completed","timing":{"startedAt":"2026-11-09T14:10:00Z","finishedAt":"2026-11-09T14:12:05Z","durationMs":125000},"input":{"planFile":"proposals/PLAN-task-20261109-user-approval.md","architectureFile":"decisions/ARCHITECTURE-task-20261109-user-approval.md","capabilitiesUsed":["VueConvention","TablePattern","FormPattern","ApiPattern"],"knowledgeFilesRead":4,"contextSizeEstimate":"~45k tokens"},"output":{"filesGenerated":3,"artifacts":["workspace/views/user/activate/index.vue","workspace/api/user.ts","workspace/types/user.d.ts"],"linesOfCode":320,"approxTokens":28000},"quality":{"confidence":85,"warnings":2,"errors":0,"checkpointsPassed":2},"dependencies":{"upstreamSkills":["project-analyzer","project-planner","project-architect"],"upstreamConfidenceMin":90,"knowledgeCapabilitiesUsed":["VueConvention","TablePattern","FormPattern","ApiPattern"]}}
```

## 字段说明

### 身份字段（必填）

| 字段 | 类型 | 说明 |
|------|------|------|
| `schemaVersion` | string | 行格式版本，当前 `2.0.0` |
| `project` | string | 项目名（来自 `analysis-config.json`，缺省为项目目录名） |
| `taskId` | string | 任务身份，见 [task-identity.md](../mechanisms/task-identity.md) |
| `runId` | string | **本次运行**唯一标识：`<taskId>/<skill>/<startedAt ISO>`。不要只用 `taskId`——同一任务会跑多个 Skill / 多次重试 |

### 运行字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `skill` | string | skill 名称（枚举见 schema） |
| `wave` | number | DAG 调度波次 |
| `status` | enum | `completed` / `degraded` / `blocked` / `failed` / `skipped`（`skipped` = 运行在产出前结束：monitor-only / 用户取消 / 无执行，**不代表失败**） |
| `timing.durationMs` | number | 执行耗时（毫秒）；缺失时由 `finishedAt - startedAt` 推导 |
| `input.contextSizeEstimate` | string | 估算上下文大小 |
| `output.filesGenerated` | number | 产出文件数 |
| `output.approxTokens` | number | 估算输出 token 数 |
| `quality.confidence` | number | 0-100。`0` 表示**未评估**（degraded / skipped / 用户在产出前取消），不是「质量极差」；聚合平均只统计 `completed` |
| `quality.warnings` | number | 警告数（降级/假设/推断） |
| `quality.errors` | number | 错误数（不可恢复） |
| `dependencies.upstreamConfidenceMin` | number | 上游 Skill 中最低的 confidence |
| `context` | object | 非标准运行的审计上下文（`reason` / `notes` / `warnings` / `autoFinalized` 等）。**自由 schema**——除指标外的信息都放这里，不要新增顶层字段。`warnings` 为字符串数组，记录「运行成功但产物不完整」这类不影响 status 的告警（如 `discovery-artifact-missing`） |

### 必填 / 选填

- **必填**：`schemaVersion` `project` `taskId` `runId` `skill` `status` `timing` `quality.confidence`
- **选填**：`wave` `input` `output` `dependencies` `billing` `context`（能填就填，不强制）
- **禁止**：schema 之外的顶层字段。writer 会在写盘前拒绝未知顶层字段（见下），要把审计信息放进 `context`。

## 写入规则

**所有 Skill 在 Output 阶段追加一行。**

```bash
# 方式 A：JSON 从 stdin
printf '%s' "$RUN_JSON" | bash shared/scripts/timeline-append.sh <project-root> -

# 方式 B：JSON 来自文件
bash shared/scripts/timeline-append.sh <project-root> /tmp/run.json
```

写入器负责：

1. 校验必填字段与枚举，并拒绝 schema 之外的顶层字段（`additionalProperties: false`）；不合规 → exit 2，**不写半条记录**。
2. 缺省补齐：`schemaVersion` / `project` / `taskId`（取 `$PS_TASK_ID`）/ `runId`（由 `taskId + skill + startedAt` 生成）/ `timing.durationMs`。
3. 单次 `O_APPEND` 追加 `JSON.stringify(record) + "\n"`。

**禁止**：读 `timeline.jsonl` → 改 → 写回；禁止在内存里维护 aggregate 后落盘。

**写入时机（终态必写）**：**每条退出路径都必须留下恰好一行终态记录**——`completed` / `degraded` /
`blocked` / `failed` / `skipped` 都算。包括 Discovery 后短路（monitor-only、drift-check、用户取消）、
resume 跳过、以及被 hook 自动收尾的运行。只在 Delivery 写的旧约定会让这些运行在指标里完全不可见。
显式收尾优先调用 `shared/scripts/runtime-run.sh finish <project-root> --skill <name> --status <status>`（见 workflow-protocol 的 Terminal Record）。
`finish` 只结束本次 Run，不修改长期 Task 的 `status`；同一 `runId` 只写一行——释放锁失败后重试不会重复记账。

## 查询能力

```bash
# 哪个 Skill 最慢？（按 avg duration 排序）
node -e '
const fs=require("fs");
const runs=fs.readFileSync(process.argv[1],"utf8").split("\n").filter(Boolean).map(JSON.parse);
const by={};
for(const r of runs){const d=r.timing?.durationMs??0;(by[r.skill]??=[]).push(d);}
Object.entries(by).map(([k,v])=>[k,Math.round(v.reduce((a,b)=>a+b,0)/v.length)])
  .sort((a,b)=>b[1]-a[1]).forEach(([k,v])=>console.log(v+"ms\t"+k));
' .project-knowledge/runtime/metrics/timeline.jsonl
```

可以回答：

```
"哪个 Skill 最容易失败？"   → COUNT(status=failed) / COUNT(*) DESC
"哪个 Skill confidence 最低？" → AVG(confidence) ASC
"最近一次 planner 到 generator 之间等了多久？" → 按 startedAt 排序，计算相邻间隔
"task A 一共跑了哪些 skill？" → filter taskId == A
```

## 与 state.json 的分工

| | state.json | timeline.jsonl |
|---|---|---|
| **内容** | 项目当前状态 | 执行历史指标 |
| **粒度** | 每个 Skill 最新一次 | 每次执行一行 |
| **用途** | Dispatcher 决策下一步 | 分析 Skill 性能和质量趋势 |
| **写入** | 覆盖当前状态 + 追加 history 摘要（单写者） | 追加一行（append-only） |
| **归档** | 始终保留 | 可定期归入 `metrics/archive/` |
