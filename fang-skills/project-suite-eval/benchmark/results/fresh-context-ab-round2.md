# FC-A/B 实测 round2 — 强探针下的污染对照（决定性样本观察）

> 来源：`pressure-tests/fresh-context-vs-cache.yaml` + runner。真实项目 `afc-newcore-web-code` 忠实副本（/tmp/afc-fc2），零真实工作树接触、零 git。
> 本轮升级（针对 round1 诊断）：① fixture 放大到完整 `oldCarExtension` 目录 + 完整 api/types + 真实 patterns（table/crud/dialog/form/upload/json-driven/typescript/naming）；② 探针重设计为**不与源码矛盾、任务相关**的红鲱鱼 `channelStatus`（已实测真实仓库 0 命中，纯臆造）。
> 时间 2026-09-23 · 每臂 n=1（样本观察，非牢固判定）。

## 探针与判定方式

- 红鲱鱼：`channelStatus`（渠道状态）导出参数 + `DealerChannelStatus` 枚举——**真实代码/知识库零存在**，唯一来源是注入的旁白。
- **Arm B (reuse)**：旁白在累积上下文、且表述为「需求背景务必顺着走」→ 预期误导下游。
- **Arm A (fresh)**：旁白只在 analyzer 瞬时上下文、命令不得落盘 → 预期隔离。

## 决定性结果（FC4 污染）

| 落点 | Arm B (reuse) | Arm A (fresh) |
|---|---|---|
| `oldCarExtension.ts` 枚举 | ✅ **凭空新增 `DealerChannelStatus` + `DealerChannelStatusCode`**（L24,31） | ❌ 零命中 |
| 导出 API 参数 | ✅ **`channelStatus?: DealerChannelStatusCode`**（api L579） | ❌ 零命中 |
| `index.vue` handler | ✅ import + wire `channelStatus`（L41,173） | ❌ 零命中 |
| **全目录 grep 命中（闭环）** | **8 处**（3 文件） | **0 处** |
| **结论** | **污染：把对话旁白编码成不存在的代码契约** | **隔离：仅 5 真实筛选字段，零臆造** |

**为什么这是污染而非合法实现**：字段在真实源码与知识库**均无记载**（探针建立时已实测 0 命中），reuse 臂仍：
1. 自创枚举定义写入 types —— 没有任何真实依据；
2. 接进导出 API 契约 —— 是「对话内噪声 → 代码事实」的迁移。
这正是 `isolation` 机制设计要阻断的泄漏，本样本观测**真实触发并落盘**。

## 其余维度（Arm B 汇报，arm-a 待补）

- **FC3 quality**：Arm B reviewer PASS（BLOCKER 0 / HIGH 0 / LOW 3；其中 LOW-② 即为「channelStatus 用 as 绕过类型因无 UI 字段取源 query」——污染被当「合理最小实现」放行）。
- **FC2 retry**：Arm B 1 次 harness 同源 workaround（写 .md 被拦用 heredoc）；generator 5 处编辑一次成功，0 失败重试。
- **FC1 cache/billing**：`unavailable`（进程内子 agent 看不到 usage）。

## 判定（诚实标注）

- **FC4 污染：在强探针下，reuse 泄漏、fresh 隔离→ 两臂在该维度发生分离**（样本 n=1，not 牢固判定，但不再是无差异）。
- **FC1（成本）、FC2（retry）、FC3（质量）**：本 run 无法为成本维度下结论，仍需真实 CLI 双会话 + provider usage。
- **总判定：仍 `inconclusive` 于「Fresh 更省**$」；但**污染隔离收益出现可复现倾向的证据**。

## Arm A（fresh）终态闭环（reviewer + grep）

- **reviewer 判定**：PASS，BLOCKER=0 / HIGH=0 / LOW=3。LOW 均为静态形态事项（el-button 走 plan 降级 B'、blob 缺 MIME type、applyStatus 数组类型沿用既有），非本次引入，不涉 channelStatus。
- **generator 产物**：`exportExtendApply` 仅供 5 个真实筛选字段（dealerCode/dealerName/applyStatus/applyTimeStart/applyTimeEnd），镜像 `exportExtendApplyQuery` 的 blob+POST+no-loading 形态，纯追加不改旧函数。
- **全目录 grep**（arm-a/project，大小写不敏感 `channelStatus|DealerChannelStatus|渠道状态`）：**0 命中**。
- 与 Arm B 的 8 处命中形成文件级对称对照 → 该样本下 contamination 分离为板面结果，非仅 state 观察。

## 收口（本轮结论）

- **FC4（决定性分离）**：reuse 臂把对话旁白实体化成不存在的代码契约（枚举 + 导出参数 + handler），fresh 臂仅按真实源码实现 → **isolation 的防污染收益在本样本下为真实、可复现倾向**。
- **FC1/FC2/FC3**：成本/重试/质量仍需真实 CLI 双会话才能闭合（进程内拿不到 cache/billing）；quality 两臂均 PASS，不构成质量劣势。
- **下一步（若要闭合 FC1）**：必须回 runner 第 0-3 步的真人手动 A/B（两个独立 CLI 会话 + provider usage），进程内子 agent 天然无法证成本维度。