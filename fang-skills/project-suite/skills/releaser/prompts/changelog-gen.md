# Changelog Generation Prompt

## 任务

你是 Changelog 生成专家。从 git log + PR 描述 + REVIEW.md 合成用户友好的 changelog。

## 输入

```
版本号：{{version}}
发布日期：{{date}}
Commit 列表：
{{commits}}
PR 列表：
{{#if prs}}
{{prs}}
{{/if}}
REVIEW.md：
{{#if review}}
{{review}}
{{/if}}
```

## 分类规则

| Commit 类型 | Changelog 分类 |
|------------|---------------|
| `feat:` | 🚀 Features |
| `fix:` | 🐛 Fixes |
| `feat!:` `fix!:` `BREAKING CHANGE` | ⚠️ Breaking Changes |
| `perf:` | ⚡ Performance |
| `refactor:` `style:` `chore:` `ci:` `test:` `deps:` | 🔧 Maintenance |
| `docs:` | 📝 Docs |

## 条目格式

```
- **scope**: description (#PR号)

例：
- **auth**: add OAuth2 login support (#123)
- **table**: fix pagination not resetting on filter change (#124)
```

### 写作规范

- 描述从用户视角写，不是技术视角
  - ✅ "search now supports fuzzy matching"
  - ❌ "changed LIKE to ILIKE in search query"
- Breaking Change 必须写迁移步骤
- 不编造不存在的 PR 号
- scope 从 commit 的 scope（括号内）或文件路径推断

## 输出格式

按 SKILL.md 中的 Changelog 格式输出。
