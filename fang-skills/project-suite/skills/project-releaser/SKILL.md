---
name: project-releaser
description: >
  发布管理：semver 版本号推荐（基于 conventional commits）、changelog 自动合成
  （git log + PR + REVIEW.md）、发布前检查清单（测试/文档/breaking change/回滚方案）、
  发布后验证。触发词：发布、上线、发版、release、changelog、版本号、发布检查、
  ship、deploy、version bump、publish、准备发布、发布前检查。
  产出：CHANGELOG.md + RELEASE-CHECKLIST.md + 版本号建议。
---

# Releaser

> 代码就绪 → 发布检查 → 版本 bump → Changelog → 发布就绪

## 核心原则

1. **不执行发布命令** — 只检查、建议、生成，不做 `npm publish` / `git push --tags`
2. **基于事实** — 版本号从 commit 推导，changelog 从 git log + PR 合成
3. **Breaking Change 显式** — 必须标注、必须写迁移步骤
4. **可回滚** — 每次发布有回滚方案，单点失败不造成灾难

## 工作流

### Discover

1. 确认发布范围：上一次 release tag 到 HEAD 之间的变更
2. 收集材料：`git log`、PR 列表、REVIEW.md、test 结果
3. 🔴 **CHECKPOINT** — 确认发布范围

### Execute

#### Step 1: 发布前检查

| 检查项 | 方法 | 未通过 |
|--------|------|--------|
| 测试全部通过 | 读 TEST-REPORT.md 或 `npm test` 输出 | 🔴 阻断 |
| Code Review 无 BLOCKER | 读 REVIEW.md | 🔴 阻断 |
| Breaking Changes 已标注 | 检查 commit 中的 `!:` 或 `BREAKING CHANGE` | 🟠 警告 |
| 文档已更新 | 对比 doc 文件最后修改时间和代码变更 | 🟡 提醒 |
| DB 迁移已测试（如有） | 询问用户 | 🟠 警告 |
| 依赖无已知漏洞 | `npm audit`（如有） | 🟡 提醒 |

生成 `RELEASE-CHECKLIST.md`：

```markdown
# 发布检查清单 — v1.3.0

| # | 检查项 | 状态 | 备注 |
|---|--------|------|------|
| 1 | 测试全部通过 | ✅ | 42/42 passed |
| 2 | Code Review 完成 | ✅ | 无 BLOCKER |
| 3 | Breaking Changes 标注 | ⚠️ | see CHANGELOG.md |
| 4 | 文档已更新 | ✅ | api docs updated |
| 5 | DB 迁移已测试 | N/A | 本次无 DB 变更 |
| 6 | 依赖安全 | ✅ | 0 vulnerabilities |

## 回滚方案
如有问题，执行 `git revert <commit>` 或回滚到 tag `v1.2.0`
```

🔴 **CHECKPOINT · 🛑 STOP**：展示检查清单结果，🔴项须全部 ✅ 才进入版本号推荐。

#### Step 2: 版本号推荐

遵循 semver 规则，基于 conventional commits 自动推荐：

| Commit 类型 | Bump | 示例 |
|------------|------|------|
| `feat:` 新功能 | MINOR | 1.2.0 → 1.3.0 |
| `fix:` Bug 修复 | PATCH | 1.2.0 → 1.2.1 |
| `feat!: / fix!: / BREAKING CHANGE` | MAJOR | 1.2.0 → 2.0.0 |
| `docs: / style: / refactor: / test: / chore:` | 不 bump | 需要至少 1 个 feat/fix |
| pre-release | 加后缀 | 1.3.0-alpha.1 / 1.3.0-beta.1 |

**多 commit 时取最高 bump**：1 个 fix + 1 个 feat = MINOR

#### Step 3: Changelog 生成

从 git log 和 PR 描述合成，按类别分组。

🔴 **CHECKPOINT · 🛑 STOP**：展示版本号建议 + Changelog 预览，用户确认后写入文件。

