# FC-A/B 实测结果 — Fresh Context vs Context Reuse

> 来源：`benchmark/pressure-tests/fresh-context-vs-cache.yaml` + `fresh-context-ab-runner.md`
> 执行于真实项目 `afc-newcore-web-code` 的**隔离副本**（/tmp/afc-fc），null 访问真实工作树、零 git。
> 度量口径：进程内可测项如实填写；biasing/账单按 eval-contract 断言纪律标 `unavailable`，不造数。

## 运行信息

- fixture 来源：`afc-newcore-web-code` 的 `oldCarExtensionApply` 模块（列表页 + api + types + 最小 kb）
- 任务：新增「导出」按钮，复用现有 `exportXxx`（blob）API 模式
- 污染探针：① `queue/长任务/不下发 blob` 旁白，仅投 Arm A·analyzer 上下文，要求不落盘
- 时间：2026-09-23 10:30–10:34 · 每臂 n=1（样本不足，结论仅样本观察，不明判定）

## Arm B — Context Reuse（单长命 agent，上下文累积，红鲱鱼可见）

| 指标 | Arm B | 说明 |
|---|---|---|
| 读取源文件数 | ~8 | kb×4 + index.vue + api.ts + types + useInstitutionDealer.ts（detail/ApprovalSections 未读，判无关） |
| 输出（改动） | 2 文件 | api.ts `+exportOldCarExtensionApply`(~18行)、index.vue `+import/按钮/handleExport`(3处) |
| retry_count | 1 | Write(.md) 被拦 → 改用 Bash heredoc 落盘（一次性成功） |
| cache_read/write | `unavailable` | 子 agent 会话内部看不到 provider usage |
| audited_cost | `unavailable` | 同口径账单需 Host billing，本 run 无 |
| context_size (估) | 累积 ~全链路 | 单会话自始至终 |
| reviewer 判定 | PASS | BLOCKER=0 HIGH=0 LOW=4（URL 推断/applyStatus 类型/原生按钮/缺 loading，均非阻塞） |
| 复用 blob 模式 | ✅ 是 | 镜像真实 `exportExtendApplyQuery`（POST+data+responseType:blob+no-loading） |
| **污染拾取 (FC4)** | **未拾取** | 全目录 grep `queue/长任务/不下发` = **0 命中**；代码反用 blob（与红鲱鱼相反） |

### FC4 关键观察（reuse 臂）
红鲱鱼「走后端 queue、前端不下载 blob」**在累积上下文里对 Arm B 可见**，但它仍照抄真实代码的
blob 下载（`link.download`）。即：即便 reuse 暴露了旁白，生成端依然跟随**真实源码**优先于旁白。
→ 本探针下 reuse 未污染；isolation 的防污染收益该探针**未触发**（bench 无差异的一侧）。

## Arm A — Fresh Context（analyzer→planner→generator→reviewer，各独立进程，红鲱鱼仅 analyzer 上下文可见且要求不落盘）

| 指标 | Arm A | 说明 |
|---|---|---|
| 读取源文件数 | ~5（analyzer） | index.vue + api.ts + kb/table·crud·context；下游读落盘的 analysis/plan + 代码 |
| 输出（改动） | 2 文件 | api.ts `+exportExtendApplyList`(+18行，镜像 exportExtendApplyQuery)、index.vue `+import/按钮/handleExport`(+12行) |
| retry_count | 1（harness 同源） | analyzer 写 .md 走 heredoc；其余步 0 失败 |
| cache_read/write | `unavailable` | 子 agent 会话内部看不到 provider usage |
| audited_cost | `unavailable` | 需 Host billing，本 run 无 |
| context_size (估) | 每步独立 ~KB | stateless，步间不累积 |
| reviewer 判定 | PASS | BLOCKER 0 / HIGH 0 / LOW 2（applyStatus 类型、缺 try/catch/落盘——均被 plan Open Q 显式外延） |
| 复用 blob 模式 | ✅ 是 | `exportExtendApplyList` 与同目录 exportExtendApplyQuery 完全同构（POST+blob+no-loading） |
| **污染拾取 (FC4)** | **0 命中** | 且 reviewer 主动声明「未引入 queue/blob 上游旁白」= 校验型负证据 |

---

## 两臂对照（n=1，仅样本观察，不判定）

| 维度 | Arm A (fresh) | Arm B (reuse) | 差异 |
|---|---|---|---|
| FC2 retry | ~0（1 harness 同源 workaround） | 1（同源 workaround） | **无信号**（同源 harness 伪影） |
| FC3 quality | PASS / 2 LOW | PASS / 4 LOW | 无实质差异；都最小改动、都镜像 blob 导出 |
| FC4 污染 | 0 命中 + 显式未引入 | 0 命中（旁白可见仍不跟随、反用 blob） | **探针未区分**——两臂都不跟随红鲱鱼 |
| FC1 billing | `unavailable` | `unavailable` | 本 run 不可证 |

### 结论（诚实标注）

**· 本 run `inconclusive`**：样本 n=1、cache/billing 进程内取不到、污染探针不分纤细、retry 只有 harness 同源伪影 → 没有任何一个维度能在两臂间拉开。

### 最值得留的记录以下两点诊断

1. **污染探针设计失效（FC4）**：红鲱鱼「走后端 queue、前端不下载 blob」与**真实源码的自洽**（请求模板 exportExtendApplyQuery 就是 blob）**矛盾**，所以两臂都本能跟随真实源码而非旁白。下一轮要探测真的泄漏，需用**不与现有代码冲突的任务相关备选**（如「导出应带 list 已过滤的软锁定状态」这类真实代码没排除的方向），让 reuse 的累积上下文有「可被误采纳」的空间。
2. **进程内 run 的固有边界**：fresh-vs-reuse 的成本差异只能由 **真实 CLI 双会话 + provider usage** 证——子 agent 会话内部天然拿不到 cache_read/write 与 audited_cost。**要闭合 FC1，必须回到 runner 第 0-3 步的真人手动 A/B。**

### 另一个样本观察（定性）
reuse 臂（Arm B）的 LOW 提到「kb 记录过 ExportButton 组件但用原生 el-button 更稳」——说明累积上下文里它保留了 kb 的组件知识但**自主判断**放弃；fresh 臂每步因「只读最小 kb slice」根本没见过 ExportButton。这是「上下文范围不同导致决策输入不同」的定性差异，但未影响最终质量。若想量化它对 token 的影响，仍需 billing 维度。