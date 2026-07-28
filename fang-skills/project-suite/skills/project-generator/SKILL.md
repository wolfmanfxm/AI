---
name: project-generator
metadata: skill.yaml
description: >
  根据需求和项目规范生成生产级代码：Vue 3 组件、页面、API 模块、工具函数、类型定义。
  必须遵循项目现有模式，从 .project-knowledge/ 提取规范而非凭记忆。
  触发词：写一个、实现、创建组件、新增页面、开发这个功能、生成代码、帮我写、implement、
  create component、build feature、generate code、write a、开发、编写、添加。
  产出：代码文件（.vue / .ts / .js 等）+ 少量注释说明。
---

# Generator

> 需求 + 项目知识 → 生产级代码

## 核心原则

1. **遵循项目模式** — 从 `.project-knowledge/` 提取写法
2. **使用项目组件** — 查 `components/catalog.md`
3. **完整性** — loading、empty、error 全状态
4. **一致性** — 缩进、引号、命名、import 与项目一致

## 职责边界

→ [references/boundary.md](references/boundary.md)

> 🔴 generator 只写代码。缺少 PLAN.md/ARCHITECTURE.md → 提示先执行上游。

## 反例黑名单

| # | ❌ 反模式 | 为什么不要做 | ✅ 正确做法 |
|---|---------|-------------|-----------|
| 1 | **跳过 `.project-knowledge/` 凭记忆写代码** | 项目组件/模式可能已更新，凭记忆生成过时代码 | 先读 `context.json` + `components/catalog.md` 确认可用组件 |
| 2 | **用户说"涉及页面展示先确认"，仍然直接写** | 你的审美判断 ≠ 用户意图，未经确认的 UI 改动产生返工 | 展示改动点清单让用户确认，确认后再写 |
| 3 | **不读目标文件直接 overwrite** | 覆盖掉用户手动修改或 linter 自动修复 | 先 `Read` 目标文件，diff 理解现有状态，再 `Edit` 增量修改 |
| 4 | **新代码不找类似实现参考** | 同项目同类页面写法可能已约定，另起炉灶导致不一致 | grep 同模块其他页面的 import/组件使用方式，套用相同模式 |
| 5 | **async 操作无 loading 状态** | 用户点击后无反馈，重复点击或以为卡死 | 每个 API 调用包裹 `loading` ref，按钮 `:loading` 绑定 |
| 6 | **TS 类型滥用 `any`** | 破坏类型安全，后续重构无保护 | 从 `types/` 导入已有接口，新接口在对应 `.d.ts` 定义 |
| 7 | **跳过上游 PLAN.md/ARCHITECTURE.md 直接生成** | 无视架构决策（composable边界/数据流/模块划分），生成后与设计冲突 | 先读 PLAN.md（任务拆解+估时）和 ARCHITECTURE.md（决策+模块设计），再套用模式生成 |
| 8 | **修改已有文件不保留原有注释和结构** | 破环代码可读性，reviewer 难以 diff | `Edit` 用最小 `old_string` 匹配，只改必要部分，保留周围代码不变 |

## 前置条件

| 优先级 | 资源 | 缺失时 |
|--------|------|--------|
| 0 | **`context.json`**（[Context Protocol](../../runtime/context/context.md)）| 🔴 BLOCK 若缺 REQUIRED 字段 → [priority](../../runtime/context/context-priority.md)；不存在则从 `.project-knowledge/` 提取 |
| 1 | `.project-knowledge/index.md` | 降级通用模式 |
| 2 | `PLAN.md`，**若存在必读** | 标注"⚠️ 无规划" |
| 3 | `ARCHITECTURE.md`，**若存在必读** | 标注"⚠️ 无架构约束" |

> `context.json` 来自 analyzer 的 Finish 阶段，包含技术栈/路径别名/编码约定/模块清单。加载后不再需逐个读 `.project-knowledge/` 文件。

## 项目知识读取（context.json 覆盖后按需补充）

| 生成类型 | context.json 已覆盖 | 按需补充 |
|---------|-------------------|---------|
| 组件 | 技术栈、别名、组件风格、已有组件列表 | `components/catalog.md`（组件详情） |
| 页面 | 路径别名、分页参数、路由模块 | `architecture/overview.md`（路由架构） |
| API 模块 | API 前缀、封装函数名、响应类型 | `api/request.md`（拦截器细节） |
| 工具函数 | 语言版本、import 规范 | `patterns/typescript.md` |
| 类型定义 | 语言版本、路径别名 | `patterns/typescript.md` |

## 工作流

### Discover

1. 读项目知识库 + PLAN.md/ARCHITECTURE.md
2. **Graph 查询** → [Graph Query Protocol](../../runtime/contracts/graph-query.md)：
   - `findNode("component", <当前组件>)` → 确认所属模块
   - `findProducers(<当前组件>)` → 了解依赖的上游 API/Store
   - `findNode("api", <关键词>)` → 已有 API 直接复用，不重复创建
3. 🔴 代码存在性检查 → [references/code-audit.md](references/code-audit.md)
4. 找类似实现，确认技术栈
5. 🔴 CHECKPOINT — 展示过滤后的改动范围（新建/修改文件清单+预估行数），用户确认后进入 Execute

### Execute

```
读知识库 → 找参考实现 → 提取模式 → 套用模式生成 → 自检
```

自检清单 → [references/self-check.md](references/self-check.md)

🔴 CHECKPOINT — 展示代码摘要（文件清单+关键片段），用户确认后写入文件

### 完成报告

→ [references/completion-report.md](references/completion-report.md)

## 失败处理

| 触发条件 | 一线修复 | 仍失败兜底 |
|---------|---------|-----------|
| `.project-knowledge/` 不存在 | 降级通用模式（Element Plus 原生、标准 TypeScript） | 标注 `⚠️ 未找到项目知识库`，代码偏保守 |
| PLAN.md 缺失且需求复杂 | 从用户描述推断组件结构 | 标注"⚠️ 无规划"，尽量生成但可能不完整 |
| `# Decision` 未全部 resolve（影响的任务） | 对受影响任务降级生成，使用最保守方案 | 标注"⚠️ 存在未 resolve 决策: D-XX" |
| 目标文件已存在（重复生成） | 检查是否同一功能 → diff 后增量修改 | 标注 `[已存在]`，跳过不覆盖 |
| 需新增依赖（package.json 未安装） | 使用已有依赖的替代方案 | 标注 `TODO: 安装 {package}`，不修改 package.json |
| 无类似实现可参考（全新模式） | 使用 `context.json` 中的项目约定生成 | 标注"⚠️ 全新模式，建议人工审核" |

## 输出末尾：Workflow Hint 块

生成完成报告结尾必须附带：

```markdown
## Workflow Hint

| # | capability | confidence | reason |
|---|-----------|:----------:|--------|
| 1 | {capability} | {0-100} | {一句话理由} |
| 2 | {capability} | {0-100} | {备选理由} |

> 💡 能力→技能映射见 `shared/routing.tsv`。
```

**产出 cap 规则**：
- 新建/修改 > 5 个文件 → 推荐 `code-review`（confidence: 85+），备选 `code-testing`（confidence: 70+）
- 涉及 API 对接 → 备选 `code-testing`（confidence: 75+）
- 仅 1-3 个小改动 → 推荐 `code-review`（confidence: 70+），备选 `documentation`（confidence: 50+）
- 始终最多 2 项
