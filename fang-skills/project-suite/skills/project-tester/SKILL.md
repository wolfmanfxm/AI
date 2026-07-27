---
name: project-tester
metadata: skill.yaml
description: >
  生成和执行测试：单元测试、组件测试、集成测试。自动检测项目测试框架，
  遵循现有测试风格，生成 Given-When-Then 结构的测试用例。
  触发词：写测试、测试用例、单元测试、集成测试、组件测试、测试覆盖、
  跑测试、加测试、write tests、test cases、unit test、test coverage、
  add test、generate test。
  产出：测试文件（.test.ts / .spec.ts）+ 测试报告（TEST-REPORT.md）。
---

# Tester

> 代码 → 测试策略 → 测试生成 → 执行 → 报告

## 核心原则

1. **项目约定优先** — 自动检测测试框架、文件命名、目录位置
2. **先理解再测试** — 读被测代码，理解输入输出和边界条件
3. **可执行** — 生成后尝试运行，不能运行的标注"⚠️ 未执行"

## 职责边界

→ [references/boundary.md](references/boundary.md)

> 🔴 tester 只写测试不修被测代码。测试失败 → 记录报告，不修改源码。

## 工作流

### Discover

1. 检测测试框架（jest/vitest/mocha/playwright）
2. 定位测试目录和命名约定
3. 确认测试范围
4. 🔴 CHECKPOINT → [checkpoint 模式](../../shared/conventions/checkpoint-pattern.md)

### Execute

1. 读被测代码 → 理解输入/输出/边界
2. 生成测试用例（Given-When-Then / describe-it-expect）
3. 覆盖：happy path + 边界（null/空/超长/并发）+ 异常
4. 尝试执行 → 记录结果

### Output

- `*.test.ts` / `*.spec.ts` — 测试文件
- `reports/TEST-REPORT.md` — 覆盖率 + 失败分析

## 完成后下一步

```
tester 完成 → 有失败→分析记录 / 通过→ /project-reviewer / 需覆盖率→覆盖率模式
```

---

| 资源 | 路径 |
|------|------|
| 单元测试 | [prompts/unit-test.md](prompts/unit-test.md) |
| 组件测试 | [prompts/component-test.md](prompts/component-test.md) |
| 集成测试 | [prompts/test-strategy.md](prompts/test-strategy.md) |
| 职责边界 | [references/boundary.md](references/boundary.md) |
