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
源: .project-knowledge/          ← 目录集合以 shared/schemas/knowledge-directories.yaml 为准，此处不列举
    ├── architecture/  components/  api/  patterns/  conventions/   ← 知识（.md）
    ├── observations/  experience/  rules/  decisions/  recommendations/
    ├── index.md                                                 ← 导航入口（**小写**）
    ├── graph.json  context.json  statistics.json  manifest.json  search-index.json
    ├── proposals/  reports/     ← 任务产物
    └── candidates/              ← 候选暂存（不同步）

目标: {vaultPath}/Projects/{project}/
    ├── README.md  (项目概述, KB 入口)
    ├── Architecture/  Components/  Patterns/  Rules/
    ├── Decisions/  Experience/  Glossary/
    └── Risks/  graph.json
```

> ⚠️ **不要在本文件列举完整目录清单**——目录集合的权威是
> [knowledge-directories.yaml](../schemas/knowledge-directories.yaml)。本文件只说明「同步到 Vault 的映射」。
> 另注：`glossary.md` 属 `architecture/`、`principles.md` 属 `rules/`，**都不在 KB 根目录**；
> 根目录的索引入口是**小写** `index.md`（曾误写 `INDEX.md`，在大小写敏感 FS 上会 404）。

rsync 命令：
```bash
# ⚠️ 规则顺序 = 优先级（rsync 首次匹配即生效）：先排除 → 再包含 → 最后 --exclude='*' 兜底。
#    反例（曾用）：把 --include='*/' 放最前面会先放行所有目录，后面的 --exclude 永不生效。
#    在 afc-newcore-web-frontend 的真实 dry-run 中，该顺序导致 .sessions/、runtime/tasks/、
#    proposals/ 全部被列入同步清单——排除规则形同虚设。
rsync -av \
  --exclude='proposals/' --exclude='candidates/' \
  --exclude='REVIEW-*.md' --exclude='TEST-REPORT*.md' --exclude='REFACTOR*.md' \
  --exclude='reports/CHANGELOG.md' --exclude='reports/RELEASE-CHECKLIST.md' \
  --exclude='decisions/ARCHITECTURE-*' \
  --exclude='runtime/tasks/' --exclude='runtime/metrics/' \
  --exclude='.sessions/' --exclude='.locks/' --exclude='.scan/' \
  --include='*/' --include='*.md' --include='*.json' --include='*.yaml' --exclude='*' \
  .project-knowledge/ "{vaultPath}/Projects/{project}/"
```

> `runtime/tasks/`、`runtime/metrics/`、`.sessions/`、`.locks/`、`.scan/` 是**执行状态 / 指标 / 扫描中间态**
> （session / context-package / snapshot / 锁 / timeline.jsonl / manifest 备份），
> 不是项目知识，永远不进 Vault。
> 任务产物用**不带路径前缀**的模式排除（`REVIEW-*.md` / `TEST-REPORT*.md` / `REFACTOR*.md`），
> 这样同时覆盖 `reports/` 下的规范位置与历史上落在知识库根目录的文件。
> `timeline.jsonl` 本身不会命中 `*.json` include，但排除 `runtime/metrics/` 同时挡住
> legacy `timeline.json` 与 `knowledge-health.json`。

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
| REVIEW-*.md | 一次性代码审查（任意目录，兼容根目录旧放置） |
| reports/CHANGELOG.md | 变更日志（发布产物，随仓库走） |
| reports/RELEASE-CHECKLIST.md | 发布检查清单（单次发布） |
| TEST-REPORT*.md | 一次性测试报告（含 task_id 后缀） |
| REFACTOR*.md | 一次性重构记录（含 task_id 后缀） |
| runtime/tasks/ | 任务级执行状态（session / context-package / pipeline-state） |
| runtime/metrics/ | 执行指标（timeline.jsonl / knowledge-health.json），不是项目知识 |
| .sessions/ | Session Snapshot（跨 session 恢复点） |
| .locks/ | 单写者锁 |
| .scan/ | Analyzer 扫描中间态与 manifest 备份 |
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