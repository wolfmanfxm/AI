# Discovery — Analyzer

> @template: discovery

## Actions

0. **Task Resolution（只读，不登记）** — 从用户原始请求确定这次要做什么，并解析任务身份：
   - 显式 `--task-id` / `$PS_TASK_ID` → 先确认该任务存在且可恢复（completed / abandoned 拒绝）
   - 用户说「继续 X」→ `task-registry.sh list` 按 goal 匹配
   - 恰好一个 active 任务，且本次请求与它的 goal 是同一件事 → 使用（打印一行确认）
   - 恰好一个 active 任务，但本次请求明显是另一件事 → **不得自动接管**：
     `AskUserQuestion`「继续 <旧 goal> / 新建任务」
   - 多个 active 任务 → 列出 id + goal + 最后活跃时间 → `AskUserQuestion` 选择（含「新建」）
   - 无 active 任务 → 记下待创建任务的 goal / slug（**不在此步 create**，由第 6 步 start 创建）
   
   **此步不调用 `start`、不拿锁、不写任何任务级文件**：运行登记必须等范围与模式确认之后，
   否则会把未经用户确认的 goal 写进任务身份。**单一 active 任务不等于当前用户意图**——
   昨天没关的「重构权限模块」不能成为今天「分析订单模块」被接上去的理由。

0.5. **锁的语义** → [single-writer.md](../../../runtime/mechanisms/single-writer.md)：由第 6 步的
   `runtime-run.sh start` 持有，Execution 每个 checkpoint 前调用 `runtime-run.sh renew`
   （内部校验 session/owner 并续租），收尾由 `runtime-run.sh finish` 释放。不要在 prompt 里
   另行调用 `writer-lock.sh`。Session 身份由 Claude Code 注入的 `CLAUDE_CODE_SESSION_ID` 提供；
   非 Claude 宿主需显式传 `--session-id`。

1. **Context Resolver** → [Context Resolver](../../../runtime/contracts/context-resolver.md)：从项目路径提取 tags → **结构事实查 `graph.json`**；已有的 architecture/patterns/glossary **知识**走 `knowledge-index.json`/`context.json`，**不要从 graph 取知识**
   - 先跑前置检查：`bash shared/scripts/check-knowledge-index.sh <project-root>`；缺失/非法 → 先跑 `knowledge-compiler.sh`，**不得**直接降级去读 markdown
2. 探测技术栈：`@adapter:filesystem.read package.json`（dependencies/devDependencies/scripts）、`@adapter:filesystem.read tsconfig.json`（paths/baseUrl）、`@adapter:filesystem.read vite.config.*`（alias/resolve）
3. 探测目录结构：`@adapter:filesystem.list src/` + 按技术栈定位组件文件（扩展名从 package.json/配置文件推断）
4. 探测 Knowledge Vault 路径：`@adapter:filesystem.list "$HOME/Data/Knowledge Vault"` → `@adapter:filesystem.list "./Knowledge Vault"` → `@adapter:filesystem.list "$HOME/Documents/Knowledge Vault"`，取第一个可达路径
5. `AskUserQuestion` 确认：
   - 项目名（默认 package.json name）
   - 分析深度：`quick`（仅架构+组件）/ `standard`（7维度）/ `deep`（7维度+交叉验证+QA）
   - 分析范围：全项目 / 指定模块（逗号分隔）
   - 输出位置：默认 `.project-knowledge/`
6. **运行登记 + 单写者锁（唯一入口）** — 用第 5 步确认后的选择调用：
   ```bash
   # 恢复已有任务
   bash shared/scripts/runtime-run.sh start <project-root> --skill project-analyzer \
     --task-id <task_id> --goal "analyze <project> (<scope>)"
   # 新建任务（用户明确选择新建时）
   bash shared/scripts/runtime-run.sh start <project-root> --skill project-analyzer \
     --goal "analyze <project> (<scope>)" --slug <slug> --new-task
   ```
   → 解析/创建 `task_id`、获取单写者锁（锁名 `analyzer`）、写运行指针，输出 `TASK_ID` / `RUN_ID` / `STARTED_AT`。
   - **用户选择新建任务时必须带 `--new-task`**：否则 start 会复用唯一的 active 任务，把新运行挂到旧任务上
   - 锁被占用 / stale / 无法创建锁目录：🔴 BLOCKED——`start` 以 exit 1 / 2 报告，按 [single-writer.md](../../../runtime/mechanisms/single-writer.md) 让用户选 等待 / break / 取消；**不得**在无锁状态下写项目级知识
   - **monitor-only / 探针运行也必须 start**——不登记的运行在 timeline 里不存在
7. 写入**任务级** Discovery 产物（**不碰项目级文件**）：
   - `runtime/tasks/<task_id>/discovery.json`：`status=discover` + 用户选择（project / mode / scope / output / vaultPath / monitorOnly）
   - `runtime/tasks/<task_id>/analysis-config.json`：本次运行的配置草稿（字段同 `analysis-config.schema.json`：`projectName` `mode` `scope` `output` `vaultPath`；**不要**自造 `project` 字段——合并脚本会因缺必填字段拒绝）
   - monitor-only / 探针开关**只存在于** `discovery.json`；`meta.json` 的 schema 没有这些字段，不要写进去（额外字段会被 `task-meta.schema.json` 的 `additionalProperties:false` 拒绝）

> ⚠️ **Discovery 不写、也不删项目级文件**：
> - `.project-knowledge/manifest.json` 是**项目级知识产物**（6 个根产物之一），它的 `status` 反映知识库状态，不是某次运行的阶段。Discovery 把它改成 `discover` 会让一次探针/取消把既有知识库标成「不可信」。
> - `.project-knowledge/analysis-config.json` 是**长期用户配置**。本次运行的选择先落任务草稿，Delivery 再由 `analysis-config-merge.mjs` 合并（先备份、项目身份字段不被改写、monitorOnly 等任务级字段拒绝进入根配置）。

## Exit

- `TASK_ID` / `RUN_ID` 已确定（`runtime-run.sh start` 已执行）
- 单写者锁已获取（失败即 BLOCKED，不允许降级继续）
- `framework` identified（从 package.json + 配置文件推断）
- `package_manager` identified（npm/yarn/pnpm）
- `scope` confirmed（用户已回答）
- `runtime/tasks/<task_id>/discovery.json` + `analysis-config.json` 已写入
- 根 `manifest.json` / `analysis-config.json` **未被修改**

## Failure

| Condition | Action |
|-----------|--------|
| 无 `package.json` | `AskUserQuestion` 手动指定框架和包管理器 |
| 权限不足（无法读项目文件） | 🔴 BLOCKED — 提示用户检查权限 |
| 单写者锁不可获取（占用 / stale / 无法创建 `.locks/`） | 🔴 BLOCKED — 不进入 Execution；让用户选择等待 / `break` / 取消后重新 `start` |
| Vault 路径全部不可达 | 🟡 DEGRADED — 跳过 Vault 同步，标注 `⚠️ Vault 不可达` |
| 用户取消 | `runtime-run.sh finish <project-root> --skill project-analyzer --status skipped --reason "用户取消"`（写终态 + 释放锁）；只删任务级草稿，**不删根 `analysis-config.json` / `manifest.json`** |

## CHECKPOINT

🔴 CHECKPOINT — 用户确认范围后进入 Execution
→ [checkpoint-pattern](../../../shared/conventions/checkpoint-pattern.md)
