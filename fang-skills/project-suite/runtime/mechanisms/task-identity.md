# Task Identity v1.0

> 持久化数据的隔离粒度：**Task**，不是 Skill，也不是 Project。
> 没有 task_id，跨 session 恢复与多任务并行都会读到别的任务的上下文。

## 问题（为什么需要这一层）

Suite 原本的存储键只有 Skill 和 Project：

| 存储 | 旧路径 | 故障模式 |
|------|--------|---------|
| Session Memory | `runtime/memory/session.json` | 任务 B 覆盖任务 A 的 goal/assumptions |
| Session Snapshot | `.sessions/<skill>/state.json` | 同一 Skill 的两个任务互相覆盖恢复点 |
| Context Package | `context-package.json` | Generator 消费到上一个任务的知识包 |
| Pipeline State | `pipeline-state.json` | 两条 Pipeline 覆盖执行记录 |

**这不是并发才有的问题。串行就会坏**：跑完任务 A → 跑任务 B → 回到 A 的 resume，A 拿到的是 B 的上下文。并发只是让它更频繁、更难查。

## 三个身份，不能互相替代

| 标识 | 生命周期 | 用途 | 谁生成 |
|------|---------|------|--------|
| `task_id` | 一个长期任务，跨 Claude Session 保持不变 | **所有任务级持久化数据的键** | Discovery 的 Task Resolution（见下） |
| `session_id` | 一次具体执行会话 | 审计、追溯「哪次运行写的」 | 每次 Skill 启动 |
| `skill` | 执行者 | 路由、能力匹配 | 框架固定 |

timeline 每行用 `taskId` 字段关联任务；`runId` 仍必须**每次运行唯一**（`<taskId>/<skill>/<startedAt>`）。
不要用 `run-YYYYMMDD-NNN`（当天并发会算出同一个编号），也不要把 `runId` 写成只有 `task_id`
（同一任务会跑多个 Skill、可能重试）。

## 存储布局

```
.project-knowledge/
├── runtime/
│   ├── tasks/
│   │   └── <task_id>/
│   │       ├── meta.json              # 任务身份 + 生命周期
│   │       ├── session.json           # Session Memory（按任务隔离）
│   │       ├── context-package.json   # 知识包（按任务隔离）
│   │       ├── pipeline-state.json    # Pipeline 执行状态（按任务隔离）
│   │       └── manifest-<skill>.json  # 该 Skill 在本任务的 checkpoint
│   ├── memory/
│   │   ├── project.json               # 项目级（不按任务分区）
│   │   └── decisions/<id>.json        # 项目级（ADR 的"为什么"）
│   ├── state.json                     # 项目执行状态（唯一权威，含 active_tasks）
│   └── metrics/timeline.jsonl         # 项目级指标（一行一 run，taskId 关联）
│
├── .sessions/
│   └── <task_id>/
│       └── <skill>/state.json         # 跨 session 恢复点（任务 × Skill）
│
├── architecture/ components/ api/ patterns/ ...   # 项目级知识（不按任务分区）
├── proposals/PLAN-<task_id>.md                    # 任务产物
└── reports/{REVIEW,TEST-REPORT,REFACTOR}-<task_id>.md
```

**不按 task 分区的东西**（保持单一权威）：`state.json`、`knowledge.json`、analyzer 的 6 个根产物、`architecture/` `components/` `api/` `patterns/` 等项目知识。它们描述"项目是什么"，不是"某个任务做了什么"。

## 任务注册表

**没有中央 index 文件**——任务目录本身就是注册表，`list` 扫描 `runtime/tasks/*/meta.json`。这样并发创建任务不需要抢同一把写锁（`mkdir` 是原子的）。

`meta.json`：

```json
{
  "schemaVersion": "1.0.0",
  "task_id": "task-20261109-user-approval",
  "goal": "开发用户审批功能",
  "status": "active",
  "originating_skill": "project-planner",
  "skills": ["project-planner", "project-generator"],
  "artifacts": { "plan": "proposals/PLAN-task-20261109-user-approval.md" },
  "created_at": "2026-11-09T10:00:00Z",
  "updated_at": "2026-11-09T10:30:00Z"
}
```

- `status`: `active` / `paused` / `completed` / `abandoned`
- `task_id` 格式：`task-YYYYMMDD-<slug>`（slug 为 ASCII kebab-case；中文目标取拼音或英文意译）
- 同日同名冲突由 `mkdir` 失败检测，追加 `-2`、`-3`

## Task Resolution（Discovery 第 0 步，所有 Skill 强制）

