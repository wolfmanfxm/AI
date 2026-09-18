# Knowledge Builder

> 从 Accepted Candidates 组装最终 `.project-knowledge/` 产出。

## Actions

1. 收集 Verifier 输出的所有 Accepted Candidates（含 confidence-adjusted）
2. 按知识类型分组（architecture / patterns / conventions / glossary / decisions / risks / antipatterns）
3. **逐组写入**最终 .md 文件——每组 Candidate 必须覆盖，不得跳过
4. 注入 Evidence Score Section（每个 Claim 的溯源）
5. 生成跨文件交叉引用
6. **存量补齐**：为既有文件补上契约要求但缺失的字段 —— 见下「存量补齐（contract backfill）」

## 存量补齐（contract backfill）

**问题**：契约（[knowledge-directories.yaml](../../../shared/schemas/knowledge-directories.yaml)）要求
`rules/` `decisions/` 必须写 `constraint:`，`patterns/` `components/` `api/` 必须写 `statement:`。
但存量知识库是在这条要求之前产出的——实测真实项目 **8/23** 文件缺 `constraint`，导致 Compiler 拒绝生成
`knowledge-index.json`，**整条知识链中断**。

**每次 Knowledge Builder 执行时都要做**（全量与增量都做，不限增量），扫描目标目录、对**缺失**契约字段的文件补齐：

| 缺失字段 | 补齐方式 |
|---------|---------|
| `constraint`（`rules/` `decisions/`） | 从正文派生**一句硬约束**（「必须 / 禁止 …」） |
| `statement`（`patterns/` `components/` `api/`） | 从正文派生**一句可直接注入的摘要** |

### 四条硬规则

1. **只补缺失，绝不覆盖。** 文件已有该字段就原样不动——人工写过的值是权威，重扫不得回退它。
2. **必须标记来源。** 补写时同时写 `constraint_source: derived-from-body`（`statement` 同理）：
   ```yaml
   constraint: "……"
   constraint_source: derived-from-body   # analyzer 从正文派生，未经人工确认；原始产出者见 generatedBy
   ```
   为什么必须：存量文件来自**多个产出者**（实测同一项目里 `generatedBy` 有 `manual` / `project-analyzer` /
   `architect` / 缺失 四种）。`generatedBy` 记录**谁产的文件**，`*_source` 记录**这个值是派生的还是原作就有的**——
   人工据此才知道该找谁确认。

   > **只对「既有文件」补写时标记**。本次分析**新建**的文件不加此标记——它没有「原作者」，字段就是本次产出的，
   > 加标记反而是噪音（实测出现过这种误标）。
3. **派生不出就不写。** 正文里抽不出硬约束或可注入摘要时（如纯背景描述），**不要编**。在交付报告里列出该文件，
   标 `⚠️ 无法派生 <field>`，交人工补。**宁缺勿造**——写一个假约束比缺字段更坏（它会被当权威注入下游）。
4. **交付报告必须列出所有补写。** 被补写的文件 + 补写的值，逐条列给用户复核。**不得静默补写。**

> 这不是「擅自改别人的文件」：`rules/` `decisions/` 的语义归属仍是原作者（`generatedBy` 可查），
> analyzer 补的只是一个**为满足下游契约而缺的机器可读字段**，全程可回溯、可回退。
> 若某文件的 `generatedBy` 是另一个 suite skill，可考虑由该 skill 复审派生值——但**不阻塞补齐**（否则知识链一直断着）。

## Coverage Gate

**全部完成前不可退出。** 逐项验证：

