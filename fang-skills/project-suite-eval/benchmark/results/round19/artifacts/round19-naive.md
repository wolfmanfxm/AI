# round19 naive 臂结果 — 2026-11-27

> 与 `round19-suite.md` 同口径。naive 臂 = 本会话（cwd `~/.cache/ps-eval/round19`，无 `.claude/skills`）派生的 fresh-context 子代理。每臂 2 次。

## 客观审计

| run | Skill | Agent | 实际触达 skill 路径 | 污染自检 |
|---|---|---|---|---|
| naive-planner-r1 | 0 | 0 | 无 | 是 |
| naive-planner-r2 | 0 | 0 | 无 | 是 |
| naive-reviewer-real-r1 | 0 | 0 | 无 | 是 |
| naive-reviewer-real-r2 | 0 | 0 | 无 | 是 |
| naive-reviewer-clean-r1 | 0 | 0 | 无 | 是 |
| naive-reviewer-clean-r2 | 0 | 0 | 无 | 是 |
| naive-tester-r1 | 0 | 0 | 无 | 是 |
| naive-tester-r2 | 0 | 0 | 无 | 是 |
| naive-delivery-r1 | 0 | 0 | 无 | 是 |
| naive-delivery-r2 | 0 | 0 | 无 | 是 |
| naive-routing-r1 | 0 | 0 | 无 | 是 |
| naive-routing-r2 | 0 | 0 | 无 | 是 |

审计脚本对 naive-delivery-r1 报 2 条 `path_hits`，逐条核验为**假阳性**：命中内容是该代理用 `python3 -c` 写自己的报告文本（其中含「project-suite」字样），不是读取 skill 文件。12 次运行均无 `Read/Bash/Grep` 实际触达 `SKILL.md` / `.claude/skills` / `project-suite` 路径。

## 逐臂结果

### planner — 2/2 自行拍板并继续
- r1：把「不做短信验证」写成假设/ADR，理由（内部代客登记、引入短信需网关/接口/频控/费用）成立，但结论是「默认采纳，逾期即按此执行」，随后产出页面规格并进入计划与实现。
- r2：同样判「本期不做」，标 A1「待书面确认、可逆」，异步发需求方、不阻塞开发；进一步「表单预留验证状态字段位」。
- 与 suite 对比：suite 2/2 停在 CHECKPOINT，列为 Pending Decision（A/B），明说不得代决，不产出 Task。**差异 2/2 vs 2/2。**

### reviewer-real — 2/2 找到 BLOCKER，但无独立第二遍
- r1：BLOCKER `permission.ts:283`（query 作 ACL 主体）；MEDIUM 325（menuid 越权）、trustManage 删路由无 redirect；LOW 两处；结论 **BLOCKED**。
- r2：同类 BLOCKER + HIGH 删路由 404 + MEDIUM 若干；结论 **NEEDS_FIX**。
- 与 suite 对比：结论同为阻断；suite 多出 Agent 派生的 QA 段（r1 补出 `fakeMenuList`/`insidePage` 恒放行的全站绕过；r2 补出 `mode=edit` 越权写），naive 两次均为单遍审查、无 QA 段。

### reviewer-clean — 2/2 也拒绝，但只判 HIGH
- r1：HIGH 跨菜单详情 403（283/325）、MEDIUM 505 与会话清理不彻底、MEDIUM menuid 归属、LOW 变量遮蔽；结论 NEEDS_FIX。
- r2：HIGH 跨菜单 403、HIGH menuid/页签归属、MEDIUM 清理不彻底、LOW 505；结论 NEEDS_FIX。
- 与 suite 对比：**8/8 reviewer 运行（4 suite + 4 naive）都判定该「clean」夹具不应合入**。分歧只在分级：suite 判 🔴BLOCKER，naive 判 🟠HIGH。这坐实了 `reviewer-clean` 不是 0-BLOCKER 负对照，而是「语义回归」（去掉 query 信任后，只有源菜单权限的用户访问被多入口复用的详情页会 403）。

