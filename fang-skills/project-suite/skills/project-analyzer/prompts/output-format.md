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
| `lifecycle` | 生命周期状态：`draft` / `confirmed` / `deprecated`（与 [../../../shared/templates/evidence-header.md](../../../shared/templates/evidence-header.md) 一致）| 是 |
| `confidence` | 置信度，见下方分级 | 是 |
| `sources` | 证据源文件列表 | 是 |
| `constraint` | 一句可执行的硬约束。**仅 `rules/` 与 `decisions/` 下必需**——这些目录的 Producer 是人（见下「固定产出结构」注），但 Compiler 对其**硬校验**：缺 `constraint` 即 `exit 1`，不生成 `knowledge-index.json`，整条知识链中断 | rules/decisions 是，其余不需要 |
| `statement` | 一句可被直接注入的 convention/pattern 摘要。**仅 `patterns/` `components/` `api/` 下必需** | patterns/components/api 是，其余不需要 |

### `statement` —— patterns / components / api 必需

Resolver hydrate 时**直接抽 `statement` 注入** `context-package.json`，Generator 因此不必读文件正文。
缺了它**不报错**，Resolver 静默退化为「`# 标题` + `##` 节标题」拼接——仍能用，但注入精度下降。

```yaml
---
id: patterns-table
generatedBy: analyzer
generatedAt: <ISO-8601-timestamp>
last_scan: <ISO-8601-timestamp>
lifecycle: confirmed
confidence: 95
statement: "列表页用 <统一表格> 包裹 + <schema表格> 声明式列配置渲染"
sources:
  - <source-file-path>
---
```

> ⚠️ **这是 Producer 侧要求，Compiler 不硬校验**。实测真实项目合规率 **0/12**——若纳入编译器硬校验，
> 会让所有真实项目编译失败。`required_frontmatter`（该写）与 `compiler_enforced`（该拦）的区别见
> [shared/schemas/knowledge-directories.yaml](../../../shared/schemas/knowledge-directories.yaml)。
> 另见 [knowledge-builder.md](knowledge-builder.md) 的 `.md frontmatter` 节。

**confidence 分级**：

| 范围 | 含义 | 示例 |
|------|------|------|
| 90-99 | 统计事实 | "<schema表格> 引用 569 次" |
| 70-89 | 模式推断 | "项目使用 Schema 驱动模式" |
| 50-69 | 人工标注 | 人工补充的经验 |

## 固定产出结构

> ⚠️ **目录集合的单一权威是 [`shared/schemas/knowledge-directories.yaml`](../../../shared/schemas/knowledge-directories.yaml)**——
> producer / consumer / ownership / 是否进 index / 必需 frontmatter 全在那里定义。本节的树是从它派生的视图，
> **不得在此新增目录**（`check-io-connectivity.sh` 不变量 I2 会断言：本文件与 knowledge-builder 的写入目录必须已在契约中声明）。

```
.project-knowledge/
│
├── manifest.json                # 元数据（knowledgeVersion, skillVersion, gitCommit）
├── statistics.json              # 仪表盘数据（组件/API/模式/质量指标）
├── context.json                 # 标准化项目上下文（技术栈/路径别名/模块清单）
├── graph.json                   # 结构化关系图谱（节点+边）
├── search-index.json            # 关键词→文件检索索引
├── index.md                     # 人类导航入口
│
├── architecture/                # 架构
├── components/                  # 组件
├── api/                         # API
├── patterns/                    # 模式（UI + 编码 + 可复用模式）
├── conventions/                 # 编码规范（人读，不入 index）
├── observations/                # 观察数据（人读，不入 index）
├── recommendations/             # 项目级应然建议（一条建议一个文件）
├── decisions/                   # 决策记录（入 index；文件必需 constraint:）
├── proposals/                   # 任务规划产物（PLAN-*.md，project-planner 产出）
├── reports/                     # 任务产物（REVIEW / TEST-REPORT / REFACTOR / CHANGELOG / RELEASE-CHECKLIST）
├── candidates/                  # 候选暂存（accepted/ rejected/）
│
├── rules/                       # 人工
├── experience/                  # 人工
└── playbooks/                   # 人工
```

> 目录集合的权威是 [`shared/schemas/knowledge-directories.yaml`](../../../shared/schemas/knowledge-directories.yaml)；
> 上面这棵树是它 + 6 个根产物的**唯一**人读视图，其它 prompt 一律引用、不得再列一份。

### 首扫契约（🔴 进 Exit 条件）

**首次扫描必须建立完整骨架**——上列**全部目录** + **6 个根产物**，即使某维度本次无内容：

- 目录**一律创建**，不是「有内容才建」。缺目录 = 下游 skill 按目录读取时知识链断裂。
- 分析型目录（`architecture/` `components/` `api/` `patterns/` `conventions/` `observations/`
  `recommendations/` `decisions/` `candidates/`）写入本次发现的内容。
- 人工型目录（`rules/` `experience/` `playbooks/`）**仅创建 `index.md`**，内容归人工维护。
- 根产物中**元数据 JSON 每次必定生成**（见下 Refresh Rules），不是首扫才有。

> 由 [check-kb-contract.sh](../../../shared/scripts/check-kb-contract.sh) 机械断言，**缺失即阻断 Delivery**。
> 实测教训：曾有项目在 13/14 契约目录缺失时仍声明 `status: completed`——「目录初次运行时全部创建」写在
> bullet 里、且没有任何门禁检查它，于是等于没写。**规格里没进 Exit 的祈使句不构成要求。**

- 各目录下按分析发现动态创建 `.md` 文件，有内容才建 *（目录必须建，文件按发现建——两者不同）*
- 人工型目录（`rules/` `experience/` `playbooks/`）仅创建 `index.md`；`decisions/` 例外——
  它同时接收 analyzer 的决策提取（写 `constraint:`）与人工 ADR


## Refresh Rules（重扫时的更新策略）

| 文件 | 刷新策略 | 触发条件 |
|------|---------|---------|
| `statistics.json` | **Always** — 每次扫描强制重新生成 | 任何扫描 |
| `context.json` | **Always** — 每次扫描强制重新生成，所有数字从 statistics 重新提取 | 任何扫描 |
| `graph.json` | **Always** — 每次扫描重建节点，自动追加新模块/移除已删模块 | 任何扫描 |
| `search-index.json` | **Always** — 每次扫描重新提取关键词 | 任何扫描 |
| `.md` 知识文件 | **On Change** — 仅内容变化时更新，未变化仅更新 `last_scan` | 维度分析发现变化 |
| `manifest.json` | **Always** — 追加 executionLog，更新 gitCommit/updatedAt/statistics | 任何扫描 |
| `index.md` | **Always** — 更新导航入口的数字和摘要 | 任何扫描 |
| `knowledge-health.json` | **Always** — 每次扫描重新检测 | 任何扫描 |

### 反例

| ❌ 错误做法 | ✅ 正确做法 |
|-----------|-----------|
| context.json 中 layers.files 用上次缓存的数字 | 从 statistics.byLayer 重新提取 |
| search-index.json 因为 markdown 没变就不重新生成 | 重新扫描全部 .md 提取关键词 |
| graph.json 保留旧节点不追加新模块 | 从 modules 列表重建，自动补齐 |
| "这个文件标记了 unchanged，跳过" | unchanged 只对 .md 生效，JSON 永远强制刷新 |
