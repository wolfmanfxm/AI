# 提交前自检清单

逐条打勾。**这里的每一条对应的都是静默故障**——不检查的话，代码能跑、能编译、CI 能过，
但功能悄悄不对。

---

## 必查（错了会静默失效）

- [ ] `<dc-form-table>` 是最外层容器，里面才放 `<dc-card>`
- [ ] `dc-search-form` 和 `dc-ft-table` 的 **`idKey` 值完全相同**
- [ ] 表格 `ref="multipleTable"`
- [ ] 表格 `:key="reloadTable"`
- [ ] 数据字段名叫 **`searchFormData`**（不是 `searchData` / `formData` / `query`）
- [ ] `searchCacheOptions.pageKey` **全仓唯一**（grep 一下确认没重名）
- [ ] 分页传给后端时是 **`pageNum` / `pageSize`**，业务条件包在 **`param`** 里
- [ ] 分页事件用 **`@pageChange`**（不是 `handleSizeChange` / `handleCurrentChange`）
- [ ] 多选表的 `rowIdKey` 已改成**接口里真实存在的主键字段名**（不是 `'pyhid'`）
- [ ] 字典列是 `type="dict"` **且** `:inputParam="{ dictCode: 'xxx' }"` 两层都写了
      （写 `type="dictSelect"` 是错的 —— 那是表单项的值）
- [ ] **每个 `dcType` 的值都在「当前应用」的映射表里**（`components.md` 的 `dcType` 全表）。
      最常见错误：写成 `dcType="date"`（应为 `datePicker`）、`dcType="dict"`（应为 `dictSelect`）。
      写错 **不报错，字段直接变空白**
- [ ] 如果这段代码是**从别的应用复制的**：确认 `dcType` 没用到只在对方应用合法的值
      （`textDecimal` / `remoteSelect` 只有 `cop-fsc-ui` 有 → fsc 抄到 opr/ucp 会静默变空白）
- [ ] `verifyRule` 放进了 `data()`
- [ ] 用到的每个 `verifyRule.xxx` 规则名**在当前应用的 `validate.js` 里存在**
      （fsc 是 opr 的子集，缺 `positiveNumber` / `version` 等）
- [ ] `updated()` 里调了 `dealHeight('multipleTable')`
- [ ] 表单 `ref` 没和查询表单的 `ref` 重名（仓库惯例是 `fromRule` / `fromRule2`）
- [ ] **表单上没有绑 `@submit`**（不存在这个事件）。保存按钮是自己渲染的，
      校验是自己用 `this.$refs.xxx.validate()` 调的，`:clickButtonFlag="false"` 关掉了自带按钮行

## 复用检查

- [ ] 列表/表单**用的是 `Dc*` 组件**，没有裸写 `el-form` / `el-table` / `el-dialog`
- [ ] 操作列内的按钮用**原生 `el-button type="text"`**（这是仓库惯例的例外）
- [ ] 接口调用走 `@/axios` 导出的 `requestGet` / `requestPost` 等，
      **没有直接 `axios.get`**
- [ ] 接口 URL 常量写在了 `service.js` 里，没有散在组件内
- [ ] 表单校验优先复用了 `@/validator/validate.js` 的既有规则，没有自己编正则
- [ ] 列表页 `mixins` 引了 `tableMixins`（+ `searchCacheMixin`），没有自己重写分页/勾选逻辑
- [ ] **没有修改任何既有 `Dc*` 组件的源码**
- [ ] **没有新增 `src/` 顶级目录**

## 跨应用检查（子应用代码）

- [ ] 消费 `window.commonComponent` 时写了判空：
      `const { OperationRecord } = window.commonComponent || {}`
- [ ] 没有把基座的组件文件**拷贝**到子应用里
- [ ] 如果用了 `requestAuthPost`，确认当前应用是 opr 或 fsc（**基座没有这个函数**）
- [ ] 如果做了文件下载，知道 ucp/opr **没有** blob 错误解包
- [ ] 如果读了 `userInfo`，用的是当前应用的字段结构（ucp 是 `.userinfo`，opr/fsc 是平铺）

## 路由检查

- [ ] `.vue` 文件的路径与后端菜单 `menuUrl` **逐字一致**
- [ ] 域内 `*-router.js` 加了静态条目（`path` 不带前导 `/`，`name` 用中文且不重名）
- [ ] 新业务域已加进 `views/view-router.js`
- [ ] 跨应用跳转的重定向路由加在了基座 `router/index.js`（不是在业务域 router 里）
- [ ] 已确认**后端菜单**会配这个页面（否则没有入口）

## 兜底

- [ ] `npm run lint` 通过
- [ ] 在浏览器里实际点过：查询、重置、翻页、新增、编辑、查看、删除/启停
- [ ] 打开 Network 面板确认接口 **返回码在白名单里**（不然会踩 P1：Promise 永不 settle）
- [ ] 编辑后取消，确认列表数据**没有被串改**（`Object.assign` 就地修改的坑）

---

## 一条经验

**如果你写的代码和旁边 10 个既有页面长得不一样，多半是你错了。**

这个仓库的写法高度统一，几乎每个需求都能找到一个 90% 相似的既有页面。
先 `grep` 找到它，再逐字对齐——比凭经验"写得好"重要得多。
