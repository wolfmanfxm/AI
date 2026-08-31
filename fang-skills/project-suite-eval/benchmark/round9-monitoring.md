# Round 9 监测方案

> 验证最近几轮「声明收口 + lifecycle policy-only」改动的真实效果。
> 本轮改动性质：大部分是命名/声明收口（静态已验），唯一行为改动是 finish-workflow「不自动 Accepted」。
> 因此本轮是**轻量验证**（suite-only，不跑 native 对比）：1 个 generator（命名无回归）+ 1 个 analyzer（不自动 Accepted）。

## 本轮改动清单

| # | 改动 | 类型 | 验证点 |
|---|------|------|--------|
| 1 | 命名收口：Engine→Protocol/Routing、删 query-api、knowledge-query.md→knowledge-access.md、graph_refresh→skill_ir_refresh、删 decay schema 字段 | 声明 | 无回归（agent 读改名后路径/文档不困惑，产出仍正确） |
| 2 | finish-workflow「occurrences ≥3 → 标记可晋升候选（不自动 Accepted）」+ promotion-rules 去「自动」 | 行为 | analyzer 不再 auto-Accept，defer 给 Reviewer |
| 3 | resolver 健壮性：basename 匹配 + garbage 告警 | 脚本 | 静态已验（check-e2e-smoke 第 5 段）；真实任务顺带观察 |

## 最小验证集

| 任务 | 用途 | 关键信号 |
|------|------|---------|
| G1（generator，批量导入组件） | 命名无回归 + 知识链完整 | decision_record 存在；knowledge_queried 无「找不到 xx.md」；REUSE 判定正确（ImportDialog 已覆盖 → 零改动或复用）；无命名困惑 |
| A1（analyzer，预置 occurrences≥3） | #2 不自动 Accepted | 产出 knowledge.json 中 occurrences≥3 文件的 status ≠ Accepted（应为 candidate/可晋升候选）；`auto_accepted: false` |

## 前置约束（沿用 round1-8）

1. 目标项目 `/Users/fangxiangming/Work/Ly/东风汽金/code/afc-newcore-web-code`，分支 `benchmark/20260813`，全程禁 commit。
2. suite agent prompt 含「绝对禁止运行任何 git 命令」+「只读/写目标项目目录 + skill 目录」+ 显式绝对路径。
3. A1 前置：预置 `runtime/knowledge.json`（patterns/table.md occurrences=3, status=candidate），跑完删除恢复干净。
4. 代码产物跑完即清。

## 判定口径

- **#2 生效** = A1 产出 `auto_accepted: false`，occurrences≥3 文件未标 Accepted。
- **#1 无回归** = G1 产出 decision_record + 正确 REUSE/实现，无「找不到 knowledge-query.md / Knowledge Query / Decision Engine」类报错。
