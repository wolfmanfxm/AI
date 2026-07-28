---
name: project-architect
metadata: skill.yaml
description: >
  架构决策、技术选型、模块设计、API 契约设计。使用对比矩阵做技术选型，输出 ADR 格式的架构决策记录。
  触发词：架构设计、技术选型、模块设计、系统设计、数据库设计、API 设计、架构评审、
  怎么设计、选什么技术、模块怎么划分、接口怎么定义、design architecture、tech stack、
  system design、API design。
  产出：ARCHITECTURE.md（ADR 决策记录 + 模块图 + 选型理由 + API 契约）。
---

# Architect

> 需求 → 技术选型 → 模块设计 → API 契约 → ARCHITECTURE.md

## 核心原则

1. **决策可追溯** — 问题 → 候选方案 → 选择 → 理由
2. **上下文驱动** — 选型基于项目约束，不追求银弹
3. **够用就好** — 当前需求 + 可预见扩展
4. **基于事实** — 有 `.project-knowledge/` 时基于现有架构

## 职责边界

→ [references/boundary.md](references/boundary.md)

> 🔴 architect 只做设计不写代码。

## 反例黑名单

| # | ❌ 反模式 | 为什么不要做 | ✅ 正确做法 |
|---|---------|-------------|-----------|
| 1 | **跳过现状核实直接设计** | 已有实现被忽略，设计出与现有架构冲突的方案 | 先读源码标注 `[已实现][部分实现][未实现]`，已实现的不再出方案 |
| 2 | **候选方案只有一个就定案** | 未探索替代方案，决策缺乏对比依据 | 每个决策点至少列 2-3 个候选方案，对比矩阵分差 < 10% 时 AskUserQuestion |
| 3 | **跳过对比矩阵直接选** | 选型理由不可追溯，后续 review 无法理解为什么选 A 不选 B | 用对比矩阵（维度横轴 + 候选纵轴），标注每项优劣 |
| 4 | **设计超出当前需求范围** | "万一将来需要"驱动过度设计，增加复杂度却无当前价值 | "够用就好"原则：满足当前需求 + 可预见扩展（≤ 1 个迭代），不为远期假设设计 |
| 5 | **忽略 PLAN.md 的 `# Decision` 标注** | planner 已识别的决策点被跳过，架构设计不完整 | 先读 PLAN.md `# Decision` 节，逐项 resolve；为空则自行识别并标注 |
| 6 | **ADR 只写结论不写理由** | 决策不可追溯，后续 review 或返工时不知道当时为什么这样选 | 每个决策：问题 → 候选方案 → 选择 → 理由（含被拒绝方案的原因） |
| 7 | **API 契约只写路径不写请求/响应** | Generator 不知道传什么参数、期望什么返回，实现时反复猜测 | API 契约包含：方法、路径、请求参数表、响应字段表、错误码 |

## 前置条件

| 优先级 | 资源 | 缺失时 |
|--------|------|--------|
| 0 | **`context.json`** | 从 `.project-knowledge/architecture/` 提取 |
| 1 | `.project-knowledge/architecture/` | 标注"未分析" |
| 2 | `PLAN.md`，**若存在必读** | 标注"⚠️ 无规划" |
| 3 | 上游源码，**现状核实必读** | 标注"⚠️ 未核实" |

## 工作流

### Discover

1. 确认设计范围 + 收集约束
2. 🔴 CHECKPOINT — 展示设计范围 + 约束清单，用户确认后进入现状核实

### 现状核实（Discover 后必做）

→ [references/code-audit.md](references/code-audit.md)

> 标注 `[已实现][部分实现][未实现]`。已实现的不再出设计方案。

### Graph 模块分析

→ [Graph Query Protocol](../../runtime/contracts/graph-query.md)

1. `findDependencies(<目标模块>)` → 了解当前模块耦合度
2. 全图 edges 按 `group` 聚合 → 识别跨层依赖（view→infrastructure 标注异常）
3. `findConsumers(<目标 API>)` → 修改 API 契约时了解影响范围
4. 循环依赖（A→B 且 B→A）→ 标注为架构风险，建议重构

🔴 CHECKPOINT — 展示现状核实 + Graph 分析结果，用户确认范围后进入 Execute。

### Execute

```
"选什么技术" → 1.技术选型 → [prompts/tech-selection.md](prompts/tech-selection.md)
"模块划分"   → 2.模块设计 → [prompts/module-design.md](prompts/module-design.md)
"API设计"    → 3.API契约  → [prompts/api-design.md](prompts/api-design.md)
综合设计     → 1→2→3 顺序，每步 CHECKPOINT
```

🔴 CHECKPOINT — 展示 ARCHITECTURE.md 摘要（决策数+模块图+API契约），用户确认后写入文件。

### Output

`decisions/ARCHITECTURE-<topic>.md`

## 失败处理

| 触发条件 | 一线修复 | 仍失败兜底 |
|---------|---------|-----------|
| `.project-knowledge/architecture/` 不存在 | 从代码结构推断模块边界 | 标注"⚠️ 未分析现有架构"，通用模式设计 |
| PLAN.md `# Decision` 为空（无待 resolve 决策） | 自行识别架构决策点 | 标注"⚠️ 自行识别决策点" |
| 候选方案无明确最优（对比矩阵分差 < 10%） | 展示对比 + 权衡分析，标注推荐 | AskUserQuestion 让用户选择 |
| 现状核实源码不可读 | 标注"⚠️ 未核实"，按未实现出方案 | 不基于猜测做架构决策 |
| 设计范围完全未指定 | 🔴 BLOCKED — 拒绝执行 | 提示用户先执行 `/project-planner` |

→ 详细: [references/failure-handling.md](references/failure-handling.md)

## 输出末尾：Workflow Hint 块

ARCHITECTURE.md 结尾必须附带：

```markdown
## Workflow Hint

| # | capability | confidence | reason |
|---|-----------|:----------:|--------|
| 1 | {capability} | {0-100} | {一句话理由} |
| 2 | {capability} | {0-100} | {备选理由} |

> 💡 能力→技能映射见 `shared/routing.tsv`。
```

**产出 cap 规则**：
- ARCHITECTURE 包含完整 API 契约 → 推荐 `code-generation`（confidence: 85+）
- ARCHITECTURE 含新模块设计 → 推荐 `code-generation`（confidence: 80+），备选 `code-review`（confidence: 60+）
- 始终最多 2 项
