# Checkpoint Protocol

> 断点续传协议。所有 skill 在批量执行子任务时遵循本协议，确保中断后可恢复。

## Manifest 结构

每个 skill 维护自己的 `manifest.json`，存储执行状态：

```json
{
  "skillVersion": "0.1.0",
  "schemaVersion": "1.0.0",
  "status": "in_progress",
  "generatedBy": "<skill-name>",
  "generatedAt": "2026-07-27T10:00:00Z",
  "lastCheckpoint": "2026-07-27T10:15:00Z",
  "projectName": "my-project",
  "gitCommit": "abc1234",
  "subtasks": [
    {
      "id": "task-1",
      "name": "analyze-architecture",
      "status": "completed",
      "files": ["architecture/overview.md"],
      "confidence": 95
    },
    {
      "id": "task-2",
      "name": "catalog-components",
      "status": "pending",
      "files": [],
      "confidence": null
    }
  ],
  "fixedOutputs": ["manifest.json", "statistics.json", "index.md"]
}
```

## Checkpoint 规则

### 何时写 Checkpoint

1. **子任务完成后立即写** — 避免已完成工作丢失
2. **token 预警时** — 剩余 token < 20% 时，完成当前子任务后写 checkpoint 并暂停
3. **用户触发暂停** — 用户说"暂停"/"等一下"时写 checkpoint

### 写入策略

```
子任务完成 → 更新 manifest.subtasks[i].status = "completed"
           → 更新 manifest.lastCheckpoint = now
           → 写入文件（原子覆盖）
```

### 恢复策略

```
读 manifest → 过滤 status = "completed" 的子任务（跳过）
           → 过滤 status = "in_progress" 的子任务（重试，文件可能不完整）
           → 按序执行 status = "pending" 的子任务
```

## 子任务并行与依赖

### 无依赖子任务 → 并行

```
Wave 0: task-A  task-B  task-C    (3 个独立任务，并行执行)
```

### 有依赖子任务 → 分波

```
Wave 0: task-A                       (无依赖)
Wave 1: task-B  task-C               (依赖 task-A)
Wave 2: task-D                       (依赖 task-B + task-C)
```

每波完成后写 checkpoint，下一波开始前检查上一波是否全部 completed。

## 文件完整性保证

1. 每个子任务在写文件前，先创建临时文件（`<filename>.tmp`）
2. 文件写完后验证（非空、可解析）
3. 验证通过后 rename 覆盖正式文件
4. 所有文件写入完成后更新 manifest
5. 恢复时忽略 `.tmp` 文件

## 与 analyzer 原有协议的关系

替代 `project-analyzer/protocol/runtime-protocol.md` 中的 manifest 状态机和 Failure Contract 部分。
