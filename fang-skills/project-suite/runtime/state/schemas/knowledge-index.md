# Knowledge Index v1.0.0

> Capability-based knowledge lookup。将"按文件路径读知识"升级为"按能力标签查询知识"。
> Skill 不需要知道 `.project-knowledge/` 的目录结构——只需要声明需要什么能力。
>
> 📖 **人类读这里** · ⚙️ **Schema: [knowledge-index.schema.json](knowledge-index.schema.json)** · 📍 **输出: `.project-knowledge/knowledge-index.json`**

## 设计目标

```
Before（Knowledge as Files）:
  Generator: "我需要 patterns/vue.md + patterns/form.md + components/catalog.md"
  → 硬编码文件路径，目录结构变更则全部 Skill 失效

After（Knowledge as Capability）:
  Generator: "我需要 rules + patterns"
  → knowledge-index.json 解析到具体文件，目录结构变更只改 index
```

**核心收益：**
- Context 减半 — 声明 2 个 capability 而非列举 5+ 个文件
- 解耦 — Skill 不知道文件路径，analyzer 重组目录不影响下游
- 可发现 — "有哪些 capability 可用？" → 直接看 index keys

## Knowledge Metadata（v1.1）

每个 `files` 元素不再是裸路径，而是带统一元数据的对象，回答「这个知识对象是什么、带什么约束」：

| 字段 | 取值 | 含义 |
|------|------|------|
| `source` | `rules/form-component-standard.md` | 相对 `.project-knowledge/` 的路径 |
| `type` | `rule` / `decision` / `pattern` / `component` / `api` / `experience` / `playbook` | 知识类别 |
| `enforcement` | `blocking` / `recommended` / `advisory` | 强制级别 |
| `priority` | `P1` / `P2` / `P3` | 知识分量 |
| `scope` | `task` / `project` / `organization` / `personal` | 仅 decision：task=一次性 feature ADR，project=长期项目决策 |

**默认映射（可由文件 frontmatter 覆盖）：**

| 目录 | type | enforcement | priority |
|------|------|-------------|----------|
| `rules/` | rule | blocking | P1 |
| `decisions/` | decision | 按 scope：project→blocking/P1，task→advisory/P2 |
| `patterns/` `components/` `api/` `architecture/` | pattern/component/api | recommended | P2 |

> `architecture/` → `type: pattern` 是**有意的归一化**（架构总览不是独立 type，按 pattern 处理），
> 不是 schema/producer 漂移。compiler 的 `emit_one "architecture" ... "pattern"` 与之对应。
| `experience/` `playbooks/` | experience/playbook | advisory/recommended | P3 |

> 区分两类知识：`rules/decisions/experience/playbooks` 是**用户手工维护的强制约束**（不是 analyzer 产出），Knowledge Compiler 必须把它们扫进来并打上 blocking 标签；`patterns/components/api` 是 analyzer 从代码发现的参考模式。

## Schema

文件位置：`.project-knowledge/knowledge-index.json`

```json
{
  "schemaVersion": "1.1.0",
  "generatedBy": "knowledge-compiler",
  "generatedAt": "2026-08-20T00:00:00Z",

  "capabilities": {
    "rules": {
      "description": "用户手写的强制编码规则",
      "files": [
        { "source": "rules/form-component-standard.md", "type": "rule", "enforcement": "blocking", "priority": "P1" },
        { "source": "rules/workspace-priority.md", "type": "rule", "enforcement": "blocking", "priority": "P1" }
      ]
    },
    "decisions": {
      "description": "用户手写的架构决策 ADR（按 scope 区分 project/task）",
      "files": [
        { "source": "decisions/architecture-decisions.md", "type": "decision", "scope": "project", "enforcement": "blocking", "priority": "P1" },
        { "source": "decisions/ARCHITECTURE-quota-mail-config.md", "type": "decision", "scope": "task", "enforcement": "advisory", "priority": "P2" }
      ]
    },
    "patterns": {
      "description": "代码发现的模式",
      "files": [
        { "source": "patterns/table.md", "type": "pattern", "enforcement": "recommended", "priority": "P2" }
      ]
    },
    "components": {
      "description": "组件编目",
      "files": [
        { "source": "components/catalog.md", "type": "component", "enforcement": "recommended", "priority": "P2" }
      ]
    },
    "experience": {
      "description": "项目经验教训",
      "files": [
        { "source": "experience/workspace-page-patterns.md", "type": "experience", "enforcement": "advisory", "priority": "P3" }
      ]
    }
  }
}
```

## 使用方式

### Generator — 消费 context-package（不读 index）

```
1. 读 context-package.json（Resolver 已预消化，见 ../../knowledge-resolver.md）
2. rules[] → 加载 blocking 约束；knowledge[] → 注入 pattern；guidance[] → 参考
3. 不再读 knowledge-index.json，也不再读整个 patterns/ 目录
```

**对比：**

| | 旧方式（knowledge-list.json，已废弃） | 新方式（knowledge-index.json → context-package.json） |
|---|---|---|
| Planner 产出 | `files: ["patterns/vue.md", "patterns/form.md", ...]` | `capabilities: ["rules", "patterns"]` → Resolver 预消化 |
| Generator 加载 | 遍历 files 列表读文件 | Resolver 遍历 knowledge[] 直接注入 pattern/constraints |
| 文件路径变更 | Planner + Generator 都要改 | 只改 index |
| Context 大小 | N 个文件路径 | 预消化知识包，无需 Generator 解析 |

### Planner — 按 capability 推荐

```
1. 读 knowledge-index.json → 了解有哪些 capability 可用
2. 分析需求 → 推导需要的 capability → e.g. "新增审批页面" → [patterns, components, api]
3. 产出 context-package.json（Resolver 预消化，Generator 直接注入）
```

### Reviewer — 按 capability 加载审查规则

```
1. 读 knowledge-index.json
2. 根据变更文件类型 → 确定需要的 capability → e.g. 改 API 文件 → [api, rules]
3. 加载对应审查规则 → 对照检查
```

### 用户/Dispatcher — 发现可用能力

```
"这个项目有哪些 capability？"
→ 读 knowledge-index.json → 展示 capability 列表 + description
→ 决定需要执行哪些 skill
```

## 生成规则

**生产者：knowledge-compiler**（独立 `runtime/knowledge/` 模块，实际逻辑见 [knowledge-compiler.md](../knowledge/knowledge-compiler.md)）

生成逻辑（确定性，非语义聚类）：
```
1. 扫描 .project-knowledge/ 下 8 个目录的 .md 文件（跳过 index.md）
2. 按目录打 type/enforcement/priority 元数据标签（capability = 目录名）
3. 每个 capability 生成 description + files（object[]：source/type/enforcement/priority）
4. 写入 .project-knowledge/knowledge-index.json
```

**更新规则（change-detection）：**
- 源文件无变化 → 复用已有 index（content-hash 检测）
- `rules/decisions/experience/playbooks` 变化 → 只重扫这些源（**不重跑 analyzer**）
- `graph.json` 变化 → 不触发 Compiler（它是结构事实，由 Planner/Architect/Generator 经 graph-query 直接读，不是 Resolver 输入）
- 其他 skill 只读不写

## 与 context-package.json 的关系

```
knowledge-index.json   — 全局映射（knowledge-compiler 产出，所有 skill 可用）
context-package.json    — 任务级知识包（Resolver 产出，generator 消费）
                           ↑ 预消化 pattern + constraints + components

⚠️ Legacy: knowledge-list.json（v1 文件路径清单）已废弃，不再作为正式输入。
```
