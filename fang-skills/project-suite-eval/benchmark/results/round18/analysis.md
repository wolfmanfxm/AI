# Round 18 分析 — L2（真实 Skill 加载）复测

> 口径（用户定）：suite 臂必须通过 Skill 工具真实加载；「读规则文本」降为 L1/静态检查。
> 本轮全部 suite 臂报告 `Skill 调用: 成功`；路由机制无对应可加载 Skill，只能 L1。
> 样本：每臂 n=1（部分机制有 L1+L2 各 1 次）。

## 结论

| 机制 | L2 结果 | 判定 |
|------|---------|------|
| planner 决策边界 | Skill 成功；停 CHECKPOINT，D-001 A/B | **pass-preliminary**（L1+L2 一致） |
| reviewer 风险触发盲扫 | Skill 成功；**0 BLOCKER + one-way 仍触发**；负对照跳过 | **pass-preliminary**（独立性未 verified） |
| delivery Safety Invariant + Proof | Skill 成功；可执行证明被跑，未执行分支标 UNPROVEN | **pass-preliminary（仅诚实分支）** |
| tester 失败分型 | Skill 成功；naive 行为等价 | **装饰品** |
| routing 敏感面下限 | 无 Skill 可加载，L1 only | **装饰品 / 静态** |

## 发现 1：L2 决定性样本成立——没有 BLOCKER 也会触发

构造了一个**正确的权限修复**（去掉守卫对 `query.prevMenuPath` 的信任，并清理一个调用方），
预期 0 BLOCKER。suite 臂逐条判定：

- Risk=HIGH：不命中（无 PLAN，DEGRADED）
- **one-way（权限与认证边界）：命中**
- BLOCKER>0：**不命中（0）**
- 文件>10：不命中（2）

→ 仍触发 Independent QA，且盲扫补出主审查漏掉的问题：另外 3 个调用方仍发失效参数，
影响面比 diff 呈现的大。这排除了「只是 BLOCKER>0 旧条件在起作用」的解释。

## 发现 2：精确性修复在 L2 成立

真实项目负对照（2 行按钮换位）：graph 算出 7 个消费者节点，但 suite 明确写「按 validation.md 排除，
不计入 QA 触发，只升审查深度」→ `[QA SKIPPED]`。
说明 `graph>5` 从 QA 触发移除后，召回与精确性在 L2 同时成立。

## 发现 3：L2 只保证规则执行，不保证验证者独立

**工具审计**（扫描 subagent transcript 的 tool_use，不靠自报）：

| 集合 | 结果 |
|------|------|
| naive 臂（6 次） | `Skill=0`，且 0 次工具输入触达 `SKILL.md` / `project-suite` / `.claude/skills` |
| suite 臂（L2） | 全部 `Skill=1`，真实加载成立 |
| reviewer verifier 派生 | **2/6**（`a46a17`、`a27845` 出现 `Agent=1`；pilot 与 L2 rep1/rep2/neg 均 `Agent=0`） |

其中一次臂明确自报：

> verifier 段在同一上下文按「盲扫→对照」顺序执行，非真 fresh context。

所以「Independent QA」在当前执行里仍是**纪律项**：产出章节 ≠ 真有独立验证者。

**修正与复测（同日）**：在 verifier.md 与 V9 明确「必须用 Agent/Task 派生；同上下文模拟不算；
无法派生标 `[QA NOT INDEPENDENT]`」。改动后两个臂 **2/2 出现 `Agent=1`**（修复前 2/6）。
其中一个臂因 `/tmp` 夹具被系统清理而正确返回 BLOCKED、未编造——这也顺带验证了「输入缺失不硬编」。
样本仍小，待重复。

## 发现 4：当证明摆在眼前，naive 也会跑

delivery 正例里，naive 臂主动执行了 `node verify.mjs before|after`，并报告 FAIL B→PASS。
所以该机制的增量不在「会不会跑可见证明」，而在：

- 未执行的分支（旧页写合法新值 / 清 key、消费方清点）是否被**显式标成 UNPROVEN**；
- UNPROVEN 是否**单独列出、不计 PASS**。

naive 把「应验证」写成清单，没有把「未验证」标出来；suite 标了。

## 发现 5：naive 的结构隔离仍未达成

新会话仍从含 `project-*` symlink 的 workspace 启动。naive 臂的「未读取 skill」是自报，
不是结构性保证。要彻底消除，需要下一次会话直接在 `/tmp/ps-eval-run2` 启动。

## 与 L1（round17）的关系

- L1 证明的是「规则文本被遵循」；L2 证明「Skill 被加载且规则生效」。
- 两条机制在 L1 判为装饰品，L2 复现同样结论（tester、routing），不是口径造成。
- 三条初步通过机制在 L2 均有真实 Skill 调用；但仍受 n=1 / 独立性自报 / naive 弱隔离限制，
  **不升级为 `pass`**。
