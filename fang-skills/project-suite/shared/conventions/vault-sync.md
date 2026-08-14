# Vault Sync Protocol v2.0

> 双同步策略：Project Sync（默认开启）+ Knowledge Promotion（默认关闭，需 Reviewer 确认）
> 同步依据：`classification-report.yaml` 中的 `promotion level`，而非文件路径。

## 三分类

```
promotion: none     → Task 产物 → 归档 .project-knowledge/，不同步
promotion: project  → 项目知识 → Project Sync → Vault/Projects/{project}/
promotion: personal → 跨项目通用 → Knowledge Promotion → Vault/Knowledge/
```

## Project Sync（默认开启）

所有 `promotion: project` 的知识 → 同步到个人知识库的项目目录。

```
源: .project-knowledge/
    ├── architecture/  components/  api/  patterns/  conventions/
    ├── observations/  experience/  rules/
    ├── glossary.md  principles.md  INDEX.md
    ├── graph.json  context.json  statistics.json
    ├── decisions/architecture-decisions.md  index.md
    └── reports/latest.md

目标: {vaultPath}/Projects/{project}/
    ├── README.md  (项目概述, KB 入口)
    ├── Architecture/  Components/  Patterns/  Rules/
    ├── Decisions/  Experience/  Glossary/
    └── Risks/  graph.json
```

rsync 命令：
```bash
rsync -av --include='*/' --include='*.md' --include='*.json' --include='*.yaml' \
  --exclude='proposals/' --exclude='reports/REVIEW-*' --exclude='reports/CHANGELOG-*' \
  --exclude='reports/TEST-REPORT.md' --exclude='reports/REFACTOR.md' \
  --exclude='decisions/ARCHITECTURE-*' --exclude='candidates/' \
  .project-knowledge/ "{vaultPath}/Projects/{project}/"
```

## Knowledge Promotion（默认关闭）

`promotion: personal` 的知识 → Reviewer 确认 → 提升到个人知识库的通用目录。

```
源: classification-report.yaml 中 personal_candidates
目标: {vaultPath}/Knowledge/{category}/

示例:
  pattern.form-schema-validation.md → Knowledge/Patterns/
  playbook.microservice-migration.md → Knowledge/Playbooks/
  decision.always-use-pnpm-for-monorepo.md → Knowledge/Decisions/
```

Promotion 条件（Reviewer 判断）：
- 跨项目适用（≥2 个项目可受益）
- 非显而易见（不是"用 TypeScript"这类常识）
- 有具体可执行的步骤/模式

## Task Artifacts（永远不同步）

`promotion: none` 的知识 → 仅保留在 `.project-knowledge/`，**永远不进 Vault**。

| 文件 | 原因 |
|------|------|
| proposals/PLAN-*.md | 一次性任务规划 |
| reports/REVIEW-*.md | 一次性代码审查 |
| reports/CHANGELOG-*.md | 一次性变更日志 |
| reports/TEST-REPORT.md | 一次性测试报告 |
| reports/REFACTOR.md | 一次性重构记录 |
| decisions/ARCHITECTURE-<feature>.md | 单功能架构决策 |
| candidates/ | 中间产物 |

## 执行流程

```
Knowledge Builder → Classifier → classification-report.yaml
                                    │
                    ┌───────────────┼───────────────┐
                    │               │               │
              promotion:none  promotion:project  promotion:personal
                    │               │               │
                    ▼               ▼               ▼
              归档本地       Project Sync     Reviewer 确认
              (不同步)       (自动同步)       (手动Promotion)
```