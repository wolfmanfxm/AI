<!-- arm=reviewer-real-r2 session=db280b31-fa64-4b2a-8847-5bb06838c1c4 turns=1 subagents=1 -->
Skill 调用: 成功（project-reviewer）

**QA 触发条件（V9）逐条判定**
| 条件 | 判定 |
|---|---|
| Risk=HIGH / confidence<70 | 无 PLAN.md、无 state.json，不可判定 → 不命中 |
| one-way（权限边界） | **命中**（路由守卫授权判定） |
| BLOCKER>0 | **命中** |
| 变更文件>10 | 不命中（6） |

**是否用 Agent/Task 派生：是**（独立 general-purpose agent，Phase A 盲扫 → Phase B 对照，同一 fresh context；未读草稿在前）

## Independent QA
- **Missed**：M1 绕过覆盖所有已注册路由（含一级页），静态 `fakeMenuList/insidePage` 成万能凭证；M2 目标页 `readonly` 仅由 `mode` 决定，可直入编辑/提交；M3 query 随页签/URL 持久化，可分享复用；M4 面包屑读 meta、页签读 query，双口径。
- **Confirmed**：F-001。**Rejected**：F-004（`from` 供返回、`prevMenuPath` 供守卫，语义不同，复用会扩大污染面）、F-005（必要性偏好，删除反破坏口径一致）。

## 问题清单
- 🔴 **F-001** `permission.ts:283`：`to.query.prevMenuPath` 优先于 meta 充当授权主体 → 前端路由鉴权绕过；配合 `mode=edit` 可越权写。修复：显式白名单（目标路由→允许调用方）+ 已注册/`typeof string` 校验 + 后端按 `applicationId` 数据级鉴权。
- 🟠 **F-003** `trustManage.ts:81`（删）：旧路由 `contractConfirm/entryDeclaration` 无 redirect → 收藏/待办深链 404（仓内 grep 0 命中，服务端配置未验证）。
- 🟡 **F-006** `permission.ts:331`：用户可控值推导 menuid，菜单高亮错；面包屑 `Breadcrumb:44` 冲突。
- 🟢 **F-002** `permission.ts:283/325`：`as string` 掩盖数组参数（fail-closed，无绕过）。
- 🟢 **F-007** `contractConfirm/index.vue:188`：同文件传参口径不一致。
- 🔵 **PRAISE** `trustManage.ts:16-19`：跳转统一到已注册规范路径，消除重复详情路由。

**AC**：无 PLAN.md → 推断 3 条，②「无权限可进」应改 ⚠️（以 F-001 修复为前提）。**V1 补**：架构 PASS（见 PRAISE）、性能 PASS（无新增请求/渲染）。**V2/V6/V7/V8**：引用有效；修复可操作；V7 因无 glossary 不裁定 drift；无 Plan target，不入 V8。

**结论：NEEDS_FIX** —— F-001 BLOCKER 阻断合并。全程只读，未写 `REVIEW.md`（评测约束）。
