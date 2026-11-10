# Discovery — Planner

> @template: discovery

## Actions

0. **Task Resolution（只读）** — 先解析 task_id（[task-identity.md](../../../runtime/mechanisms/task-identity.md)）。
   - 新任务 → 记下待创建的 goal / slug，由收尾的 `runtime-run.sh start --new-task --goal ...` 创建（**不要在此步 `task-registry.sh create`**）
   - 恰有一个 active 任务、且本次需求与它的 goal 是同一件事 → 使用（打印一行确认）
   - 恰有一个 active 任务、但本次需求是另一件事 → `AskUserQuestion` 继续旧任务 / 新建任务
   - 多个 active 任务 → 列出后让用户选择（含新建）
   - **task_id 未确定前不读知识包、不写任何文件。** 单一 active 任务不等于当前用户意图。

1. **Context Resolver** — 读 `runtime/tasks/<task_id>/context-package.json`（rules[]/knowledge[]/guidance[]），先拿到本项目的约束与知识 → [Context Resolver](../../../runtime/contracts/context-resolver.md)
   - 本任务还没有知识包（新建任务）→ 直读项目级 `rules/`、`decisions/`（project-scope）、`experience/`，**不要读根级 legacy context-package.json**（那是别的任务的过滤结果）

2. **Project Constraints（blocking）** — 加载 context-package.json 的 rules[] 全部 blocking 约束（rules + project-scope decisions）。这是硬约束，后续 Reuse/Decision/Task 都据此判断。

3. **Relevant Knowledge（recommended）** — 加载 context-package.json 的 knowledge[]（patterns/components/api），用于 Reuse Analysis。

4. **Experience / Playbooks（advisory）** — 加载 context-package.json 的 guidance[]（含 task-scope decisions），用于提高方案质量，非强制。

5. **Code Audit** → [prompts/code-audit.md](code-audit.md)：标注 `[已实现]` / `[部分实现]` / `[未实现]` → Interview 前先知道项目有什么。

5. **Completeness Check** → [prompts/completeness-check.md](completeness-check.md)：
   - 多维度评分（goal/scope/constraints/knowledge）→ planning_confidence
   - Code Audit 已发现 + Context Resolver 已查询 → 计入 knowledge 维度
   - ≥0.9 → 直接 Plan | 0.7-0.89 → ≤2 questions | 0.5-0.69 → ≤3 questions | <0.5 → ≤5 questions + Assumption

6. 读用户输入 + 上游 `PLAN.md` / `ARCHITECTURE.md`（若存在）

7. 一句话总结 **Goal** + 划定 **Scope** 边界（显式列出 包含/不包含）

8. CHECKPOINT — 展示 Goal + Scope

9. **运行登记 + 单写者锁（唯一入口）** — 用户确认 Goal / Scope 后调用：
   ```bash
   # 恢复已有任务
   bash shared/scripts/runtime-run.sh start <project-root> --skill project-planner \
     --task-id <task_id> --goal "<确认后的 goal>"
   # 新任务（用户明确选择新建时必须带 --new-task）
   bash shared/scripts/runtime-run.sh start <project-root> --skill project-planner \
     --goal "<确认后的 goal>" --slug <slug> --new-task
   ```
   → 输出 `TASK_ID` / `RUN_ID` / `STARTED_AT`，写入本次运行上下文。锁被占用 / stale → 🔴 BLOCKED。

## Exit

- Goal 一句话已确认 + Scope 边界已确认
- 用户已点确认
- `TASK_ID` / `RUN_ID` 已确定（`runtime-run.sh start` 已执行）

## Failure

| Condition | Action |
|-----------|--------|
| 无任何需求输入 | 🔴 BLOCKED |
| `context.json` 缺失 | 从 `.project-knowledge/` 提取 |
| `context-package.json` 缺失 | 兜底直读 `.project-knowledge/rules/`、`decisions/`（project-scope，非 `ARCHITECTURE-*`）、`experience/` |

## CHECKPOINT

🔴 CHECKPOINT — 展示 Goal + Scope，用户确认后进入 Execution
→ [checkpoint-pattern](../../../shared/conventions/checkpoint-pattern.md)
