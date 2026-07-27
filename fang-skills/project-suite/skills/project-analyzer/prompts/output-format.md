# Output Format Specification

## 通用规则
1. Markdown + YAML Frontmatter（分析产出用 `.md`，元数据用 `.json`）
2. 源文件引用 `file:line` 格式
3. 从源文件复制实际代码，不编造
4. 中文为主体描述，代码原文

## Evidence Header

每个 `.md` 文件必须包含：

```yaml
---
id: component-search-form
generatedBy: analyzer
generatedAt: 2026-07-24T14:00:00Z
last_scan: 2026-07-24T14:00:00Z
lifecycle: draft
confidence: 98
sources:
  - src/components/SearchForm.vue
  - src/views/user/list.vue
---
```

**字段说明**：

| 字段 | 含义 | 必填 |
|------|------|------|
| `id` | 文档唯一标识 | 是 |
| `generatedBy` | 生成工具，固定 `analyzer` | 是 |
| `generatedAt` | 首次生成时间 | 是 |
| `last_scan` | 最后校验时间。增量扫描确认内容仍然准确但无需修改时更新此字段 | 是 |
| `lifecycle` | 生命周期状态：`draft` / `confirmed` / `deprecated`（与 [../../shared/templates/evidence-header.md](../../shared/templates/evidence-header.md) 一致）| 是 |
| `confidence` | 置信度，见下方分级 | 是 |
| `sources` | 证据源文件列表 | 是 |

**confidence 分级**：

| 范围 | 含义 | 示例 |
|------|------|------|
| 90-99 | 统计事实 | "SchemaTable 引用 569 次" |
| 70-89 | 模式推断 | "项目使用 Schema 驱动模式" |
| 50-69 | 人工标注 | 人工补充的经验 |

## 固定产出结构

```
.project-knowledge/
│
├── manifest.json                # 元数据（knowledgeVersion, skillVersion, gitCommit）
├── statistics.json              # 仪表盘数据（组件/API/模式/质量指标）
├── graph.json                   # 结构化关系图谱（节点+边）
├── search-index.json            # 关键词→文件检索索引
├── index.md                     # 人类导航入口
│
├── architecture/                # 架构
├── components/                  # 组件
├── api/                         # API
├── patterns/                    # 模式（UI + 编码 + 可复用模式）
├── observations/                # 观察数据
├── proposals/                   # 候选规范
├── reports/                     # 报告（含 changelog）
│
├── rules/                       # 人工
├── experience/                  # 人工
├── playbooks/                   # 人工
└── decisions/                   # 人工
```

- 元数据 JSON 每次必定生成
- 目录初次运行时全部创建
- 各目录下按分析发现动态创建 `.md` 文件，有内容才建
- `rules/` `experience/` `playbooks/` `decisions/` 仅创建 index.md