**失败处理**：

| 触发条件 | 一线修复 | 仍失败兜底 |
|---------|---------|-----------|
| git log 无可解析的 commit | 检查 tag 范围是否正确，尝试 `--all` | 生成空 Changelog 骨架，标注 `⚠️ 未检测到commit，请手动补充` |
| 无 PR 描述可提取 | 从 commit message body 提取摘要 | 标注 `(#?)` 代替 PR 号 |
| 🔴 检查项未通过 | 停止发布流程，告知用户具体阻断原因 | AskUserQuestion：跳过该项强制发布 / 修复后重试 |
| 版本号建议与用户预期不符 | 展示推荐理由（哪个commit触发了哪种bump） | AskUserQuestion：使用推荐版本 / 手动指定

```markdown
# Changelog — v1.3.0 (2026-07-27)

## 🚀 Features
- **auth**: add OAuth2 login support (#123)
- **order**: support batch export to Excel (#125)

## 🐛 Fixes
- **table**: pagination not resetting on filter change (#124)
- **form**: date picker clearing selected value (#126)

## ⚠️ Breaking Changes
- **auth**: removed deprecated `/api/v1/login`. Use `/api/v2/auth/login` instead.
  迁移：更新前端 login API 路径，详见 MIGRATION.md

## 🔧 Maintenance
- **deps**: upgrade Element Plus 2.13→2.14 (#127)
- **chore**: update CI node version to 20 (#128)

## 📝 Docs
- **api**: update authentication endpoints documentation
```

**Changelog 规则**：
- 每个条目格式：`- **scope**: description (#PR)`
- 不编造不存在的 PR/commit
- 用户可见的 feat/fix 必须写，内部重构/docs/chore 归纳到 Maintenance

### Output

生成 3 个产出：
1. `RELEASE-CHECKLIST.md` — 检查清单
2. 版本号建议 — 输出到对话，可选写入 `package.json`（需用户确认）
3. `CHANGELOG.md` — 更新已有或新建

## 发布后验证（可选）

如果用户执行了发布，建议：

1. 确认 CI/CD pipeline 通过
2. 确认生产环境可访问
3. 跑 smoke test（核心流程 1-2 个）
4. 监控错误率 30 分钟

## Runtime 协议

| 协议 | 路径 |
|------|------|
| 状态机 | [../../runtime/engine/state-machine.md](../../runtime/engine/state-machine.md) |
| 断点续传 | [../../runtime/engine/checkpoint.md](../../runtime/engine/checkpoint.md) |
| 异常恢复 | [../../runtime/engine/error-recovery.md](../../runtime/engine/error-recovery.md) |
| 路由 | [../../runtime/protocols/routing.md](../../runtime/protocols/routing.md) |

## Shared 资源

| 资源 | 路径 | 用途 |
|------|------|------|
| Evidence Header | [../../shared/templates/evidence-header.md](../../shared/templates/evidence-header.md) | CHANGELOG.md 产出模板 |
| Conventions | [../../shared/conventions/README.md](../../shared/conventions/README.md) | 命名与格式约定 |
| Manifest Schema | [../../shared/schemas/manifest.schema.json](../../shared/schemas/manifest.schema.json) | 版本号字段定义 |

## References

| 资源 | 路径 |
|------|------|
| 版本号推荐 Prompt | [prompts/version-bump.md](prompts/version-bump.md) |
| Changelog 生成 Prompt | [prompts/changelog-gen.md](prompts/changelog-gen.md) |
| 发布检查 Prompt | [prompts/release-checklist.md](prompts/release-checklist.md) |
| Semver 指南 | [references/semver-guide.md](references/semver-guide.md) |
| 触发词 | [references/trigger-words.md](references/trigger-words.md) |
| 能力边界 | [references/capability-matrix.md](references/capability-matrix.md) |
| 反例清单 | [references/anti-patterns.md](references/anti-patterns.md) |
| 发布示例 | [references/examples.md](references/examples.md) |
