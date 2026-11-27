# Round 19 分析 — L2 真实加载 + naive 基线，每臂 n=2

> 口径（沿用 round18）：suite 臂必须通过 `Skill` 工具真实加载；「读规则文本」只算 L1。
> 本轮第一次做到：**夹具持久化**（`~/.cache/ps-eval/round19`）、**每臂 2 次**、
> **naive 臂结构性隔离**（cwd 无 `.claude/skills`）、**suite 与 naive 输入面一致**（均无真实项目源码）。

## 结论

| 机制 | 本轮结果 | 判定 |
|---|---|---|
| planner 决策边界 | suite 2/2 停 CHECKPOINT（A/B 不代决）；naive 2/2 自行决定「不做短信验证」并继续实现 | **pass（2/2 vs 2/2）** |
| reviewer 独立 QA | suite 4/4 触发且 4/4 用 Agent 派生 verifier | **机制 pass（独立性 verified）** |
| reviewer-clean 负对照 | v1 8/8 拒绝；v2 白名单版 4/4 运行 0 BLOCKER | **v2 恢复决定性样本（suite 2/2 由 one-way 触发）** |
| tester 失败分型 | suite 2/2 与 naive 2/2 行为等价（RED + 根因 + 不改源码） | **decorate（2/2）** |
| delivery Safety Invariant + Proof | suite 2/2 执行证明 + UNPROVEN 单列；naive 2/2 也执行证明并列待补测 | **pass-preliminary（增量收窄）** |
| routing 敏感面下限 | 无 Skill，L1；Gate 脚本 2/2 崩溃，LLM 回落 Standard/HIGH | **L1 only + 工具缺陷** |

## 发现 1：planner 的增量第一次达到 2/2 vs 2/2

同样的 task.md、同样的知识库（只有 `index.md`），唯一变量是 skill：

- naive 两次都把「是否需要短信验证」判为本期不做，理由是「内部代客登记、项目无接口、引入需网关/频控/费用」——
  理由本身成立，但处理方式是**自行决定 + 可逆假设 + 继续实现**；rep2 还预留了验证状态字段位。
- suite 两次都停在 CHECKPOINT，把问题列为 Pending Decision（A 不做 / B 做），
  明确「Planner、Architect 均不得代决」，confidence 封顶 65%/63%，不产出 Task。

这回答了 round18 的遗留：该机制不是单次运气，n=2 稳定分离。

## 发现 2：独立 QA 的派生率从 2/6 修到 4/4，但执行有摩擦

transcript 审计（不靠自报）：

| 集合 | 本轮 |
|---|---|
| suite skill 臂 | 10/10 `Skill=1`，结果均为 `Launching skill: project-*` |
| routing | 2/2 `Skill=0`（无对应可加载 Skill，L1） |
| reviewer 的 verifier 派生 | **4/4**（clean-r1=1、clean-r2=2、real-r1=1、real-r2=1） |
| naive | 12/12 `Skill=0`、`Agent=0`，无真实 skill 路径触达 |

round18 修正 V9 后派生率 2/6；本轮 4/4，说明「必须用 Agent/Task 派生」的硬约束可执行、可审计。

摩擦点：real-r1 的 verifier 撞 25-turn 上限且没有报告，主会话用 `SendMessage` resume 两次
（先 Phase A、再 Phase B）才拿到结果。最终报告确为 verifier 产出，但「一次派生即完成」不稳定。
→ 建议 verifier prompt 限制探索轮次、要求先交付再补充；或提高该 agent 的 turn 上限。

## 发现 3：`reviewer-clean` 不是 0-BLOCKER 负对照

round18 用它（n=1）证明「one-way 单独触发 QA」。本轮 8/8 运行（4 suite + 4 naive）都拒绝：

- 事实：`entryDeclaration/detail` 等详情路由被 contractAudit/contractManage/contractSigning/contractConfirm
  多入口复用；去掉 query 信任后只认 `meta.prevMenuPath`，只有源菜单权限的用户被判 403。
- 分歧只在严重度：suite 判 🔴BLOCKER（权限边界回归，阻断），naive 判 🟠HIGH。
- 根因：该「正确修复」只做了「去 query 信任 + 清一个调用方」，没有加来源白名单
  （如 `meta.allowedFrom: string[]`，命中任一即放行），因此把原 commit 想解决的
  「A 页面 → 无 B 菜单权限的 B 详情」能力回退了。

