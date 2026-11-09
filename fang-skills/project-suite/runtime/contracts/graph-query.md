# Graph Query Protocol v2.0.0

> 统一的 `.project-knowledge/graph.json` 查询协议。所有 Skill 通过这 7 个标准查询消费**结构事实**。
> schema 见 [../../shared/schemas/graph.schema.json](../../shared/schemas/graph.schema.json)（v3.0.0）。
>
> **本协议只查结构**：`module` / `file` / `component` / `api` / `view` / `store` / `infrastructure`。
> `pattern` / `decision` / `risk` / `convention` 等知识**不在 graph.json**，走
> `knowledge-index.json → context-package.json`（见 [knowledge-access.md](knowledge-access.md)）。

## 设计原则

- **零依赖** — 用 `grep`/`jq` 直接查 JSON，不需要图数据库
- **协议稳定** — 换存储（Neo4j/MCP/SQLite）时 Skill 不用改
- **只读** — Skill 查询 graph，不修改。写入只由 analyzer 负责
- **单一关系表示** — 关系只在 `edges` 里；节点上不另存 `dependsOn`
- **层级/域分离** — `layer` 表结构层，`domain` 表业务域；`group` 只做展示分组

## 节点与边约定

| 项 | 约定 |
|----|------|
| 节点 `id` | 全局唯一；`file` 节点的 `id` 使用仓库相对路径 |
| 节点 `type` | `module` · `file` · `component` · `api` · `view` · `store` · `infrastructure` |
| `module.domain` | 业务域，必填 |
| `component/api/view/store/infrastructure.layer` | 结构层，必填 |
| `group` | 仅展示分组，**不用于**架构层级判定 |
| `files[]` | 节点对应的仓库相对源文件路径；`findImpacted` 的路径索引 |
| 边方向 | `from` = 消费者/依赖方，`to` = 被依赖方/提供方 |
| `edges[].relation` | `imports` · `depends_on` · `uses` · `composes` · `configures` |

```
A.vue imports B.ts   =>  { "from": "view-user", "to": "component-table", "relation": "imports" }
                          from = 消费者（A.vue）；to = 提供方（B.ts）
```

## 7 个标准查询

### 1. `findNode(type, name)`
查找指定类型的节点。

```bash
# 查找组件节点
jq '.nodes[] | select(.type=="component" and (.label | test("UserTable"; "i")))' graph.json

# 查找 API 节点
jq '.nodes[] | select(.type=="api" and (.label | test("user"; "i")))' graph.json

# 查找模块节点
jq '.nodes[] | select(.type=="module" and (.domain | test("user"; "i")))' graph.json
```

**返回：** 匹配的节点列表（`id, type, label, layer/domain, files, refs/functions`）

### 2. `findRelated(nodeId)`
查找与指定节点直接关联的所有节点。

```bash
jq --arg id "component-user" '
  .edges[] | select(.from==$id or .to==$id) |
  {from, to, relation}
' graph.json
```

**返回：** 边列表（from, to, relation）

### 3. `findConsumers(nodeId)`
查找哪些节点依赖（引用/使用）指定节点。

```bash
jq --arg id "api-user" '
  [.edges[] | select(.to==$id) | .from] | unique
' graph.json
```

**返回：** 消费者节点 ID 列表

### 4. `findProducers(nodeId)`
查找指定节点依赖哪些上游节点（名称保留兼容；语义是「依赖」，不是「谁生产了它」）。

```bash
jq --arg id "component-user" '
  [.edges[] | select(.from==$id) | .to] | unique
' graph.json
```

**返回：** 上游/被依赖节点 ID 列表

### 5. `findDependencies(nodeId)`
查找指定节点的全部依赖链（递归，深度 ≤ 3，不含起点）。

