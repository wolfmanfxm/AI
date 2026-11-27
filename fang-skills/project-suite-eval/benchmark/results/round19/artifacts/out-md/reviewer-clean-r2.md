<!-- arm=reviewer-clean-r2 session=d48ab509-2ec4-4168-8daa-36d424a72b83 turns=16 subagents=2 -->
Skill 调用: 成功（project-reviewer）

前置: **DEGRADED**（无 PLAN.md / .project-knowledge / AC）

### QA 触发条件逐条判定
1. Risk=HIGH 或上游 confidence<70: ⚠️ 无来源，不计命中
2. one-way（权限/认证边界）: ✅ **命中**
3. BLOCKER>0: ✅ **命中（BLOCKER=1）**
4. 变更文件>10: ❌ 不命中（2）
→ 独立 QA 必须执行。

**是否用 Agent/Task 派生: 是**（两个独立 verifier：Phase A 盲扫 → Phase B 对照，均不共享主审查上下文；`judgePathIfAuthed` 语义另经上游 `src/utils/url.ts:142-151` 只读核实）

## Independent QA
- **Missed**: ①鉴权全局生效，上游跨模块 `prevMenuPath` 生产者约百处同样 403；②删 contractAudit 的 query 参数非安全必需，且改变面包屑归属（`Breadcrumb:72` query 优先）；③缺回滚说明。
- **Confirmed**: F-001（403 可复现）、PRAISE、F-005/006/007。
- **Rejected**: F-002「死参数」不成立（`:505`、`Breadcrumb:72`、detail 页 goBack、`useDownloadFileName` 仍消费）→ 降 MEDIUM；F-004 降 LOW。
- Missed 无全新类别 BLOCKER，但 F-001 修复须覆盖全部生产者。

### 问题清单
- 🔴 **F-001** `permission.ts:283`(+294-302): 跨模块详情鉴权改由 meta 指向**目标父菜单**；仅持源菜单权限者被判 403（如合同审核点进件编号 → `entryDeclaration/detail`）。修复: meta 增来源允许列表，query 命中白名单才采信。
- 🟠 **F-006** 权限闸零回归测试（仓库有 vitest），全局行为变更无覆盖。
- 🟡 **F-002** 清理不彻底: `contractManage:159/167`、`contractConfirm:183`、`contractSigning:143/151` 仍传 `prevMenuPath`；非死参但已不参与鉴权，须并入允许列表方案。
- 🟡 **F-003** `permission.ts:325-332`: menuid 归属由源菜单改目标父菜单，缺失为 `'-1'`，页签/高亮/日志漂移。
- 🟢 **F-004** `:505` afterEach 仍读 query（仅侧栏 UI）；**F-005** `:283` 多余括号；**F-007** `324/331` 变量遮蔽致 `navigationLogParams` 恒 null（既有）。
- 🔵 **PRAISE**: 不再采信用户可控 query，确实关闭 `?prevMenuPath=` 越权，方向正确。

### 结论
**NEEDS_FIX（HOLD-FIX-FIRST），不建议合入。** 安全方向正确，但以跨模块 403 权限回归为代价且迁移不完整；须覆盖全部生产者 + 来源允许列表 + 回归测试。全程只读，未创建/修改/删除任何文件。
