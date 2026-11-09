# Knowledge Access 边界 v3.0

> 统一知识访问边界。Skill 通过结构化入口获取知识，而非直接读 .md 文件。
>
> 上一版（v1.0）把「知识查询」设计成单一 `@knowledge:<type>` 接口，底层落到
> `knowledge-graph.yaml` —— 但该文件从未被任何 Producer 产出，从未闭环。
> 本版收口为**两条明确路径**，各管一类，不再混用。

## 两类知识访问（边界唯一权威）

| 类别 | 访问方式 | 底层产物 | 契约 |
|------|---------|---------|------|
| **结构事实**（模块/文件/组件/API 的存在性、依赖链、影响半径） | 图查询 | `.project-knowledge/graph.json` | [graph-query.md](graph-query.md) |
| **知识**（rules/decisions/patterns/components/api/experience/playbooks 的约束与模式） | Resolver 预消化 | `knowledge-index.json` → `runtime/tasks/<task_id>/context-package.json` | [../knowledge-resolver.md](../knowledge-resolver.md) |

## graph.json 硬白名单（结构图唯一标准）

`schema` 见 [../../shared/schemas/graph.schema.json](../../shared/schemas/graph.schema.json)（v3.0.0）。
**本节的类型白名单是防止知识对象回流的硬约束；改 Analyzer 时必须同时改这里。**

### 允许的节点类型

`module` · `file` · `component` · `api` · `view` · `store` · `infrastructure`

### 禁止的节点类型 / 字段

- **禁止类型**：`pattern` · `convention` · `principle` · `decision` · `risk` · `antipattern` ·
  `glossary` · `framework` · `instinct` · `playbook`，以及任何 `architecture` 之类的混合类型。
- **禁止字段**（这些是 Knowledge Object 的字段，不是结构事实）：
  `statement` · `confidence` · `scope` · `category` · `obviousness` · `tags` ·
  `predictive_power` · `related` · `occurrences` · `source` · `evidence` · `promotion`。
- **禁止 `dependsOn` 数组**：关系只在 `edges` 里表达，避免「节点内 `dependsOn` + 顶层 `edges`」双重真相。

### 关系与方向

| 项 | 约定 |
|----|------|
| `edges[].relation` | `imports` · `depends_on` · `uses` · `composes` · `configures` |
| 方向 | `from` = 消费者/依赖方，`to` = 被依赖方/提供方。`A.vue imports B.ts` → `{from: A.vue, to: B.ts}` |
| 影响分析 | 节点用 `files[]` 声明自己对应的仓库相对路径；`findImpacted(paths)` 先做 path→node 映射，再反向查 `edges.to` |

### 节点属性

| 属性 | 用于 | 说明 |
|------|------|------|
| `domain` | `module` | 业务域；`module` 节点必填 |
| `layer` | `component` / `api` / `view` / `store` / `infrastructure` | 结构层；不要用 `group` 判定架构层级 |
| `group` | 全部 | **仅展示分组**（UI/报表），不承载业务域或架构层语义 |
| `files[]` | 全部（推荐） | 仓库相对源文件路径，`findImpacted` 的唯一路径索引 |

### 文件名作用域

本白名单只约束 **`.project-knowledge/graph.json`**。
`Vault/Organization/<org>/graph.json` 是组织级**知识**对象示例（见
[organization-layer.md](../registry/organization-layer.md)），不是项目结构图，不适用本节白名单；
后续应改名为 `org-knowledge.json` 之类，避免同名混淆。

## 规则

1. **Knowledge 不直接读 .md** —— 结构事实走 `graph-query`，知识走 `Resolver` 产出的
   `runtime/tasks/<task_id>/context-package.json`，Skill 不手翻 `.project-knowledge/**/*.md`。
2. **Task Artifact 不通过 Query** —— PLAN.md / ARCHITECTURE.md / 目标源码直接
   `@adapter:filesystem.read`。
3. **两条路径不混用** —— `component/api/module/file/view/store/infrastructure` 属于结构事实
   （graph.json 节点）；`rule/decision/pattern/experience/playbook` 属于知识
   （knowledge-index → context-package）。
4. **observations 当前没有机器链路** —— `observations/`（risk/antipattern）是**人读产物**，
   Compiler 不索引、Resolver 不注入、Reviewer 不从它机器取风险。不要为了保留旧声明把
   `risk/antipattern` 塞回 `graph.json`。若未来需要，必须一次性闭环
   `observations → Compiler → knowledge-index → Resolver → context-package`，并同步 schema/E2E。

## 各 Skill 的典型访问

| Skill | 结构事实（graph-query） | 知识（Resolver） |
|-------|------------------------|------------------|
| Planner | `findNode(module/component/api)`、`findDependencies` | context-package.json 的 rules/knowledge/guidance |
| Architect | `findDependencies` 看耦合、`findConsumers` 看影响、按 `layer` 识别跨层依赖 | `decision`(scope=project) 避免重复决策 |
| Generator | `findNode(component/api)` 避免重复造轮子 | context-package.json 直接注入 pattern/constraints |
| Reviewer | `findImpacted` 看变更影响、`findConsumers` 看波及面 | rules 的 blocking 约束对照审查 |
| Documenter | `findNode(module/component/api)` 溯源 | context-package.json 的 knowledge |

## 历史（已废弃）

- `knowledge-query.sh` —— **已归档到 [docs/archive/](../../docs/archive/knowledge-query.sh)**（2026-09-18，同 check-decay.sh）
- `check-decay.sh` —— **已归档到 [docs/archive/](../../docs/archive/check-decay.sh)**（2026-09-18）。
  它是恒 `exit 1` 的存根，留在 `shared/scripts/` 会让「全套检查」永远带一个红灯，磨掉红灯信号。
  已废弃，见脚本头部说明。
- `knowledge-list.json`（v1 文件路径清单）已废弃，被 `context-package.json` 取代。
- `graph.json` 2.0.0（Knowledge Objects 形状）已废弃；见 [graph-query.md](graph-query.md) 的 Legacy 节。
