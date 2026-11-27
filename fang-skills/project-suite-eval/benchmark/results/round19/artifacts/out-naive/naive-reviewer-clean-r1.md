审查根目录：/Users/fangxiangming/.cache/ps-eval/round19/reviewer-clean/project（下列 file:line 相对该根）

1. HIGH src/router/permission.ts:283、325 —— prevMenuPath 只认 meta 后，跨菜单详情跳转的判权由“来源菜单”改为“目标路由归属菜单”：contractAudit 跳 contractConfirm/detail、entryDeclaration/detail 时，仅有合同审核菜单权限的用户将被 403。需按菜单授权矩阵验证；若跨菜单只读查看是业务需求，应为每个入口配置独立 detail 路由/meta，或交由后端判权，并补回归用例。
2. MEDIUM src/router/permission.ts:505 —— afterEach 仍读 `_to.query.prevMenuPath`，与“URL query 不参与”矛盾；workspace/views/trustManage/contractManage/index.vue:159,167、contractConfirm/index.vue:183、contractSigning/index.vue:143,151 仍在传该参数，清理不彻底（虽仅影响左侧菜单折叠，旧参数仍生效）。建议一并删除并只读 meta。
3. MEDIUM src/router/permission.ts:325-331 —— 详情页 menuid 修正从来源菜单改为目标 meta 菜单，跨菜单进入时页签分组及后端按 menuid 的数据范围/日志可能变化；直接打开详情页时则由 -1 变为父菜单 id（属改善），需联调确认。
4. LOW src/router/permission.ts:331 —— 内层 `const matchedMenu` 遮蔽外层，详情页 navigationLogParams 永不赋值（旧问题，本次语义变化后更明显）。
5. LOW 无单测：建议覆盖“伪造 ?prevMenuPath 不再提权”及跨菜单跳转场景。

结论：NEEDS_FIX

污染自检：未读取 SKILL.md/project-suite（是）
