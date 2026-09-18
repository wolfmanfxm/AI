# Validation — Documenter

> @template: validation

## Checks

| # | Check | Method | On Failure |
|---|-------|--------|------------|
| V1 | 源码溯源 | 每个关键信息标注 `file:line` | 补全溯源标注 |
| V2 | 风格一致 | 标题层级/表格样式/代码块语言与已有文档一致 | 修正风格 |
| V3 | 无编造 | 所有断言在源码中有对应 | 标注 `[推断]` 或删除 |
| V4 | Vault 同步 | API/组件文档已同步到 Knowledge Vault | 执行同步 |
| V5 | 无覆盖人工内容 | 已有文档的人工章节未被覆盖 | 回滚人工章节，标注 `[CONFLICT]` |
| V6 | 链接可达 | 所有内部链接目标文件存在 | 修正链接 |

## QA Agent

**触发条件**：API 文档（被多项目复用，准确性要求高）

**方法**：spawn 独立 agent，仅读文档 + 源文件（不含对话上下文），验证：
1. 每个 `file:line` 引用的代码确实存在且语义匹配
2. 参数/返回值描述与实际类型一致
3. 示例代码可以运行（至少语法正确）

→ [qa-pattern](../../../workflow-protocol/references/qa-pattern.md)

## Verification（独立验证子流程，**非 Stage**）

本阶段在 Exit 前加载 [verifier.md](verifier.md)，以 fresh context 执行独立验证（不参与本阶段产出）。

> 依据 `skill.yaml` 的 `verification: { mode: direct-verify }` → 见
> [workflow-protocol · Verification Contract](../../../workflow-protocol/SKILL.md)。
> ⚠️ 上方 `## Checks` 表与本 skill 的 `verifier.md` 检查项**当前内容高度重叠**——两份必须同步改，
> 尚未收敛为单一来源（见 roadmap 已知缺口）。

## Exit

无 CRITICAL 发现（溯源完整、风格一致、无编造、Vault 已同步）
