# Validation Framework

> 独立验证阶段框架。每个 Skill 在 Execution 完成后必须执行 Validation，而非在 Output 中隐式检查。

## 5 类标准检查

| 类别 | 说明 | 适用 Skill |
|------|------|-----------|
| **completeness** | 覆盖完整性：所有声称的维度/模块/功能都有对应产出 | 全部 |
| **consistency** | 跨产出一致性：不同文件/模块之间无自相矛盾 | analyzer, planner, architect |
| **reference** | 引用有效性：所有文件路径/链接/API 引用可达 | analyzer, documenter, generator |
| **content** | 内容质量：无空章节、无显著重复、无占位符 | analyzer, documenter |
| **contract** | 契约符合性：产出符合 skill.yaml 中 claim 的 produces 能力类型 | 全部 |

## 标准 Validation Stage 模板

每个 Skill 的 SKILL.md 中，Validation 阶段使用以下格式：

```markdown
### Stage: Validation

| Check | Method | On Failure |
|-------|--------|------------|
| <检查项1> | <验证方法> | <失败处理> |
| <检查项2> | <验证方法> | <失败处理> |
| ... | ... | ... |

**QA Agent**: spawn 独立 agent，仅读本次产出文件（不含对话上下文），使用 [qa-pattern.md](qa-pattern.md) 模板检查遗漏和矛盾
**Output**: validation-report.md
**Exit**: 无 CRITICAL 发现，或所有 CRITICAL 已修复并记录
```

## validation-report.md 格式

```markdown
# Validation Report

> Skill: <skill-name> | 时间: <ISO-8601> | 总体: PASS / NEEDS_FIX / BLOCKED

## Findings

| # | Severity | Check | File | Description | Suggestion |
|---|----------|-------|------|-------------|------------|
| 1 | CRITICAL | completeness | overview.md | 缺少模块依赖关系图 | 补充 mermaid 图或文字描述 |
| 2 | WARNING | reference | api/xxx.md | 引用的源文件路径不存在 | 更新为正确路径或标注 [DEPRECATED] |
| 3 | INFO | content | catalog.md | 3 个组件缺少使用示例 | 建议补充示例代码 |

## QA Agent Findings

> 以下由独立 QA Agent（fresh context）发现，非主 agent 自检。

| # | Severity | Description | Suggestion |
|---|----------|-------------|------------|
| 1 | WARNING | 架构文档中提到的 WebSocket 模块在组件目录中无对应条目 | 确认是否遗漏或标注为外部依赖 |
| 2 | INFO | 3 处使用了不同的术语描述同一概念（"用户模块" vs "账户模块"） | 统一术语 |

## Summary

- CRITICAL: N 项（必须修复）
- WARNING: N 项（建议修复）
- INFO: N 项（可选修复）
```

## 各 Skill 的 Validation Checks

### project-analyzer

| Check | Method | On Failure |
|-------|--------|------------|
| 架构完整性 | overview/modules/tech-stack 均非空，modules.md 覆盖所有 `src/` 一级目录 | 返回 Execution 补全该维度 |
| API 引用有效性 | API 文档中引用的源文件路径存在（`ls` 验证） | 标注 `[BROKEN REF]: <path>` |
| 组件存在性 | catalog.md 中组件路径可访问 | 标注 `[MISSING]: <path>` |
| 内部链接可达 | 所有 .md 内部链接（`[text](path)`）目标文件存在 | 标注 `[DEAD LINK]: <link>` |
| 无空白章节 | 每个 .md 文件无连续 >3 行的空白段落 | 标注 `[EMPTY]: <file>:<section>` |
| 无重复内容 | 跨文件无 >80% 相似的段落（模糊匹配） | 标注 `[DUPLICATE]: <file1> ↔ <file2>` |
| 统计一致性 | statistics.json 数字与 .md 文件数量一致 | 重新计数并更新 |

### project-generator

| Check | Method | On Failure |
|-------|--------|------------|
| Import 正确性 | 所有 import 路径对应的文件存在 | 修正路径或标注 TODO |
| 组件复用 | 未重复生成 graph.json 中已存在的组件 | 替换为 import 已有组件 |
| 模式一致性 | 代码风格与 `.project-knowledge/patterns/` 一致 | 修正为符合模式 |
| TS 类型完整 | 无 `any` 滥用（除非上游就是 `any`） | 从 types/ 导入或定义接口 |
| 全状态覆盖 | loading/empty/error 状态都有处理 | 补全缺失状态 |

