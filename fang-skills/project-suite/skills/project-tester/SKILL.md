---
name: project-tester
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

1. **项目约定优先** — 自动检测测试框架、文件命名、目录位置，不自行决定
2. **先理解再测试** — 读被测代码，理解输入输出和边界条件后再写测试
3. **可执行** — 生成后尝试运行，不能运行的标注"⚠️ 未执行"
4. **分层覆盖** — 单元测逻辑、组件测交互、集成测流程

## 前置检测

启动时自动检测项目测试环境：

| 检测项 | 方法 | 示例 |
|--------|------|------|
| 测试框架 | 读 `package.json` devDependencies | vitest / jest / mocha |
| 测试文件位置 | 搜索 `*.test.ts` `*.spec.ts` `__tests__/` | `src/__tests__/` |
| 测试文件命名 | 读 2-3 个现有测试文件名 | `ComponentName.test.ts` vs `component-name.spec.ts` |
| 运行命令 | 读 `package.json` scripts | `npm test` / `npm run test:unit` |
| 现有断言风格 | 读 1 个现有测试 | `expect().toBe()` vs `assert.equal()` |
| Mock 方式 | 读 1 个含 mock 的测试 | `vi.mock()` / `jest.mock()` |

若无法自动检测，AskUserQuestion 确认。

**失败处理**（环境检测+测试生成阶段）：

| 触发条件 | 一线修复 | 仍失败兜底 |
|---------|---------|-----------|
| 检测不到测试框架 | 搜索 `package.json` 所有 devDeps 中 test 相关关键词 | AskUserQuestion：手动指定框架 / 跳过测试执行仅生成代码 |
| 被测代码无法解析（语法错误/非TS/JS）| 标注 `⚠️ 代码无法解析`，跳过该文件 | 基于函数签名文本做最小推断 |
| 框架不支持所需测试类型 | 降级：集成测试→单元测试，快照测试→断言测试 | 标注限制，生成骨架代码 |
| `npm test` 不可用 | 尝试 `npx vitest run` `npx jest` 等直接调用 | 标注 `⚠️ 未执行`，仅生成测试文件 |
| 覆盖率工具不可用 | 跳过覆盖率数据，仅统计测试用例数 | 标注 `⚠️ 无覆盖率数据` |

## 工作流

### Discover

1. 确认测试范围：单个函数 / 组件 / 模块 / 全量补充
2. 检测测试环境（上表）
3. 读被测代码 + 现有测试（若存在）
4. 🔴 **CHECKPOINT** — 确认测试范围 + 框架 + 风格

### Execute

#### 按类型选择策略

| 测试类型 | 测什么 | 侧重 | 参考 prompt |
|---------|--------|------|------------|
| **单元测试** | 纯函数、工具方法、composable | 输入→输出正确性、边界 | [unit-test.md](prompts/unit-test.md) |
| **组件测试** | Vue 组件 | Props→渲染、事件、slot | [component-test.md](prompts/component-test.md) |
| **集成测试** | API 调用链、多模块协作 | 数据流正确性 | main.md |
| **测试策略** | 从零规划测试 | 优先级、覆盖率目标 | [test-strategy.md](prompts/test-strategy.md) |

#### 测试用例结构

每个测试用例遵循 Given-When-Then：

```typescript
it('应该在传入空数组时返回 0', () => {
  // Given：准备数据
  const input: number[] = []

  // When：执行操作
  const result = sum(input)

  // Then：验证结果
  expect(result).toBe(0)
})
```

#### 必须覆盖的场景

| 优先级 | 场景 | 示例 |
|--------|------|------|
| P0 | 正常路径 | 正常输入 → 预期输出 |
| P0 | 核心边界 | 空值、零、负数、最大/最小值 |
| P1 | 异常路径 | 无效输入、网络错误、超时 |
| P1 | 状态转换 | loading → success → update |
| P2 | 并发/竞态 | 快速切换、重复提交 |

#### 执行与修复

生成后尝试运行测试：
- 全部通过 → 记录覆盖率
- 有失败 → 分析原因（测试写错 vs 发现 bug）
  - 测试写错 → 修复测试
  - 发现 bug → 记录到 TEST-REPORT.md，不修改被测代码

### Output

生成 `TEST-REPORT.md`：

```markdown
---
id: test-<module>
generatedBy: tester
generatedAt: <ISO-8601>
sources:
  - <tested files>
---

# 测试报告 — [模块名]

## 环境
- 框架：vitest 2.x
- 运行结果：12/12 ✅ 通过
- 覆盖率：行 95% / 分支 88% / 函数 100%

## 测试列表

| 文件 | 用例数 | 覆盖场景 |
|------|--------|---------|
| src/utils/format.test.ts | 8 | 正常/边界/异常 |

## 未覆盖
| 文件:行 | 未覆盖原因 |
|---------|-----------|
| src/utils/format.ts:45 | 仅 debug 模式触发 |

## 发现的 Bug（如有）
| 测试 | 预期 | 实际 | 严重度 |
|------|------|------|--------|
```

## Runtime 协议

| 协议 | 路径 |
|------|------|
| 状态机 | [../../runtime/engine/state-machine.md](../../runtime/engine/state-machine.md) |
| 断点续传 | [../../runtime/engine/checkpoint.md](../../runtime/engine/checkpoint.md) |
| 异常恢复 | [../../runtime/engine/error-recovery.md](../../runtime/engine/error-recovery.md) |
| 路由 | [../../runtime/protocols/routing.md](../../runtime/protocols/routing.md) |

## Shared 资源

| 资源 | 路径 | 用途 |
|------|------|------|
| Evidence Header | [../../shared/templates/evidence-header.md](../../shared/templates/evidence-header.md) | TEST-REPORT.md 产出模板 |
| Conventions | [../../shared/conventions/README.md](../../shared/conventions/README.md) | 命名与格式约定 |

## References

| 资源 | 路径 |
|------|------|
| 单元测试 Prompt | [prompts/unit-test.md](prompts/unit-test.md) |
| 组件测试 Prompt | [prompts/component-test.md](prompts/component-test.md) |
| 测试策略 Prompt | [prompts/test-strategy.md](prompts/test-strategy.md) |
| Mock 策略指南 | [references/mock-strategy.md](references/mock-strategy.md) |
| 触发词 | [references/trigger-words.md](references/trigger-words.md) |
| 能力边界 | [references/capability-matrix.md](references/capability-matrix.md) |
| 反例清单 | [references/anti-patterns.md](references/anti-patterns.md) |
| 测试示例 | [references/examples.md](references/examples.md) |
