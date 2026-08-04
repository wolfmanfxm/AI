# Validation — Generator

> @engine: validation

## Checks

| # | Check | Method | On Failure |
|---|-------|--------|------------|
| V1 | Import 正确性 | 所有 import 路径对应的文件/模块存在 | 修正路径或标注 TODO |
| V2 | 组件复用 | 未重复生成 graph.json 中已存在的组件 | 替换为 import 已有组件 |
| V3 | 模式一致性 | 代码风格与 `.project-knowledge/patterns/` 一致 | 修正为符合模式 |
| V4 | TS 类型完整 | 无 `any` 滥用（除非上游是 `any`） | 从 types/ 导入或定义接口 |
| V5 | 全状态覆盖 | loading/empty/error 状态都有处理 | 补全缺失状态 |

## QA Agent

**触发条件**：生成代码 >200 行 或 生成 ≥3 个文件

**方法**：spawn 独立 agent，仅读生成的文件（不含对话上下文），检查：
1. import 是否正确（路径存在、模块已安装）
2. 是否重复生成了已有组件/API
3. 模式是否与项目 conventions 一致
4. 有无常见的反模式（参见 [references/boundary.md](../references/boundary.md) 反例黑名单）

→ [qa-pattern](../../../workflow-engine/references/qa-pattern.md)

## Output

- `completion-report.md`：Knowledge Used 反馈 + Candidate 发现 + QA findings + timeline 写入
→ [references/completion-report.md](../references/completion-report.md)

## Exit

无 CRITICAL 发现（BLOCKER 级别问题必须修复后才能 exit）
