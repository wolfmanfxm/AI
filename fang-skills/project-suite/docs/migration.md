# Migration Guide

> 从独立 `project-analyzer` 迁移到 `project-suite/skills/analyzer/` 的指南。

## 发生了什么

`project-analyzer` 原本是一个独立 skill，自带 protocol、schema、templates 等基础设施。现在它成为 `project-suite` 中的一个 skill，共享的基础设施提升到 `runtime/` 和 `shared/`。

## 文件映射

| 原路径（project-analyzer/） | 新路径（project-suite/） | 说明 |
|---------------------------|------------------------|------|
| `SKILL.md` | `skills/analyzer/SKILL.md` | 更新触发词引用 + runtime 引用 |
| `prompts/*.md` | `skills/analyzer/prompts/*.md` | 直接复制 |
| `references/trigger-words.md` | `skills/analyzer/references/trigger-words.md` | 直接复制 |
| `references/capability-matrix.md` | `skills/analyzer/references/capability-matrix.md` | 更新引用路径 |
| `references/anti-patterns.md` | `skills/analyzer/references/anti-patterns.md` | 更新引用路径 |
| `references/exceptions.md` | → `runtime/engine/error-recovery.md` | 提升为通用协议 |
| `protocol/phase-1-discovery.md` | → `runtime/engine/state-machine.md` | 提升为通用状态机 |
| `protocol/phase-2-execution.md` | → `runtime/engine/state-machine.md` | 同上 |
| `protocol/phase-2-finish.md` | → `runtime/engine/state-machine.md` | 同上 |
| `protocol/runtime-protocol.md` | → `runtime/engine/error-recovery.md` + `runtime/engine/checkpoint.md` | 拆分提升 |
| `protocol/development-flow.md` | → `SUITE.md` + `skills/analyzer/references/development-flow.md` | 拆分：框架部分 → SUITE，skill 专属部分保留 |
| `schema/analysis-config.schema.json` | `shared/schemas/analysis-config.schema.json` | 提升 |
| `schema/manifest.schema.json` | `shared/schemas/manifest.schema.json` | 提升 |
| `schema/graph.schema.json` | `shared/schemas/graph.schema.json` | 提升 |
| `templates/*` | `shared/templates/` | 提升 |
| `examples/output-example.md` | `shared/examples/analyzer-output.md` | 提升并重命名 |

## SKILL.md 变更

### Frontmatter

```yaml
# 旧
name: project-analyzer

# 新
name: analyzer
```

### 引用路径变更

```markdown
# 旧
[protocol/phase-1-discovery.md](protocol/phase-1-discovery.md)

# 新
[../../runtime/engine/state-machine.md](../../runtime/engine/state-machine.md)（通用状态机）
→ 见 skills/analyzer/references/development-flow.md（analyzer 专属流程）
```

## 向后兼容

迁移后，用户原有的 `.project-knowledge/` 产出依然有效。新旧 manifest 的 schema 差异通过 `schemaVersion` 字段自动适配。

## 迁移检查清单

- [ ] 复制 prompts/ 到 skills/analyzer/prompts/
- [ ] 复制 references/ 专属文件到 skills/analyzer/references/
- [ ] 复制 schema/ 到 shared/schemas/
- [ ] 复制 templates/ 到 shared/templates/
- [ ] 复制 examples/ 到 shared/examples/（重命名）
- [ ] 更新 SKILL.md frontmatter（name: analyzer）
- [ ] 更新 SKILL.md 中所有引用路径
- [ ] 更新 prompts 中所有引用路径
- [ ] 验证：从 skills/analyzer/ 触发 skill，确认 runtime 文件可访问
- [ ] 原始 project-analyzer/ 目录保留但不再使用（或删除）
