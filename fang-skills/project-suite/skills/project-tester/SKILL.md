---
name: project-tester
metadata: skill.yaml
description: >
  生成和执行测试：单元测试、组件测试、集成测试。自动检测项目测试框架，
  遵循现有测试风格，生成 Given-When-Then 结构的测试用例。
  触发词：写测试、测试用例、单元测试、集成测试、组件测试、测试覆盖、
  跑测试、加测试、write tests、test cases、unit test、test coverage。
  产出：测试文件（.test.ts / .spec.ts）+ TEST-REPORT.md。
---

# Tester

> 代码 + Acceptance Criteria → 测试策略 → 生成 → 执行 → 报告
> Candidate → Verify → Accept | 遵循 [workflow-engine](../../workflow-engine/SKILL.md) — stages 声明 + prompts 业务逻辑

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

→ [references/boundary.md](references/boundary.md)
> 🔴 tester 只写测试不修被测代码。测试失败 → 记录报告，不修改源码。

## 反例黑名单

> 禁止: ① 修改被测代码（记录[潜在Bug]不修） ② 只写happy path不写边界/异常 ③ 生成后不执行验证 | → [完整清单](references/boundary.md)

## Common Rationalizations

> "这个函数很简单，happy path 够了" → 仍然覆盖边界+异常
> "测试跑了就行，失败可能是环境问题" → 每个失败必须分析原因
> "AC 太多了，挑几个重要的测" → 每条 AC 至少 1 个用例

## 失败处理

> 一线修复 → 兜底模式: [failure-handling.md](references/failure-handling.md) | 每stage详见 [prompts/](prompts/) | 恢复: manifest.json → [checkpoint](../../runtime/engine/checkpoint.md)

## 引用索引

| 资源 | 路径 |
|------|------|
| workflow-engine | [../../workflow-engine/SKILL.md](../../workflow-engine/SKILL.md) |
| Stage Discovery | [prompts/discovery.md](prompts/discovery.md) |
| Stage Execution | [prompts/execution.md](prompts/execution.md) |
| Stage Validation | [prompts/validation.md](prompts/validation.md) |
| 测试策略 Prompt | [prompts/test-strategy.md](prompts/test-strategy.md) |
| 单元测试 Prompt | [prompts/unit-test.md](prompts/unit-test.md) |
| 组件测试 Prompt | [prompts/component-test.md](prompts/component-test.md) |
| Mock 策略 | [references/mock-strategy.md](references/mock-strategy.md) |

## 完成后下一步 → /project-reviewer
