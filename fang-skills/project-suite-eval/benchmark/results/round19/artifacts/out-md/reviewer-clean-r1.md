<!-- arm=reviewer-clean-r1 session=aae5f22e-8e2e-4de2-8bec-4893bad4607b turns=24 subagents=1 -->
Skill 调用: 成功（project-reviewer）

配置: **DEGRADED**（无 `PLAN.md` / `.project-knowledge`，无 AC；depth=standard 五轴全审）。

### QA 触发条件逐条判定
1. Risk=HIGH 或上游 confidence<70: **不命中**（无 Risk Assessment / state.json，无法确认）
2. one-way（权限与认证边界）: **✅ 命中**
3. BLOCKER > 0: **✅ 命中（BLOCKER 数 = 1）**
4. 变更文件 > 10: **不命中**（2 文件）
→ 必须执行独立 QA。

**是否用 Agent/Task 派生: 是**（verifier 子代理 `a66fc67`，Phase A 盲扫 → Phase B 对照）。

## Independent QA
Phase A 未读草稿、独立报出 BLOCKER。Phase B: Confirmed 5 / Rejected 0 / Missed 2（HIGH 无测试矩阵、LOW 既有 menuid）。Missed 无未处理 BLOCKER。

### 问题清单
- 🔴 **F-001** `permission.ts:283` — 跨模块详情跳转鉴权由 query(来源菜单) 改为静态 `meta`(目标父菜单)。如「合同审核」→`entryDeclaration/detail`（`trustManage.ts:19`）仅持合同审核权限者将 403。修复：`allowedFrom` 多父路径白名单，任一命中放行。
- 🟠 **F-002** `contractManage:159,167` / `contractConfirm:183` / `contractSigning:143,151` — 调用方清理不彻底，仍传已失效的 `prevMenuPath`；一旦恢复 query 优先即复活越权。
- 🟠 **F-007**（QA Missed）— 全局鉴权行为变更无单测/跨模块边验证矩阵。
- 🟡 **F-003** `permission.ts:505` — `afterEach` 仍读 `query.prevMenuPath`，与新策略矛盾（侧边栏收起不一致）。
- 🟡 **F-004** `permission.ts:325-336/441-448` — menuid/菜单高亮/导航日志归属改挂目标父菜单；页签按 path+query 全等去重，删 query 后可能产生重复页签。
- 🟢 **F-005** `permission.ts:283` — 冗余双括号，注释与 505 实现冲突。
- 🟢 **F-008**（QA Missed，既有）—`to.query.menuid` 仍用户可控参与归属（非本次引入）。
- 🔵 **F-006 PRAISE** — 鉴权不再采信用户可控 query，确实关闭 `?prevMenuPath=` 越权，方向正确。

### 五轴 / AC
正确性 F-001/F-003/F-004；安全 F-001+F-006；可读性 F-005；架构 F-002/F-007；性能 PASS。AC 对照：**不可执行**（DEGRADED，无 AC）；Scope 无 PLAN 无法判定。

### 结论
**NEEDS_FIX（HOLD-FIX-FIRST），不建议合入。** 安全修复方向正确，但以权限回归换取安全且仅完成半迁移；须先改为多父路径白名单、清完全部调用方、补跨模块权限测试矩阵。全程只读，未改动任何文件。
