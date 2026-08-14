# Timeline Protocol v1.0.0

> 执行链路可观测。记录每个 Skill 的运行指标，解决"哪个 Skill 最慢？哪个最容易失败？"只能凭感觉的问题。
>
> 📖 **人类读这里** · ⚙️ **Schema: [timeline.schema.json](timeline.schema.json)** · 📍 **输出: `.project-runtime/metrics/timeline.json`**

## 定位

```
state.json    → 项目当前状态（现在到哪了）
knowledge.json → 知识生命周期（哪些知识可信）
timeline.json  → 执行历史指标（每次运行花了多久、产出多少、成功还是失败）
                  ↑ 本协议定义
```

## 文件位置

`.project-runtime/metrics/timeline.json`

## Schema

```json
{
  "schemaVersion": "1.0.0",
  "project": "my-web-app",
  "runs": [
    {
      "runId": "run-20260730-001",
      "skill": "project-analyzer",
      "wave": 1,
      "status": "completed",

      "timing": {
        "startedAt": "2026-07-30T14:00:00Z",
        "finishedAt": "2026-07-30T14:03:22Z",
        "durationMs": 202000
      },

      "input": {
        "scope": "full",
        "mode": "standard",
        "filesScanned": 2260,
        "dimensions": ["architecture","components","coding-style","ui-pattern","api","patterns","observations"],
        "contextSizeEstimate": "~80k tokens"
      },

      "output": {
        "filesGenerated": 18,
        "artifacts": ["context.json","graph.json","knowledge-index.json","index.md","overview.md","..."],
        "approxTokens": 45000
      },

      "quality": {
        "confidence": 92,
        "warnings": 0,
        "errors": 0,
        "degradedDimensions": []
      },

      "dependencies": {
        "upstreamSkills": [],
        "knowledgeFilesRead": [],
        "knowledgeCapabilitiesUsed": []
      }
    },
    {
      "runId": "run-20260730-002",
      "skill": "project-generator",
      "wave": 4,
      "status": "completed",

      "timing": {
        "startedAt": "2026-07-30T14:10:00Z",
        "finishedAt": "2026-07-30T14:12:05Z",
        "durationMs": 125000
      },

      "input": {
        "planFile": "artifacts/plans/PLAN-user-activate.md",
        "architectureFile": "artifacts/decisions/ARCHITECTURE-user.md",
        "capabilitiesUsed": ["VueConvention","TablePattern","FormPattern","ApiPattern"],
        "knowledgeFilesRead": 4,
        "contextSizeEstimate": "~45k tokens"
      },

      "output": {
        "filesGenerated": 3,
        "artifacts": ["workspace/views/user/activate/index.vue","workspace/api/user.ts","workspace/types/user.d.ts"],
        "linesOfCode": 320,
        "approxTokens": 28000
      },

      "quality": {
        "confidence": 85,
        "warnings": 2,
        "errors": 0,
        "checkpointsPassed": 2
      },

      "dependencies": {
        "upstreamSkills": ["project-analyzer","project-planner","project-architect"],
        "upstreamConfidenceMin": 90,
        "knowledgeCapabilitiesUsed": ["VueConvention","TablePattern","FormPattern","ApiPattern"]
      }
    }
  ],

  "aggregates": {
    "totalRuns": 8,
    "totalDurationMs": 1800000,
    "bySkill": {
      "project-analyzer": { "runs": 2, "avgDurationMs": 195000, "avgConfidence": 91, "failures": 0 },
      "project-generator": { "runs": 3, "avgDurationMs": 130000, "avgConfidence": 83, "failures": 0 }
    },
    "byStatus": {
      "completed": 7,
      "degraded": 1,
      "blocked": 0,
      "failed": 0
    }
  }
}
```

## 字段说明

### 每条 run 记录

| 字段 | 类型 | 说明 |
|------|------|------|
| `runId` | string | 唯一标识，格式 `run-YYYYMMDD-NNN` |
| `skill` | string | skill 名称 |
| `wave` | number | DAG 调度波次 |
| `status` | enum | `completed` / `degraded` / `blocked` / `failed` |
| `timing.durationMs` | number | 执行耗时（毫秒） |
| `input.contextSizeEstimate` | string | 估算上下文大小 |
| `output.filesGenerated` | number | 产出文件数 |
| `output.approxTokens` | number | 估算输出 token 数 |
| `quality.confidence` | number | 0-100 |
| `quality.warnings` | number | 警告数（降级/假设/推断） |
| `quality.errors` | number | 错误数（不可恢复） |
| `dependencies.upstreamConfidenceMin` | number | 上游 Skill 中最低的 confidence |

### aggregates（由 Runtime 自动计算）

每次追加 run 时更新。也可定期重算。

## 写入规则

**所有 Skill 在 Output 阶段写入一条 run 记录。**

写入流程：
```
1. 读 timeline.json（若存在）
2. 追加当前 run 到 runs[] 末尾
3. 更新 aggregates（增量计算：移动平均 + 计数递增）
4. 写回 timeline.json
```

**写入时机**：state.json 写入之后，result.md 输出之前。

**最简写入**（Skill 不知道精确 token 数时可以省略估算字段）：
```json
{
  "runId": "run-20260730-003",
  "skill": "project-tester",
  "wave": 5,
  "status": "completed",
  "timing": { "startedAt": "...", "finishedAt": "...", "durationMs": 45000 },
  "output": { "filesGenerated": 2 },
  "quality": { "confidence": 78 }
}
```

**必填字段**：`runId` `skill` `status` `timing` `quality.confidence`
**选填字段**：`input` `output` `dependencies`（能填就填，不强制）

## 查询能力

有了 timeline.json 后可以回答：

```
"哪个 Skill 最慢？"
→ 按 skill 分组，AVG(durationMs) DESC

"哪个 Skill 最容易失败？"
→ 按 skill 分组，COUNT(status=failed) / COUNT(*) DESC

"哪个 Skill confidence 最低？"
→ 按 skill 分组，AVG(confidence) ASC

"最近一次 planner 到 generator 之间等了多久？"
→ timeline 按 startedAt 排序，计算相邻 skill 的间隔

"generator 的 confidence 在下降吗？"
→ 按时间序列看 generator confidence 趋势
```

## 与 state.json 的分工

| | state.json | timeline.json |
|---|---|---|
| **内容** | 项目当前状态 | 执行历史指标 |
| **粒度** | 每个 Skill 最新一次 | 每次执行一条 |
| **用途** | Dispatcher 决策下一步 | 分析 Skill 性能和质量趋势 |
| **写入** | 覆盖当前状态 + 追加 history 摘要 | 追加 run 记录 + 更新聚合 |
| **归档** | 始终保留 | 可定期归入 `metrics/archive/` |
