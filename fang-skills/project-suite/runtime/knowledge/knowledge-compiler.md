# Knowledge Compiler v1.0.0

> 汇总、分类、索引知识。**不是 analyzer**——analyzer 从代码发现结构事实（→ `graph.json`）。
> Compiler 扫描 **authored knowledge**（`.project-knowledge/` 下的 .md 文件），打上统一元数据，生成 `knowledge-index.json`。
> `graph.json`（JSON 结构事实）由 Planner/Architect/Generator 经 graph-query.md 直接查询——**既不是 Compiler 输入，也不是 Resolver 输入**。

## 职责边界

| 模块 | 职责 | 产物 |
|------|------|------|
| project-analyzer | 从代码发现结构事实 | `graph.json`（组件/API/模块 + 依赖，Planner/Architect 经 graph-query 查询） |
| **knowledge-compiler** | 扫描 .md 知识 → 分类/打标签 | `knowledge-index.json`（metadata-only） |
| context-resolver | 按任务分桶 + hydrate | `context-package.json` |

关键区分：

- `graph.json` = analyzer 的「结构事实」（组件/API/模块 + 依赖），由 Planner/Architect/Generator 经 graph-query.md 直接查询，**既不是 Compiler 输入，也不是 Resolver 输入**。
- `rules/decisions/experience/playbooks` = 用户手工维护的**强制约束**，Compiler 必须扫进来。
- `knowledge-index.json` = 统一索引，**只存 metadata，不复制 Markdown 正文**。

## 输入（.md 知识源）

Compiler 扫描 `.project-knowledge/` 下 8 个目录的 .md 文件（**不含 `graph.json`**）：

| 目录 | 来源 | 级别 |
|------|------|------|
| `rules/` `decisions/` | 用户手写强制约束 | P1 |
| `patterns/` `components/` `api/` `architecture/` | analyzer 产出参考模式 | P2 |
| `experience/` `playbooks/` | 用户手写经验/手册 | P3 |

> `graph.json`（analyzer 的 JSON 结构事实）**不是 Compiler 输入**，由 Planner/Architect/Generator 经 graph-query.md（findNode/findTransitiveDeps/findConsumers）直接查询。

## 输出

`.project-knowledge/knowledge-index.json`（capability-keyed + 每文件 Knowledge Metadata）

## 元数据映射（默认，可被文件 frontmatter 覆盖）

| 目录 | type | enforcement | priority |
|------|------|-------------|----------|
| `rules/` | rule | blocking | P1 |
| `decisions/` | decision | 按 scope：project→blocking/P1，task→advisory/P2 | 见下方 decision 区分 |
| `patterns/` `components/` `api/` `architecture/` | pattern / component / api | recommended | P2 |
| `experience/` `playbooks/` | experience / playbook | advisory / recommended | P3 |

> 分类规则：先看 `type`（是什么类别）→ 定 `priority`（P1/P2/P3）→ 定 `enforcement`（blocking/recommended/advisory）。

## constraint 必需性（按 type 分级）

| type | constraint | 说明 |
|------|-----------|------|
| `rule`（`rules/`） | **REQUIRED** | 强制编码规则必须有精确的一句话约束 |
| `decision`（`decisions/`，长期 project decision） | **REQUIRED** | 长期项目决策必须写清约束 |
| `experience` / `playbook` | OPTIONAL | 经验/手册无强制约束 |
| `pattern` / `component` / `api` | 不需要 | 走 `context-package` 的 `knowledge.constraints` |

> **decision 区分（已实现）**：compiler 用 `detect_scope` 确定性区分——优先 frontmatter `scope:`，
> 否则按文件名约定（`ARCHITECTURE-*.md` → task，其余 → project）。
> project decision → enforcement=blocking（进 constraints，constraint REQUIRED）；
> task decision（一次性 feature ADR）→ enforcement=advisory（进 guidance，不进 blocking）。

## 触发时机（change-detection）

1. **每次任务开始前**：检查 `.project-knowledge/` 下 8 个目录的 .md 是否有变化：
   - 有变化 → 重扫 .md（不重跑 analyzer）
   - 无变化 → 直接复用已有 index

> 用户改一条 rule 后，**不需要重跑 analyzer，也不需要跑 documenter**。Compiler 检测到 `rules/` 变化 → 重扫 → 更新 index。
> `graph.json` 变化**不触发** Compiler（它不是 Resolver 输入；结构事实由各 Skill 经 graph-query 直接读，每次任务即时查询）。

## 与 analyzer / resolver 的关系

```
project-analyzer ──→ graph.json ──(结构事实)──→ Planner/Architect/Generator 直接读（graph-query）
knowledge-compiler ──→ knowledge-index.json ──→ context-resolver ──→ context-package.json
      ↑
rules/decisions/experience/playbooks/patterns/components/api/architecture
```

- Compiler 只扫 .md 知识文件，**不碰 graph.json**。
- graph.json 是结构事实，由 Planner/Architect/Generator 经 graph-query.md 直接查询，**不经过 Resolver**。
- Resolver 只读 knowledge-index.json（Compiler 产出）；graph.json 不是 Resolver 输入。
- Compiler 独立于 analyzer：改 rule 只重扫 .md，不重跑 analyzer。

## lifecycle 过滤（只作用于 analyzer 产出的目录）

Compiler 读 `runtime/knowledge.json`（analyzer 产出），对 **analyzer 产出的目录**（`patterns/components/api/architecture`）排除
`status` 明确为「非 Accepted」（Candidate / Deprecated / expired / rejected / Artifact / draft）的 source。

- `rules/decisions/experience/playbooks` 是用户手写的权威约束，**恒入 index**，不受 lifecycle 过滤。
- `runtime/knowledge.json` 缺失 → 排除清单为空 → 不过滤（bootstrap 向后兼容，不丢未分类文件）。
- lifecycle status 变化会纳入 change-detection hash：`Candidate → Accepted` 晋升无需改 .md 也能触发重扫。

> 这兑现了 [knowledge-lifecycle.md](../state/schemas/knowledge-lifecycle.md) 里「index 只列 Accepted」的声明，
> 但**只对 analyzer 产出的目录生效**——用户手写的 rules/decisions 不受 lifecycle 门控（它们是 born-accepted 的权威约束）。

## 自校验

Compiler 完成后校验（失败则 exit 1，拒绝生成有效 index）：

- `source` 存在
- `type` / `enforcement` / `priority` 取值合法
- `rules` / `decisions` 都含 `constraint`（REQUIRED）
- 无重复 source
- 无悬空 capability

> 校验结果不单独落文件，直接以 exit code 表达：`exit 0` = 有效，`exit 1` = 无效（打印 ❌ 清单）。
