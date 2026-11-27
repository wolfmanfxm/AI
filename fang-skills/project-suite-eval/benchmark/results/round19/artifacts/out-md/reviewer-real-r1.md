<!-- arm=reviewer-real-r1 session=0888a58b-68b3-40c5-bc2b-fea0250d2f3d turns=31 subagents=1 -->
Skill 调用: 成功（project-reviewer）

前置：无 PLAN.md 与 AC → ⚠️ 无验收标准（DEGRADED）；变更 6 文件。

QA 触发逐条判定：
- Risk=HIGH / confidence<70：⚠️ 无来源，不计
- one-way 权限/认证边界：✅ 命中（改路由 ACL）
- BLOCKER>0：✅（F-01）
- 变更文件>10：❌（6）
→ 触发独立 QA

**是否用 Agent/Task 派生：是**（Agent 工具，verifier a9d07df2；Phase A 盲扫先于 Phase B 对照，独立上下文，未读草稿）

## Independent QA
Missed：无新增 BLOCKER；补强 F-01 —— `fakeMenuList`(/workbench)/`insidePage` 恒放行，无需任何菜单即可越权，且可挂任意已注册路由。
Confirmed：F-01/02/04/05/07/08、PRAISE；F-03 降 MEDIUM，F-06 降 LOW。
Rejected：F-02 的「审计日志 objid 伪造」子句（无 file:line 支撑，已删）。

问题清单：
- 🔴F-01 `src/router/permission.ts:283-284`：ACL 采信 URL 可控的 `query.prevMenuPath`，`judgePathIfAuthed` 只校验字符串是否命中菜单，而 fakeMenuList 含 `/workbench` → 任意登录用户加 `?prevMenuPath=/workbench` 绕过全站 403。修复：query 不得直连 ACL，限详情路由 + 来源白名单校验。
- 🟠F-02 `permission.ts:325-332`：query 值写回 `menuid`，`useCompAuth.ts:15`/`usePermission.ts:56` 据此取按钮权限 → 跨菜单替换 ctrlPurview。修复：menuid 仅由 `to.path`/meta 推导。
- 🟡F-03 `trustManage.ts:78-86`：删旧路由无兼容重定向（代码 0 引用，外部书签/菜单配置[不确定]）。
- 🟡F-04 `permission.ts:283/325`：query 可为 string[]，`as string` 致误 403 / menuid=-1。
- 🟡F-05 `BusinessBoard.vue:383,390`、`DealerTodoTabs.vue:256,263`、`trustWorkflow.ts:79` 未带 prevMenuPath，同场景仍 403（修复不完整）。
- 🟢F-06 `permission.ts:505` 菜单收起条件扩至全站 query[低置信]；F-07 权限守卫零测试；F-08 meta/query 语义并存无注释。
- 🔵PRAISE：删除重复路由 `contractConfirmDetail2`，统一到父提交已存在的目标路由。
- 五轴：正确性 ✅ / 安全 ❌(F-01/02) / 架构 PASS / 可读性 PASS / 性能 PASS。

结论：**NEEDS_FIX**，F-01 阻断合并。
