# Knowledge Resolver v1.0.0

> Task → Knowledge Graph → Top K → Generator
> Generator 永远不自己搜索知识库。Resolver 是唯一的检索入口。
>
> 📖 **人类读这里**（算法说明） · ⚙️ **Schema: [knowledge-index.schema.json](state/schemas/knowledge-index.schema.json)** · 📍 **输出: `.project-runtime/knowledge-index.json`**

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
   - 组件名（如 FormSelect, UserTable）
   - API 模块名（如 orderApi, userApi）
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
   
5. 输出 Context Package（`context-package.json`）
```

## Context Package（主输出，v2.0）

> ⚙️ **Schema: [context-package.schema.json](contracts/context-package.schema.json)**

Context Package 是预消化的知识包。Generator 不再读文件、不再自己判断——直接遍历 `context.knowledge[]`，注入 pattern，遵守 constraints。

**核心转变：**

```
Before:  knowledge-list.json = ["patterns/table.md", "api/order.md", ...]
         Generator → 读每个文件 → 自己 parse → 自己判断用哪个段落 → 不可靠

After:   context-package.json = { knowledge: [{ pattern: "PageTable + SchemaTable", constraints: [...] }], ... }
         Generator → for (k of knowledge) { 注入 k.pattern; 遵守 k.constraints; 避免 k.anti_pattern } → 可靠
```

### 示例

Plan: "新增收货地址 CRUD 页面" → Resolver 输出：

```json
{
  "plan": "PLAN-order-shipping-address.md",
  "generatedBy": "knowledge-resolver",
  "confidence": 91,
  "context": {
    "knowledge": [
      {
        "capability": "TablePattern",
        "pattern": "DataTable + SchemaTable + SearchForm",
        "constraints": ["pageIndex/pageSize 数字", "Element Plus 命名空间"],
        "anti_pattern": "不要手写 el-table + el-pagination",
        "source": "patterns/table.md",
        "confidence": 92
      },
      {
        "capability": "DialogPattern",
        "pattern": "Dialog + FormContainer + setDialogVisible(isNew, data?)",
        "constraints": ["emit('refresh')", "ElMessage.success()"],
        "anti_pattern": "不要用 el-dialog 裸写",
        "source": "patterns/dialog.md",
        "confidence": 88
      },
      {
        "capability": "ApiPattern",
        "pattern": "export function getXxxPageList(params): Promise<AxiosResponse<T>>",
        "constraints": ["pageIndex/pageSize", "data.code === 0", "GET=params POST=data"],
        "anti_pattern": "不要用 export const 箭头函数 + method 小写",
        "source": "api/overview.md",
        "confidence": 90
      }
    ],
    "components": [
      {
        "name": "Dialog",
        "path": "@app/components/common/Dialog/index.vue",
        "usage": "v-model:visible + #footer 插槽",
        "reuse": true
      },
      {
        "name": "FormContainer",
        "path": "@app/components/common/FormContainer/index.vue",
        "usage": "ref + .validate() 返回 Promise",
        "reuse": true
      }
    ],
    "api": [
      {
        "module": "order",
        "functions": ["getShippingAddressPage", "saveShippingAddress", "deleteShippingAddress"],
        "conventions": ["export function 风格", "baseService URL 前缀"],
        "source": "api/order.md"
      }
    ],
    "rules": [
      {
        "rule": "workspace-priority",
        "constraint": "组件从 @app/components/ 引入，不碰 src/components/",
        "blocking": true
      },
      {
        "rule": "defineOptions",
        "constraint": "每个组件必须 defineOptions({ name: '...' })",
        "blocking": true
      }
    ]
  }
}
```

### Generator 消费方式

```
1. 读 context-package.json
2. for (k of context.knowledge):
     → 注入 k.pattern 作为生成模板
     → 遵守 k.constraints[]
     → 避免 k.anti_pattern
3. for (c of context.components):
     → if c.reuse → import c.path，不重新生成
4. for (a of context.api):
     → 按 a.conventions 生成 API 调用
5. for (r of context.rules):
     → if r.blocking → 必须遵守，否则报错
```

### 与 knowledge-list.json（已废弃）的对比

| | knowledge-list.json (v1) | context-package.json (v2) |
|---|---|---|
| 内容 | 文件路径列表 | 预提取的 pattern/约束/组件 |
| Generator 操作 | 读文件 → 自己理解 | 遍历 → 直接注入 |
| 依赖 | Generator 需要知道每个文件的结构 | Generator 不需要知道文件在哪 |
| 可靠性 | 依赖 Generator 的解析能力 | pattern 已提取，Generator 只管执行 |

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
1. 读 context-package.json（唯一知识入口）
2. 遍历 context.knowledge → 直接注入 pattern + 遵守 constraints
3. 遍历 context.components → reuse=true 的直接 import，不重新生成
4. 遍历 context.api → 按 conventions 生成 API 调用
5. 遍历 context.rules → blocking=true 的强制遵守
6. 不知道文件在哪、不需要 parse markdown、不自己判断用哪个模式
```

### Reviewer 消费

Reviewer 审查时:

```
1. 读 context-package.json
2. 验证 Generator 的代码是否符合 context.knowledge[].pattern
3. 检查是否使用了 context.components[].reuse=true 的组件
4. context.rules[].blocking=true 的约束被违反 → BLOCKER
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
