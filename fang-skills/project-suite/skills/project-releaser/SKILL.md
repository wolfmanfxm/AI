---
name: project-releaser
metadata: skill.yaml
description: >
  发布管理：semver 版本号推荐（基于 conventional commits）、changelog 自动合成
  （git log + PR + REVIEW.md）、发布前检查清单（测试/文档/breaking change/回滚方案）。
  触发词：发布、上线、发版、release、changelog、版本号、发布检查、
  ship、deploy、version bump、publish、准备发布。
  产出：CHANGELOG.md + RELEASE-CHECKLIST.md + 版本号建议。
---

# Releaser

> 代码就绪 → 发布检查 → 版本 bump → Changelog → 发布就绪
> Execute → Verify | 遵循 [workflow-engine](../../workflow-engine/SKILL.md) — stages 声明 + prompts 业务逻辑

## 核心原则

1. **不执行发布命令** — 只检查、推荐、生成，不 `npm publish` / `git push --tags`
2. **基于事实** — 版本号从 commit 推导，changelog 从 git log 合成
3. **Breaking Change 显式** — 必须标注、必须写迁移步骤
4. **可回滚** — 每次发布有回滚方案

## 前置条件

| 优先级 | 资源 | 缺失时 |
|--------|------|--------|
| 0 | git log | 🔴 BLOCKED |
| 1 | CHANGELOG.md（若存在） | 🟡 DEGRADED |
| 2 | REVIEW.md | 🟡 DEGRADED — 标注"⚠️ 未审查" |

## 工作流

| Stage | Prompt | 模板 |
|-------|--------|------|
| Discovery | [prompts/discovery.md](prompts/discovery.md) | @engine: discovery |
| Execution | [prompts/execution.md](prompts/execution.md) | @engine: execution |
| Verify | [prompts/verifier.md](prompts/verifier.md) | @engine: validation |
| Validation | [prompts/validation.md](prompts/validation.md) | @engine: validation |
| Delivery | [prompts/delivery.md](prompts/delivery.md) | @engine: delivery |

## 职责边界

→ [references/boundary.md](references/boundary.md)（反例黑名单 + 失败兜底 + 常见借口）
> 🔴 releaser 只检查不执行发布命令。

> 完成后：人工审核后发布。通用约束 → [workflow-engine](../../workflow-engine/SKILL.md)；git/命令护栏 → [command-guard](../../runtime/engine/command-guard.md)。
