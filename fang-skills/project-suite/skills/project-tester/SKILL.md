---
name: project-tester
metadata: skill.yaml
description: >
  生成和执行测试：单元测试、组件测试、集成测试。自动检测项目测试框架，
  遵循现有测试风格，生成 Given-When-Then 结构的测试用例。
  触发词：写测试、测试用例、单元测试、集成测试、组件测试、测试覆盖、
  跑测试、加测试、write tests、test cases、unit test、test coverage、add test、generate test。
  产出：测试文件（按项目测试框架）+ TEST-REPORT.md。
---

# Tester

> 代码 + Acceptance Criteria → 测试策略 → 生成 → 执行 → 报告
> Execute → Verify | 遵循 [workflow-engine](../../workflow-engine/SKILL.md) — stages 声明 + prompts 业务逻辑

## 核心原则

1. **项目约定优先** — 自动检测框架、命名、目录
2. **AC 驱动** — 每条 AC 至少一个用例
3. **先理解再测试** — 读被测代码，理解输入输出和边界
4. **可执行** — 生成后尝试运行，不运行的标注"⚠️ 未执行"

## 前置条件

| 优先级 | 资源 | 缺失时 |
|--------|------|--------|
| 0 | 被测 Code | 🔴 BLOCKED |
| 1 | `PLAN.md > # Acceptance Criteria` | 从代码推断，标注"⚠️ 无验收标准" |
| 2 | `.project-knowledge/patterns/` | 标注"⚠️ 缺少项目规范" |

## 工作流

| Stage | Prompt | 模板 |
|-------|--------|------|
| Discovery | [prompts/discovery.md](prompts/discovery.md) | @engine: discovery |
| Execution | [prompts/execution.md](prompts/execution.md) | @engine: execution |
| Verify | [prompts/verifier.md](prompts/verifier.md) | @engine: validation |
| Validation | [prompts/validation.md](prompts/validation.md) | @engine: validation |

## 职责边界

→ [references/boundary.md](references/boundary.md)（反例黑名单 + 失败兜底 + 常见借口）
> 🔴 tester 只写测试不修被测代码。测试失败 → 记录报告，不修改源码。

> 完成后：/project-reviewer。通用约束 → [workflow-engine](../../workflow-engine/SKILL.md)；git/命令护栏 → [command-guard](../../runtime/engine/command-guard.md)。
