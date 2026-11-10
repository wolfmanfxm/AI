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
  "artifacts": { "plan": "proposals/PLAN-task-20261109-user-approval.md" },
  "created_at": "2026-11-09T10:00:00Z",
  "updated_at": "2026-11-09T10:30:00Z"
}
```

- `status`: `active` / `paused` / `completed` / `abandoned`
- `task_id` 格式：`task-YYYYMMDD-<slug>`（slug 为 ASCII kebab-case；中文目标取拼音或英文意译）
- 同日同名冲突由 `mkdir` 失败检测，追加 `-2`、`-3`
- `skills[]` 已废弃：历史任务保留读取，新任务不写（执行历史以 timeline 为准）；`touch` 只刷新 `updated_at`
- `touch` / `set-status` 对同一 Task 的 `meta.json` 做 mkdir 互斥（`.meta.lock`），
  「同一 Task + 不同 Skill」允许并行，但不能丢更新

## Task Resolution（Discovery 第 0 步，所有 Skill 强制）

> 这是这次改造的关键：文件按任务分开了，还必须让 Skill 知道**这次是哪个任务**。

Task Resolution 的**只读解析**在 Discovery 最开始执行，先于 Context Resolver 和任何文件读取；
**运行登记**（第 6 步）在用户确认本阶段输入之后执行。

```
1. 显式指定：用户/调用方给了 task_id（$PS_TASK_ID 或参数）→ 先校验存在且 status 可恢复
2. 恢复意图：用户说「继续 X」「resume X」→ task-registry.sh list 匹配 goal 关键字
3. 单活动任务 + 请求目标与它的 goal 一致 → 使用它（打印一行确认，不阻塞）
4. 单活动任务 + 请求目标明显是另一件事 → **不得自动接管**：
   AskUserQuestion「继续 <旧 goal> / 新建任务」
5. 多活动任务：列出 active 任务（id + goal + 最后活跃时间）→ AskUserQuestion 选择（含「新建」）
6. 无活动任务：
   - planner / analyzer 等能定义任务的 Skill → 记下 goal / slug，由随后的
     `runtime-run.sh start --new-task --goal ...` 创建（**不在 Task Resolution 里直接 `task-registry.sh create`**）
   - 其他 Skill（generator/tester/reviewer/refactorer/documenter/releaser）
     → 记下 `--slug "<skill>-<timestamp>"` 的回退 goal，由 `start --new-task --goal ...` 创建，
       并在收尾报告中标注 "⚠️ 无上游任务，已自动建任务 <task_id>"
7. 用户确认本阶段输入后 → runtime-run.sh start（创建/恢复 Run + 单写者锁 + 运行指针）
   - 恢复旧任务 → `--task-id <id>`
   - 确认新建 → `--new-task --goal ...`
   - **Runtime 不会自动选择任务**：既不给任务身份也不给 `--new-task` 时直接拒绝（exit 2）
