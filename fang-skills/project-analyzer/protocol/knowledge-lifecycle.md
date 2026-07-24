# Knowledge Lifecycle Protocol

知识文件随时间演进的状态机。由每次 Analysis Flow 执行时检查和更新。

## 状态机

```
Draft ──→ Confirmed ──→ Deprecated ──→ Archived ──→ Deleted
  │           │              │
  └───────────┴──────────────┘
         可回退到 Draft
```

| 状态 | 含义 | 触发条件 |
|------|------|---------|
| Draft | 首次生成，未经二次确认 | 首次分析产出 |
| Confirmed | 经多次分析确认，内容稳定 | 连续 2 次分析未发生显著变化 |
| Deprecated | 内容已过时，但仍有参考价值 | 对应源码已删除 / 引用归零 / 模式不再出现 |
| Archived | 移入 `archive/`，仅保留历史记录 | Deprecated 后经过 2 个分析周期 |
| Deleted | 永久删除 | Archived 后经过 2 个分析周期，或用户手动删除 |

## 状态转换规则

### Draft → Confirmed

- 条件：连续 2 次分析中该文件均被生成（或被引用）
- 标记：文件 Evidence Header 中 `lifecycle: confirmed`
- 首次分析全部产出为 Draft，第二次分析时确认

### Confirmed → Deprecated

- 条件（任一）：
  - 组件引用计数降至 0（如 `BigFileUpload`）
  - 对应源码目录被删除（如某个 view 模块被移除）
  - Pattern 在最近 2 次分析中不再出现
- 标记：文件 Evidence Header 中 `lifecycle: deprecated`，文件中添加 `> ⚠️ Deprecated` 首行
- 不自动删除：保留供人工审查

### Deprecated → Archived

- 条件：Deprecated 后经过 2 次分析周期，用户未恢复
- 操作：文件移动到 `.project-knowledge/archive/`，保留目录结构
- 标记：`lifecycle: archived`

### Deprecated → Confirmed（恢复）

- 条件：用户在 `rules/` 中标记"保留"或源码被恢复
- 操作：恢复为 Confirmed 状态

### Archived → Deleted

- 条件：Archived 后经过 2 次分析周期
- 操作：永久删除文件
- 之后：再次分析时不再生成该文件

### 任何状态 → Draft（回退）

- 条件：知识文件被检测到与源码显著不符，但源码存在
- 操作：标记为 Draft，下次分析重新确认

## 文件分类与生命周期策略

| 文件类型 | 策略 | 说明 |
|---------|------|------|
| `architecture/overview.md` | 永久 Confirmed | 架构总览不废弃，只更新 |
| `components/catalog.md` | 组件级生命周期 | 每个组件条目独立跟踪 |
| `patterns/crud.md` | Pattern 级生命周期 | Pattern 不再出现则 Deprecated |
| `observations/statistics.md` | 每次覆盖 | 不参与生命周期，纯数据报告 |
| `rules/` 目录 | 不参与 | 人工维护，永不自动修改 |

## 组件引用的生命周期跟踪

对 `components/catalog.md` 中的每个组件条目：

```
第N次分析：ComponentA refs=58
第N+1次分析：ComponentA refs=58 → (不变) → Draft → Confirmed
第N+2次分析：ComponentA refs=0  → Deprecated，标注 ⚠️
第N+3次分析：ComponentA refs=0  → (仍为0) → Deprecated 持续
第N+4次分析：ComponentA refs=0  → (满2周期) → Archived
第N+5次分析：ComponentA 已归档 → (满2周期) → Deleted
```

引用计数短暂归零后恢复（如重构期间）→ 回退到 Draft 重新确认。

## 与 Overwrite Policy 的关系

| Overwrite Policy | 生命周期 |
|-----------------|---------|
| 自动覆盖 | 每次分析更新文件内容，同时检查状态转换 |
| 永不覆盖 | `rules/` 等人工目录不参与生命周期 |

生命周期是对 Overwrite Policy 的补充：Overwrite 定义了"能不能覆盖"，Lifecycle 定义了"覆盖之外还要做什么"（标记 Deprecated、移动 Archive、删除）。
