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
 │  读 State（state.json + knowledge.json + 上游 artifacts；根 state.json 只读）
 │  执行（进度写任务级 snapshot）
 │  写项目级产物（knowledge.json 走 analyzer 单写者锁）
 │  追加终态 timeline + 产出 State 更新建议
 │  输出收尾报告（含 confidence + convergence + 建议下一步）
 │  结束
 │
 ▼
用户 / Dispatcher（统一提交根 state.json，再次决策）
```

**Skill 之间互相不知道对方存在。** 通信只靠 `.project-knowledge/runtime/` 中的文件。Skill 完成后给出建议，用户决定是否采纳。

## State 层

`.project-knowledge/runtime/` 是 Skill 间的共享记忆：

```
.project-knowledge/runtime/
├── state.json         # 项目当前状态 + 执行历史
└── knowledge.json      # 知识文件生命周期追踪
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

并行必须遵守 [task-identity.md 的并发政策](../mechanisms/task-identity.md#并发政策)：

| 场景 | 建议 |
|------|------|
| 不同 Task、相同 Skill | 协议允许（任务产物按 task_id 隔离）；⚠️ 当前运行指针仍按 skill 单槽，实现未生效 |
| 不同 Task、不同 Skill | 允许，但需依赖已解除、写入范围不冲突 |
| 相同 Task、相同 Skill | 禁止同时运行 |
| 相同 Task、不同 Skill | 有条件允许（依赖解除 + 写入范围不冲突） |
| 共享项目级写者（Analyzer / Releaser / 写 knowledge.json 的 Reviewer） | 始终受单写者锁约束，不同 task 不能绕过 |
| 同时修改相同源码 | 文件范围不重叠，或使用独立 Git Worktree |

当同 Wave 的 Skill 互不依赖时，可以并行：

```
planner + architect（都只依赖 analyzer，互不依赖）→ 可并行
tester + documenter（都只依赖 generator，互不依赖）→ 可并行
```

**Task 级隔离不等于源码级隔离**：两个 Planner 写不同 PLAN 没问题；两个 Generator 即使 PLAN
不同，也可能同时改同一个源文件。

> 项目级 `state.json` 仍只由 Dispatcher 串行提交；并行任务各自写任务级 snapshot 和 timeline，
> 不直接读改写根 `state.json`。

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

**Skill 不直接写根 `state.json`。** 每次执行结束后，Skill 产出的是「State 更新建议」，
由 **Dispatcher 串行提交**；进度与终态另走两条独立通道：

| 内容 | 写入者 | 位置 |
|------|--------|------|
| 执行进度（phase / 子任务） | 当前 Skill | `.sessions/<task_id>/<skill>/state.json`（任务级 snapshot） |
| 运行终态（一次 Run 一行） | `runtime-run.sh finish` | `runtime/metrics/timeline.jsonl`（append-only） |
| 项目当前状态（phase / status / active_tasks / history） | **仅 Dispatcher** | `runtime/state.json` |

Skill 在收尾报告里给出的建议形如：

```json
{
  "state_update_suggestion": {
    "phase": "architecture",
    "status": "in_progress",
    "history_entry": {"task_id": "task-20261109-user-approval", "skill": "project-analyzer",
                      "status": "completed", "confidence": 92, "at": "..."},
    "blockers": []
  }
}
```

Dispatcher 合并多个任务的建议后**串行**写根 `state.json`：同一项目同一时刻只有一个写者，
一次推进一个任务。`history[]` 由 Dispatcher 追加（带 `task_id`），Skill 不删除、不覆盖。

## Fresh Context 模式

每个 Skill 在独立的 `/clear` 上下文中执行。上下文不累积：

```
/clear
/project-planner
  → 读 context.json + state.json + .project-knowledge/（根 state.json 只读）
  → 写 PLAN.md + context-package.json（任务级）
  → 产出 State 更新建议（Dispatcher 提交）
  → 结束（上下文丢弃）

/clear
/project-generator
  → 读 context-package.json（预消化知识包，~3-5 条 pattern/constraints）
  → 读 PLAN.md > # Task Breakdown
  → 生成代码
  → 写收尾报告 + State 更新建议（Dispatcher 提交）
  → 结束（上下文丢弃）

/clear
/project-reviewer
  → 读 state.json（了解变更范围）
  → 读 PLAN.md > # Acceptance Criteria
  → 审查（写 knowledge.json 须持 analyzer 单写者锁）
  → 写 REVIEW.md + State 更新建议（Dispatcher 提交）
  → 结束（上下文丢弃）
```

**每个 Skill 的上下文只有几 KB，不是几十万 token。**

**State 层是唯一的信息传递媒介。** Skill 不依赖对话历史——所有需要的信息都从 `.project-knowledge/runtime/` 和 artifact 文件中读取。

### Stateless Skill 原则

```
✅ 每个 Skill:
   1. 启动（/clear 后的 fresh context）
   2. 读 .project-knowledge/runtime/state.json（只读，了解当前状态）
   3. 读 artifact 文件（PLAN.md / context-package.json / diff）
   4. 执行（进度写 .sessions/<task_id>/<skill>/state.json）
   5. 写项目级 artifact 文件 + 追加终态 timeline
   6. 产出 State 更新建议（由 Dispatcher 提交根 state.json）
   7. 结束

❌ 禁止:
   - 依赖上一轮对话中的信息
   - 假设上下文中有上次执行的结果
   - 跳过 state.json 直接读"我上次写的那个文件"
   - 直接读改写根 state.json（违反单写者）
```

这本质上就是 serverless function 的模型：启动 → 读入 → 计算 → 写出 → 销毁。Skill 是 stateless 的，State 是 persistent 的。
