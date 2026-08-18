# Unified Skill I/O Contract

> 所有 Skill 的输入输出遵循统一格式。Skill 之间通过 State 通信，不直接调用。

## 输入：4 个标准入口

每个 Skill 启动时接收这 4 个输入：

```
┌─────────────────────────────────────────┐
│               Skill Input               │
├───────────────┬─────────────────────────┤
│ context.json  │ 项目技术上下文            │
│ state.json    │ 项目当前状态 + 上游产出    │
│ task.md       │ 当前任务描述              │
│ knowledge.md  │ 可用知识摘要（仅 accepted）│
└───────────────┴─────────────────────────┘
```

### context.json（来自 Analyzer）
```json
{
  "techStack": { "framework": "<框架>", "ui": "<组件库>", "lang": "<语言>" },
  "aliases": { "@": "src", "<业务层别名>": "workspace" },
  "conventions": { "component": "<组件范式>", "form": "reactive()" },
  "modules": ["<api 目录>/", "<页面目录>/", "<组件目录>/"]
}
```

### state.json（来自 .project-runtime/）
```json
{
  "phase": "generating",
  "current": { "skill": "project-generator", "task": null },
  "history": [
    {"skill": "project-planner", "confidence": 85, "output": "artifacts/plans/PLAN-user-activate.md"},
    {"skill": "project-architect", "confidence": 90, "output": "artifacts/decisions/ARCHITECTURE-auth.md"}
  ],
  "blockers": []
}
```

### task.md（当前任务）
当前 Skill 需要完成的具体任务描述。来自 PLAN.md 的 Task Breakdown 或用户直接输入。

### knowledge.md（知识摘要，v2 预消化）

> 知识注入唯一入口 = `context-package.json`（Knowledge Resolver 产出，预消化 pattern + constraints + components）。
> Generator 不再读文件、不自己判断——直接遍历 `context.knowledge[]` 注入。见 [knowledge-resolver.md](../knowledge-resolver.md)。

```json
{
  "plan": "PLAN-user-activate.md",
  "generated_by": "knowledge-resolver",
  "schemaVersion": "2.0.0",
  "context": {
    "knowledge": [
      {"capability": "TablePattern", "pattern": "DataTable + <schema表格>", "constraints": ["pageIndex/pageSize 数字"], "anti_pattern": "不要手写 el-table", "source": "patterns/table.md"}
    ],
    "components": [{"name": "Dialog", "path": "@app/components/common/Dialog", "reuse": true}],
    "api": [{"module": "order", "functions": ["getPage"], "conventions": ["export function 风格"]}],
    "rules": [{"rule": "workspace-priority", "constraint": "组件从 @app/components/ 引入", "blocking": true}]
  }
}
```

**规则：**
- Planner 在 `# Reuse Analysis` 中列出可复用资产 → Resolver 产出 `context-package.json`
- Generator 启动时读 `context-package.json` → 遍历 `context.knowledge[]` 直接注入，遵守 constraints、避免 anti_pattern
- Generator **不搜索** `.project-knowledge/` — 不知道还有别的知识
- Context 恒定、可预测、不膨胀

> ⚠️ **Legacy**：`knowledge-list.json`（v1 文件路径清单，Generator 自行解析）已废弃，被 `context-package.json` 取代。新 Skill 不得再以其为正式输入。见 [knowledge-resolver.md](../knowledge-resolver.md)「Legacy Compatibility」。

## 输出：3 个标准出口

```
┌─────────────────────────────────────────┐
│              Skill Output               │
├───────────────┬─────────────────────────┤
│ 收尾报告       │ 执行结果摘要（名字由 skill 自定，见下）│
│ state.json    │ 更新后的项目状态           │
│ artifacts/    │ 产出文件                  │
└───────────────┴─────────────────────────┘
```

### 收尾报告（统一格式，文件名由 skill 自定）

> 每个 Skill 必须产出**一份**收尾报告（`gates.yaml` `require_closing_report`），遵循下面的统一格式。
> **文件名由 skill 自定**，不存在一个强制叫 `result.md` 的文件——各 skill 的实际报告名：

| Skill | 收尾报告文件名 |
|-------|--------------|
| analyzer | `validation-report.md`（+ verification-report.md） |
| planner | `validation-report.md` |
| architect | `ARCHITECTURE-<topic>.md`（ADR 本身即收尾） |
| generator | `completion-report.md` |
| tester | `TEST-REPORT.md` |
| reviewer | `REVIEW-<topic>.md` |
| refactorer | `REFACTOR.md` |
| documenter | 文档本身（含 Evidence Header） |
| releaser | `CHANGELOG.md` + `RELEASE-CHECKLIST.md` |
| pipeline-orchestrator | `pipeline-report.md` |

统一格式（内容结构，非文件名）：