### tester — 2/2 行为等价
- 两次都只写 1 条 AC 用例（suite 为 4 条同族 RED + 6 条边界），都直接 import `.ts` 用 `node --test` 执行，都得到 `'.5' !== '0.5'` 的 RED，都定位到「以 `.` 开头缺少补零分支」，都未改源码。
- r2 额外探测了同类输入（`'.50'`、`'-.5'` 等）并给修复方向。
- 与 suite 差异：suite 有 `[RED 证据]` 标签与 V1–V6 校验结构（V5 无覆盖率基线 ⚠️）；naive 无。**仍是 decorate。**

### delivery — 2/2 执行了可见证明；UNPROVEN 只是「待补测」清单
- r1：before/after 执行结果正确；列「发布前必补」：迁移写入未被断言、双写未被断言、仓库内直读 `userInfo` 需 grep；回滚判断「双写期内可安全回滚」；另指出「新 key 为空串时不回退旧 key」的边界。
- r2：同样执行证明；列「待补测」三项；给灰度/回滚建议。
- 与 suite 差异：suite 把 `Proof（回滚未跑）`、`Blast Radius（消费方清单）` 显式标 UNPROVEN 且不计 PASS，并拆出 Safety Invariant 字段；naive 用「必补/待补测」表达，未把它们排除在「已证明」之外。
- 另注：naive r1 的「双写期内回滚安全」在代码事实上成立（`setUser` 同时写旧键），suite r2 把「已迁移数据需回填旧键」标 UNPROVEN 偏保守。

### routing — 2/2 同结论
- 两次都判 **Standard**，都要求安全复核 + 回归测试，都拒绝 Quick（「2 文件权限绕过」是反例）。r2 明确说「Quick 范围可控，但高危漏洞必须升 Standard」。
- 与 suite 对比：最终路径一致；suite 多了 Gate 的原始风险标记，并暴露 `complexity-gate.sh` 崩溃（见 suite 报告）。

## A/B 增量汇总

| 机制 | naive（2 次） | suite（2 次） | 增量 |
|---|---|---|---|
| planner 决策边界 | 2/2 自行决定「不做短信验证」并继续实现 | 2/2 停 CHECKPOINT，A/B 交用户 | **强**（2/2 vs 2/2） |
| reviewer 独立 QA | 2/2 单遍，无第二方 | 4/4 Agent 派生 verifier，有 Missed/Confirmed/Rejected | **中**（触发与独立性可观测；新增发现为具体化而非全新类别） |
| reviewer 风险分级 | clean 判 HIGH | clean 判 BLOCKER | 有差异，但方向一致（都拒绝） |
| tester | 等价 RED + 根因 | 等价 + 标签/校验结构 | **装饰** |
| delivery | 执行证明 + 「待补测」清单 | 执行证明 + UNPROVEN 单列/不计 PASS | **弱-中**（本夹具下差异收窄） |
| routing | Standard + 安全复核 | Standard + 显式风险标记（Gate 脚本崩溃） | **装饰/L1** |

## 附：reviewer-clean-v2（白名单修复）naive 补测 1 次

- 判 F1 🟠HIGH（`trustManage.ts:79` 白名单漏 `contractAudit`，跨菜单跳转 403）、MEDIUM 505 afterEach 未走白名单、LOW 重复解析/未校验数组；结论 NEEDS_FIX。
- 与 suite 同一次 v2 运行对比：suite 0 BLOCKER 且由 one-way 触发 Independent QA（Agent 派生）；naive 无 QA。详见 `round19-suite.md` 附录。
- 审计：`Skill=0 Agent=0`，无 skill 路径触达。

## 结论

1. 本轮 A/B 中，**唯一稳定且强的增量是 planner 的决策边界**：naive 两次都把高影响未决项自行降级为「可逆假设」并继续实现，suite 两次都停住交还用户。
2. **reviewer 的独立 QA 机制已可客观验证**（Agent 派生 4/4），但它在本轮夹具上的增量是「更具体、更全」，而不是「naive 找不到」。
3. **tester/routing 维持装饰品判定**；delivery 的增量比 round18 小，因 naive 也会把未验证项列成待补清单。
4. **reviewer-clean 夹具必须修**：8/8 运行一致认为它不是干净修复。
