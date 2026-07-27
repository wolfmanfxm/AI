# Conventions

> 所有 skill 和产出文件遵循的统一约定。

## 文件命名

| 规则 | 示例 |
|------|------|
| skill 名：小写英文 | `analyzer` `planner` `generator` |
| prompt 文件：kebab-case | `architecture.md` `code-generation.md` |
| 产出文件：kebab-case | `overview.md` `component-catalog.md` |
| JSON 文件：kebab-case | `manifest.json` `analysis-config.json` |
| schema 文件：kebab-case 后缀 `.schema.json` | `manifest.schema.json` |

## SKILL.md 格式

```yaml
---
name: skill-name
description: >
  一行或多行描述。包含 触发场景 和 产出。触发词见 references/trigger-words.md。
---
```

- name 与目录名一致
- description 是触发的主要依据，需包含具体触发词和场景
- 中文描述为主

## 产出文件格式

### Markdown

- YAML Frontmatter 必须包含：`id`, `generatedBy`, `generatedAt`, `confidence`, `sources`
- 中文描述 + 代码原文
- 源文件引用格式：`[file:line]`（如 `src/api/user.ts:42`）

### JSON

- 必须有 `$schema` 或 `schemaVersion` 字段
- ISO 8601 时间格式
- camelCase 属性名

## Skill 间引用

skill 引用 suite 内其他文件时，使用相对路径：

```markdown
[../../runtime/engine/state-machine.md](../../runtime/engine/state-machine.md)
[../../shared/schemas/manifest.schema.json](../../shared/schemas/manifest.schema.json)
```

## 语言

- 协议文件：中文
- prompt 文件：中文指令 + 英文技术术语
- schema 文件：英文（property names）+ 中文 description
- 产出文件：中文描述 + 原文代码
