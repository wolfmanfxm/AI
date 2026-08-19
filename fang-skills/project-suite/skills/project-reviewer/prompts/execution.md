# Execution — Reviewer

> @template: execution

## Actions

### 0. Graph 结构检查

→ [Graph Query Protocol](../../../runtime/contracts/graph-query.md)
- `findConsumers(<变更文件>)` → 本次改动影响哪些模块
- `findTransitiveDeps(<变更模块>)` → 传递依赖深度 ≤2，检查是否引入循环依赖
- 循环依赖检测命中 → 🔴 BLOCKER（架构级问题）

### 1. 五轴扫描

| 轴 | 重点 | Prompt |
|----|------|--------|
| 正确性 | 逻辑错误、边界条件、类型安全、状态一致性、API 契约 | [prompts/correctness.md](correctness.md) |
| 安全性 | 注入、XSS、敏感数据、权限、输入校验 | [prompts/security.md](security.md) |
| 可读性 | 命名、复杂度、注释、函数长度 | 通用检查 |
| 架构 | 模块边界、接口设计、复用、扩展性 | 通用检查 |
| 性能 | N+1 查询、渲染、内存、包体积 | 通用检查 |

每轴逐文件检查，每个发现标注 `file:line` + `修复方案`。

### 2. AC 对照

逐条验证 `# Acceptance Criteria` → 标注 ✅/❌/⚠️。不能验证的（主观描述）→ 标注 ⚠️ + 原因。

### 3. Scope 边界检查

变更是否超出 `# Scope` → 超出标注 `[SCOPE CREEP]`。

### 4. Candidate 验证

若 Generator 产出了 Candidate 知识 → 验证准确性 → 标注 confidence → 满足 R3 (>85) → 更新 `knowledge.json`。

### 5. 问题分级

| 🔴 BLOCKER | 🟠 HIGH | 🟡 MEDIUM | 🟢 LOW | 🔵 PRAISE |
|------------|---------|-----------|--------|-----------|
| 生产事故 | 大概率线上问题 | 代码质量改善 | 锦上添花 | 值得学习 |

→ 详细：[references/severity-guide.md](../references/severity-guide.md)

🔴 CHECKPOINT — 展示审查摘要（BLOCKER/HIGH/MEDIUM/LOW/PRAISE 计数）

## Exit

- 所有变更文件审查完成
- 问题已分级（BLOCKER→LOW）+ PRAISE 已记录
- AC 对照表完成

## Failure

| Condition | Action |
|-----------|--------|
| 文件过大无法完整读取 | 分段读关键区域（函数签名+分支+异常处理），标注 `⚠️ 未完整审查` |
| 不熟悉的语言/框架 | 仅做通用检查（命名/结构/注释），标注 `[超出审查范围]` |
| PLAN.md 缺失 | 从代码推断功能意图 → 降级为纯代码审查，标注 `⚠️ 无验收标准` |
