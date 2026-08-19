# Project State

> `.project-runtime/` — 项目的持久化状态层。Skill 退出后信息不丢失。
> 用户是 Dispatcher。State 是 Skill 间的共享记忆。

## 状态真相边界（单一权威）

> 状态文件很多，但**只有一个 Execution State 权威**，其余是派生/恢复/指标。避免「多个状态真相」。

| 文件 | 性质 | 权威关系 |
|------|------|---------|
| **`state.json`** | **Execution State（唯一权威）** — 项目当前 phase/status/history/blockers | 唯一权威，其他 Skill 读它了解「现在到哪了」 |
| `knowledge.json` | 知识生命周期（独立维度，不是执行状态） | 权威：知识的 Accepted/Candidate 状态 |
| `manifest.json` | 断点续传辅助（skill 级子任务进度） | **派生自 state.json，仅恢复用**，不是独立执行状态真相 |
| `.sessions/<skill>/state.json` | Session 快照（跨 session 恢复） | **恢复辅助**，内容以 state.json 为准 |
| `timeline.json` | 执行指标（timing/quality） | **指标派生**，不含执行状态决策信息 |

**规则**：判断「项目现在什么阶段、哪些 skill 完成了、有什么 blocker」——**只读 `state.json`**。manifest/session-snapshot/timeline 是 state.json 的辅助数据，冲突时以 state.json 为准。

## 核心理念

```
用户（Dispatcher）
 │
 │  读 .project-runtime/ 了解：
 │    - 当前什么阶段
 │    - 哪些 Skill 已完成
 │    - 每个 Skill 的置信度
 │    - 知识文件的可信状态
 │
 ├──→ 决定：继续推进 / 重试上游 / 暂停补充信息
 │
 ▼
Skill
 │  读 State → 执行 → 写 State → 输出收尾报告 → 结束
 │  Skill 之间互相不知道对方存在
```

**Skill 不记忆。State 永远存在。**

## 初始化

**由 project-analyzer 在首次执行时创建 `.project-runtime/`**：

1. analyzer Finish Phase B 检测 `.project-runtime/` 是否存在
2. 不存在 → 创建目录结构：`state.json` + `knowledge.json` + `metrics/` + `artifacts/`
3. 写入初始 state（`phase: analyzing, status: in_progress`）
4. 后续 skill 通过读 state 了解当前阶段

**其他 skill 不负责创建 `.project-runtime/`**，仅 analyzer 有这个职责。若 analyzer 未执行（如直接调用 generator），下游 skill 降级为无状态模式。

## 目录结构

```
.project-runtime/
├── state.json              # 项目当前状态 + 执行历史（含 confidence gate）
├── knowledge.json           # 知识文件生命周期追踪
├── knowledge-index.json     # Capability→文件映射
├── metrics/                 # 可观测层（v1.3.0）
│   ├── timeline.json        # 全量执行历史指标
│   ├── knowledge-health.json # 知识库质量检测报告
│   └── archive/             # 归档的旧 timeline（按季度）
└── artifacts/               # 统一产出目录
    ├── plans/               # PLAN-*.md
    ├── decisions/           # ARCHITECTURE-*.md
    ├── reviews/             # REVIEW-*.md
    ├── reports/             # TEST-REPORT.md, REFACTOR.md
    └── releases/            # CHANGELOG.md
```

## state.json

```json
{
  "project": "project-name",
  "updated": "2026-07-28T15:00:00",
  "phase": "planning",
  "status": "in_progress",
  "current": {
    "skill": "project-planner",
    "started": "2026-07-28T15:00:00"
  },
  "history": [
    {
      "skill": "project-analyzer",
      "status": "completed",
      "confidence": 92,
      "output": "artifacts/knowledge/",
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
| `current` | 当前执行的 Skill |
| `history[]` | 执行历史，每个 Skill 追加一条 |
| `history[].confidence` | 该 Skill 的自评置信度 |
| `history[].suggested_next` | Skill 建议的下一步（用户参考） |
| `blockers[]` | 阻塞项列表 |

**规则：** Skill 只追加 history，不删除。用户可随时查看完整执行链路。

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

3. 写 State:
   - state.json → 追加 history（含 confidence + suggested_next）
   - knowledge.json → 更新知识状态（analyzer/reviewer）
   - timeline.json → 追加 run 记录（timing/quality/dependencies）
   - artifacts/ → 写入产出文件

4. 输出收尾报告:
   - 做了什么 / 没做什么
   - confidence
   - 建议下一步（用户参考）
```
