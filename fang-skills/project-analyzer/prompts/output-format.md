# Output Format Specification

## 通用规则

1. **Markdown + YAML Frontmatter** — 分析产出用 `.md`，元数据用 `.json`
2. **源文件引用** — `file:line` 格式
3. **实际代码** — 从源文件复制，不编造
4. **中文主体** — 描述用中文，代码原文

## 固定产出

每次分析必定生成：

| 文件 | 模板 |
|------|------|
| `manifest.json` | [templates/metadata/manifest.json](../templates/metadata/manifest.json) |
| `index.md` | [templates/metadata/index.md](../templates/metadata/index.md) |
| `search-index.json` | [templates/metadata/search-index.json](../templates/metadata/search-index.json) |
| `architecture/overview.md` | [templates/architecture/overview.md](../templates/architecture/overview.md) |
| `changelog/latest.md` | 记录本次知识变化 |

## 按需产出

根据分析发现动态创建，**有内容才建文件**。参考维度：

- `architecture/` — modules.md, tech-stack.md, dependencies.md 等
- `components/` — catalog.md, {{ComponentName}}.md 等
- `api/` — request.md, auth.md, modules.md 等
- `ui/` — layout.md, table.md, form.md, dialog.md 等
- `coding-style/` — typescript.md, vue.md, naming.md 等
- `patterns/` — crud.md, search.md 等（从 UI 和编码中提取的可复用模式）
- `observations/` — statistics.md, duplicates.md, dead-code.md 等
- `proposals/` — {{rule-name}}.md（候选规范，待人工确认）
- `reports/` — latest.md, quality.md, coverage.md

## 人工目录（仅 index.md）

`rules/` `playbooks/` `experience/` `decisions/`

## Frontmatter

```yaml
---
date: YYYY-MM-DD
project: <项目名>
version: <YYYYMMDD.N>
---
```
