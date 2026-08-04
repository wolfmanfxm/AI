# Knowledge Builder

> 从 Accepted Candidates 组装最终 `.project-knowledge/` 产出。

## Actions

1. 收集 Verifier 输出的所有 Accepted Candidates（含 confidence-adjusted）
2. 按知识类型分组（architecture / patterns / conventions / glossary / decisions / risks / antipatterns）
3. **逐组写入**最终 .md 文件——每组 Candidate 必须覆盖，不得跳过
4. 注入 Evidence Score Section（每个 Claim 的溯源）
5. 生成跨文件交叉引用

## Coverage Gate

**全部完成前不可退出。** 逐项验证：

| Candidate | 目标文件 | 验证方式 |
|-----------|---------|---------|
| directory.md | architecture/modules.md | 目录树 + 模块清单已合并 |
| framework.md | architecture/tech-stack.md | 技术栈表已写入 |
| architecture.md | architecture/overview.md | 分层+边界已写入 |
| patterns.md | patterns/*.md | 每种模式独立文件 |
| conventions.md | conventions/*.md | 每种规范独立文件 |
| glossary.md | architecture/glossary.md | 术语表已写入 |
| decisions.md | architecture/decisions.md | 决策记录已写入 |
| risks.md | observations/risks.md | 风险清单已写入 |
| antipatterns.md | observations/antipatterns.md | 反模式清单已写入 |
| principles.md | conventions/principles.md | Always/Never/Prefer/Avoid 已写入 |

**未覆盖的 Candidate → 返回重写对应文件 → 不可 Exit。**

## Output Structure

**双轨输出**：Machine-readable Knowledge Graph（下游 Skill 消费）+ Human-readable Markdown（人读）。

```
.project-knowledge/
├── knowledge-graph.yaml     ← ⭐ 权威知识图谱（machine-readable）
├── architecture/
│   ├── overview.md          ← 人读版本
│   ├── modules.md
│   └── tech-stack.md
├── patterns/
├── conventions/
├── glossary.md
├── decisions.md
├── risks.md
├── antipatterns.md
├── principles.md
├── INDEX.md
├── statistics.json
├── context.json
└── graph.json
```

## knowledge-graph.yaml — Knowledge Objects

从 accepted candidates 组装 → [schema](../../../shared/schemas/knowledge-object.schema.json)

```yaml
# .project-knowledge/knowledge-graph.yaml
nodes:
  - id: pattern.repository
    type: pattern
    category: behavioral
    confidence: 0.94
    statement: "项目使用 Repository Pattern 封装数据访问"
    evidence:
      - { path: src/repositories/UserRepository.ts, type: file, lines: 45 }
      - { path: src/repositories/OrderRepository.ts, type: file, lines: 62 }
    related:
      - { id: principle.repository, relation: implements }
      - { id: api.customer, relation: references }
    source: { extractor: pattern, verdict: accepted }
    occurrences: 17
    predictive_power: "Can answer: where to add data access for new entity?"
    obviousness: non-obvious
    tags: [repository, data-access, abstraction]

  - id: convention.pascalcase
    type: convention
    category: behavioral
    confidence: 0.95
    statement: "组件命名使用 PascalCase"
    evidence:
      - { path: workspace/views/, type: ratio, note: "95% of .vue files" }
    related:
      - { id: antipattern.kebabcase, relation: contradicts }
    source: { extractor: convention, verdict: accepted }
    occurrences: 380
    obviousness: somewhat-obvious
    tags: [naming, component, convention]

edges:
  - { from: pattern.repository, to: principle.repository, relation: implements }
  - { from: pattern.repository, to: api.customer, relation: references }
  - { from: convention.pascalcase, to: antipattern.kebabcase, relation: contradicts }

# 下游 Skill 消费方式:
# Planner:   读取 knowledge-graph.yaml → 了解可复用资产
# Architect: 读取 nodes[type=decision] → 了解已有架构决策
# Generator: 读取 nodes[type=pattern,component,api] → 套用模式生成代码
# Reviewer:  读取 nodes[type=antipattern,risk] → 对照审查
```

## Evidence Score Section

每个 .md 文件末尾附 Evidence Score 表：

```markdown
## Evidence Score

| Claim | Confidence | Occurrences | Verified | Evidence |
|-------|-----------|-------------|----------|----------|
| Repository Pattern | 0.91 | 18 | ✅ | src/repositories/ (18 files) |
| PascalCase convention | 0.95 | 380 | ✅ | 95% of components |
| ... | | | | |

Overall Confidence: 0.89
```
