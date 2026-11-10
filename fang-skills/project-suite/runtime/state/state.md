# Project State

> `.project-knowledge/runtime/` — 项目的持久化状态层。Skill 退出后信息不丢失。
> 用户是 Dispatcher。State 是 Skill 间的共享记忆。

## 状态真相边界（单一权威）

> 状态文件很多，但**只有一个 Execution State 权威**，其余是派生/恢复/指标。避免「多个状态真相」。

| 文件 | 性质 | 权威关系 |
|------|------|---------|
| **`state.json`** | **Execution State（唯一权威）** — 项目当前 phase/status/history/blockers | 唯一权威，其他 Skill 读它了解「现在到哪了」 |
| `knowledge.json` | 知识生命周期（独立维度，不是执行状态） | 权威：知识的 Accepted/Candidate 状态 |
| `manifest.json` | 断点续传辅助（skill 级子任务进度） | **skill 自维护的执行级状态（子任务粒度），非 state.json 派生**，不是独立执行状态真相 |
| `.sessions/<task_id>/<skill>/state.json` | Session 快照（跨 session 恢复） | **恢复辅助**，内容以 state.json 为准 |
| `timeline.jsonl` | 执行指标（timing/quality） | **指标派生**，不含执行状态决策信息 |

**规则**：判断「项目现在什么阶段、哪些 skill 完成了、有什么 blocker」——**只读 `state.json`**。manifest/session-snapshot/timeline 记录不同粒度的执行细节（skill 内子任务进度 / session 快照 / 指标），不参与「项目当前阶段」判定；冲突时以 state.json 为准。

## 核心理念

```
用户（Dispatcher）
 │
 │  读 .project-knowledge/runtime/ 了解：
 │    - 当前什么阶段
 │    - 哪些 Skill 已完成
 │    - 每个 Skill 的置信度
 │    - 知识文件的可信状态
 │
 ├──→ 决定：继续推进 / 重试上游 / 暂停补充信息
 │
 ▼
Skill
 │  读 State → 执行 → 提交 State 更新建议 → 输出收尾报告 → 结束
 │  Skill 之间互相不知道对方存在
```

**Skill 不记忆。State 永远存在。**

## 初始化

**由 project-analyzer 在首次执行时创建 `.project-knowledge/runtime/` 的目录骨架**：

1. analyzer Finish Phase B 检测 `.project-knowledge/runtime/` 是否存在
2. 不存在 → 创建目录骨架：`knowledge.json` + `metrics/`（**根 `state.json` 不在其中**）
3. 产出初始的 State 更新建议（`phase: analyzing, status: in_progress`），由 **Dispatcher 串行提交**为根 `state.json`；analyzer 不直接写它
4. 后续 skill 通过读 state 了解当前阶段（根 `state.json` 不存在时按「无状态」降级，不自行补写）

**其他 skill 不负责创建 `.project-knowledge/runtime/`**，仅 analyzer 有这个职责。若 analyzer 未执行（如直接调用 generator），下游 skill 降级为无状态模式。

## 目录结构

```
.project-knowledge/runtime/
├── state.json              # 项目当前状态 + 执行历史（含 confidence gate）
├── knowledge.json           # 知识文件生命周期追踪
├── metrics/                 # 可观测层（v1.3.0）
│   ├── timeline.jsonl       # 全量执行历史指标（一行一 run，append-only）
│   ├── knowledge-health.json # 知识库质量检测报告
│   └── archive/             # 归档的旧 timeline（按季度）
```

> 产出文件不在 `runtime/` 下——统一写入 `.project-knowledge/` 对应子目录：
> PLAN→`proposals/`、ARCHITECTURE→`decisions/`、REVIEW/TEST-REPORT/CHANGELOG→`reports/`。

## state.json

```json
{
  "project": "project-name",
  "updated": "2026-07-28T15:00:00",
  "phase": "planning",
  "status": "in_progress",
  "current": {
    "skill": "project-planner",
    "task_id": "task-20261109-user-approval",
    "started": "2026-07-28T15:00:00"
  },
  "active_tasks": {
    "task-20261109-user-approval": { "skill": "project-planner", "status": "in_progress" },
    "task-20261109-order-management": { "skill": "project-generator", "status": "in_progress" }
  },
  "history": [
    {
      "task_id": "task-20261109-user-approval",
      "skill": "project-analyzer",
      "status": "completed",
      "confidence": 92,
      "output": ".project-knowledge/",
      "suggested_next": "project-planner",
      "at": "2026-07-28T14:00:00"
    }
  ],
  "blockers": []
}
```

