# Knowledge Query API v1.0

> 统一知识查询接口。Skill 通过结构化查询获取 Knowledge Object，而非读取 .md 文件。

## Knowledge Access 边界（两类访问）

Skill 获取数据分两类，边界清晰，避免 "Skill A → query, Skill B → md, Skill C → graph" 的失控：

| 类别 | 访问方式 | 例子 |
|------|---------|------|
| **Knowledge**（项目知识/长期积累） | **必须走 Query API** | pattern / convention / decision / instinct / component / glossary |
| **Task Artifact**（任务产物/一次性） | **直接读文件** | PLAN.md / ARCHITECTURE.md / 目标源码 / REVIEW.md |

```
Knowledge（需要什么知识？）
  → knowledge.query
  → Context Package（预消化，注入而非读文件）

Task Artifact（本次任务的具体输入）
  → @adapter:filesystem.read
```

**规则**：Knowledge 不直接读 .md；Artifact 不通过 Query。这条边界由 Context Resolver 统一守护——所有知识消费必经它。

## 查询语法

```
@knowledge:<type> [filters]
```

## 查询参数

| 参数 | 示例 | 说明 |
|------|------|------|
| `type` | `pattern` `convention` `principle` `decision` `risk` `antipattern` `instinct` `all` | 知识类型 |
| `scope` | `project` `organization` `personal` | 范围过滤 |
| `tags` | `form,vue3,validation` | 标签（AND） |
| `confidence>=` | `0.8` | 最低置信度 |
| `related_to` | `pattern.repository` | 与指定 id 关联的知识 |
| `limit` | `10` | 返回条数上限 |

## 返回格式

```yaml
query: { type: pattern, scope: project, tags: [form], confidence>=: 0.8 }
results:
  - id: pattern.form-wrapper
    type: pattern
    confidence: 0.96
    statement: "所有复杂表单使用 FormWrapper 封装"
    evidence: [{path: workspace/views/, type: ratio, note: "331 files use FormWrapper"}]
    related:
      - {id: convention.form-naming, relation: references}
      - {id: principle.always-form-wrapper, relation: implements}
    score: { quality: 0.95, reuse: 12, freshness: 1.0 }
    tags: [form, vue3, wrapper]
```

## 各 Skill 查询模式

| Skill | 典型查询 | 用途 |
|-------|---------|------|
| **Planner** | `type=pattern,component,api scope=project` | 了解可复用资产 |
| **Architect** | `type=decision scope=project` | 避免重复决策 |
| **Generator** | `type=pattern,convention,component tags=<module>` | 套用模式生成代码 |
| **Reviewer** | `type=antipattern,risk scope=project` | 对照审查 |
| **Documenter** | `type=api,component scope=project` | 溯源文档 |
| **Tester** | `type=convention tags=test` | 遵循测试规范 |

## CLI 工具

`shared/scripts/knowledge-query.sh` — 从 `graph.json` 中查询：

```bash
# 查询所有 Form 相关的 pattern
bash shared/scripts/knowledge-query.sh --type pattern --tags form

# 查询高置信度 convention
bash shared/scripts/knowledge-query.sh --type convention --confidence 0.8

# 查询与 repository pattern 关联的所有知识
bash shared/scripts/knowledge-query.sh --related-to pattern.repository
```
