# Error Recovery

> 所有 skill 共享的异常分类与恢复策略。skill 遇到异常时遵循本协议，不自行发明处理逻辑。

## 异常分级

| 级别 | 定义 | 示例 |
|------|------|------|
| **WARNING** | 可自动修复，不阻塞执行 | 文件不存在重试后找到、编码格式自动转换 |
| **DEGRADED** | 自动降级，部分功能不可用 | 某子任务失败，其他子任务继续、置信度降低 |
| **BLOCKED** | 需用户决策，skill 暂停 | 项目名未知、关键目录找不到、权限不足 |
| **FATAL** | 不可恢复，skill 终止 | 磁盘满、核心文件损坏 |

## 恢复策略矩阵

### WARNING

```
策略：自动修复 → 记录日志 → 继续执行
示例：package.json 不在根目录 → 向上一级搜索 → 找到后继续
```

### DEGRADED

```
策略：标记降级 → 写 partial 结果 → 继续其余子任务 → manifest status = partial
示例：某维度 agent 超时 → 主 agent 用已有数据合成 → 标注置信度 < 50
```

### BLOCKED

```
策略：写 checkpoint → AskUserQuestion → 等待用户响应 → 恢复执行
示例：无法推断框架 → 询问用户 → 用户选择后继续
```

### FATAL

```
策略：写 checkpoint → 报告错误详情 → manifest status = interrupted → 终止
示例：磁盘满无法写入 → 告知用户 → 等待手动修复后 resume
```

## 异常恢复决策树

```
异常发生
  ├─→ 能自动修复？      → YES → WARNING → 自动修复 → 继续
  ├─→ 能降级执行？      → YES → DEGRADED → 标记降级 → 继续其余
  ├─→ 能用默认值替代？  → YES → BLOCKED（低优，给默认选项）→ AskUserQuestion
  ├─→ 必须用户决策？    → YES → BLOCKED → 写 checkpoint → AskUserQuestion
  └─→ 无法恢复？        → YES → FATAL → 写 checkpoint → 终止
```

## 子任务级异常

单个子任务失败时：

1. 不阻塞其他子任务（无依赖前提下）
2. 子任务状态标记为 `failed`
3. manifest 记录失败原因
4. 其他子任务继续执行
5. 最终状态：若全部 completed → `completed`，若有 failed → `partial`

## 与 analyzer 原有协议的关系

替代 `project-analyzer/references/exceptions.md` 和 `project-analyzer/protocol/runtime-protocol.md` 中的 Failure Contract 部分。