### project-planner

| Check | Method | On Failure |
|-------|--------|------------|
| 9 模块完整 | 每个 section 非空，内容 ≥3 行 | 返回 Execution 补全 |
| 依赖无循环 | Task Deps 图中无 A→B→A | 🔴 BLOCK — 重新设计依赖 |
| AC 可验证 | 每条 AC 有明确的 pass/fail 条件 | 标注并降级置信度 |
| Decision↔Task 绑定 | 每个 Decision 标注影响哪些 Task | 补充映射 |

### project-architect

| Check | Method | On Failure |
|-------|--------|------------|
| ADR 决策链完整 | 问题→候选方案→选择→理由 四段不缺 | 返回 Execution 补全 |
| 对比矩阵完整 | 候选方案 ≥2，维度 ≥3，分差说明 | 补全矩阵或标注原因 |
| 现状核实准确 | `[已实现]` 标注的模块路径存在 | 修正标注 |
| API 契约可实施 | 每个 endpoint 有 method/path/request/response | 补全缺失字段 |

### project-reviewer

| Check | Method | On Failure |
|-------|--------|------------|
| 五轴全覆盖 | 每个审查轴至少 1 条记录（含 PRAISE 或 PASS） | 补全未覆盖的轴 |
| file:line 有效 | 每个发现标注的文件路径+行号存在 | 修正引用 |
| AC 逐条对照 | AC 表逐条标注 ✅/❌/⚠️，无遗漏 | 补全遗漏的 AC |
| 分级合理 | BLOCKER 有明确阻断理由，无 LOW 误标 BLOCKER | 调整分级 |

### project-tester

| Check | Method | On Failure |
|-------|--------|------------|
| AC 逐条覆盖 | 每条 AC 至少 1 个测试用例 | 补全缺失用例 |
| 边界条件覆盖 | null/undefined/空值/超长 场景有测试 | 补全边界用例 |
| 测试可执行 | `npx vitest run` 无语法/配置错误 | 修正后重试 |
| 无篡改源码 | 测试文件不含被测源码的修改 | 回滚修改 |

### project-refactorer

| Check | Method | On Failure |
|-------|--------|------------|
| 行为不变 | 重构前后测试结果一致（全绿→全绿） | 🔴 BLOCK — git revert |
| 指标改善 | 圈复杂度/行数/重复率至少一项改善 >10% | 标注"⚠️ 边际改善" |
| 范围受控 | 改动文件 ≤5，每个 commit 一个动作 | 拆分过大的重构 |
| 测试保护 | 每次重构前测试全绿，重构后仍全绿 | 停止重构，先修测试 |

### project-documenter

| Check | Method | On Failure |
|-------|--------|------------|
| 源码溯源 | 每个关键信息标注 `file:line` | 补全溯源标注 |
| 风格一致 | 标题层级/表格样式/代码块语言 与已有文档一致 | 修正风格 |
| 无编造 | 所有断言在源码中有对应 | 标注 `[推断]` 或删除 |
| Vault 同步 | API/组件文档已同步到 Knowledge Vault | 执行同步 |

### project-releaser

| Check | Method | On Failure |
|-------|--------|------------|
| 全链路 Confidence | state.json history 全部 ≥70 | 🟠 GATE — AskUserQuestion |
| Semver 合规 | 版本号符合 conventional commits 推导 | 修正为推荐版本 |
| Breaking Change 标注 | 每个 BREAKING CHANGE 有迁移步骤 | 补全迁移说明 |
| 回滚方案 | RELEASE-CHECKLIST.md 含 git revert 命令 | 补全回滚方案 |

## Exit 条件

Validation Stage 的 Exit 条件统一为：

```
Exit: 无 CRITICAL 发现，或所有 CRITICAL 已修复并在 manifest 中记录
```

CRITICAL 发现未修复 → 不可进入 Delivery。WARNING/INFO 可记录后放行。