```bash
jq --arg id "view-user" '
  def walk($frontier; $seen; $depth):
    if $depth == 0 or ($frontier | length) == 0 then $seen
    else
      ([ $frontier[] as $n | .edges[] | select(.from == $n) | .to ] | unique) as $next
      | ([ $seen[], $next[] ] | unique) as $newseen
      | walk($next; $newseen; $depth - 1)
    end;
  walk([$id]; [$id]; 3) | .[] | select(. != $id)
' graph.json
```

**返回：** 依赖节点 ID 列表（去重，最多 3 层）

### 6. `findImpacted(paths)`
查找修改指定文件会影响哪些节点。输入是**仓库相对文件路径数组**。

实现方式：**path → 所属节点 → 反向查 consumers**。节点用 `files[]` 声明自己对应的源文件；
`file` 节点则直接用 `id` 匹配路径。**不需要为每个文件建独立节点。**

```bash
jq --argjson files '["src/components/UserTable.vue"]' '
  [ .nodes[] | select(
      (((.files // []) | map(select(. as $f | $files | index($f))) | length) > 0)
      or ((.id as $i | $files | index($i)) != null)
    ) | .id ] as $changed
  | [ .edges[] | select(.to as $t | $changed | index($t)) | .from ] | unique
' graph.json
```

**返回：** 受影响节点 ID 列表（即 `$changed` 的消费者；不含变更文件自身）

> 语义检查：`A.vue → B.ts` 被记录为 `{from: A.vue, to: B.ts}`。修改 `B.ts` 时，
> 上式的 `$changed` 命中 `B.ts` 所属节点，`edges[].to` 匹配它，返回 `edges[].from`（`A.vue`）。
> 如果只查 `.from == B.ts`，返回的是 B.ts 的依赖，方向就反了。

### 7. `findTransitiveDeps(nodeId)`
查找指定节点的传递依赖链（深度 3 层，不含起点），用于精确加载结构上下文。

```bash
jq --arg id "view-user" '
  def walk($frontier; $seen; $depth):
    if $depth == 0 or ($frontier | length) == 0 then $seen
    else
      ([ $frontier[] as $n | .edges[] | select(.from == $n) | .to ] | unique) as $next
      | ([ $seen[], $next[] ] | unique) as $newseen
      | walk($next; $newseen; $depth - 1)
    end;
  walk([$id]; [$id]; 3) | .[] | select(. != $id)
' graph.json
```

**返回：** 传递依赖节点 ID 列表（去重，最多 3 层）
**用途：** Generator 生成 `UserTable` → 查 graph → 依赖 API/Store/Validation → 只加载对应结构上下文。

## 知识加载流程（Resolver → Generator）

```
Resolver:
  1. 分析需求 → 确定涉及哪些组件/API
  2. 查 graph: findNode / findTransitiveDeps → 得到结构依赖链
  3. 读 knowledge-index.json → 按 capability 分桶
  4. 生成 context-package.json: 预消化 pattern + constraints + knowledge
  5. 写入 `.project-knowledge/runtime/tasks/<task_id>/context-package.json`

Generator:
  1. 读 context-package.json → 遍历 context.knowledge[] 直接注入
  2. 只消费知识包里的 pattern/constraints（~3-5 条，不是整个目录）
  3. 结构问题查 graph.json（findNode(component/api)），知识问题查 context-package
  4. 不搜索 .project-knowledge/ — 不知道还有别的知识
```

> ⚠️ **Legacy**：v1 的 `knowledge-list.json`（文件路径清单）已废弃，被 `context-package.json` 取代。
> 见 [knowledge-resolver.md](../knowledge-resolver.md)。

## 各 Skill 使用方式

### Generator — 生成前查询

```
1. 读 context-package.json（知识）+ graph.json（结构）
2. 结构查询：
   - findNode("component", <当前组件名>) → 了解组件所属模块/层
   - findProducers(<当前组件>) → 了解依赖的上游（API/Store/其他组件）
   - findNode("api", <关键词>) → 找到已有 API，不重复创建
3. 知识查询：context-package.json 的 pattern/constraints
4. 将结构结果写入 PLAN.md > # Reuse Analysis
```

