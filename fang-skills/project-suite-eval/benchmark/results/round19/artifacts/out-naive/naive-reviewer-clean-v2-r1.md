问题清单

[HIGH] workspace/router/trustManage.ts:79 — contractConfirm/detail 的 allowedPrevMenuPaths 漏了 `/trustManage/contractAudit`，但 workspace/views/trustManage/contractAudit/index.vue:378-384 明确以 `prevMenuPath:'/trustManage/contractAudit'` 跳转该详情页。白名单拒绝后 judgePath 回退到 meta.prevMenuPath=`/trustManage/contractConfirm`：无 contractConfirm 菜单权限的用户会被 403（现有功能中断）；两级权限都有的用户 menuid 与页签/导航日志会挂到 contractConfirm 下（归属错乱）。修复：白名单补该路径，并逐条对照所有 router.push 的 prevMenuPath 来源；建议加守卫单测。

[MEDIUM] src/router/permission.ts:515 — afterEach 仍无条件读 `_to.query.prevMenuPath` 决定收起侧边栏，未走白名单：伪造/非法参数仍会产生 UI 副作用，与新策略不一致。修复：复用白名单校验结果，或抽 `resolvePrevMenuPath(to)` 供 beforeEach/afterEach 共用。

[LOW] permission.ts:283-289 与 331-335 — 同一白名单解析逻辑重复，后续易漂移（本次漏项即同类风险）。建议抽公共 helper，仅保留一处。

[LOW] permission.ts:284 — 仅 `|| []`，未校验是否数组；meta 误配为字符串时 `.includes` 语义会退化为子串匹配。建议 `Array.isArray(...)`。

[INFO] 对未声明 allowedPrevMenuPaths 的既有详情路由，query 版 prevMenuPath 由“优先”变为被忽略；本 fixture 内未见依赖，但需全仓确认。

[INFO] 授权仍以“来源菜单”判定，任一白名单来源有权限即可查看详情数据，纵深防御需后端接口权限兜底。

总体结论：NEEDS_FIX（安全收紧方向正确，但白名单漏项造成确定性功能回归）。

污染自检：未读取 SKILL.md/project-suite（是）
