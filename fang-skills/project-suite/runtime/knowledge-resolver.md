# Knowledge Resolver v1.0.0

> Task → Knowledge Graph → Top K → Generator
> Generator 永远不自己搜索知识库。Resolver 是唯一的检索入口。

## 核心原则

```
之前:  Generator 读 patterns/ + components/ + api/ → 自己判断用哪个
之后:  Resolver(Task, Graph) → knowledge-list.json → Generator 只读这 3-5 个文件
```

Generator 不知道还有别的知识。Context 恒定、可预测、不膨胀。

## 算法

```
输入: Task（来自 PLAN.md > # Task Breakdown）+ graph.json
输出: knowledge-list.json（Top K 文件路径，默认 K=5）

1. 提取实体
   从 Task 描述中提取:
   - 组件名（如 FormSelect, CustomerTable）
   - API 模块名（如 quotaManage, customerApi）
   - 模式关键词（如 CRUD, 审批流, 文件上传）

2. 图查询
   对每个实体:
   - findNode(type, name) → 定位节点
   - findTransitiveDeps(nodeId) → 获取传递依赖链（深度 ≤ 2）
   
3. 映射到知识文件
   每个图节点映射到 .project-knowledge/ 中的文件:
   - component 类型 → components/catalog.md + 对应 pattern
   - api 类型 → api/<module>.md + api/overview.md
   - pattern 类型 → patterns/<name>.md
   
4. 去重 + 排序
   - 去重: 同一文件只保留一次
   - 排序: 按节点在依赖链中的距离（直接依赖 > 间接依赖）
   - 限制: Top K（默认 5，可配置）
   
5. 输出 knowledge-list.json
```

## knowledge-list.json

```json
{
  "plan": "PLAN-credit-activate.md",
  "generated_by": "knowledge-resolver",
  "generated_at": "2026-07-28T16:00:00",
  "max_files": 5,
  "files": [
    {
      "path": "patterns/form.md",
      "reason": "FormSelect 组件的表单模式",
      "graph_node": "comp-FormSelect",
      "distance": 1
    },
    {
      "path": "api/quotaManage.md",
      "reason": "quotaManage API 模块文档",
      "graph_node": "api-quotaManage",
      "distance": 1
    },
    {
      "path": "components/catalog.md",
      "reason": "已有组件清单",
      "graph_node": "comp-CustomerTable",
      "distance": 2
    },
    {
      "path": "patterns/dialog.md",
      "reason": "FormSelect 依赖 Dialog 组件",
      "graph_node": "comp-Dialog",
      "distance": 2
    },
    {
      "path": "rules/frontend-convention.md",
      "reason": "强制编码约束",
      "graph_node": null,
      "distance": 0
    }
  ]
}
```

**字段说明:**
| 字段 | 说明 |
|------|------|
| `files[].path` | 相对于 `.project-knowledge/` 的文件路径 |
| `files[].reason` | 为什么需要这个文件（Generator 可据此判断是否适用） |
| `files[].graph_node` | 关联的 graph.json 节点 ID（可为 null） |
| `files[].distance` | 在依赖链中的距离（0=强制约束, 1=直接依赖, 2=间接依赖） |

## 集成点

### Planner 调用

Planner 在 Step 4（Reuse Analysis）之后调用 Resolver:

```
1. Reuse Analysis → 确定涉及的组件/API/模式
2. 调用 Resolver(任务列表, graph.json) → knowledge-list.json
3. 将 knowledge-list.json 写入 artifacts/plans/
```

### Generator 消费

Generator 启动时:

```
1. 读 knowledge-list.json
2. 只加载 files[].path 列表中的文件
3. 按 distance 排序加载（distance=0 的规则最先读）
4. 对每个文件，检查 reason 是否适用当前 Task
   - 适用 → 完整加载
   - 不适用 → 跳过
5. 不知道还有别的知识文件
```

### Reviewer 消费

Reviewer 审查时:

```
1. 读 knowledge-list.json
2. 验证 Generator 是否正确使用了指定的知识
3. knowledge-list.json 中的文件被正确引用 → PRAISE
4. Generator 使用了列表外的文件 → WARN（可能未授权）
```

## 降级

```
graph.json 不存在 → Resolver 退化为 PLAN.md # Reuse Analysis 直接映射
knowledge-list.json 不存在 → Generator 从 PLAN.md # Reuse Analysis 提取文件列表
两者都不存在 → Generator 降级通用模式
```

## 与 Knowledge Lifecycle 的关系

Resolver 只返回 `status: accepted` 的知识文件。
`Candidate` 状态的文件不进入 knowledge-list.json。
这确保 Generator 永远不把猜测当事实。

→ [state/schemas/knowledge-lifecycle.md](state/schemas/knowledge-lifecycle.md)
