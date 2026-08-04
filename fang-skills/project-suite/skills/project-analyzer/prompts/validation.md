# Validation — Analyzer

> @engine: validation

## Checks

| # | Check | Method | On Failure |
|---|-------|--------|------------|
| V1 | 架构完整性 | `overview.md` / `modules.md` / `tech-stack.md` 均非空且 ≥100 bytes | 返回 Execution 补全该维度 |
| V2 | API 引用有效性 | API 文档中引用的源文件路径存在（`ls` 验证） | 标注 `[BROKEN REF]: <path>` |
| V3 | 组件存在性 | `catalog.md` 中组件路径可访问 | 标注 `[MISSING]: <path>` |
| V4 | 内部链接可达 | 所有 .md 内部链接（`[text](path)`）目标文件存在 | 标注 `[DEAD LINK]: <link>` |
| V5 | 无空白章节 | 每个 .md 文件无连续 >3 行的空白段落 | 标注 `[EMPTY]: <file>:<section>` |
| V6 | 无重复内容 | 跨文件无 >80% 相似的段落（模糊匹配） | 标注 `[DUPLICATE]: <file1> ↔ <file2>` |
| V7 | 统计一致性 | `statistics.json` 数字与本次扫描 .md 文件的实际内容一致（禁止复用缓存数字） | 从本次扫描数据重新提取并更新 |

## QA Agent

**触发条件**：全量分析模式（非增量）

**方法**：spawn 独立 agent，仅读本次生成的全部 .md 文件（不含对话上下文），检查：
1. 遗漏 — 应该覆盖但没覆盖的模块/维度
2. 矛盾 — 跨文件描述冲突（如 A 文件说模块 X 依赖 Y，B 文件说 Y 已废弃）
3. 断链 — 引用不存在的文件路径
4. 术语不一致 — 同一概念在不同文件中用了不同名称

→ [qa-pattern](../../../workflow-engine/references/qa-pattern.md)

## Output

`validation-report.md`：
- Findings 列表（severity: CRITICAL/WARNING/INFO + file + description + suggestion）
- QA Agent findings 独立段落
- Overall: PASS / NEEDS_FIX / BLOCKED

## Exit

无 CRITICAL 发现，或所有 CRITICAL 已修复并在 manifest 中记录
