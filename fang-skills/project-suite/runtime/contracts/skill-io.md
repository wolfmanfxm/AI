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
  "techStack": { "framework": "Vue 3.4", "ui": "Element Plus 2.13", "lang": "TypeScript" },
  "aliases": { "@": "src", "@workspace": "workspace" },
  "conventions": { "component": "<script setup lang=\"ts\">", "form": "reactive()" },
  "modules": ["workspace/api/", "workspace/views/", "workspace/components/"]
}
```

### state.json（来自 .project-runtime/）
```json
{
  "phase": "generating",
  "current": { "skill": "project-generator", "task": null },
  "history": [
    {"skill": "project-planner", "confidence": 85, "output": "artifacts/plans/PLAN-credit-activate.md"},
    {"skill": "project-architect", "confidence": 90, "output": "artifacts/decisions/ARCHITECTURE-auth.md"}
  ],
  "blockers": []
}
```

### task.md（当前任务）
当前 Skill 需要完成的具体任务描述。来自 PLAN.md 的 Task Breakdown 或用户直接输入。

### knowledge.md（知识摘要）
仅包含 `status: accepted` 的知识条目摘要，避免上下文膨胀。

### knowledge-list.json（精确加载清单）

Planner 产出，Generator 消费。Generator 不搜索知识库——只读这个清单里指定的文件。

```json
{
  "plan": "PLAN-credit-activate.md",
  "generated_by": "project-planner",
  "files": [
    "components/catalog.md",
    "patterns/form.md",
    "api/quotaManage.ts"
  ],
  "graph_queries": [
    {"type": "component", "name": "FormSelect"},
    {"type": "api", "name": "quotaManage"}
  ]
}
```

**规则：**
- Planner 在 `# Reuse Analysis` 中已经列出了可复用资产 → 同时生成 `knowledge-list.json`
- Generator 启动时读 `knowledge-list.json`，只加载 `files` 列表中的文件
- Generator **不搜索** `.project-knowledge/` — 不知道还有别的知识
- Context 恒定、可预测、不膨胀

## 输出：3 个标准出口

```
┌─────────────────────────────────────────┐
│              Skill Output               │
├───────────────┬─────────────────────────┤
│ result.md     │ 执行结果摘要              │
│ state.json    │ 更新后的项目状态           │
│ artifacts/    │ 产出文件                  │
└───────────────┴─────────────────────────┘
```

### result.md（统一格式）
```markdown
# Result: {skill-name}

**Status:** {completed | degraded | blocked}
**Confidence:** {0-100}%
**Summary:** [一句话摘要]

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

### state.json（增量更新）
Skill 只更新自己负责的字段，不覆盖整个 state.json：
- `phase` / `status` → 更新项目状态
- `history[]` → 追加本次执行记录
- `blockers[]` → 追加/解除阻塞项

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

| Score | 含义 | 用户参考 |
|-------|------|---------|
| 90-100 | 高置信度，产出可靠 | 正常推进 |
| 70-89 | 中等置信度，有标注的假设 | 建议检查假设再推进 |
| 40-69 | 低置信度，信息不足 | 建议补充信息后重新执行 |
| < 40 | 不可靠 | 不应直接用于下游 |

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
