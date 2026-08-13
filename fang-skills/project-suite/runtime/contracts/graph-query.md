# Graph Query Protocol v1.0.0

> 统一的 graph.json 查询协议。所有 Skill 通过这 7 个标准查询消费 Knowledge Graph。
> graph.json 由 project-analyzer 生成，schema 见 `../../shared/schemas/graph.schema.json`。

## 设计原则

- **零依赖** — 用 `grep`/`jq` 直接查 JSON，不需要图数据库
- **协议稳定** — 换存储（Neo4j/MCP/SQLite）时 Skill 不用改
- **只读** — Skill 查询 graph，不修改。写入只由 analyzer 负责

## 7 个标准查询

### 1. `findNode(type, name)`
查找指定类型的节点。

```bash
# 查找组件节点
jq '.nodes[] | select(.type=="component" and .label | test("CustomerTable"; "i"))' graph.json

# 查找 API 节点
jq '.nodes[] | select(.type=="api" and .label | test("customer"; "i"))' graph.json
```

**返回：** 匹配的节点列表（id, type, label, group, refs/functions）

### 2. `findRelated(nodeId)`
查找与指定节点直接关联的所有节点。

```bash
jq --arg id "comp-01" '
  .edges[] | select(.from==$id or .to==$id) |
  {from, to, relation}
' graph.json
```

**返回：** 边列表（from, to, relation）

### 3. `findConsumers(nodeId)`
查找哪些节点依赖（引用/使用）指定节点。

```bash
jq --arg id "api-customer" '
  [.edges[] | select(.to==$id) | .from] | unique
' graph.json
```

**返回：** 消费者节点 ID 列表

### 4. `findProducers(nodeId)`
查找指定节点依赖哪些上游节点。

```bash
jq --arg id "comp-01" '
  [.edges[] | select(.from==$id) | .to] | unique
' graph.json
```

**返回：** 生产者节点 ID 列表

### 5. `findDependencies(nodeId)`
查找指定节点的全部依赖链（递归，深度 ≤ 3）。

```bash
jq --arg id "comp-01" '
  def deps($id; $depth):
    if $depth > 3 then empty
    else [.edges[] | select(.from==$id) | .to] | unique | .[]
    end;
  [deps($id; 1)] | unique
' graph.json
```

**返回：** 依赖节点 ID 列表（去重）

### 6. `findImpacted(paths)`
查找修改指定文件会影响哪些节点。输入文件路径列表，返回受影响节点。

```bash
jq --argjson files '["workspace/views/customer/index.vue"]' '
  [.edges[] | select(.from as $f | $files | index($f)) | .to] | unique
' graph.json
```

**返回：** 受影响节点 ID 列表

### 7. `findTransitiveDeps(nodeId)`
查找指定节点的传递依赖链（深度2-3层），用于精确加载知识文件。

```bash
# 查找 OrderForm 组件的所有传递依赖
jq --arg id "comp-OrderForm" '
  def deps($id):
    [.edges[] | select(.from==$id) | .to] | unique;
  def trans($ids; $depth):
    if $depth > 3 then empty
    else $ids + ([$ids[] | deps(.)] | flatten | unique - $ids) end;
  trans([$id]; 1) | .[]
' graph.json
```

**返回：** 传递依赖节点 ID 列表（去重）
**用途：** Generator 生成 OrderForm → 查 graph → 依赖 Upload、API、Validation → 只加载对应知识文件

## 知识加载流程（Planner → Generator）

```
Planner:
  1. 分析需求 → 确定涉及哪些组件/API
  2. 查 graph: findTransitiveDeps("comp-Target") → 得到依赖链
  3. 生成 knowledge-list.json: 列出需要加载的知识文件（不是整个 patterns/）
  4. 写入 artifacts/plans/

Generator:
  1. 读 knowledge-list.json → 知道要加载哪些文件
  2. 只加载 files 列表中的文件（~3-5个，不是整个目录）
  3. 不搜索 .project-knowledge/ — 不知道还有别的知识
  4. Context 恒定、可预测
```

## 各 Skill 使用方式

### Generator — 生成前查询

```
1. 读 graph.json
2. 查询：
   - findNode("component", <当前组件名>) → 了解组件所属模块
   - findProducers(<当前组件>) → 了解依赖的上游（API/Store/其他组件）
   - findNode("api", <关键词>) → 找到已有 API，不重复创建
3. 将查询结果写入 PLAN.md > # Reuse Analysis（补充 graph 视角）
```

### Reviewer — 审查前查询

```
1. 读 graph.json
2. 对每个变更文件：
   - findImpacted([变更文件路径]) → 本次修改影响哪些节点
   - findConsumers(<受影响节点>) → 哪些模块依赖它
3. 影响节点 > 5 → 标注为 HIGH risk，Full audit
   API 节点被修改 → 检查所有 findConsumers 的节点是否兼容
```

### Architect — 设计前查询

```
1. 读 graph.json
2. 查询：
   - 目标模块的 findDependencies → 了解耦合度
   - 全图 edges 按 group 聚合 → 识别跨层依赖（view→api 是正常的，view→infrastructure 是异常）
   - findConsumers API 节点 → 修改 API 契约时了解影响范围
3. 循环依赖（A→B 且 B→A）→ 标注为架构风险
```

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
  "schemaVersion": "1.1",
  "capabilities": ["module", "file", "symbol", "call", "impact"],
  "nodes": [...],
  "edges": [...]
}
```

- `module`/`file` → project-analyzer 生成（graph.json 里的 nodes/edges）
- `symbol`/`call`/`impact` → 外部 Code Intelligence provider（如 CodeGraph）提供

### 边界（ADR-002 正式记录）

project-suite **不实现** symbol 级静态分析（AST/type resolution/call graph）。这些委托给外部 provider。

| 层 | 谁提供 | 内容 |
|----|--------|------|
| Module Graph | project-analyzer | 模块依赖、循环依赖、跨层依赖 |
| Symbol Graph | CodeGraph（外部） | symbols/calls/references/impact |

`graph.json` 是 Module Graph 的 portable artifact，**不是** CodeGraph 数据库。两者概念分离。
