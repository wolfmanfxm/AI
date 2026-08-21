# Knowledge Resolver v1.0.0

> Task → 分桶（constraints/knowledge/guidance）→ context-package.json → Generator
> Generator 永远不自己搜索知识库。Resolver 是唯一的检索入口。
>
> 📖 **人类读这里**（算法说明） · ⚙️ **Schema: [context-package.schema.json](contracts/context-package.schema.json)** · 📍 **输出: `.project-knowledge/context-package.json`**

## 核心原则

```
之前:  Generator 读 patterns/ + components/ + api/ → 自己判断用哪个
之后:  Resolver(Task, Index) → context-package.json → Generator 只消费这个预消化知识包
```

Generator 不知道还有别的知识。Context 恒定、可预测、不膨胀。

## 算法

```
输入: Task + candidates（Planner # Reuse Analysis 传入：source/capability/tag）+ knowledge-index.json
输出: context-package.json（分桶：constraints 全量 + knowledge Top-K + guidance Top-K）

1. 分桶（按 type，确定性）
   遍历 knowledge-index.json 每个 capability 的每个 file entry，按 type 归桶：
   - rule → rules（blocking 约束，恒全量）
   - decision → scope=project（blocking）→ rules；scope=task（advisory）→ guidance
   - experience / playbook → guidance
   - pattern / component / api → knowledge

2. 候选集过滤（candidates：Planner # Reuse Analysis 传入的 source/capability/tag）
   - rules（blocking constraints）：恒全量，不受 candidates / Top-K 影响
   - knowledge / guidance：按 candidates 过滤（传了才过滤 + 裁 Top-K；不传 = 全量，向后兼容）
   - Top-K：knowledge 默认 5，guidance 默认 3；rank 恒按 priority → confidence↓ → tag-overlap↓ → source

3. Hydrate（读源取正文，确定性）
   - rule / project-decision：读 frontmatter `constraint` → context.rules[].constraint
   - knowledge / guidance：读 frontmatter `statement`/`summary`（否则首个 `# 标题`）→ pattern
   - Index 只存 metadata（discover），正文在 hydrate 阶段取（retrieve + hydrate）

4. 输出 Context Package
   context.rules[]     = 全量 blocking 约束（type=rule/decision）
   context.knowledge[] = 预消化 pattern（P2）
   context.guidance[]  = experience/playbooks（P3）
```

> **结构事实不走 Resolver**：component/api/module 的存在性、依赖链、影响半径由 Planner/Architect/Generator
> 经 [graph-query.md](contracts/graph-query.md)（findNode/findTransitiveDeps/findConsumers）直接查 `graph.json`，
> 再填入 context-package 的 `components`/`api`。Resolver 只读 `knowledge-index.json`（Compiler 产出），**graph.json 不是 Resolver 输入**。

## Context Package（主输出，v2.0）

> ⚙️ **Schema: [context-package.schema.json](contracts/context-package.schema.json)**

Context Package 是预消化的知识包。Generator 不再读文件、不再自己判断——直接遍历 `context.knowledge[]`，注入 pattern，遵守 constraints。

**核心转变：**

```
Before:  knowledge-list.json = ["patterns/table.md", "api/order.md", ...]
         Generator → 读每个文件 → 自己 parse → 自己判断用哪个段落 → 不可靠

After:   context-package.json = { knowledge: [{ pattern: "<统一表格> + <schema表格>", constraints: [...] }], ... }
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
        "pattern": "DataTable + <schema表格> + SearchForm",
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
1. Reuse Analysis → 确定涉及的组件/API/模式 → 产出 candidates
2. 调用 Resolver(任务列表, candidates) → context-package.json
3. 将 context-package.json 写入 `.project-knowledge/context-package.json`
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
knowledge-index.json 不存在 → Resolver 无法运行（需先跑 knowledge-compiler.sh 生成 index）
context-package.json 不存在 → Generator 从 PLAN.md # Reuse Analysis 提取文件列表
两者都不存在 → Generator 降级通用模式
```

## Legacy Compatibility（v1 → v2）

> ⚠️ `knowledge-list.json` 是 v1 旧产物（文件路径清单，Generator 自行解析）。v2.0 起被
> `context-package.json`（预消化知识包）取代。**任何新 Skill 不得再以 knowledge-list.json 为正式输入。**
> 它仅作为「老项目残留 artifact」保留向后兼容，见 [context-package.schema.json](contracts/context-package.schema.json)。

## 与 Knowledge Lifecycle 的关系

Resolver **不读 status** —— 它消费 Compiler 产出的 `knowledge-index.json`，而 Compiler 已对 analyzer 产出的目录
（patterns/components/api/architecture）排除了 status 明确非 Accepted 的文件（见 [knowledge-compiler.md](knowledge/knowledge-compiler.md) 的 lifecycle 过滤）。
`rules/decisions/experience/playbooks` 是用户手写的权威约束，恒入 index，不受 lifecycle 门控。

所以 Candidate 的 analyzer 产出知识不会进入 context-package.json —— 这确保 Generator 永远不把猜测当事实。

→ [state/schemas/knowledge-lifecycle.md](state/schemas/knowledge-lifecycle.md)
