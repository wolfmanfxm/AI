# Capability Matrix

## 能力边界

### 保证能力

✓ 架构分析
✓ 组件编目
✓ API 发现
✓ 模式提取
✓ 编码风格分析
✓ 知识索引生成
✓ 增量刷新
✓ 开发前检查

### 不做

✗ 业务需求分析
✗ 运行时分析
✗ 安全审计
✗ 性能基准测试
✗ 部署验证
✗ 代码重构
✗ 测试生成

> 触发词命中了但意图落在"不做"区域 → 不调用本 skill，直接告知用户边界。

## 产出契约

> 目录集合的权威是 [`shared/schemas/knowledge-directories.yaml`](../../../shared/schemas/knowledge-directories.yaml)，
> 人读视图是 [output-format.md](../prompts/output-format.md) 的「固定产出结构」。
> **本节只描述「哪类目录以什么策略维护」，不重述目录清单。**

**固定根产物** — 每次扫描必定生成（见 output-format.md「Refresh Rules」）：
`manifest.json`（含 `knowledgeVersion` + `schemaVersion`）、`statistics.json`、`context.json`、
`graph.json`、`search-index.json`、`index.md`。
由 [check-kb-contract.sh](../../../shared/scripts/check-kb-contract.sh) 断言在位，**缺失阻断 Delivery**。

**按需产出** — 由维度 agent 按实际代码检测结果动态生成，有内容才建文件：`architecture/`
`components/` `api/` `patterns/` `conventions/` `observations/` `recommendations/` `candidates/`。

其中 `components/` 除 `catalog.md` + 高复用组件独立 `.md` 外，**多应用项目**（monorepo / 微前端，
同一仓库含 ≥2 个可独立运行的应用）额外产出 **`components/reuse-ledger.md`：组件复用总账**——
逐组件记录「在哪些应用出现、是否各应用各自重写、可提升为共享组件的候选」，跨应用复用率落此一处。

> ⚠️ **不要为复用账新建目录**（曾出现 `component-inventory/`）：契约未声明该目录 → 它不进 index、
> 下游读不到，且违反 [check-io-connectivity.sh](../../../shared/scripts/check-io-connectivity.sh) 的不变量 I2
> （规格里声明的写入目录必须已在契约中声明）。**并入 `components/` 即符合契约，且能被 Compiler 索引。**

**人工维护** — 以下目录 `ownership: manual`，分析只创建占位 `index.md`，**重扫不覆盖既有内容**：

| 目录 | 维护者 | 说明 |
|------|--------|------|
| `rules/` | 人工 | 团队编码规则（analyzer 可写入自身提取的原则，需 `constraint:`） |
| `experience/` | 人工 | 项目经验教训 |
| `playbooks/` | 人工 | 操作手册 |
| `decisions/` | 人工 | 架构决策记录（analyzer 写 `decisions/*.md`，需 `constraint:`） |

> 「不覆盖」指**不覆盖已有内容**，不等于「绝不写」：`rules/` `decisions/` 同时接收 analyzer 的
> 提取产出与存量补齐（见 [knowledge-builder.md](../prompts/knowledge-builder.md) 的「存量补齐」——
> 只补缺失字段、绝不改写已有值、且标记 `*_source: derived-from-body` 可回溯）。

## 覆盖策略

非首次运行时，按目录的 `ownership` 字段（契约）决定覆盖行为——**照契约的
`ownership: generated | manual` 判定，不另列目录名单**：

| ownership | 目录 | 行为 |
|-----------|------|------|
| `generated` | `architecture/` `components/` `api/` `patterns/` `conventions/` `observations/` `recommendations/` `candidates/` `proposals/` `reports/` + 全部根产物 | **自动覆盖**——机器生成内容，不应人工编辑 |
| `manual` | `rules/` `experience/` `playbooks/` `decisions/` | **不覆盖既有内容**；但允许 analyzer 补写**缺失**的机器可读字段（见下） |

对比标记：非首次运行时，自动覆盖区域的文件对比后标注 `[NEW]` / `[CHANGED]` / `[REMOVED]` / `[CONFIRMED]`；
`manual` 区域跳过不处理。

### 例外：存量补齐（唯一允许触碰 `manual` 目录的写操作）

`manual` 目录的既有文件若**缺**契约要求的 frontmatter 字段（`constraint:` / `statement:`），
由 [knowledge-builder.md](../prompts/knowledge-builder.md) 补写——**只补缺失、绝不覆盖已有值**、
标记 `*_source: derived-from-body`、并在交付报告逐条列出。缺该字段会导致 Compiler 拒绝生成
`knowledge-index.json`（整条知识链中断），因此这条例外是**必需**的，不是可选的。

---

## Prompt Capability Matrix

> 本表是「维度 prompt → 落点」的路由视图，**不是产出清单**。完整产出集合见「产出契约」一节。

| Prompt | 输入 | 落点（契约目录） | 依赖 |
|--------|------|---------|------|
| [prompts/architecture.md](../prompts/architecture.md) | `package.json` + 目录结构 | `architecture/` | 无 |
| [prompts/components.md](../prompts/components.md) | `src/components/` `workspace/components/` | `components/` | architecture（组件目录位置） |
| [prompts/coding-style.md](../prompts/coding-style.md) | `.vue` `.ts` 文件抽样 | `patterns/` | architecture（技术栈确认） |
| [prompts/api-pattern.md](../prompts/api-pattern.md) | `src/api/` `workspace/api/` | `api/` | architecture（API 目录位置） |
| [prompts/ui-pattern.md](../prompts/ui-pattern.md) | 视图模板代码抽样 | `patterns/` | components（已知可用组件） |
| [prompts/patterns.md](../prompts/patterns.md) | architecture/ + components/ + api/ | `patterns/` | architecture + components + api |
| [prompts/observations.md](../prompts/observations.md) | 全部已有产出 | `observations/` | 所有前序维度 |
| [prompts/change-analysis.md](../prompts/change-analysis.md) | git diff + 已有产出 | `reports/` | architecture（模块结构） |

## 并行策略

```
Wave 0（无依赖，可立即并行）
  architecture

Wave 1（依赖 architecture，4 个可并行）
  components  coding-style  api-pattern  change-analysis

Wave 2（依赖 Wave 1，2 个可并行）
  ui-pattern（需 components）  patterns（需 architecture + components + api）

Wave 3（依赖全部前序）
  observations
```
