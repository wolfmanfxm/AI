问题清单

- **BLOCKER** `src/router/permission.ts:283`：鉴权判定直接取用户可篡改的 `to.query.prevMenuPath`，且对全部路由生效。任何人只需在地址后加 `?prevMenuPath=<自己已授权的路径>`，即可令 `judgePathIfAuthed` 通过，绕过 403 访问任意已注册页面（含一级菜单页），金融系统的前端权限门禁实际失效。修复：改为路由级白名单（如 `meta.allowedPrevMenuPaths`，只允许上述 4 个列表页），值必须命中白名单才采用，否则回退 `meta.prevMenuPath/realPath`；并强调后端接口鉴权兜底。
- **MEDIUM** `src/router/permission.ts:325-334`：menuid 同样由该 query 推导，目标详情页会拿到调用方菜单 id。若详情页按钮/数据权限按 menuid 取数，可能出现按钮越权或页签归属错误。建议与白名单同源校验，只读场景（mode=view）显式限制操作。
- **MEDIUM** `workspace/router/trustManage.ts:81`：直接删除 `/trustManage/contractConfirm/entryDeclaration` 路由，未保留 alias/redirect，历史收藏、消息通知、外部链接将 404。建议加 `redirect` 到新路径过渡。
- **LOW** `src/router/permission.ts:283,325`：`as string` 断言不安全，`?prevMenuPath=a&prevMenuPath=b` 会解析为数组，传入 `judgePathIfAuthed`/`getMenuByPathOrId` 可能异常；应先归一化取首个字符串并过滤非法值。
- **LOW** `src/router/permission.ts:505`：afterEach 仅凭 query 真值收缩侧边栏，可被 URL 直接触发，建议与白名单统一判断。
- **LOW** `workspace/views/trustManage/contractManage/index.vue:159` 等 4 页：`from` 与 `prevMenuPath` 重复硬编码同一路径，建议用 `route.path` 生成，避免路由变更后漂移。

总体结论：**BLOCKED**（存在 BLOCKER 级前端鉴权绕过，修复前不可合入）

污染自检：未读取 SKILL.md/project-suite（是）
