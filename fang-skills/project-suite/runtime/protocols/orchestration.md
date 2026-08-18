# Orchestration v0.7.0

> 跨 skill 工作流编排。用户是 Dispatcher。Skill 通过 State 文件通信，不直接串联。

## 核心模式：User-as-Dispatcher

```
用户
 │
 │  读 state.json（了解当前状态）
 │  读 Skill 建议（完成后）
 │
 ├──→ 决定执行哪个 Skill
 │
 ▼
Skill
 │  读 State（state.json + knowledge.json + 上游 artifacts）
 │  执行
 │  写 State（更新 state.json + knowledge.json）
 │  输出收尾报告（含 confidence + convergence + 建议下一步）
 │  结束
 │
 ▼
用户（再次决策）
```

**Skill 之间互相不知道对方存在。** 通信只靠 `.project-runtime/` 中的文件。Skill 完成后给出建议，用户决定是否采纳。

## State 层

`.project-runtime/` 是 Skill 间的共享记忆：

```
.project-runtime/
├── state.json         # 项目当前状态 + 执行历史
├── knowledge.json      # 知识文件生命周期追踪
└── artifacts/          # 统一产出目录
    ├── plans/          # PLAN-*.md
    ├── decisions/      # ARCHITECTURE-*.md
    ├── reviews/        # REVIEW-*.md
    ├── reports/        # TEST-REPORT.md, REFACTOR.md
    └── releases/       # CHANGELOG.md
```

→ 详细规范：[../state/state.md](../state/state.md)

## Workflow 模板

`runtime/registry/workflow-library.yaml` 中的 Pipeline 定义是**编排参考**，实际执行由 pipeline-orchestrator 驱动：

| 模板 | 文件 | 适用场景 |
|------|------|---------|
| full-sdlc | `workflows/full-sdlc.yaml` | 完整生命周期 |
| quick-change | `workflows/quick-change.yaml` | 轻量改动 |
| (自定义) | `workflows/*.yaml` | 用户按需创建 |

每个 Skill 的 `完成后` 参考这些模板给建议，但最终由用户决定。

## 并行建议

当同 Wave 的 Skill 互不依赖时，建议用户可并行执行：

```
planner + architect（都只依赖 analyzer，互不依赖）→ 可并行
tester + documenter（都只依赖 generator，互不依赖）→ 可并行
```

## Confidence 作为决策参考

每个 Skill 完成后输出 confidence（0-100）。用户根据分数决定下一步：

| Confidence | 含义 | 用户参考 |
|-----------|------|---------|
| ≥ 90 | 产出可靠 | 正常推进 |
| 70-89 | 有标注假设 | 建议检查假设再推进 |
| 40-69 | 信息不足 | 建议补充信息后重新执行 |
| < 40 | 不可靠 | 不应直接用于下游 |

**这不是自动阻断。** 用户始终拥有最终决策权。

## State 更新协议

每个 Skill 执行完成后更新 `.project-runtime/state.json`：

```json
{
  "phase": "architecture",
  "status": "in_progress",
  "history": [
    {"skill": "project-analyzer", "status": "completed", "confidence": 92, "at": "..."},
    {"skill": "project-planner", "status": "completed", "confidence": 85, "at": "..."}
  ]
}
```

Skill 只追加 history，不删除。用户可随时查看完整执行链路。

## Fresh Context 模式

每个 Skill 在独立的 `/clear` 上下文中执行。上下文不累积：

```
/clear
/project-planner
  → 读 context.json + state.json + .project-knowledge/
  → 写 PLAN.md + context-package.json + state.json
  → 结束（上下文丢弃）

/clear
/project-generator
  → 读 context-package.json（预消化知识包，~3-5 条 pattern/constraints）
  → 读 PLAN.md > # Task Breakdown
  → 生成代码
  → 写收尾报告 + state.json
  → 结束（上下文丢弃）

/clear
/project-reviewer
  → 读 state.json（了解变更范围）
  → 读 PLAN.md > # Acceptance Criteria
  → 审查
  → 写 REVIEW.md + state.json
  → 结束（上下文丢弃）
```

**每个 Skill 的上下文只有几 KB，不是几十万 token。**

**State 层是唯一的信息传递媒介。** Skill 不依赖对话历史——所有需要的信息都从 `.project-runtime/` 和 artifact 文件中读取。

### Stateless Skill 原则

```
✅ 每个 Skill:
   1. 启动（/clear 后的 fresh context）
   2. 读 .project-runtime/state.json（了解当前状态）
   3. 读 artifact 文件（PLAN.md / context-package.json / diff）
   4. 执行
   5. 写 .project-runtime/state.json + artifact 文件
   6. 结束

❌ 禁止:
   - 依赖上一轮对话中的信息
   - 假设上下文中有上次执行的结果
   - 跳过 state.json 直接读"我上次写的那个文件"
```

这本质上就是 serverless function 的模型：启动 → 读入 → 计算 → 写出 → 销毁。Skill 是 stateless 的，State 是 persistent 的。
