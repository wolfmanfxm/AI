# Knowledge Health Protocol v1.0.0

> 知识库质量检测。analyzer 增量模式自动扫描 `.project-knowledge/`，发现重复、过期、断裂引用、空文档。
> 让知识库越来越干净，而非越来越大。

## 定位

```
knowledge-index.json  → 哪些 capability 可用
knowledge.json        → 每个文件的生命周期状态
knowledge-health.json → 哪些文件有质量问题（NEW v1.3.0）
```

## 文件位置

`.project-runtime/metrics/knowledge-health.json`

## Schema

```json
{
  "schemaVersion": "1.0.0",
  "generatedBy": "project-analyzer",
  "generatedAt": "2026-07-30T14:00:00Z",
  "mode": "incremental",

  "summary": {
    "totalFiles": 42,
    "healthyFiles": 35,
    "issuesTotal": 7,
    "bySeverity": {
      "error": 1,
      "warning": 3,
      "info": 3
    }
  },

  "issues": [
    {
      "id": "KH-001",
      "severity": "error",
      "type": "broken_link",
      "file": "architecture/overview.md",
      "location": "line 42",
      "detail": "引用 components/catalog.md 但该文件不存在",
      "brokenRef": "components/catalog.md",
      "suggestion": "移除引用或恢复目标文件"
    },
    {
      "id": "KH-002",
      "severity": "warning",
      "type": "empty_document",
      "file": "api/legacy.md",
      "detail": "文件仅 86 bytes，只有 Evidence Header 无正文",
      "fileSize": 86,
      "suggestion": "补充内容或删除文件"
    },
    {
      "id": "KH-003",
      "severity": "warning",
      "type": "duplicate_content",
      "files": ["patterns/form.md", "patterns/dialog.md"],
      "detail": "标题和内容相似度 87%，疑似描述同一模式的不同方面",
      "similarity": 0.87,
      "overlappingSections": ["## 表单校验", "## 弹窗模式"],
      "suggestion": "合并为一个文件或明确分工边界"
    },
    {
      "id": "KH-004",
      "severity": "info",
      "type": "stale_reference",
      "file": "patterns/crud.md",
      "detail": "引用的 API 模块 `workspace/api/oldQuota.ts` 已不存在（30 天前删除）",
      "brokenRef": "workspace/api/oldQuota.ts",
      "lastSeen": "2026-06-30",
      "suggestion": "更新引用到当前 API 路径"
    },
    {
      "id": "KH-005",
      "severity": "info",
      "type": "orphan_knowledge",
      "file": "patterns/upload-legacy.md",
      "detail": "知识文件 90 天内未被任何 skill 读取（timeline.json 无引用记录）",
      "daysUnused": 90,
      "suggestion": "确认是否仍适用，考虑标记 Deprecated"
    },
    {
      "id": "KH-006",
      "severity": "warning",
      "type": "outdated_evidence",
      "file": "overview.md",
      "detail": "Evidence Header 记录 `generatedAt: 2026-04-01`，超过 90 天未刷新",
      "generatedAt": "2026-04-01",
      "daysSinceRefresh": 120,
      "suggestion": "执行增量分析刷新"
    }
  ],

  "trend": {
    "previousTotal": 9,
    "currentTotal": 7,
    "delta": -2,
    "resolvedSinceLastRun": ["KH-007", "KH-008"]
  }
}
```

## 检测类型

### error（阻断级 — 信息错误）

| 类型 | 检测方式 | 阈值 |
|------|---------|------|
| `broken_link` | 扫描 `.md` 中 `[text](path.md)` 引用 → 检查目标文件是否存在 | 任一不存在 |

### warning（应修 — 质量下降）

| 类型 | 检测方式 | 阈值 |
|------|---------|------|
| `empty_document` | `wc -c` | < 200 bytes |
| `duplicate_content` | 标题相似度（编辑距离 / 最长公共子串） | > 80% |
| `outdated_evidence` | Evidence Header `generatedAt` 距今 | > 90 天 |
| `missing_evidence_header` | 检查文件前 5 行是否有 Evidence Header | 不存在 |

### info（建议修 — 可积累）

| 类型 | 检测方式 | 阈值 |
|------|---------|------|
| `stale_reference` | 引用指向已删除的代码文件（对比 git log） | 代码文件已删除 |
| `orphan_knowledge` | timeline.json 中无该文件被读取的记录 | > 90 天 |
| `large_file` | `wc -l` | > 500 行 |

## 检测执行规则

### 全量模式（analyzer --mode full）

```
1. 扫描 .project-knowledge/ 所有 .md 文件
2. 执行全部 7 种检测
3. 生成全新的 knowledge-health.json
4. 无 trend 对比（首次或全量重置）
```

### 增量模式（analyzer --mode incremental）

```
1. 只扫描 manifest.json 中标记 [CHANGED] 的文件 + 其引用目标
2. 对变更文件执行 broken_link + empty_document + outdated_evidence
3. 对全量执行 duplicate_content（去重新增文件与已有文件的相似度）
4. 更新 knowledge-health.json：
   - 已修复的 issue → 从 issues[] 移除
   - 新发现的 issue → 追加
   - 未变化的 issue → 保留
5. 更新 trend（对比上次 run 的 total）
```

### 健康阈值

analyzer 在 Finish 阶段检查 summary：

```
summary.issuesBySeverity.error > 0:
  → 在 manifest.json 标注 ⚠️ "知识库存在断裂引用，建议修复后再进入下游"
  → 不阻断（error 只影响知识质量，不影响代码分析结果）

summary.issuesBySeverity.warning > 5:
  → 在 context.json 标注 ⚠️ "知识库健康度低（{N} warnings），下游 skill 注意验证"
```

## 与 timeline.json 的联动

`orphan_knowledge` 检测依赖 timeline.json：

```
for each file in .project-knowledge/:
  search timeline.json runs[].input.knowledgeFilesRead
  if file not found in any run within 90 days:
    → orphan_knowledge
```

这要求 timeline.json 中至少 1 个 run 记录了 `input.knowledgeFilesRead`。

## 查询能力

```
"知识库有哪些断裂引用？"
→ knowledge-health.json → issues[type=broken_link]

"最近健康度在改善还是恶化？"
→ trend.delta（负数=改善，正数=恶化）

"哪些文件该退休了？"
→ issues[type=orphan_knowledge] + issues[type=outdated_evidence]

"有没有两个人在写同一件事？"
→ issues[type=duplicate_content]
```