```

> **单一 active 任务 ≠ 当前用户意图。** 自动接管只在「请求目标与任务 goal 一致」时成立；
> 昨天留下一个没关的「重构权限模块」，不能成为今天「分析订单模块」被接上去的理由。
> 判断不了是否同一件事 → 问，按第 4 / 5 步处理。
> 同一个确认规则适用于 Analyzer 与 Planner，两者不得一个有确认、一个静默接管。

**禁止**：扫描到哪个任务目录就用哪个；按修改时间猜测；在未解析出 task_id 时写入任何任务级文件；
在 Skill Discovery 之外（Hook / 宿主事件）创建 Task / Run。

> **Task Resolution 是唯一解析入口，`runtime-run.sh start` 是唯一登记入口。**
> 前 1–6 步只读；第 7 步（用户确认本阶段输入后）才由 Discovery 调用 `start` 创建/恢复 Run。
> 这样 Hook 不需要、也无法猜「用户最终选了哪个任务 / 什么范围」，不会落 `Run <skill>` 脏任务。

### 不持有 Task Run 的 Skill（Task-scoped Dispatcher）

`pipeline-orchestrator` 是 **Dispatcher 类** Skill：它协调多个 Skill 的生命周期，
本身**不创建自己的 Run**（没有属于它的 `start` / 运行指针 / 锁）。因此它：

- **不调用 `runtime-run.sh start`**；在 `VALID_SKILLS` 之外，`start --skill pipeline-orchestrator`
  会被拒绝（`未知 skill`）。
- **但必须绑定一个目标 `task_id`**：恢复已有任务由用户选定；新 Pipeline 在用户确认 goal 后
  调用 `task-registry.sh create`（只建 Task，不建 Run）。绑定结果通过 `PS_TASK_ID` 传给
  后续所有 Skill。
- 写编排产物 `runtime/tasks/<task_id>/pipeline-state.json` / `pipeline-report.md`；
  作为 Dispatcher 串行提交根 `state.json`。

其他 Skill 一律按上面的 Task Resolution 登记自己的 Run。新增 Skill 时先回答
「它有没有一个属于自己的 Run」——没有就按 Dispatcher 类处理，但仍要明确它绑定哪个 Task，
不要为了通过模板检查硬造一个 Run。

### 显式 override

```
PS_TASK_ID=task-20261109-order-mgmt /project-generator
```

优先级最高，用于脚本/子 agent/CI。

## 生命周期

| 事件 | 动作 |
|------|------|
| 任务开始 | `runtime-run.sh start`（内部 `task-registry.sh create`）→ 创建目录 + meta.json + Run |
| Skill 执行 | `touch <task_id>` 刷新 updated_at（执行历史以 timeline 为准，不再维护 skills[]） |
| 用户暂停 | meta.status = `paused`；snapshot.status = `paused` |
| 任务完成 | **由编排方/用户显式** `task-registry.sh set-status <task_id> completed`；保留目录（审计用） |
| 废弃 | meta.status = `abandoned`；不删除（知识生命周期另有治理） |

> ⚠️ **单次 Skill 的 `runtime-run.sh finish` 不关闭任务。** 它只结束本次 Run
> （timeline + 释放锁 + 清运行指针），并 `touch` 刷新 `updated_at`。
> 如果 finish 自动把任务标成 `completed`，同一任务的后续 Skill 在 Task Resolution
> 时看不到 active 任务，会新建一个任务并切断 resume——「一个任务是多个 Skill 的集合」这层身份就丢了。
>
> 运行指针（`runtime/current-runs/<skill>.json`）记录 `ownerId` 与 `sessionId`。
> **正常启动的唯一调用者是 Skill Discovery**（Task Resolution 之后）；Hook 不创建 Task / Run，
> 只在 SessionEnd 做异常退出兜底。`start` 只在身份一致（同 task / owner / session）时幂等复用；
> 指针有 sessionId 而调用方没有 session 时，`start` / `finish` / `renew` 一律拒绝（fail-closed）；
> Claude Code 注入 `CLAUDE_CODE_SESSION_ID`，非 Claude 宿主必须显式 `--session-id`。

## 并发政策

> 协议决策：**同一项目下，不同 `task_id` 的独立任务允许并行执行**，包括同一个 Skill 在不同
> `task_id` 下的并行运行。运行指针与锁的实现迁移后置，不为了尚未支持的并行能力提前扩建 Runtime。

| 场景 | 协议决定 | 原因 |
|------|---------|------|
| 不同 Task、相同 Skill | 允许 | 任务级产物（snapshot / context-package / PLAN / 报告）按 task_id 隔离 |
| 不同 Task、不同 Skill | 允许 | 无依赖且写入范围不冲突 |
| 相同 Task、相同 Skill | 禁止同时运行 | 同一任务的同一执行职责不应重复写入 |
| 相同 Task、不同 Skill | 有条件允许 | 必须满足依赖关系已解除、写入范围不冲突 |
| 不同 Task、两个 Analyzer | 禁止 | 共同写项目级知识（graph / statistics / index / 根产物） |
| 不同 Task、两个 Releaser | 禁止 | 共同写版本号和 CHANGELOG |
| 不同 Task、同时改相同源码 | 有条件允许 | 文件范围不重叠，或使用独立 Git Worktree |

**Task 级隔离 ≠ 源码级隔离。** 两个 Planner 写不同 PLAN 没问题；两个 Generator 即使 PLAN
不同，也可能同时改同一个源文件。不能因为 `task_id` 不同就认为任意源码并发都安全。

**实现约束**（目标）：

- Run 身份由 `task_id + skill + run_id` 唯一确定；`renew` / `finish` 必须能唯一定位 Run，
  不能只传 `--skill` 就结束「同名 Skill 的某一个运行」。
- 运行指针按 `task_id + skill` 隔离：`runtime/current-runs/<task_id>/<skill>.json`。
- 锁绑定共享写入资源，而不是 Skill 身份（见 [single-writer.md](single-writer.md)）。
- SessionEnd 只收尾当前 Session 拥有的 Run。

**当前实现限制**：`runtime-run.sh` 仍使用按 skill 单槽的运行指针与锁
（`current-runs/<skill>.json`），因此「同一 Skill、不同 Task 并行」**尚未生效**——后启动的
`start` 会复用或拒绝。迁移完成前，不得把该场景视为已支持；验收测试见
`check-task-isolation.sh` 的并发用例。

归档/清理不在本协议内——任务目录是审计证据，删除属于人工治理。

## 与并发的关系

task_id 解决**数据分区**，不解决**同一文件的并发写**：

| 场景 | task_id 是否解决 |
|------|----------------|
| 两个任务各自写 session/context/snapshot | ✅ 路径分离 |
| 不同 Task 的同一 Skill 并行（如两个 Planner） | ✅ 协议允许，产物路径分离；⚠️ 当前运行指针仍按 skill 单槽，实现未生效 |
| 两个任务同时追加 state.json history | ❌ 最后写入者覆盖 → 见下 |
| 两个任务同时改同一个源文件 | ❌ task_id 不隔离源码 → 文件范围不重叠或独立 Worktree |
| 两个 Analyzer 重建项目知识 | ❌ task_id 救不了 → 单写者锁 |
| 两个 Releaser 写版本号 / CHANGELOG | ❌ task_id 救不了 → 单写者锁 |

### state.json / timeline.jsonl 的写入纪律

- `history[]` 每条必须带 `task_id`；`current` 改为 `active_tasks`（见 [state.md](../state/state.md)）。
- 根 `state.json` **只由 Dispatcher 串行提交**（用户一次推进一个任务）。Skill 的执行进度写任务级
  `.sessions/<task_id>/<skill>/state.json`，终态写 timeline；并行任务**不得直接读改写根 `state.json`**。
  串行提交意味着不需要乐观并发字段：没有多个 Dispatcher 同时写，就不预先维护版本号协议。
- `timeline` 已改为 append-only `timeline.jsonl`（`O_APPEND` 单次追加，底层写入器 `shared/scripts/timeline-append.sh`）。它解决的是**追加不丢行**；每行用 `taskId` 归属任务，`runId` 保持每次运行唯一。读取方（`collect-metrics.sh`）在读取时聚合，不存储 `aggregates`。
- **运行时的唯一入口是 `runtime-run.sh`**：`start` 写运行指针并加锁，`finish` 追加终态行并释放锁。直接调 `task-registry.sh` / `writer-lock.sh` / `timeline-append.sh` 只用于诊断或宿主 hook，不作为 Skill 的常规路径。

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