> 这是这次改造的关键：文件按任务分开了，还必须让 Skill 知道**这次是哪个任务**。

在 Discovery 阶段最先执行，先于 Context Resolver 和任何文件读取：

```
1. 显式指定：用户/调用方给了 task_id（$PS_TASK_ID 或参数）→ 使用它
2. 恢复意图：用户说「继续 X」「resume X」→ task-registry.sh list 匹配 goal 关键字
3. 单活动任务：runtime/tasks/ 下恰好一个 status=active → 使用它（打印一行确认，不阻塞）
4. 多活动任务：列出 active 任务（id + goal + 最后活跃时间）→ AskUserQuestion 让用户选择
5. 无活动任务：
   - planner / analyzer 等能定义任务的 Skill → task-registry.sh create "<goal>"
   - 其他 Skill（generator/tester/reviewer/refactorer/documenter/releaser/orchestrator）
     → 回退到 task-registry.sh create --slug "<skill>-<timestamp>"，并在收尾报告中标注
       "⚠️ 无上游任务，已自动建任务 <task_id>"
```

**禁止**：扫描到哪个任务目录就用哪个；按修改时间猜测；在未解析出 task_id 时写入任何任务级文件。

### 显式 override

```
PS_TASK_ID=task-20261109-order-mgmt /project-generator
```

优先级最高，用于脚本/子 agent/CI。

## 生命周期

| 事件 | 动作 |
|------|------|
| 任务开始 | `task-registry.sh create` → 创建目录 + meta.json |
| Skill 执行 | `touch <task_id> <skill>` 追加 skills + updated_at |
| 用户暂停 | meta.status = `paused`；snapshot.status = `paused` |
| 任务完成 | meta.status = `completed`；保留目录（审计用） |
| 废弃 | meta.status = `abandoned`；不删除（知识生命周期另有治理） |

归档/清理不在本协议内——任务目录是审计证据，删除属于人工治理。

## 与并发的关系

task_id 解决**数据分区**，不解决**同一文件的并发写**：

| 场景 | task_id 是否解决 |
|------|----------------|
| 两个任务各自写 session/context/snapshot | ✅ 路径分离 |
| 两个任务同时追加 state.json history | ❌ 最后写入者覆盖 → 见下 |
| 两个 Analyzer 重建项目知识 | ❌ task_id 救不了 → 单写者锁 |

### state.json / timeline.jsonl 的写入纪律

- `history[]` 每条必须带 `task_id`；`current` 改为 `active_tasks`（见 [state.md](../state/state.md)）。
- 并发写同一项目状态时，**同一项目同一时刻只允许一个 Skill 写 `state.json`**（用户是 Dispatcher，一次推进一个）。若确实要并发，写前读 `state_version`，写后校验，冲突则重读合并重试；不要静默覆盖。
- `timeline` 已改为 append-only `timeline.jsonl`（`O_APPEND` 单次追加，写入器 `shared/scripts/timeline-append.sh`）。它解决的是**追加不丢行**；每行用 `taskId` 归属任务，`runId` 保持每次运行唯一。读取方（`collect-metrics.sh`）在读取时聚合，不存储 `aggregates`。

### 项目级知识的单写者

Analyzer 会 `Always` 重建 `graph.json` / `statistics.json` / `manifest.json` 等根产物。**任何 task_id 分区都无法阻止两个 Analyzer 互相覆盖**——这是项目级真相，必须单写者。见 [single-writer.md](single-writer.md)。

## 历史数据迁移

旧目录（`.sessions/<skill>/`、根 `context-package.json`、`runtime/memory/session.json`）不自动改：

1. Discovery 检测到旧路径且无任务目录 → 提示用户，`AskUserQuestion`：迁移为 `task-legacy` / 忽略并新建。
2. 迁移 = `mv` 到 `runtime/tasks/task-legacy/` + `.sessions/task-legacy/<skill>/`，写 meta.json 标注 `"migrated_from": "legacy"`。
3. 不迁移也能跑：解析器保留 legacy 回退（见 `knowledge-resolver.sh`），但会打印 stderr 告警。

## 验证

`shared/scripts/check-task-isolation.sh` 做**串行**回归（A → B → 回到 A），这是最高频、可确定性复现的失败路径；并发场景在串行通过后再手工验证。

验收断言：
- 任务 A 恢复后读不到 B 的 goal / assumptions
- Generator 只消费自己任务的 context-package
- 两个 Snapshot 独立恢复
- `state.json` history 两条都在且各带 task_id
- 一个任务的完成状态不覆盖另一个任务的执行状态
