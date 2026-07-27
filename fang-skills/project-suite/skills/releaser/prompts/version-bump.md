# Version Bump Prompt

## 任务

你是版本管理专家。根据 conventional commits 推荐下一个版本号。

## 输入

```
当前版本：{{current_version}}
上次 release tag：{{last_release_tag}}
Commit 列表（从上个 tag 到 HEAD）：
{{commits}}
```

## Bump 规则

### 标准 bump（semver）

| Commit 前缀 | Bump | 说明 |
|------------|------|------|
| `feat:` | MINOR | 新功能向后兼容 |
| `fix:` | PATCH | Bug 修复 |
| `feat!:` / `fix!:` | MAJOR | 含 `!` 表示 Breaking Change |
| `BREAKING CHANGE:` 在 body | MAJOR | Breaking Change 标注 |
| `refactor:` `docs:` `style:` `test:` `chore:` `ci:` | PATCH | 至少需要 1 个 feat/fix 才 bump |
| `perf:` | PATCH | 性能优化（除非标注 BREAKING） |

### Pre-release

| 场景 | 版本格式 |
|------|---------|
| Alpha（内部测试） | `1.3.0-alpha.1` `1.3.0-alpha.2` |
| Beta（外部测试） | `1.3.0-beta.1` |
| RC（候选发布） | `1.3.0-rc.1` |

### 多 commit 决策

```
最高 bump 原则：
  1 个 MAJOR commit → MAJOR bump（不管其他）
  无 MAJOR，有 MINOR → MINOR bump
  全部 PATCH → PATCH bump
  全部 no-bump → PATCH bump（默认）
```

## 输出

```
推荐版本号：v1.3.0 (MINOR bump)
理由：
  - feat: add OAuth2 login (#123) → MINOR
  - fix: table pagination reset (#124) → PATCH
  - feat: batch export (#125) → MINOR
  → 最高 bump 为 MINOR，1.2.0 → 1.3.0

是否需要 pre-release 后缀？[否/alpha/beta/rc]
```
