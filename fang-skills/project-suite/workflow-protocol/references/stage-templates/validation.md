# Stage Template: Validation

> Suite 拥有（Protocol）。Skill 通过 `@template: validation` 引用，只需提供 Checks 表格 + Exit。

## Standard Contract

| Field | Value |
|-------|-------|
| Entry  | Execution 完成，所有产出文件已写入 |
| Input  | Execution 阶段全部产出文件 + skill.yaml `interface.outputs` |
| Output | validation-report.md（findings + overall: PASS/NEEDS_FIX/BLOCKED）+ **convergence 判定** |
| Recovery | Validation 是只读检查，中断后直接重新执行即可（无需 resume） |

**Convergence（统一停止条件）**：验证即判断「是否该停」。基于 Checks 结果产出收敛判定（见 [convergence.md](../../../shared/primitives/convergence.md)）：

```yaml
convergence:
  status: sufficient | insufficient | blocked
  evidence: [至少 1 条支撑判断的证据]
  next_action: handoff | continue | investigate | blocked
```

- Checks 全部通过 → `sufficient → handoff`（交下游）
- 有非 CRITICAL 遗留 → `insufficient → continue`（补一轮）
- 缺关键输入 → `blocked`（回上游）

## Custom Fields (Skill Must Provide)

| Field | Description |
|-------|-------------|
| **Checks** | 本 Skill 的验证检查项（表格：Check / Method / On Failure） |
| **Exit**   | 验证通过条件（统一为：无 CRITICAL 发现，或所有 CRITICAL 已修复） |

## QA Agent

- 参见 [qa-pattern.md](../qa-pattern.md) — Main Agent → QA Agent → Reviewer Agent
- QA Agent 仅读产出文件（不含对话上下文），检查遗漏、矛盾、断链、空章节、重复
- QA findings 计入 validation-report.md

## 示例：Analyzer 的 Validation

```markdown
### Stage: Validation
@template: validation

| # | Check | Method | On Failure |
|---|-------|--------|------------|
| V1 | 架构完整性 | overview/modules/tech-stack 均非空 | 返回 Execution 补全 |
| V2 | API 引用有效性 | 文档引用的源文件路径存在 | 标注 [BROKEN REF] |
| V3 | 内部链接可达 | 所有 .md [text](path) 目标存在 | 标注 [DEAD LINK] |

**Exit**: 无 CRITICAL 发现，或所有 CRITICAL 已修复并记录到 manifest
```