**字段：**
| 字段 | 说明 |
|------|------|
| `phase` | 当前阶段：analyzing / planning / architecture / generating / testing / reviewing / releasing |
| `status` | in_progress / waiting / blocked / completed |
| `current` | 最近一次执行的 Skill（兼容字段；`task_id` 必填） |
| `active_tasks` | 并行任务视图：task_id → 最近 skill + status。**唯一权威仍是本文件**，不是另建状态层 |
| `history[]` | 执行历史，每条**必须带 `task_id`**；多个任务各自追加，互不覆盖 |
| `history[].confidence` | 该 Skill 的自评置信度 |
| `history[].suggested_next` | Skill 建议的下一步（用户参考） |
| `blockers[]` | 阻塞项列表 |

**规则：**
> **写者唯一**：根 `state.json` 由 **Dispatcher 串行提交**（同一项目同一时刻一个写者，一次推进一个任务）。
> Skill 的执行进度写任务级 snapshot，终态写 timeline；并行处理不同任务时，各 Skill **不得直接读改写根 `state.json`**。
> Skill 只能产出 **State 更新建议**（history 条目 / phase 建议 / blocker），由 Dispatcher 合并后统一写入。
> 写入纪律见 [task-identity.md](../mechanisms/task-identity.md#statejson--timelinejsonl-的写入纪律)。

## knowledge.json

追踪 `.project-knowledge/` 中每个知识文件的生命周期：

```json
{
  "files": {
    "patterns/table.md": {
      "status": "Accepted",
      "occurrences": 3,
      "promotion_rules_met": ["r1", "r2", "r3"],
      "source": "project-analyzer",
      "created": "2026-07-28T14:00:00",
      "promoted_at": "2026-07-28T14:30:00",
      "confidence": 92,
      "score": 92
    },
    "candidate/upload-pattern.md": {
      "status": "Candidate",
      "occurrences": 1,
      "source": "project-analyzer",
      "created": "2026-07-28T14:00:00",
      "confidence": 65,
      "score": 65
    }
  }
}
```

**生命周期状态（v2.0）：**

| 状态 | 含义 | 下游可用？ |
|------|------|----------|
| `Artifact` | 任务产物，任务结束即清理 | ❌ 不进入知识库 |
| `Candidate` | 首次出现，等待验证 | ⚠️ 仅供 Planner/Architect 参考 |
| `Accepted` | 满足晋升规则（≥3/5），正式知识 | ✅ 全部 Skill，Generator 优先 |
| `Deprecated` | 不再推荐，保留历史 | ❌ 仅供追溯 |

**关键规则：Generator 只读 `Accepted` 状态的知识 — 不把猜测当事实。**
**90% 的产出停留在 `Artifact` 层，永不进入知识库。**

→ 详细状态机：[schemas/knowledge-lifecycle.md](schemas/knowledge-lifecycle.md)

## Skill 读写协议

所有 Skill 遵循统一模式：

```
1. 读 State:
   - state.json → 了解项目当前状态 + 上游产出
   - knowledge.json → 了解可用知识及其可信状态

2. 执行:
   - 读需要的 artifacts（PLAN.md / ARCHITECTURE.md / code）
   - 执行本 Skill 的职责

3. 状态写入边界（固定）:
   - 执行进度 → 任务级 `.sessions/<task_id>/<skill>/state.json`（并行任务各写各的；权威定义见 [session-snapshot.md](../mechanisms/session-snapshot.md)）
   - 终态 → `timeline.jsonl` 追加一行 run（`taskId` 单独字段；`runId` = `<taskId>/<skill>/<startedAt>`，必须唯一）
   - 根 `state.json` → **只由 Dispatcher 串行提交**（phase/status/history）；Skill 不直接读改写
   - knowledge.json → 更新知识状态（analyzer / reviewer）。二者是同一份 **项目级共享资源**，
     共用 `analyzer` 单写者锁（见 [single-writer.md](../mechanisms/single-writer.md)），
     不同任务不能各自并发更新
   - 任务级产出 → `runtime/tasks/<task_id>/`（session / context-package / pipeline-state）
   - 产出文件 → 写入 `.project-knowledge/` 对应子目录（文件名带 task_id，见下）

4. 输出收尾报告:
   - 做了什么 / 没做什么
   - confidence
   - 建议下一步（用户参考）
```

## 产出文件命名

任务产物必须带 `task_id`，避免两个并行任务互相覆盖：

| 产物 | 路径 |
|------|------|
| PLAN | `proposals/PLAN-<task_id>.md` |
| ARCHITECTURE | `decisions/ARCHITECTURE-<task_id>.md` |
| REVIEW | `reports/REVIEW-<task_id>.md` |
| TEST-REPORT | `reports/TEST-REPORT-<task_id>.md` |
| REFACTOR | `reports/REFACTOR-<task_id>.md` |

> 需要额外区分同一任务内的多份报告时，用 `<TYPE>-<task_id>-<topic>.md`。
> 项目级知识（architecture/ components/ api/ patterns/）**不带** task_id——它们描述项目，不描述任务。
