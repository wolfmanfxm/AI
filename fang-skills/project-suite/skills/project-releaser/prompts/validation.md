# Validation — Releaser

> @template: validation

## Checks

| # | Check | Method | On Failure |
|---|-------|--------|------------|
| V1 | 全链路 Confidence | state.json history 全部 ≥70 | 🟠 GATE — AskUserQuestion |
| V2 | Semver 合规 | 版本号符合 conventional commits 推导 | 修正为推荐版本 |
| V3 | Breaking Change 标注 | 每个 BREAKING CHANGE 有具体迁移步骤 | 补全迁移说明 |
| V4 | 回滚方案 | RELEASE-CHECKLIST.md 含 git revert 命令 + 验证步骤 | 补全回滚方案 |
| V5 | Changelog 完整 | Added/Changed/Fixed/Deprecated/Removed 分类正确，无遗漏重大变更 | 补全遗漏 |

## QA Agent

**触发条件**：全链路有 confidence<70 的环节

**方法**：spawn 独立 agent，仅读 CHANGELOG + state.json + REVIEW.md（不含对话上下文），复审：
1. 风险评估 — 低置信度环节的实际风险
2. Changelog 完整性 — 是否有遗漏的 breaking change
3. 回滚方案可行性 — 回滚命令是否具体可执行

→ [qa-pattern](../../../workflow-protocol/references/qa-pattern.md)

## Verification（独立验证子流程，**非 Stage**）

本阶段在 Exit 前加载 [verifier.md](verifier.md)，以 fresh context 执行独立验证（不参与本阶段产出）。

> 依据 `skill.yaml` 的 `verification: { mode: direct-verify }` → 见
> [workflow-protocol · Verification Contract](../../../workflow-protocol/SKILL.md)。
> ⚠️ 上方 `## Checks` 表与本 skill 的 `verifier.md` 检查项**当前内容高度重叠**——两份必须同步改，
> 尚未收敛为单一来源（见 roadmap 已知缺口）。

## Exit

无 CRITICAL 发现；全链路 confidence 检查通过或用户已主动覆盖
