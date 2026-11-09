# Single Writer v1.0

> 项目级真相（project-level truth）同一时刻只能有一个写者。
> 这不是并发优化，是数据完整性约束——task_id 分区救不了同一文件的两个写者。

## 哪些写者需要单写者约束

| 写者 | 写的文件 | 为什么必须单写 |
|------|---------|--------------|
| **project-analyzer** | `graph.json` `statistics.json` `context.json` `search-index.json` `manifest.json` `index.md` + `architecture/` `components/` `api/` `patterns/` | 每次扫描 `Always` 全量重建；两个 Analyzer 会互相抹掉对方的结果，且都声明 completed |
| **project-releaser** | 版本号 / `CHANGELOG.md` | 双写会产生重复版本号或丢条目 |
| 其他 Skill | `state.json` `knowledge.json` | 见 [task-identity.md](task-identity.md) 的写入纪律；默认单 Dispatcher |

**不需要锁**：任务级文件（session / context-package / snapshot / pipeline-state）。它们的路径已按 `task_id` 分开。
`runtime/metrics/timeline.jsonl` 也不需要锁——它是 append-only（`timeline-append.sh` 单次 `O_APPEND`，不读改写，聚合读取时计算）；**回到读改写就重新需要单写者**。

## 锁协议

通过 `shared/scripts/writer-lock.sh` 获取，不在 prompt 里手写 shell：

```
bash shared/scripts/writer-lock.sh <knowledge-dir> <writer-name> acquire [--owner-id <id>] [--ttl-seconds 3600]
bash shared/scripts/writer-lock.sh <knowledge-dir> <writer-name> release --owner-id <id>
bash shared/scripts/writer-lock.sh <knowledge-dir> <writer-name> status
bash shared/scripts/writer-lock.sh <knowledge-dir> <writer-name> break --owner-id <id>
```

- 锁目录：`<knowledge-dir>/.locks/<writer-name>.lock/`（`mkdir` 原子创建）
- `owner.env`：`owner_id` / `pid` / `hostname` / `started_at` / `ttl_seconds`
- **退出即释放**：Skill 在每个退出路径（completed / degraded / blocked / 用户取消）都必须 `release`
- TTL 默认 3600s；超过 TTL 视为 stale，`acquire` 会报告 stale owner 并拒绝，除非显式 `break`
- **不要用 pid 判活**：锁的持有者是 Skill 会话，不是拉起脚本的短命 shell 进程——`acquire` 退出后 pid 就消失了

## Analyzer 的接入点

| 阶段 | 动作 |
|------|------|
| Discovery | `acquire analyzer`；失败 → 🟡 DEGRADED，展示当前 owner + started_at，让用户决定「等待 / 强制接管(break) / 取消」 |
| Execution → Delivery | 持有锁；每次 checkpoint 前 `status` 校验 owner 仍是自己（防止被 break 后继续写） |
| Delivery 结束 | `release` |
| 异常退出 | 下次 acquire 检测到 stale（TTL 超时或 pid 不存在）→ 提示接管 |

> 为什么 Analyzer 不能靠 task_id：它写的是**项目级知识**，不是任务产物。两个任务扫描同一项目，产出的 graph/statistics 是同一份真相。

## 失败兜底

| 情况 | 行为 |
|------|------|
| 锁被占用且 owner 存活 | 不写入，输出 BLOCKED + owner 信息 |
| 锁 stale（超 TTL） | 提示可 `break`，不自动抢 |
| 无法创建 `.locks/`（权限） | 🟡 DEGRADED：继续执行，但在收尾报告标注 `⚠️ 未获单写者保护` |
| 用户明确要求并行扫描 | 拒绝——拆分扫描范围不是并行写同一份知识库的理由 |