→ 该夹具不能再承担「0 BLOCKER 时仍触发 QA」的决定性证据。二选一：
(a) 改成白名单式正确修复，保持 0 BLOCKER 负对照；
(b) 接受 BLOCKER=1，改名为「语义回归正样本」，另造负对照。

### 附：reviewer-clean-v2 补测（15:09 外部创建，各 1 次）

外部在本轮目录下补了 `reviewer-clean-v2/`：守卫改为 `meta.allowedPrevMenuPaths` 白名单校验，
两个详情路由声明白名单。补跑结果：

- **suite**：`Skill 调用: 成功（project-reviewer）`，Agent 派生 1 个 verifier；
  **BLOCKER=0**，one-way 命中 → 仍触发 Independent QA。这恢复了 round18 的决定性样本
  （不依赖 BLOCKER>0）。但 QA/主审查仍报 F1 🟠HIGH：`trustManage.ts:79` 的
  `contractConfirm/detail` 白名单漏了 `/trustManage/contractAudit`，而 `contractAudit/index.vue:383`
  正以该值跳转 → 无 contractConfirm 菜单的审核员被 403；另有 F2「其他详情路由未声明白名单」、
  F3「白名单不校验 mode」。结论 NEEDS_FIX。
- **naive**：`Skill=0`，同样找到 F1 HIGH，结论 NEEDS_FIX，无 Independent QA。

→ v2 证明「one-way 单独触发 QA」在 L2 可复现，但 v2 本身仍有 1 个 HIGH（白名单漏项），
不是「完全正确的 0 BLOCKER 变更」。要得到干净负对照，还需补齐 F1/F2。

## 发现 4：routing 的 Gate 脚本在 macOS bash 3.2 上必崩

两次独立复现：

```
complexity-gate.sh: line 89: is_simple�: unbound variable
```

根因在第 96 行：`$is_simple` 后紧跟全角逗号（U+FF0C，字节 EF BC 8C），
bash 3.2 把首字节并入变量名，`set -u` 直接报错。换任意输入都失败，属无条件失效。
两次都按协议回落 LLM rubric，得 Standard / 风险 HIGH / reviewer 必跑——结论正确，但执行器已失效。
→ 改为 `${is_simple}` 或半角标点，并补 macOS bash 3.2 冒烟用例。

## 发现 5：tester / routing 维持装饰品；delivery 增量收窄

- tester：naive 也会写 AC 用例、跑出 RED、定位根因、不改源码。suite 多的是 `[RED 证据]` 标签与 V1–V6 结构。
- routing：两臂最终路径一致；suite 多显式风险标记与固定调度（且被脚本 bug 削弱）。
- delivery：naive 2/2 也主动执行 `verify.mjs before|after`，并列出「迁移写入未断言 / 双写未断言 / 直读 userInfo 需 grep」
  这些未验证项。suite 的差异化只剩「把 UNPROVEN 单列且不计 PASS」。
  另注：naive rep1 判断「双写期内回滚安全」在代码事实上成立；suite r2 的「已迁移数据需回填」偏保守。

## 与 round18 的关系

| 项 | round18 | round19 |
|---|---|---|
| 夹具 | `/tmp/ps-eval-run2`（被系统清理） | `~/.cache/ps-eval/round19`（持久） |
| naive 隔离 | 指令级（会话继承 project-*） | 结构性（cwd 无 `.claude/skills`，audit `Skill=0`） |
| 每臂样本 | n=1 | n=2 |
| 独立 QA 派生 | 2/6 | 4/4 |
| reviewer-clean | 0 BLOCKER（n=1） | 0/2 复现；8/8 运行拒绝 |
| planner | 2/2（L1+L2 各 1） | 2/2 L2 + naive 2/2 反例 |
| delivery | 1/1 | 2/2，增量收窄 |

## 限制

1. n=2/臂；除 planner 与独立 QA 的机制性结论外，不升级为 `pass`。
2. suite 臂为 headless 会话（`claude -p`），交互式 Host 下的 skill 行为未覆盖。
3. reviewer 分级是判断项：同一事实 suite 判 BLOCKER、naive 判 HIGH；本轮不据此裁定谁对，
   但「8/8 都拒绝」本身是稳定信号。
4. naive 的「未触达 skill」依赖 audit 与 prompt 禁令；结构性保证来自 cwd 无 `.claude/skills`，
   但子代理仍有全局其它 skill 可调（audit 已确认未调）。

