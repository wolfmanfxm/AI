# round19 suite 臂结果 — 2026-11-27

> 口径来自 `PROMPTS.md`：suite 臂必须通过 `Skill` 工具真实加载；reviewer 的 Independent QA 必须出现 `Agent`/`Task` 派生；每臂 ≥2 次；事后用 `audit/audit-transcript.py` 客观核对。

## 运行方式

- 每次运行 = 一个**全新 headless Claude Code 会话**（`claude -p`），cwd 为 `/tmp/ps-eval-suite-cwd`（`.claude/skills/` 软链 project-* 套件，外加 `shared/runtime/workflow-protocol` 软链；**不含被测项目源码**）。
- 工具权限用显式 allowlist（`Skill Read Grep Glob Bash Write Edit MultiEdit TodoWrite Agent Task`），未使用 `--dangerously-skip-permissions`。
- 夹具一律用 `~/.cache/ps-eval/round19` 持久路径。tester 临时目录 `/tmp/ps-eval-run19-tester/`。
- 每臂 2 次（repeatability），共 12 次；另有一次早期 pilot（真实仓 cwd）已作废，不计入。
- Prompt 模板与原始输出：`results/prompts/*.txt`、`results/out/*.json`；审计快照：`results/audit-all.jsonl`。

## 客观审计（tool_use，不靠自报）

| run | Skill 工具 | Skill 结果 | Agent/Task 派生 | 触达 skill 路径 | 结论 |
|---|---|---|---|---|---|
| planner-r1 | 1 | Launching skill: project-planner | 0 | 7 | eligible |
| planner-r2 | 1 | Launching skill: project-planner | 0 | 7 | eligible |
| reviewer-real-r1 | 1 | Launching skill: project-reviewer | 1（verifier a9d07df2，需 resume 一次） | 11 | eligible |
| reviewer-real-r2 | 1 | Launching skill: project-reviewer | 1（background general-purpose ab109368） | 10 | eligible |
| reviewer-clean-r1 | 1 | Launching skill: project-reviewer | 1（verifier a66fc67d） | 7 | eligible |
| reviewer-clean-r2 | 1 | Launching skill: project-reviewer | 2（verifier a07fb39a + a4db9849） | 4 | eligible |
| tester-r1 | 1 | Launching skill: project-tester | 0 | 4 | eligible |
| tester-r2 | 1 | Launching skill: project-tester | 0 | 5 | eligible |
| delivery-r1 | 1 | Launching skill: project-releaser | 0 | 8 | eligible |
| delivery-r2 | 1 | Launching skill: project-releaser | 0 | 6 | eligible |
| routing-r1 | 0 | —（无可加载 Skill） | 0 | 8（shared 协议） | L1 only |
| routing-r2 | 0 | —（无可加载 Skill） | 0 | 5（shared 协议） | L1 only |

所有 Skill 调用 `is_error` 均为空；报告开头均出现 `Skill 调用: 成功（<skill>）`。routing 与 round18 一致，无对应可加载 Skill，只能 L1。

## 逐臂结果（2/2 重复性）

### planner — 2/2 停在 CHECKPOINT
- r1：confidence 65%，D-001「短信验证」A（~0.5d）/B（+3~5d，外部依赖），明确「Planner、Architect 均不得代决」，不产出 Task，停 CHECKPOINT。
- r2：confidence 63%，PD-001 同样 A/B，同样停在 CHECKPOINT，不进入 Architect/Generator。
- **判定：pass（机制重复成立）**。差异只在置信度与编号命名，行为等价。

### reviewer-real — 2/2 BLOCKER + 独立 QA
- 共同：`permission.ts:283` 采信 URL 可控 `query.prevMenuPath` 作为 ACL 主体 → 鉴权绕过；删旧路由无 redirect（升/降级有差异）；结论 NEEDS_FIX。
- r1 的 QA 补强：`fakeMenuList`(`/workbench`)/`insidePage` 恒放行 → 任意登录用户 `?prevMenuPath=/workbench` 可绕过全站 403。
- r2 的 QA 补强：`mode=edit` 可越权进入写操作；query 随页签持久化可分享复用。
- **判定：机制成立（风险触发 + 独立 QA）**；两次 QA 均为真派生。

