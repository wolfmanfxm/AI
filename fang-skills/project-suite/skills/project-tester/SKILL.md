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

> 代码 + Acceptance Criteria → 测试策略 → 测试生成 → 执行 → 报告

## 核心原则

1. **项目约定优先** — 自动检测测试框架、文件命名、目录位置
2. **AC 驱动** — 对照 PLAN.md `# Acceptance Criteria` 生成测试，每条 AC 至少一个用例
3. **先理解再测试** — 读被测代码，理解输入输出和边界条件
4. **可执行** — 生成后尝试运行，不能运行的标注"⚠️ 未执行"

## 职责边界

→ [references/boundary.md](references/boundary.md)

> 🔴 tester 只写测试不修被测代码。测试失败 → 记录报告，不修改源码。

## 前置条件

| 优先级 | 资源 | 缺失时 |
|--------|------|--------|
| 0 | **被测 Code**（文件/变更列表）| 🔴 BLOCKED |
| 1 | **`PLAN.md > # Acceptance Criteria`** | 从代码推断测试策略，标注"⚠️ 无验收标准" |
| 2 | `.project-knowledge/patterns/` | 标注"⚠️ 缺少项目规范" |
| 3 | `PLAN.md > # Risk Assessment` | HIGH 风险任务优先加测 |
| 4 | `ARCHITECTURE.md` | 了解 API 契约用于集成测试 |

## 工作流

### Discover

1. 读 `PLAN.md > # Acceptance Criteria` → 提取验收条件为测试目标
2. 检测测试框架（jest/vitest/mocha/playwright）
3. 定位测试目录和命名约定
4. 🔴 CHECKPOINT → [checkpoint 模式](../../shared/conventions/checkpoint-pattern.md)

### Execute

1. 读被测代码 → 理解输入/输出/边界
2. 对照 Acceptance Criteria 生成测试用例（Given-When-Then / describe-it-expect）
3. 覆盖：happy path + 边界（null/空/超长/并发）+ 异常
4. 尝试执行 → 记录结果

### Output

- `*.test.ts` / `*.spec.ts` — 测试文件
- `reports/TEST-REPORT.md` — 覆盖率 + AC 对照表 + 失败分析

## 失败处理

| 触发条件 | 一线修复 | 仍失败兜底 |
|---------|---------|-----------|
| 检测不到测试框架 | 扫描 `package.json` devDependencies（jest/vitest/mocha） | 默认生成 jest 风格，标注"⚠️ 未检测到框架，默认 jest" |
| 被测代码不可读/不存在 | 🔴 BLOCKED — 拒绝执行 | 提示用户确认文件路径 |
| 测试执行失败（语法/类型错误） | 修正 import 路径、mock 配置、类型引用 | 标注"⚠️ 需人工修复"，记录具体错误到报告 |
| 测试执行失败（断言失败 = 发现 bug） | **不修改被测代码**，记录到报告 `[潜在Bug]` | 标注被测代码行号 + 预期 vs 实际 |
| Acceptance Criteria 不可验证（纯主观描述） | 拆解为可验证子条件，标注推断依据 | 标注"⚠️ AC 不可验证，测试基于代码推断" |
| 已有测试文件存在（同名） | 检查是否同一测试目标 → 追加用例 | 重命名新文件加 `-extended` 后缀 |

## 完成后下一步

```
tester 完成 → 有失败→分析记录 / 通过→ /project-reviewer / 需覆盖率→覆盖率模式
```

---

| 资源 | 路径 |
|------|------|
| 单元测试 Prompt | [prompts/unit-test.md](prompts/unit-test.md) |
| 组件测试 Prompt | [prompts/component-test.md](prompts/component-test.md) |
| 测试策略 Prompt | [prompts/test-strategy.md](prompts/test-strategy.md) |
| 职责边界 | [references/boundary.md](references/boundary.md) |