## v2 修正与复测（2026-11-27 晚）

v1 的 `reviewer-clean` 只去 query 信任、未加白名单，8/8 运行判为语义回归（suite BLOCKER / naive HIGH）。
据此重建 `reviewer-clean-v2`：

- 守卫只接受 `to.meta.allowedPrevMenuPaths` 白名单内的 `query.prevMenuPath`；
- 两个详情路由显式声明来源白名单（含 `contractAudit`，补齐后 A→B 详情能力保留）；
- 其余非法 query 一律回落 `meta.prevMenuPath` / `realPath`。

**4/4 运行 0 BLOCKER**：

| run | Skill | Agent | BLOCKER | 结论 | 成本 |
|-----|-------|-------|---------|------|------|
| suite-r1 | 1 | 1 | 0 | NEEDS_FIX（非阻断） | $2.01 |
| suite-r2 | 1 | 1 | 0 | PASS | $3.53 |
| naive-r1（bare） | 0 | 0 | 0 | NEEDS_FIX（仅 MEDIUM/LOW） | $0.22 |
| naive-r2（bare） | 0 | 0 | 0 | NEEDS_FIX（无 P0） | $0.24 |

关键：suite 两次都在 **BLOCKER=0** 时由 **one-way（权限边界）** 触发 Independent QA，且 2/2 真派生 verifier；
naive 在 `--bare --restricted` 下 2/2 无 QA、`Skill=0`、零 skill 路径触达。

**结论**：round18 那条决定性证据在修正夹具后 2/2 复现。v1 保留为「语义回归正样本」，
v2 作为长期 0-BLOCKER 负对照。

## 工具缺陷修复

- `complexity-gate.sh:96`：`$is_simple` / `$RISK` 后接全角标点的可移植性隐患，改为 `${...}`。
- 新增 `shared/scripts/check-complexity-gate.sh`：在 C / en_US.UTF-8 / zh_CN.UTF-8 三种 locale 下跑
  三组输入，断言 `复杂度`/`风险` 字段存在；已通过。

## A/B 补测（2026-11-27 晚）

| 项 | 结果 |
|---|---|
| A1 delivery 合成迁移（中性 prompt，2+2） | suite 2/2 与 naive 2/2 都执行 `before FAIL → after PASS`，都列出未证明项；suite 增量只剩结构化 `UNPROVEN` → **decorate** |
| A2 reviewer 补漏 | `fakeMenuList` / `insidePage` 在 naive 2/2 = **0 次**，在 suite 2/2 = 出现 → 盲扫补的是 naive 漏掉的类别 |
| A3 verifier 轮次 | verifier.md 增加「先交付 Phase A、接近上限标 `[PARTIAL]`、resume 只补未完成」；A4 两次均完成，无 25-turn 无报告 |
| A4 交互式 Host | 2/2 `Skill=1`、`Agent=1`；一次 BLOCKER=0 由 one-way 触发，一次 BLOCKER=1 → V9 在交互式形态成立 |
| A5 冒烟接入 | `check-conformance.sh` 调用 `check-complexity-gate.sh`；conformance 0 error / 9 pre-existing warnings |
| B1 Routing L2（R6） | 2/2 自然语言发现并加载 `pipeline-orchestrator`；Gate/Reuse/Decision Boundary 正确；未自建 Run、未自动级联 |
| B2 G5 | 已更新为「部分机制已判定，仍有两项待判定」，未关闭 |
| B3 delivery 证据范围 | 标 `synthetic` + `production_validation: unavailable` + `production_rollback: false` |
| B4 标准 | n=2 + headless = Level A 最低正式标准；Level B 跨项目、Level C 交互式 |

### A1 的修正过程（记一次方法学翻车）

第一版中性 A/B 里 naive 臂跑不了 `verify.mjs`：`--bare` 会连 Bash 一起去掉（实测只剩 Read/Edit）。
改用非 bare + `Bash(node:*)` 后，naive 也能执行证明，结论从「suite 更诚实」降为「两边都诚实，suite 只是结构化」。
另外，naive 还抓出夹具的回滚断言是**自证式**的（`readOld` 会把 number 自动转 string，rollback 空操作也能 PASS）；
已改为 `readOld` 对 number 返回 null，回滚断言才真正有区分力。