### reviewer-clean — **2/2 都是 BLOCKER=1，未复现「0 BLOCKER」**
- 两次都判定 `permission.ts:283` 改回「只认 meta」后，跨模块详情页（如合同审核 → 进件申报详情）对「只有源菜单权限」的用户返回 403，属权限回归，记 🔴 BLOCKER；结论 NEEDS_FIX。
- 两次均因此触发 QA（one-way + BLOCKER>0 同时命中）。
- QA 额外发现：上游仍有约百处 `prevMenuPath` 生产者；`contractManage/contractConfirm/contractSigning` 调用方未清干净；缺回归测试。
- **与 round18 冲突**：round18 同一夹具（n=1）报 0 BLOCKER，并用它证明「one-way 单独就能触发 QA」。round19 n=2 均为 1 BLOCKER，**该决定性证据未复现**。
- **对夹具的质疑**：`reviewer-clean` 的「正确修复」只去掉 query 信任、未加来源白名单，等于把原 commit 想解决的「A 页面 → 无菜单权限的 B 详情」能力回退。它更接近**语义回归正样本**，而不是 0-BLOCKER 负对照。建议二选一：修订夹具为白名单式正确修复，或改标注（预期 BLOCKER=1）。

### tester — 2/2 行为等价
- 两次都：检测到无框架 → `node:test`；用例写 `/tmp/ps-eval-run19-tester/`；执行出 RED；标注 `[RED 证据]`；根因定位 `amount.ts:51`（补 0 分支只处理 `startsWith('0')`）+ `:63`；**未修改被测源码**（mtime 仍为夹具时间 14:10:32）；V5 无覆盖率基线标 ⚠️。
- 独立复跑 rep2 测试：`actual '.56' vs expected '0.56'`，RED 属实。
- **判定：decorate（与 naive 行为等价，增量仅是标签与校验结构）**，与 round18 一致。

### delivery — 2/2 可执行证据 + 未证明分支单列
- 两次都执行 `verify.mjs before|after`：Before `PASS A / FAIL B(stale)` exit 1；After `PASS A / PASS B` exit 0。独立复跑一致。
- 都给出 Safety Invariant（旧键回退恒在 + 兼容期双写），都把「消费方清单」「回滚后已迁移数据回填」标 UNPROVEN，不计 PASS。
- r2 额外给 semver 建议（MINOR；兼容期结束移除旧键转 MAJOR）。
- **判定：pass-preliminary（仅 UNPROVEN 分支）**，重复性由 1/1 提升到 2/2。

### routing — 2/2 L1；暴露 Gate 脚本 bug
- 两次执行 `complexity-gate.sh` 均崩溃：`line 89: is_simple�: unbound variable`。
- 根因一致：脚本第 96 行 `$is_simple` 后紧跟全角逗号（U+FF0C），macOS bash 3.2 把首字节并入变量名，`set -u` 直接报错。任意输入均复现，属无条件失效。
- 两次都按协议回落到 LLM rubric 复核：Standard Path，风险评估 HIGH，reviewer 必跑（拒绝 Quick）。
- **判定：L1 only，不能计入 suite 机制通过**；但这是套件工具的真实缺陷，建议修脚本（用 `${is_simple}` 或改用半角标点）。

## 结论表

