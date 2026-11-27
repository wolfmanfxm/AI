审查根目录：/Users/fangxiangming/.cache/ps-eval/round19/reviewer-real/project（以下 file:line 相对该目录）

问题清单
- BLOCKER src/router/permission.ts:283、325：鉴权改为优先信任 URL query `prevMenuPath`，且对全部非微前端路由生效。任何已登录用户构造 `/任意路由?prevMenuPath=/我有权限的菜单` 即可通过 `judgePathIfAuthed`，绕过菜单鉴权访问详情/列表（跨模块越权，如无合同审核菜单也可看合同审核详情）。修复：仅当目标路由 meta.prevMenuPath 存在时允许覆盖；query 值须与目标路由允许的父路径白名单比对（或路由表映射），不符则回退 meta 并走 403；使用后从 URL 移除。
- HIGH workspace/router/trustManage.ts:81-86（删除块）：删除旧路由 `/trustManage/contractConfirm/entryDeclaration` 未留 redirect。历史书签、外部通知链接、SessionStorage 中已打开的旧页签会命中未注册路由→404。建议保留 redirect 到新详情页，并全仓 grep 旧 path 与 name `contractConfirmDetail2`。
- MEDIUM src/router/permission.ts:283、325：`prevMenuPath` 长期留在 URL 与页签 query 中，可复制传播，且权限收回后链接仍可复用；建议计算后从 URL 剔除（参照 token 清理）。另需确认 detail.vue 是否把 route.query 透传给接口。
- MEDIUM 本次改动无任何权限分支单测/e2e：建议补 beforeEach 用例（正常访问、伪造 prevMenuPath、数组/空串）。
- LOW src/router/permission.ts:283、325：`as string` 掩盖数组与空串（`?prevMenuPath=a&prevMenuPath=b`），会把非字符串传入 judgePathIfAuthed/getMenuByPathOrId；应加 `typeof === 'string'` 校验。
- LOW contractAudit:371/383、contractConfirm:183、contractManage:159/167、contractSigning:143/151：prevMenuPath 字符串重复硬编码，易与路由漂移；建议抽常量/helper。contractConfirm:188 handleView 未传该参数，行为不一致，建议统一。

总体结论：NEEDS_FIX（BLOCKER 必须修复后方可合入）

污染自检：未读取 SKILL.md/project-suite（是）
