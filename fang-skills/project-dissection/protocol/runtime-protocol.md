# Runtime Protocol

## Operating Mode

Production · Deterministic · Incremental OK · Dev OK
Goal: Generate stable, reusable project knowledge.

## Resource Boundaries

> 以下为执行建议，非强制保证。随 context 演进自行调整。

### 行为原则

| 原则 | 说明 |
|------|------|
| 优先并行分析 | 无依赖的维度并行执行 |
| manifest 存在时避免全量扫描 | 非首次运行优先增量 |
| 优先增量更新 | 增量模式回退全量前先尝试 git diff 范围 |
| 跳过大型二进制文件 | PDF/图片/视频等不参与文本分析 |
| 不扫描构建产物 | 跳过 `node_modules/` `dist/` `.git/` 等 |
| 遵循 ignore 文件 | 遵循 `.gitignore` 排除规则 |
| 非必要不读取 vendor 依赖 | `node_modules/` 中的代码不分析 |

### 项目规模自适应策略

```
小型项目               中型项目               大型项目
(<200 源文件)          (200-800 源文件)       (>800 源文件)
    │                      │                      │
    ▼                      ▼                      ▼
 单次扫描               并行                  增量
 主 agent 直接扫描      维度 agent 并行       优先增量 + 变更维度
 不 spawn 子 agent      按需 spawn            仅变更模块全量重扫
```

> 阈值基于源码文件数（排除 `node_modules/` `dist/` `.git/`）。首次运行用 `find . -type f \( -name "*.vue" -o -name "*.ts" -o -name "*.tsx" -o -name "*.js" \) ! -path "*/node_modules/*" ! -path "*/dist/*" | wc -l` 判断。

---

## manifest 状态机

```
confirmed → in_progress → completed
                ↓              ↑
             partial ──────────┘ (resume)
                ↓
           interrupted ────────┘ (resume)
```

- `confirmed`：Phase 1 完成，尚未开始执行
- `in_progress`：至少一个维度 agent 已启动
- `partial`：token 耗尽或超时，部分维度已完成
- `interrupted`：外部中断（用户取消 / session 丢失）
- `completed`：所有维度完成，固定产出已生成

schemaVersion 主版本号变化表示破坏性变更。knowledgeVersion 仅全量刷新时递增。

---

## Failure Contract

### 若架构无法推断

→ 输出部分知识，推断章节标注 `confidence: <50`。
  manifest 标记 `status: partial`，列出缺失维度。

### 若分析中途 token 耗尽

→ 立即持久化所有已完成章节文件。
  manifest 更新各维度状态（`completed` / `pending` / `partial`）。
  下次运行读 manifest → 从第一个 `pending` 维度恢复。

### 若分析被中断

→ manifest 状态更新为 `interrupted`。
  恢复时：读 manifest，跳过 `completed` 维度，重新执行 `pending`。
  已写入文件保留。

### 若某维度 agent 失败

→ 主 agent 从部分数据合成产出，标记 `⚠️ 子agent超时，数据由主agent补充`。
  不阻塞其他维度。
