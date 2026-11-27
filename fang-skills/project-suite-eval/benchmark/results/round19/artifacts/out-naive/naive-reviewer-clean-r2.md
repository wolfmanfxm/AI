问题清单
- HIGH src/router/permission.ts:283：删除 query.prevMenuPath 回退后，detail 页只按静态 meta.prevMenuPath 鉴权；而 entryDeclaration/detail 等被 contractAudit、contractManage、contractSigning、contractConfirm 多入口复用，仅有来源菜单权限的用户会被误判 403。建议 meta 改用父路径白名单数组、校验任一授权项，或交由服务端鉴权，而非单值回退。
- HIGH src/router/permission.ts:325：该处 prevMenuPath 用于 menuid/页签归属而非鉴权，本次一并删除会把跨菜单打开的详情归到 detail 自带的父菜单（如 entryDeclaration），造成页签分组、菜单高亮、navigationLog 的 objid/objname 错误。建议保留来源归属，但先对 query 做白名单校验，或由 from 推导。
- MEDIUM 清理不彻底：contractManage/index.vue:159,167、contractSigning/index.vue:143,151、contractConfirm/index.vue:183 仍传 prevMenuPath，现已成死参数且与 contractAudit 不一致。
- LOW src/router/permission.ts:505：afterEach 仍读 _to.query.prevMenuPath 控制侧栏折叠，与“不采信 query”矛盾；建议仅用 meta。
- LOW 调用方保留的 from 参数在当前快照中无消费方，确认是否为死参数。

总体结论：NEEDS_FIX（去掉对 query 的鉴权信任方向正确，但需补齐多入口鉴权模型与归属逻辑）

污染自检：未读取 SKILL.md/project-suite（是）
