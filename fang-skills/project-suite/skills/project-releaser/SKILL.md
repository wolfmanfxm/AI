---
name: project-releaser
metadata: skill.yaml
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

1. **不执行发布命令** — 只检查、建议、生成，不 `npm publish` / `git push --tags`
2. **基于事实** — 版本号从 commit 推导，changelog 从 git log + PR 合成
3. **Breaking Change 显式** — 必须标注、必须写迁移步骤
4. **可回滚** — 每次发布有回滚方案

## 职责边界

→ [references/boundary.md](references/boundary.md)

> 🔴 releaser 只检查建议不执行发布命令。

## 工作流

### Discover

1. 读 `git log` → 解析 conventional commits（feat/fix/refactor/docs/...）
2. 读 `CHANGELOG.md`（若存在）→ 追加/新建
3. 读 REVIEW.md（若存在）→ 确认审查状态
4. 🔴 CHECKPOINT → [checkpoint 模式](../../shared/conventions/checkpoint-pattern.md)

### Execute

1. **版本号推荐**：breaking change → MAJOR / feat → MINOR / fix → PATCH
2. **Changelog 合成** → [prompts/changelog-gen.md](prompts/changelog-gen.md)
3. **检查清单** → [prompts/release-checklist.md](prompts/release-checklist.md)
4. **输出**：CHANGELOG.md + RELEASE-CHECKLIST.md

## 完成后下一步

```
releaser 完成 → 人工审核后发布 / 修复后重新: /project-releaser
```
