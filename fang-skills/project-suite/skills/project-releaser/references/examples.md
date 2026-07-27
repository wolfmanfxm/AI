# Examples — Releaser

> 真实发布示例。

---

## 示例 1：完整发布流程

### 输入

> "准备发布，从 v1.2.0 以来的变更"

### 收集到的材料

```
Commits:
  feat(auth): add OAuth2 login (#123)
  fix(table): pagination not resetting (#124)
  feat(order): batch export to Excel (#125)
  chore(deps): upgrade Element Plus (#127)
  docs(api): update auth endpoints

Tests: 42/42 ✅
Review: 无 BLOCKER
```

### 输出

**版本号**：v1.3.0 (MINOR bump) — 2 个 feat

**RELEASE-CHECKLIST.md**：

| # | 检查项 | 状态 |
|---|--------|------|
| 1 | 测试全部通过 | ✅ 42/42 |
| 2 | Code Review 完成 | ✅ 无 BLOCKER |
| 3 | Breaking Changes | ✅ 无 |
| 4 | 文档已更新 | ✅ api docs |
| 5 | 回滚方案 | `git revert` 或回滚 tag `v1.2.0` |

**CHANGELOG.md**（摘要）：

```markdown
# Changelog — v1.3.0 (2026-07-27)

## 🚀 Features
- **auth**: add OAuth2 login support (#123)
- **order**: support batch export to Excel (#125)

## 🐛 Fixes
- **table**: pagination not resetting on filter change (#124)

## 🔧 Maintenance
- **deps**: upgrade Element Plus 2.13→2.14 (#127)

## 📝 Docs
- **api**: update authentication endpoints documentation
```

---

## 示例 2：有 Breaking Change

### 输入

> "下一个版本号？我们改了 login API 的参数"

### Commit

```
feat!(auth): change login API parameters
  BREAKING CHANGE: login(email, password) → login({ email, password, captcha? })
```

### 输出

**版本号**：v2.0.0 (MAJOR bump) — 1 个 Breaking Change

**CHANGELOG.md 关键部分**：

```markdown
## ⚠️ Breaking Changes
- **auth**: changed login API signature. `login(email, password)` → `login({ email, password, captcha? })`
  迁移：将所有 `login(email, password)` 调用改为对象参数形式。
  详见 src/api/auth.ts 新函数签名。
```
