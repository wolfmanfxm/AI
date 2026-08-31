# Knowledge Access 边界 v2.0

> 统一知识访问边界。Skill 通过结构化入口获取知识，而非直接读 .md 文件。
>
> 上一版（v1.0）把「知识查询」设计成单一 `@knowledge:<type>` 接口，底层落到
> `knowledge-graph.yaml` —— 但该文件从未被任何 Producer 产出，从未闭环。
> 本版收口为**两条明确路径**，各管一类，不再混用。

## 两类知识访问（边界唯一权威）

| 类别 | 访问方式 | 底层产物 | 契约 |
|------|---------|---------|------|
| **结构事实**（组件/API/模块存在性、依赖链、影响半径） | 图查询 | `graph.json` | [graph-query.md](graph-query.md) |
| **知识**（rules/decisions/patterns/components/api/experience/playbooks 的约束与模式） | Resolver 预消化 | `knowledge-index.json` → `context-package.json` | [../knowledge-resolver.md](../knowledge-resolver.md) |

## 规则

1. **Knowledge 不直接读 .md** —— 结构事实走 `graph-query`，知识走 `Resolver` 产出的
   `context-package.json`，Skill 不手翻 `.project-knowledge/**/*.md`。
2. **Task Artifact 不通过 Query** —— PLAN.md / ARCHITECTURE.md / 目标源码直接
   `@adapter:filesystem.read`。
3. **两条路径不混用** —— `component/api/module` 属于结构事实（graph.json 节点）；
   `rule/decision/pattern/experience/playbook` 属于知识（knowledge-index → context-package）。

## 各 Skill 的典型访问

| Skill | 结构事实（graph-query） | 知识（Resolver） |
|-------|------------------------|------------------|
| Planner | `findNode(component/api)` 了解可复用资产 | context-package.json 的 rules/knowledge/guidance |
| Architect | `findDependencies` 看耦合、`findConsumers` 看影响 | `decision`(scope=project) 避免重复决策 |
| Generator | `findNode(api)` 避免重复建 API | context-package.json 直接注入 pattern/constraints |
| Reviewer | `findImpacted` 看变更影响 | rules 的 blocking 约束对照审查 |
| Documenter | `findNode(component/api)` 溯源 | context-package.json 的 knowledge |

## 历史（已废弃）

- `knowledge-query.sh` / `check-decay.sh`（旧 CLI，查询从未产出的 `knowledge-graph.yaml`）
  已废弃，见脚本头部说明。
- `knowledge-list.json`（v1 文件路径清单）已废弃，被 `context-package.json` 取代。
