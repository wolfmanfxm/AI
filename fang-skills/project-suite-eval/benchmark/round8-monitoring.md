# Round 8 监测报告 — 额外动作型机制补测

> 验证此前「理论分类为额外动作型 RED 强」但未实测的机制，是否真的改变行为。
> 本轮最重要的产出是一个**推翻性发现**：round7 的「额外动作型 RED 强」分类，对当前模型系统性失效。

## 本轮改动性质

round7 结论曾把机制分两类：额外动作型（先读源码/真跑测试/增量修改/精确溯源）RED 强，判断型（遵循模式/现状核实/够用就好）RED 弱。本轮补测了 6 个「额外动作型」——它们此前标「✅ 生效」但无实测证据。

## 测试对象与方法

目标项目 `/Users/fangxiangming/Work/Ly/东风汽金/code/afc-newcore-web-code`，naive（不加载 skill）vs suite（加载 skill）对比，全程禁 git、只读/隔离产物。

| 机制 | 场景 | naive 行为 | suite 行为 | 判定 |
|------|------|-----------|-----------|------|
| 组件复用（generator P1） | 写查询列表页 | 用 PageTable+SchemaSearch+SchemaTable，参考 taskManage | 用 4 个封装组件，读 5 份 KB | ❌ decorate（都复用项目组件） |
| 增量修改（generator P2） | 改一处逻辑 | Read 后 Edit，diff 3 行，不 overwrite | Read 后 Edit，diff 1 行 | ❌ decorate（都 Read-then-Edit） |
| 完整性（generator P3） | 写异步列表组件 | 全四态（loading/empty/error/success） | 三态覆盖 | ❌ decorate（都全状态） |
| 精确引用（reviewer P1） | 审查 format.ts | 6 条 finding 全 file:line（还挖出错别字、falsy-0 陷阱） | 8 条 finding 全 file:line + 分级 | ❌ decorate（都精确引用） |
| 可操作（reviewer P3） | 审查 format.ts 给修复 | 8 条「位置/改什么/为什么」可执行修复 | 12 条「位置/改法/为什么」+ 五轴 | ❌ decorate（都可操作） |
| AC 对照（reviewer P2） | 对照 3 条 AC 验证 | 逐条对照 + file:line | 逐条对照 + file:line | ❌ decorate（都逐条对照） |

## 关键发现：round7 的「额外动作型 RED 强」分类已失效

**6/6 全部 decorate** —— naive 没加载 skill，也做到了「组件复用」「Read-then-Edit」「全状态覆盖」「file:line 引用」「可操作修复」「逐条 AC 对照」。

这系统性推翻 round7 的结论。round7 说「额外动作型（先读源码/真跑测试/增量修改/精确溯源）是 LLM 默认不会做的动作」，但本轮证明：

- **增量修改（Read-then-Edit）** 已是当前模型的默认行为（Read/Edit 工具范式训练了它）
- **组件复用 / 完整性 / 精确引用 / 可操作 / AC 对照** 都是现代 LLM 的通用能力

**真正仍可能 RED 强的，只剩 round7 已实证的「真跑测试」（可执行）、「读源码再测试」（先理解再测试）这类「模型仍不会默认做的动作」。**

## 方法论结论

1. **RED 假设必须针对当前模型重测，不能沿用历史结论**。round7 的「额外动作型 vs 判断型」分类，本质上是「当时模型的能力边界」，不是机制的内在属性。
2. **「额外动作型」这个类别太粗**。它把「真跑测试」（模型仍不会默认做）和「Read-then-Edit」（现已是默认行为）混在一起。需要进一步细分：**「执行型额外动作」（真跑测试、真读源码）vs「格式型默认行为」（file:line、可操作修复、全状态）**。
3. **skill 的真正增量价值**，可能收敛到极少数「执行型额外动作」（如 tester 的「生成后尝试运行」），其余绝大多数「格式/判断」规则都是 LLM 通用能力。

## 执行型机制复测（追加，第 2 批）

补测 round7 判为「唯一强 GREEN」的两个执行型机制，验证它们对当前模型是否仍 RED 强：

| 机制 | naive 行为（无 skill） | suite 行为 | 判定 |
|------|----------------------|-----------|------|
| 可执行（tester P4） | 主动 `npx vitest run`，失败后借 workspace 工具链 workaround，21 tests 跑通 | 24 tests 跑通（同 workaround） | ❌ decorate（都主动运行） |
| 先理解再测试（tester P3） | 先 Read 源码，31 断言，抓到 `0→''` 但 `'0'→'0'` 不对称 bug | 先 Read 源码，19 用例，抓到 0 不对称/负数符号/全角数字 | ❌ decorate（都读源码） |

**结论：两个执行型机制也全部 decorate。** 至此 round10+round8 实测 14 个机制（判断型 6 + 格式型 6 + 执行型 2）全部 RED 弱。round7 的「可执行 = 唯一强 GREEN」也失效——当前模型的 naive 天然会跑测试（甚至坚持跑通）、会读源码（甚至抓边界 bug）。

## 建议下一步

1. **重测 round7 已实证的 2 个「执行型」机制**（可执行、先理解再测试），确认它们对当前模型是否仍 RED 强——这决定了 suite 还有没有「硬增量」。
2. **把 6 个 decorate 机制在 ledger 降级**（✅ 生效 → ❌ decorate），并重新审计「额外动作型 vs 判断型」分类是否需要按「执行型 vs 格式型」重构。
3. **剩余 4 个额外动作型**（决策可追溯、EvidenceScore、先候选、AC 驱动）大概率也是 decorate，可快速跑完收尾。

## 越界/产物

- P2 naive 改 `format.ts`、suite 改 `validator.ts`，已 `git checkout` 恢复。
- 其余产物写 `.benchmark-tmp/`，已清理。目标项目工作树干净。
- 一个 agent（P3 suite 首派）进程丢失，已重派补跑。
