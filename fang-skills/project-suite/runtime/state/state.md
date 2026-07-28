# Project State

> `.project-runtime/` — 项目的持久化状态层。Skill 退出后信息不丢失。
> 用户是 Dispatcher。State 是 Skill 间的共享记忆。

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
 │  读 State → 执行 → 写 State → 输出 result.md → 结束
 │  Skill 之间互相不知道对方存在
```

**Skill 不记忆。State 永远存在。**

## 目录结构

```
.project-runtime/
├── state.json           # 项目当前状态 + 执行历史
├── knowledge.json        # 知识文件生命周期追踪
└── artifacts/            # 统一产出目录
    ├── plans/            # PLAN-*.md
    ├── decisions/        # ARCHITECTURE-*.md
    ├── reviews/          # REVIEW-*.md
    ├── reports/          # TEST-REPORT.md, REFACTOR.md
    └── releases/         # CHANGELOG.md
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
      "status": "accepted",
      "source": "project-analyzer",
      "verified_by": "human",
      "created": "2026-07-28T14:00:00",
      "verified_at": "2026-07-28T14:30:00",
      "confidence": 92
    },
    "components/catalog.md": {
      "status": "draft",
      "source": "project-analyzer",
      "verified_by": null,
      "created": "2026-07-28T14:00:00",
      "confidence": 78
    }
  }
}
```

**生命周期状态：**

| 状态 | 含义 | 下游可用？ |
|------|------|----------|
| `draft` | 初步生成，未验证 | ❌ 仅供参考 |
| `verified` | Reviewer 或人工确认通过 | ⚠️ 可用但标注来源 |
| `accepted` | 确认准确，用于生产决策 | ✅ 直接引用 |
| `archived` | 过时 / 不再适用 | ❌ 不再使用 |

**关键规则：Generator 只读 `accepted` 状态的知识 — 不把猜测当事实。**

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
   - artifacts/ → 写入产出文件

4. 输出 result.md:
   - 做了什么 / 没做什么
   - confidence
   - 建议下一步（用户参考）
```
