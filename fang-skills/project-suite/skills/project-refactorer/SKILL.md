---
name: project-refactorer
metadata: skill.yaml
description: >
  改善代码结构不改变外部行为：提取函数/组件、简化条件逻辑、移除死代码、语义化重命名、
  拆分过大模块。每次重构必须安全可逆，有测试跑测试，无测试先加表征测试。
  触发词：重构、优化结构、提取公共、简化代码、消除重复、拆分模块、重命名、
  refactor、clean up、extract method、simplify、reduce complexity、优化这段代码。
  产出：重构后代码 + REFACTOR.md（变更记录 + 改善指标 + 验证结果）。
---

# Refactorer

> 代码 → 识别坏味道 → 安全重构 → 验证 → REFACTOR.md

## 核心原则

1. **行为不变** — 重构前后外部行为完全一致
2. **安全第一** — 有测试先跑测试，没测试先加表征测试
3. **小步快跑** — 每次只做一个重构动作，可独立提交回滚
4. **可量化** — "圈复杂度 15→3" > "改好了"

## 职责边界

→ [references/boundary.md](references/boundary.md)

> 🔴 refactorer 只改善结构不改行为。没测试保护不重构。

## 反例黑名单

| # | ❌ 反模式 | 为什么不要做 | ✅ 正确做法 |
|---|---------|-------------|-----------|
| 1 | **无测试保护直接重构** | 重构后行为变化无人知晓，引入回归bug | 有测试先跑绿 → 无测试先加表征测试 → 确认绿后才重构 |
| 2 | **一次性重构 >5 个文件** | 变更范围大难以 review，一旦出错回滚成本高 | 拆分为多次小重构，每次 1-2 文件，独立提交 |
| 3 | **重构同时改功能** | 行为和结构同时变化，diff 无法区分哪个导致问题 | 重构 commit 只做结构变化，功能变更单独 commit |
| 4 | **不量化改善效果** | "感觉好多了"无法说服 review，下次重构无基线对比 | REFACTOR.md 记录：圈复杂度 15→3 / 行数 800→320 / 重复率 40%→5% |
| 5 | **测试变红后强行提交** | 重构引入了 bug 但被忽略，后续开发者基于坏代码继续工作 | 测试变红 → `git diff` 逐段排查 → 无法定位则 `git revert` 整个重构 |

## 前置条件

| 优先级 | 资源 | 缺失时 |
|--------|------|--------|
| 0 | **待重构代码** | 🔴 BLOCKED |
| 1 | 现有测试 | 🟡 DEGRADED — 无测试保护不重构 |
| 2 | `.project-knowledge/patterns/` | 🟡 DEGRADED |

## 工作流

### Discover

1. 识别坏味道：长函数/重复代码/过深嵌套/God Class/魔数
2. 确认测试覆盖：有测试→跑一遍；无测试→加表征测试
3. 选重构手法（9种）→ [prompts/extract-method.md](prompts/extract-method.md)
4. 🔴 CHECKPOINT → [checkpoint 模式](../../shared/conventions/checkpoint-pattern.md)

### Execute（小步循环）

```
循环直到目标达成:
  1. 跑现有测试 → 确认全绿（不绿则停止，先修测试）
  2. 做 1 个重构动作（提取/内联/重命名/简化条件/...）
  3. 跑测试 → 仍绿 → git commit（message: "refactor: {具体动作}"）
  4. 测试变红 → git revert → 分析原因 → 记录 REFACTOR.md → 继续下一个动作
```

### Output

`.project-knowledge/reports/REFACTOR.md`：
- 变更清单（每个重构动作 + commit hash）
- 改善指标（圈复杂度/行数/重复率/依赖深度，Before→After）
- 测试结果（通过数/失败数/跳过数）
- 失败记录（若有 revert，记录原因+教训）

## 失败处理

| 触发条件 | 一线修复 | 仍失败兜底 |
|---------|---------|-----------|
| 无测试覆盖（项目无测试框架） | 先写表征测试（characterization test）— 记录当前行为 | 标注"⚠️ 无测试保护"，缩小重构范围到纯提取/重命名 |
| 现有测试失败（重构前就不绿） | 停止重构，记录失败测试到 REFACTOR.md | 建议先 `/project-tester` 修复，不强行重构 |
| 重构后测试变红 | `git diff` 对比变更，逐段回滚到最近一个绿点 | `git revert` 整个重构 commit，REFACTOR.md 记录失败原因 |
| 重构范围过大（>5 文件） | 拆分为多次小重构，每次 1-2 文件 | AskUserQuestion 确认是否一次性重构 |
| 圈复杂度改善不明显（<20%） | 尝试更激进的手法（提取策略模式、引入多态） | 标注"⚠️ 边际改善"，不强制继续 |

## 引用索引

| 资源 | 路径 |
|------|------|
| 入口 Prompt | [prompts/main.md](prompts/main.md) |
| 提取方法 | [prompts/extract-method.md](prompts/extract-method.md) |
| 简化逻辑 | [prompts/simplify-logic.md](prompts/simplify-logic.md) |
| 职责边界 | [references/boundary.md](references/boundary.md) |
| 安全协议 | [references/safety-protocol.md](references/safety-protocol.md) |
| 失败处理 | [references/failure-handling.md](references/failure-handling.md) |

## 完成后下一步

```
refactorer 完成 → /project-tester 或 /project-reviewer
```
