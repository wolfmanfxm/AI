# Context Resolver v2.0

> Task → 分桶（constraints / knowledge / guidance）→ context-package.json。
> 解决"1000 篇知识，Skill 读哪些？"的问题——**Skill 不读 .md，只消费 Resolver 编译好的知识包**。
>
> 算法与实现见 [../knowledge-resolver.md](../knowledge-resolver.md) + `shared/scripts/knowledge-resolver.sh`。
> 本契约只描述「Resolver 输出什么」，不重复算法细节。

## 核心转变

```
Before:  Task → 提取 tags → score 排序 → top-10（语义聚类，未落地）
After:   Task → 按 type 分桶 → 全量 constraints + Top-K knowledge/guidance（确定性）
```

## 三类知识访问（边界唯一权威）

| 桶 | 内容 | enforcement | 消费方式 |
|----|------|-------------|---------|
| **constraints** | rules + project-scope decisions（恒全量） | blocking | 必须遵守，违反即错 |
| **knowledge** | patterns / components / api | recommended | 用于实现（REUSE） |
| **guidance** | experience / playbooks / task-scope decisions | advisory | 参考，非强制 |

## 输出（context-package.json）

```json
{
  "context": {
    "rules": [
      { "rule": "form-component-standard", "type": "rule", "constraint": "所有表单必须用 <统一表单封装>", "blocking": true }
    ],
    "knowledge": [
      { "capability": "patterns", "source": "patterns/table.md", "enforcement": "recommended" }
    ],
    "guidance": [
      { "type": "decision", "scope": "task", "source": "decisions/ARCHITECTURE-x.md", "enforcement": "advisory" }
    ]
  }
}
```

## Progressive Disclosure（强制）

Resolver 输出 = metadata 指针，**不做默认全量 hydrate**。

```
Index → Select → Hydrate
```

1. **Index**：只存 metadata（`source` / `enforcement` / `priority` / `statement`）——见
   [context-package.schema.json](context-package.schema.json) 的 `knowledgeEntry`，全文不出现。
2. **Select**：仅对当前任务命中（candidates 过滤 + Top-K）的条目进入 hydrate。
3. **Hydrate**：只取被选中条目的正文；未选中、未命中的条目**不载入**。
4. **禁令**：禁止因「可能有用」而加载全文；禁止把 `patterns/`/`components/`/`api/` 原文灌入 package。
5. 已有结构化结果（`pattern` / `constraints` / `recommendation.statement`）优先于 raw source——Generator
   消费结构化结果，不自行 parse 原文。

> 这不是新机制——schema v2.x 的 metadata-only / 方案 B hydrate 已是本契约的实现。此处显式化
> 「不做默认全量 hydrate」的禁令，防止下游实现退化回「全量展开」。

## 结构事实（不走 Resolver，走 graph-query）

组件/API/模块的存在性、依赖链、影响半径 → [Graph Query Protocol](graph-query.md)（`graph.json`）：

- `findNode(type, name)` → 定位节点
- `findTransitiveDeps(nodeId)` → 传递依赖链
- `findConsumers(nodeId)` → 谁依赖它（影响范围）

**边界**：`component/api/module` 属于结构事实（graph.json）；`rule/decision/pattern/experience/playbook` 属于知识（context-package）。两条路径不混用。

## 集成

Planner / Generator / Reviewer 的 Discovery 阶段第一步：读 context-package.json（Resolver 已编译）→ 加载 constraints（blocking）→ knowledge（reuse）→ guidance（advisory）→ 再做现状探查。
