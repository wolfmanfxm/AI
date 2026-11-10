# Single Writer v2.0

> **锁绑定共享写入资源，不是 Skill 身份。** 项目级真相同一时刻只能有一个写者。
> 这不是并发优化，是数据完整性约束——task_id 分区救不了同一文件的两个写者。

## 哪些写者需要单写者约束

| 共享资源 | 写者 | 为什么必须单写 |
|---------|------|--------------|
| 项目级知识：`graph.json` `statistics.json` `context.json` `search-index.json` `manifest.json` `index.md` + `architecture/` `components/` `api/` `patterns/` | **project-analyzer** | 每次扫描 `Always` 全量重建；两个 Analyzer 会互相抹掉对方的结果，且都声明 completed |
| 知识生命周期：`knowledge.json` | **project-analyzer**（Finish 写入）+ **project-reviewer**（Candidate 验证后更新） | 两个真实 Producer 读改写同一状态文件，会丢条目或把 Verified 覆盖回 Candidate |
| 版本号 / `CHANGELOG.md` | **project-releaser** | 双写会产生重复版本号或丢条目 |
| `state.json`（执行状态权威） | **Dispatcher**（串行提交） | 并行 Skill 各自读改写会丢 history；Skill 只写任务级 snapshot + timeline |

**不需要锁**：任务级文件（session / context-package / snapshot / pipeline-state）路径已按
`task_id` 分开。`runtime/metrics/timeline.jsonl` 也不需要锁——它是 append-only
（`timeline-append.sh` 单次 `O_APPEND`，不读改写，聚合读取时计算）；**回到读改写就重新需要单写者**。

> **当前实现（待收敛）**：`runtime-run.sh start` 仍按 skill 派生锁名——`project-analyzer`
> 与 `project-reviewer` 共用 `analyzer` 锁（它们都写项目级知识 / `knowledge.json`），
> 其余 skill 用完整名。后者只是**执行串行化**，不是资源锁；它带来的唯一影响是
> 「同一 skill、不同 task」暂时无法并行（协议已允许，实现后置）。
> 收敛方向：锁只按共享资源命名，不按 skill 命名。

## 锁协议

通过 `shared/scripts/writer-lock.sh` 获取，不在 prompt 里手写 shell：

```
bash shared/scripts/writer-lock.sh <knowledge-dir> <writer-name> acquire [--owner-id <id>] [--ttl-seconds 3600]
bash shared/scripts/writer-lock.sh <knowledge-dir> <writer-name> renew   --owner-id <id> [--ttl-seconds 3600]
bash shared/scripts/writer-lock.sh <knowledge-dir> <writer-name> release --owner-id <id>
bash shared/scripts/writer-lock.sh <knowledge-dir> <writer-name> status [--expect-owner <id>]
bash shared/scripts/writer-lock.sh <knowledge-dir> <writer-name> break --force [--expect-owner <id>]
```

`status` 退出码：`0` 已锁且（若给了 `--expect-owner`）owner 一致、`2` stale（owner 一致或未指定）、
`3` owner 不一致（**先于 stale 判定**）、`4` 未锁。`break` 缺 `--force` 时返回 `3`，不删锁。

- 锁目录：`<knowledge-dir>/.locks/<writer-name>.lock/`（`mkdir` 原子创建）
- `owner.env`：`owner_id` / `pid` / `hostname` / `started_at` / `ttl_seconds` / `renewed_at` / `renewed_epoch`
- **退出即释放**：Skill 在每个退出路径（completed / degraded / blocked / 用户取消）都必须 `release`
- TTL 默认 3600s；`renew` 从续租时刻重新计时。超过 TTL 视为 stale，`acquire` 会报告 stale owner 并拒绝，除非显式 `break --force`
- **长任务必须续租**：每个 checkpoint 调用一次 `runtime-run.sh renew <root> --skill <name>`；不引入后台心跳进程
- **不要用 pid 判活**：锁的持有者是 Skill 会话，不是拉起脚本的短命 shell 进程——`acquire` 退出后 pid 就消失了
- **Session 身份 fail-closed**：运行指针记录 `sessionId`；指针有 sessionId 而调用方没有 session 时，
  `finish` / `renew` / `start` 一律拒绝。Claude Code 注入 `CLAUDE_CODE_SESSION_ID`（旧名
  `CLAUDE_SESSION_ID` 仅作兼容）；非 Claude 宿主必须显式传 `--session-id`