### Reviewer — 审查前查询

```
1. 读 context-package.json（rules/guidance）+ graph.json（影响面）
2. 对每个变更文件：
   - findImpacted([变更文件路径]) → 本次修改影响哪些节点
   - findConsumers(<受影响节点>) → 哪些模块依赖它
3. 影响节点 > 5 → 标注为 HIGH risk，Full audit
   API 节点被修改 → 检查所有 findConsumers 的节点是否兼容
4. 知识约束（rules blocking）从 context-package.json 读，不从 graph 读
```

### Architect — 设计前查询

```
1. 读 context-package.json（decisions）+ graph.json（结构）
2. 结构查询：
   - 目标模块的 findDependencies → 了解耦合度
   - 全图 edges 按 node.layer 聚合 → 识别跨层依赖（view→api 正常，view→infrastructure 异常）
   - findConsumers API 节点 → 修改 API 契约时了解影响范围
3. 循环依赖（A→B 且 B→A）→ 标注为架构风险
4. 已有架构决策从 context-package.json 读，不从 graph 读
```

> 用 `layer` 判定架构层级，不要用 `group`。`group` 只做展示分组。

## Legacy / 迁移

| graph.json 版本 | 状态 | 处理 |
|----------------|------|------|
| `3.0.0` | ✅ 当前结构图 | 按本协议查询 |
| `2.0.0` | ⚠️ 旧 Knowledge Objects 图 | **不是结构图**。`check-graph-contract.sh` 给 warning；重跑 Analyzer 全量重建 |
| `1.0.0` / `1.1` | ⚠️ 更早示例 | 同上；文档示例已统一到 3.0.0 |

> Graph Query Protocol 版本（本文件 v2.0.0）与 Graph Schema 版本（3.0.0）**独立管理**。
> 本版语义变更：`findImpacted` 方向修正、`findDependencies` / `findTransitiveDeps` 真正递归、
> `group` → `layer`/`domain`、`dependsOn` 移除、`files[]` 成为影响分析索引。

## 未来演进

```
现在:  jq 直接查 graph.json
以后:  同协议 → Neo4j / MCP graph tool / SQLite
       Skill 代码不变
```

## Capability 分层 + Provider 抽象

Graph 协议从"模块依赖图"升级为"图能力协议"。Skill 按 capability 查询，不关心底层 provider。

### 能力分层

```
Graph Query Protocol（稳定协议）
    │
    ├── module.*          ← project-analyzer 提供（已实现）
    │     module.list / module.dependencies / module.impact
    │
    └── symbol.*          ← 外部 Code Intelligence provider 提供（预留）
          symbol.search / symbol.definition / symbol.references
          call.*          ← callers / callees
          reference.*     ← 引用
          impact.*        ← 修改影响半径
```

### Provider 抽象

`graph.json` 只声明 capabilities 元数据，不存储 symbol 数据：

```json
{
  "schemaVersion": "3.0.0",
  "capabilities": ["module", "file"],
  "nodes": [
    {
      "id": "component-user",
      "type": "component",
      "label": "UserTable",
      "layer": "component",
      "files": ["src/components/UserTable.vue"]
    }
  ],
  "edges": [
    { "from": "view-user", "to": "component-user", "relation": "imports" }
  ]
}
```

- `module`/`file` → project-analyzer 生成（graph.json 里的 nodes/edges）
- `symbol`/`call`/`reference`/`impact` → 外部 Code Intelligence provider（如 CodeGraph）提供

### 边界（ADR-002 正式记录）

project-suite **不实现** symbol 级静态分析（AST/type resolution/call graph）。这些委托给外部 provider。

| 层 | 谁提供 | 内容 |
|----|--------|------|
| Module Graph | project-analyzer | 模块依赖、循环依赖、跨层依赖 |
| Symbol Graph | CodeGraph（外部） | symbols/calls/references/impact |

`graph.json` 是 Module Graph 的 portable artifact，**不是** CodeGraph 数据库。两者概念分离。