```markdown
# Result: {skill-name}

**Status:** {completed | degraded | blocked}
**Confidence:** {0-100}%
**Summary:** [一句话摘要]

**Convergence:** {sufficient | insufficient | blocked} → {stop | execute | investigate}
**Evidence:** [支撑收敛判断的证据]

## What Was Done
- [具体做了什么]

## What Was NOT Done
- [明确未覆盖的内容 + 原因]

## Issues
| # | 类型 | 描述 | 严重度 |
|---|------|------|--------|
| 1 | gap | API 文档缺失，部分端点基于推断 | medium |

## Next
**Suggested:** {下一步 Skill 建议}
**Blockers:** {阻塞后续执行的问题}
```

> **Convergence**（统一停止条件）是 Suite 一级原语：`sufficient`=证据够、停下；`insufficient`=缺证据、补；`blocked`=缺输入、回上游。见 [convergence.md](../../shared/primitives/convergence.md)。

### state.json（增量更新）
Skill 只更新自己负责的字段，不覆盖整个 state.json：
- `phase` / `status` → 更新项目状态
- `history[]` → 追加本次执行记录
- `blockers[]` → 追加/解除阻塞项

### timeline.json（执行指标追加）

**所有 Skill 在 Output 阶段必须向 timeline.json 追加一条 run 记录。**

最简写入（必填字段）：
```json
{
  "runId": "run-20260730-NNN",
  "skill": "project-xxx",
  "wave": 4,
  "status": "completed",
  "timing": { "startedAt": "ISO-8601", "finishedAt": "ISO-8601", "durationMs": 125000 },
  "output": { "filesGenerated": 3 },
  "quality": { "confidence": 85 }
}
```

完整写入（建议能填就填）：
```json
{
  "runId": "run-20260730-NNN",
  "skill": "project-xxx",
  "wave": 4,
  "status": "completed",
  "timing": { "startedAt": "...", "finishedAt": "...", "durationMs": 125000 },
  "input": {
    "planFile": "...",
    "capabilitiesUsed": ["<框架约定>","TablePattern"],
    "knowledgeFilesRead": 4,
    "contextSizeEstimate": "~45k tokens"
  },
  "output": {
    "filesGenerated": 3,
    "artifacts": ["..."],
    "linesOfCode": 320,
    "approxTokens": 28000
  },
  "quality": {
    "confidence": 85,
    "warnings": 2,
    "errors": 0
  },
  "dependencies": {
    "upstreamSkills": ["project-analyzer","project-planner"],
    "upstreamConfidenceMin": 90
  }
}
```

**写入时机**：state.json 写入之后，收尾报告输出之前。
**写入方式**：读 timeline.json → 追加 runs[] → 增量更新 aggregates → 写回。

→ 完整协议：[../metrics/timeline.md](../metrics/timeline.md)

### artifacts/
按类型放入对应子目录：`plans/` / `decisions/` / `reviews/` / `reports/` / `releases/`

## 各 Skill 的映射

| Skill | Input: task.md 来源 | Output: artifacts/ |
|-------|--------------------|--------------------|
| analyzer | 用户需求（分析范围） | knowledge/ |
| planner | 用户需求 | plans/ |
| architect | PLAN.md > # Decision | decisions/ |
| generator | PLAN.md > # Task Breakdown | code（项目目录） |
| tester | PLAN.md > # Acceptance Criteria | reports/ |
| reviewer | 变更 diff | reviews/ |
| refactorer | 重构目标描述 | code + reports/ |
| documenter | 文档需求 | documents/ |
| releaser | 发布指令 | releases/ |

## 置信度（Confidence）

**所有 Skill 输出必须包含 Confidence 评分。**

| Score | 含义 | Gate | 行为 |
|-------|------|------|------|
| 90-100 | 高置信度，产出可靠 | 🟢 PASS | 直接进入下游 |
| 70-89 | 中等置信度，有标注的假设 | 🟡 REVIEW | 建议 Review 后推进 |
| 40-69 | 低置信度，信息不足 | 🟠 GATE | 强制 Review，禁止 Release |
| < 40 | 不可靠 | 🔴 BLOCK | 阻断，必须重做或人工介入 |

Confidence 计算规则（各 Skill 通用框架）：
```
confidence = 100
- 20 if 输入信息模糊/不完整
- 15 if 依赖的 knowledge 状态非 accepted
- 15 if 依赖的上游产出置信度 < 70
- 10 if 遇到未预见的边界条件
- 10 if 使用了降级/fallback 模式
- 5  per 未验证假设（max -20）
```

**Confidence Gate 行为：**
- 🟢 PASS → 下游正常执行，state.json 记录 `gate: "PASS"`
- 🟡 REVIEW → 下游正常执行，state.json 标注 `gate: "REVIEW"` + AskUserQuestion
- 🟠 GATE → Reviewer 强制执行后才能进入 Generator；Releaser 拒绝执行
- 🔴 BLOCK → state.json 写入 blocker，下游 Skill 启动时检测到 blocker → 拒绝执行

→ 完整 Gate 协议：[../engine/confidence-gate.md](../engine/confidence-gate.md)