> ⚠️ **Skill 运行不要直接调本脚本**：用 `shared/scripts/runtime-run.sh start|finish`。
> 它把「任务解析/创建 + 锁 + 运行指针 + 终态 timeline」绑成一个幂等生命周期；
> 直接 `acquire` 再分头 `timeline-append` 会得到与 start 不一致的 runId，且容易漏掉失败/取消路径。
> `writer-lock.sh` 是这层之下的机制脚本（Host hook、诊断、人工接管时使用）。

## 所有权不变式（指针 owner == 真实锁 owner）

运行指针（`runtime/current-runs/<skill>.json`）里的 `ownerId` 只是**声明**；锁目录里的
`owner.env` 才是**事实**。两者不一致意味着锁曾被 `break` 后被他人接管，或者指针是旧的——
此时任何"复用/收尾/写入"都会把别人的运行当成自己的。

| 场景 | 行为 |
|------|------|
| `start` 复用已有运行的 pointer | 指针 owner/session 匹配后，还要求**真实锁 owner 与指针 owner 一致**；不一致 → `LOCK=occupied`，拒绝复用（`runtime-run.sh` 用 `status --expect-owner` 校验） |
| `start` 新建任务但获锁失败 | 新建的 Task 立即 `set-status abandoned`，不留孤儿任务（失败时明确提示手动兜底） |
| `start` 命中 `paused` 任务 | 获锁成功后自动转回 `active`；`completed` / `abandoned` 任务拒绝普通恢复 |
| `finish` 写终态前 | 指针 owner 与真实锁 owner 不一致 → 拒绝写 `completed`，保留指针让人确认现场。**顺序固定**：验 owner → 释放自己的锁 → 追加终态 → 删指针；释放失败即中止，绝不先写 completed |
| Host hook 放行 `Write/Edit` | 运行指针存在时，除 session 校验外还要求锁仍被持有且 owner 与指针一致；有锁无指针 → 拒绝（无法确认写入者） |

> 指针可以比锁"活得久"（锁 stale 或被人 break），但反过来不行：**写终态和落盘必须同时证明两者属于自己**。

## Analyzer 的接入点

| 阶段 | 动作 |
|------|------|
| Discovery | `runtime-run.sh start <root> --skill project-analyzer`（内部 acquire `analyzer`）；失败 → 🔴 BLOCKED（exit 1/2），展示当前 owner + started_at，让用户决定「等待 / 强制接管(break --force) / 取消」 |
| Execution → Delivery | 持有锁；每个 checkpoint 前 `runtime-run.sh renew <root> --skill project-analyzer`（内部校验 session/owner 并续租）；失败 → 停止项目级写入 |
| Delivery 结束 | `runtime-run.sh finish <root> --skill project-analyzer --status ...`（内部 release；锁被别的 owner 持有时保留运行指针并报错） |
| 异常退出 / hook 收尾 | `runtime-run.sh finish --skill <name> --session-id <id> --auto-finalized`（记 degraded；只收本 session 的指针；无 sessionId 的旧指针不自动收尾） |

> 为什么 Analyzer 不能靠 task_id：它写的是**项目级知识**，不是任务产物。两个任务扫描同一项目，产出的 graph/statistics 是同一份真相。

## Reviewer 的接入点

Reviewer 会更新 `knowledge.json`（Candidate 验证后的状态），是 `knowledge.json` 的第二个真实
Producer，因此与 Analyzer 共用同一把 `analyzer` 锁：

| 阶段 | 动作 |
|------|------|
| Discovery | `runtime-run.sh start <root> --skill project-reviewer ...`（内部 acquire `analyzer`）；Analyzer 正在跑 → exit 1，🔴 BLOCKED |
| Execution → Validation | 持有锁；写 `knowledge.json` 前确认锁仍在；每个 checkpoint `runtime-run.sh renew <root> --skill project-reviewer` |
| 收尾 | `runtime-run.sh finish <root> --skill project-reviewer --status ...`（内部 release） |

> 若将来把 `knowledge.json` 的写入收敛为单一 Producer（例如 Reviewer 只产出验证报告、
> 由 Analyzer 统一落盘），再取消共享锁；**在此之前不能假设 Reviewer 是只读的**。

## 失败兜底

| 情况 | 行为 |
|------|------|
| 锁被占用且 owner 存活 | 不写入，输出 BLOCKED + owner 信息 |
| 锁 stale（超 TTL） | 提示可 `break --force`，不自动抢 |
| 无法创建 `.locks/`（权限） | 🔴 BLOCKED：无法建立互斥就不得写项目级知识；报错并让用户修复权限或显式接管 |
| 用户明确要求并行扫描 | 拒绝——拆分扫描范围不是并行写同一份知识库的理由 |