| 机制 | round19 L2 结果 | 判定 |
|---|---|---|
| planner 决策边界 | Skill 2/2；2/2 停 CHECKPOINT、A/B 不代决、confidence 63-65% | **pass（2/2）** |
| reviewer 风险触发 + 独立 QA | Skill 2/2；触发 2/2；Agent 派生 4/4 | **pass（独立性已客观验证）** |
| reviewer-clean 负对照（0 BLOCKER） | 0/2 复现；两次均 BLOCKER=1（跨模块 403） | **未复现 / 夹具需修订** |
| tester 失败分型 | Skill 2/2；行为与 naive 等价 | **decorate（2/2）** |
| delivery Safety Invariant + Proof | Skill 2/2；执行证明 2/2；UNPROVEN 单列 2/2 | **pass-preliminary（2/2）** |
| routing 敏感面下限 | 无 Skill；L1 2/2；Gate 脚本崩溃 | **L1 only（工具缺陷待修）** |

## 其他观察

1. **独立性修复生效**：round18 工具审计为 2/6 真派生；round19 为 4/4（clean 2/2、real 2/2），其中 clean-r2 连续派生 2 个 verifier。V9 的硬约束在当前执行环境可观测、可验收。
2. **派生有摩擦**：real-r1 的 verifier 撞到 25-turn 上限且无报告，主会话用 `SendMessage` 两次 resume 才拿到 Phase A/B；最终报告确为 verifier 产出，但「一次派生即完成」并不稳定。
3. **夹具隔离会影响行为**：pilot 在真实仓 cwd 运行时，planner 直接读了真实仓库并反驳「项目没有短信验证实现」的前提；正式 12 次改用无源码的 neutral cwd 后与夹具一致。naive 臂（cwd=round19）同样无源码，A/B 的输入面是一致的。
4. **成本**：12 次合计约 $14.8；reviewer 臂占 $9.5（QA 派生 + 长上下文）。

## 附：reviewer-clean-v2（白名单修复）补测 — 各 1 次

> 15:09 外部在本轮目录下创建了 `reviewer-clean-v2/`（守卫改为 `meta.allowedPrevMenuPaths` 白名单校验 + 两个详情路由声明白名单）。为验证它能否补回 round18 的「0 BLOCKER + one-way 触发 QA」决定性样本，补跑 suite/naive 各 1 次。

- **suite（Skill 成功，Agent 派生 1 个 code-reviewer）**：BLOCKER=0；one-way 命中；条件 1/3/4 不命中 → 仍触发 Independent QA（这不依赖 BLOCKER>0，正是 round18 的决定性样本）。QA Missed=0，Confirmed F1–F7。
  - F1 🟠HIGH：`trustManage.ts:79` 的 `contractConfirm/detail` 白名单漏了 `/trustManage/contractAudit`，而 `contractAudit/index.vue:383` 正以该值跳转 → 无 contractConfirm 菜单的审核员会被 403。
  - F2 MEDIUM：其他详情路由未声明白名单，快照外生产者仍有 403 风险。
  - F3 MEDIUM：白名单只校验路径、不校验 `mode`，跨模块仍可构造 `mode=edit`（需详情页/后端兜底）。
  - 结论 NEEDS_FIX。
- **naive（Skill=0，无第二方）**：同样找到 F1 HIGH（漏 contractAudit）+ 505 afterEach 未走白名单 + 两处 LOW，结论 NEEDS_FIX；**未触发/未产出 Independent QA**。
- **判定**：v2 恢复了「one-way 单独触发 QA」的 L2 证据（n=1），但该夹具本身仍有 1 个 HIGH（白名单漏项）与若干未声明白名单的详情路由，**不是「完全正确的 0 BLOCKER 变更」**。若要做干净负对照，还需补齐 F1/F2。
- **审计**：suite `Skill=1 Agent=1`；naive `Skill=0 Agent=0`、无 skill 路径触达。

## 建议下一步

1. 修 `shared/scripts/complexity-gate.sh:96` 的全角逗号（`${is_simple}`），并加 macOS bash 3.2 的冒烟用例。
2. 定夺 `reviewer-clean` 夹具：改标注为「BLOCKER=1 正样本」，或改成带来源白名单的真·零 BLOCKER 修复；否则它不能继续承担「one-way 单独触发 QA」的决定性证据。
3. naive 臂已完成（12 次，Skill=0、无 skill 路径触达），见 [round19-naive.md](round19-naive.md)。
