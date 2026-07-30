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

## 前置条件

| 优先级 | 资源 | 缺失时 |
|--------|------|--------|
| 0 | **git log** | 🔴 BLOCKED |
| 1 | `CHANGELOG.md`（若存在） | 🟡 DEGRADED — 从 git log 生成 |
| 2 | `REVIEW.md` | 🟡 DEGRADED — 标注"⚠️ 未审查" |

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

## 失败处理

| 触发条件 | 一线修复 | 仍失败兜底 |
|---------|---------|-----------|
| `git log` 无 conventional commits | 按 commit 首词推断类型（feat→MINOR, fix→PATCH） | 读 `package.json` 当前版本，默认 PATCH bump，标注"⚠️ 非标准 commit" |
| 无法确定版本号（无历史 tag） | 从 `package.json` 读当前版本，推荐 `1.0.0` 为首个正式版 | AskUserQuestion 让用户指定版本号 |
| CHANGELOG.md 不存在 | 从 git log 生成全新 CHANGELOG.md | 标注"⚠️ 首次生成，请人工审核" |
| REVIEW.md 不存在 | 标注"⚠️ 未审查"，继续生成 | 不阻塞 — Changelog 独立于审查状态 |
| 检测到 breaking change 但无迁移说明 | 在 CHANGELOG 显式标注 BREAKING CHANGE + 生成迁移步骤 | AskUserQuestion 确认是否有遗漏的迁移需求 |

## 完成后下一步

```
releaser 完成 → 人工审核后发布 / 修复后重新: /project-releaser
```