| Candidate | 目标文件 | 验证方式 |
|-----------|---------|---------|
| directory.md | architecture/modules.md | 目录树 + 模块清单已合并 |
| framework.md | architecture/tech-stack.md | 技术栈表已写入 |
| architecture.md | architecture/overview.md | 分层+边界已写入 |
| patterns.md | patterns/*.md | 每种模式独立文件 |
| conventions.md | conventions/*.md | 每种规范独立文件 |
| glossary.md | architecture/glossary.md | 术语表已写入 |
| decisions.md | decisions/decisions.md（**必需 `constraint:`**） | 决策记录已写入 |
| risks.md | observations/risks.md | 风险清单已写入 |
| antipatterns.md | observations/antipatterns.md | 反模式清单已写入 |
| principles.md | conventions/principles.md | Always/Never/Prefer/Avoid 已写入 |

**未覆盖的 Candidate → 返回重写对应文件 → 不可 Exit。**

### frontmatter 契约（与 Coverage Gate 同级，缺失同样**不可 Exit**）

写入每个目标文件时，按 [shared/schemas/knowledge-directories.yaml](../../../shared/schemas/knowledge-directories.yaml) 的 `required_frontmatter` 补齐字段：

| 目标目录 | 必需字段 | 缺失后果 |
|---------|---------|---------|
| `patterns/` `components/` `api/` | `statement:` | 不报错，但 Resolver 静默退化为标题拼接，注入精度下降（实测真实项目 0/12 合规） |
| `decisions/` | `constraint:` | **Compiler 硬校验**——缺即拒绝生成 `knowledge-index.json`，整条知识链中断 |

> 字段写法见 [output-format.md](output-format.md) 的「字段说明」与 `statement` 小节。
> 契约要求「Producer 该写」的字段，其**声明**由 `check-io-connectivity.sh` 不变量 I4 把关（防止「要求了但没告诉产出者」）。

## Output Structure

**双轨输出**：Machine-readable Knowledge Graph（下游 Skill 消费）+ Human-readable Markdown（人读）。

> ⚠️ **目录集合的单一权威是 [`shared/schemas/knowledge-directories.yaml`](../../../shared/schemas/knowledge-directories.yaml)**——
> 哪个目录由谁产出、谁消费、是否进 index、必须写哪些 frontmatter，一律以它为准。本节的树是从它派生的视图，
> **不得在此新增目录**（`check-io-connectivity.sh` 的不变量 I2 会断言：本节声明的写入目录必须已在契约中声明）。
>
> 另注：`decisions/` 是 index 目标目录（契约 `indexed_by_compiler: true`），且其文件**必须**写 `constraint:`
> （契约 `compiler_enforced: [constraint]`）。**不要再把决策写进 `architecture/`**——那会被当作 pattern 索引。

```
.project-knowledge/
├── graph.json     ← ⭐ 权威知识图谱（machine-readable）
├── architecture/
│   ├── overview.md          ← 人读版本
│   ├── modules.md
│   ├── tech-stack.md
│   └── glossary.md
├── patterns/
├── components/
├── api/
├── conventions/             ← 人读（不入 index）
├── decisions/               ← 入 index；文件必需 constraint:
├── observations/            ← 人读（不入 index）：risks.md / antipatterns.md
├── proposals/  reports/     ← 任务产物落点（不入 index）
├── candidates/  domain/     ← 候选暂存 / 领域词汇（不入 index）
├── statistics.json
└── context.json
```

## .md frontmatter（供 Resolver hydrate）

每个 patterns/components/api 的 .md 文件 frontmatter，除 `id`/`generatedBy`/`lifecycle`/`confidence` 外，
**必须写 `statement:`**——一句可执行的 convention/pattern 摘要。Resolver hydrate 直接抽它注入
context-package.json，Generator 不再读文件正文：

```yaml
---
id: patterns-table
statement: "列表页用 <统一表格> 包裹 + <schema表格> 声明式列配置渲染"
constraints: "分页 <分页参数> 数字；Element Plus 命名空间 <组件库前缀>"
anti_pattern: "不要手写 el-table + el-pagination"
tags: "table, list, search, workspace"
---
```

- `statement` = 一句 convention（Generator 直接注入，不读文件正文）——**必写**
- `constraints` = 逗号/分号分隔的硬约束（可选）
- `anti_pattern` = 什么不该做（可选）
- `tags` = 逗号分隔的标签（Resolver 用 tag 过滤/排序）——**推荐写**

没有 `statement` 时，Resolver 退化为「`# 标题` + `##` 节标题」拼接（仍可用，但不如 statement 精确）。

## graph.json — Knowledge Objects

从 accepted candidates 组装 → [schema](../../../shared/schemas/knowledge-object.schema.json)

```yaml
# .project-knowledge/graph.json
nodes:
  - id: pattern.repository
    type: pattern
    category: behavioral
    confidence: 0.94
    statement: "项目使用 Repository Pattern 封装数据访问"
    evidence:
      - { path: src/repositories/UserRepository.ts, type: file, lines: 45 }
      - { path: src/repositories/OrderRepository.ts, type: file, lines: 62 }
    related:
      - { id: principle.repository, relation: implements }
      - { id: api.user, relation: references }
    source: { extractor: pattern, verdict: accepted }
    occurrences: 17
    predictive_power: "Can answer: where to add data access for new entity?"
    obviousness: non-obvious
    tags: [repository, data-access, abstraction]

  - id: convention.pascalcase
    type: convention
    category: behavioral
    confidence: 0.95
    statement: "组件命名使用 PascalCase"
    evidence:
      - { path: workspace/views/, type: ratio, note: "95% of .vue files" }
    related:
      - { id: antipattern.kebabcase, relation: contradicts }
    source: { extractor: convention, verdict: accepted }
    occurrences: 380
    obviousness: somewhat-obvious
    tags: [naming, component, convention]

edges:
  - { from: pattern.repository, to: principle.repository, relation: implements }
  - { from: pattern.repository, to: api.user, relation: references }
  - { from: convention.pascalcase, to: antipattern.kebabcase, relation: contradicts }

# 下游 Skill 消费方式:
# Planner:   读取 graph.json → 了解可复用资产
# Architect: 读取 nodes[type=decision] → 了解已有架构决策
# Generator: 读取 nodes[type=pattern,component,api] → 套用模式生成代码
# Reviewer:  读取 nodes[type=antipattern,risk] → 对照审查
```

## Evidence Score Section

每个 .md 文件末尾附 Evidence Score 表：

```markdown
## Evidence Score

| Claim | Confidence | Occurrences | Verified | Evidence |
|-------|-----------|-------------|----------|----------|
| Repository Pattern | 0.91 | 18 | ✅ | src/repositories/ (18 files) |
| PascalCase convention | 0.95 | 380 | ✅ | 95% of components |
| ... | | | | |

Overall Confidence: 0.89
```
