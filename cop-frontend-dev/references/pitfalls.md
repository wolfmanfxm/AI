# 踩坑清单

**这里的坑全部是静默的**：不报错、不抛异常，只是「没反应」「数据不对」「显示成数字」。
每条都给出源码位置，可自行核对。

---

## P1 🔴 请求失败时 Promise 永远不 settle，`loading` 永久卡 true

**症状**：点查询后转圈不停；之后再点任何查询都没反应。

**原因**：`requestPost` / `requestGet` 在响应 code 不在白名单时，
**只弹一个全局 toast，既不 `resolve` 也不 `reject`**。

```js
// cop-opr-ui/src/axios/index.js:180-186
} else if (['E999999', 'EOPR04Z1008', 'EOPR05Z1067', 'EOPR05Z1068'].includes(result.data.code)) {
  resolve(result.data)
} else {
  // resolve(result.data)      ← 被注释掉了
  hideLoading()
  authError(result.data.msg || '服务异常！！！')
}                              ← 没有 resolve，也没有 reject
```

**连锁反应**（最常见的报障：「前端点了没反应」）：

```
Promise 永不 settle
  → .then 不执行      → this.tableData 不更新
  → .finally 不执行   → this.loading 保持 true
  → 下次查询被 if (this.loading) return 挡掉    ← cop-opr-ui/.../contractTemplateConfigList.vue:115
    → 页面永久卡住
```

**应对**：
- 页面里 `.then` 内的 `else { this.$message.error(res.msg) }` **几乎永远走不到**，别指望它兜底。
- 错误提示走的是全局 `authError`（1 秒防抖），**不要在页面里重复弹**。
- 调试接口问题时，先看 Network 面板的响应体，不要只看页面。

> 附带：三个应用的成功码白名单**各不相同**（`requestGet` 与 `requestPost` 也不一样），
> 且判断逻辑**不在 `interceptors.js` 里，而在每个 `requestXxx` 函数体内**。
> 排查「这个接口为什么没进 then」要去读对应应用的 `src/axios/index.js`。

---

## P2 🔴 `idKey` 两边不同名 → 查询按钮静默失效

```js
// cop-opr-ui/src/plugin/form/ft-form.vue:109-135（queryForm 内）
element.idKey === _idKey && element.$options._componentTag === 'dc-ft-table'
```

`DcSearchForm` 点了「查询」后，是在 `dcFormTable.$children` 里**递归反查**表格实例，
按 `idKey` 匹配。匹配不到 → 只 `console.log('queryForm')`，**不报错、不提示**。

**必须两边写同一个值**（仓库惯例都是 `multipleTable`）：

```vue
<dc-search-form idKey="multipleTable" ...>
<dc-ft-table     idKey="multipleTable" ...>
```

---

## P3 🔴 `ref` / `:key` / `rowIdKey` 三个名字写错，各有各的静默故障

| 名字 | 必须写成 | 写错的后果 |
|------|---------|-----------|
| 表格 `ref` | `ref="multipleTable"` | `tableMixins` 读不到 → 列设置为空、跨页勾选报错、表格高度塌陷 |
| 表格 `:key` | `:key="reloadTable"` | 列显示/隐藏设置**不生效**（不重建表格） |
| `rowIdKey` | **你接口里真实存在的主键字段名** | 多选跨页比对退化成 `undefined === undefined` → **勾选错乱** |

`rowIdKey` 的默认值 `'pyhid'` 是**从别的项目带过来的模板遗留值**。
仓库里多处直接写着 `rowIdKey: 'pyhid'`，但那些页面的行数据里并没有这个字段。
**新增多选表时务必改掉。**

依据：`cop-opr-ui/src/mixins/tableMixins.js:139-142, 50-55, 199-273`

---

## P4 🔴 分页字段名会变形

组件内部用的是 `paginationParam.currentPage` / `.pageSize`，
**发给后端时必须改名**，业务条件另外包一层：

```js
const params = {
  pageSize: paginationParam.pageSize,
  pageNum: paginationParam.currentPage,     // ← currentPage 改名成 pageNum
  param: { ...this.searchFormData }         // ← 业务条件包进 param
}
```

另外：**页面里没有 `handleSizeChange` / `handleCurrentChange`**（全仓 grep 零命中）。
`dc-ft-table` 内部吞掉了 Element 的两个分页事件，统一只对外暴露一个：

```vue
@pageChange="pageChange"     <!-- 参数是对象 { currentPage, pageSize } -->
```

`pageChange` 由 `tableMixins` 提供，**页面不用自己写**。

---

## P5 🟡 字典列少写一层 → 要么显示原始码值，要么整格空白

```vue
<!-- ✅ 对：type + inputParam 两层都要 -->
<dc-base-table-column prop="staSteCode" label="状态" type="dict"
  :inputParam="{ dictCode: 'COP0002' }" />

<!-- ❌ 错：少了 type，或 dictCode 写成平铺 prop -->
<dc-base-table-column prop="staSteCode" label="状态" dictCode="COP0002" />
```

依据：`cop-opr-ui/src/plugin/table-column/dc-base-table-column.vue:12-16`
（`v-if="type === 'dict'"` 且 `v-if="inputParam.dictCode"` **两个条件同时满足**才翻译）。

**三种错法，三种症状**：

| 写错的方式 | 落到哪 | 症状 |
|-----------|-------|------|
| `type="dict"` 漏了（或写成 `dictSelect`） | 默认分支 `v-else` | **显示原始码值** `0` / `1` / `2` |
| `type="dict"` 有，但 `inputParam` 里没有 `dictCode` | dict 分支，`template` 的 `v-if` 不成立 | **整格空白** |
| `type="dict"` 有，但 `inputParam` 整个没传 | dict 分支，`inputParam` 是 `undefined` | **渲染时抛 TypeError** |

> 第三种是**实测确认**的（Vue 2.7 下跑过）：`inputParam` 的默认值写成了
> `default: () => {}` —— 箭头函数体是空块，**返回 `undefined` 而不是空对象**
> （正确写法应是 `() => ({})`）。所以不传时 `inputParam === undefined`，
> 模板里 `inputParam.dictCode` 直接抛
> `TypeError: Cannot read properties of undefined`。
> 全仓 230 处 `type="dict"`（ucp 38 / opr 109 / fsc 83）都传了 `inputParam`，这个坑目前没人踩到。

> ⚠️ 特别注意 **`type="dictSelect"` 是错的**。示例页
> `show-case/table-up/index.vue:52,73` 自己就写错了，照抄示例会导致不翻译。
> `dictSelect` 是 `dc-form-item` 的 `dcType` 值，**表格列要用 `dict`**。

表单/查询项则是另一种写法——`dictCode` 直接作为属性：
`<dc-form-item dcType="dictSelect" dictCode="COP0109" />`。**两个地方写法不一样，别混。**

---

## P6 🟡 表单校验不生效：`verifyRule` 没放进 `data`

```js
import { verifyRule } from '@/validator/validate.js'

export default {
  data () {
    return {
      verifyRule,        // ← 不放这里，模板里的 verifyRule.xxx 就是 undefined
      // ...
    }
  }
}
```

`verifyRule` 是 `@/validator/validate.js` 导出的一个约 60 条规则的对象
（`AZazNum`、`mobile`、`IDNo`、`email`、`uscc`、`version`、`pDecimal`、`cnapsCode` …）。
**用之前先 grep 有没有现成的，不要自己编正则。**

⚠️ **`cop-fsc-ui` 的 `validate.js` 是 `cop-opr-ui` 的子集**：
缺 `positiveNumber`、`positiveNumberOrZero`、`version`，多 `posInter`、`noAnySpace`。
从 opr 抄代码到 fsc 时，引用了 fsc 没有的规则名 → **校验静默失效**。

---

## P7 🟡 搜索条件缓存串页：`pageKey` 必须唯一、数据字段必须叫 `searchFormData`

```js
searchCacheOptions: {
  pageKey: 'contractTemplateConfigList'   // 每个列表页唯一，全仓不能重名
},
data () {
  return {
    searchFormData: { ... }               // 字段名必须是这个
  }
}
```

- 两个列表页用同一个 `pageKey` → **搜索条件互相串**。
- 数据字段改名 → 缓存恢复失效（`searchCacheMixin` 默认 `searchKey: 'searchFormData'`）。

---

## P8 🟡 子应用独立运行时 `window.commonComponent` 是 `undefined`

基座在 `cop-ucp-ui/src/main.js:12-16` 写入：

```js
window.commonComponent = { FileDirectory, OperationRecord, signInfoDialog }
```

**这个对象只在基座设置。** 子应用如果脱离基座单独跑（`npm run dev` 直连 opr/fsc），它就是 `undefined`。

现有代码里消费点判空**不一致**——`OperationRecord` 的 6 个消费点**没判空**，
`signInfoDialog` 的 3 个消费点写了 `|| {}`。**新写代码一律用防御式**：

```js
const { OperationRecord, signInfoDialog } = window.commonComponent || {}
```

**注意 `pdfViewDialog` 不在这个对象里**（只有 3 个成员），
要用 PDF 预览得自己处理——目前三个应用各写了一套。

---

## P9 🟡 新增页面要改四处，少一处就 404 或没入口

| # | 改哪 | 漏了会怎样 |
|---|------|-----------|
| ① | 建 `.vue` 文件，**路径必须等于后端 `menuUrl`** | webpack 报模块找不到 |
| ② | 域内 `*-router.js` 加静态条目 | 本地直连访问不到 |
| ③ | `views/view-router.js` 聚合（**新业务域才需要**） | 同上 |
| ④ | 后端配菜单，`menuUrl` 填成**文件路径** | 没配 → 侧边栏没入口；**形状填错 → webpack 报模块找不到、页面直接打不开** |

`formatRoutes` 是用 `` import(`@/views${menuUrl}.vue`) `` 动态导入的
（`cop-ucp-ui/src/utils/router.js:94`）——**文件路径和菜单里的 `menuUrl` 必须逐字一致。**
`menuUrl` 同时是**浏览器 URL**（`router.js` 里 `path: menuUrl`，
且 `tableMixins.js:108` 拿 `window.location.pathname` 去比对菜单项）。

生成的页面文件是 `src/views/<域>/<模块>/index.vue`，所以 `menuUrl` 是
`/<域>/<模块>/index`——**末尾的 `/index` 不能省**，省了就解析成
`src/views/<域>/<模块>.vue`（不存在）。

### ⚠️ `menuUrl` 里**不要**带 `/view`（这一条容易搞混）

你在 URL 里、在基座 `router/index.js` 里会看到 `/view` 这一段，例如基座硬编码的
`/cop-opr/view/shipping-manage/pickupAudit`（`cop-ucp-ui/src/router/index.js:57`）。
**那是基座自己路由表里的前缀，不是 `menuUrl` 字段的内容。**
`menuUrl` 是从 `src/views/` 算起、去掉 `.vue` 的路径，**不含 `/view`**——
因为三个应用**都没有** `src/views/view/` 这个目录（已核验：git 历史里也从未有过）。

> 🔴 **证据冲突，必须跟后端当面确认**：仓库里唯一的菜单样例
> `cop-ucp-ui/src/mocks/api/oms/uaa/menu/userNav.json` 把 `menuUrl` 写成了
> `/view/show-case/table-up`——**既多了 `/view`、又少了 `/index`**，
> 而真实文件是 `src/views/show-case/table-up/index.vue`（已核验存在）。
> 也就是说**这份 mock 与当前代码对不上，不可当格式依据**。
> 交付时把本条原文转给后端菜单负责人，让他确认线上 `menuUrl` 的真实形态，
> **不要照着 mock 猜**。

跨应用跳转的重定向路由是**基座 `router/index.js` 里手工硬编码的**，要加在那里。

---

## P10 🟡 别照抄注释掉的代码

这个仓库有大量「注释掉但看起来是活的」代码。**看到 `//` 先确认它到底生不生效。**

已确认是**死的**：

| 位置 | 内容 | 后果 |
|------|------|------|
| `cop-ucp-ui/src/utils/micro.js:77` | 基座的 `store.replaceState` 白屏回填（整段 6 行注释） | 基座自身没有白屏防护，**子应用是活的** |
| `cop-fsc-ui/src/axios/index.js:24` | `timeout: window.$VelaConfig.timeout \|\| 3000` | **fsc 的请求没有超时**，慢接口会永久挂起 |
| `cop-opr-ui/src/utils/micro.js:224-225` | `if (IS_MOCK) { require('@/mocks/mock.js') }`——**两行都是活的**，且 `entry-configuration.js:22` 写的是 `IS_MOCK: true` | **opr 真的会加载 mock 数据**。调试 opr 时看到假数据、接口没真发出去，就是这里 |
| `cop-ucp-ui/src/utils/micro.js:233-235` | `if (IS_MOCK)` 是活的、`require` 那行被注释；`IS_MOCK: false` | ucp 不会加载 mock |
| `cop-fsc-ui/src/utils/micro.js:227-229` | 整个 `if (IS_MOCK)` 块 | **把 fsc 的 `IS_MOCK` 改成 `true` 也不会加载 mock**——守卫本身没了 |
| `cop-opr-ui/src/axios/interceptors.js:129` | OCR 报错提示 `showErrorMsg(error, '请上传合规的营业执照')` | 用户上传不合规营业执照时**没有任何提示**，以为上传成功了 |
| `cop-fsc-ui/src/App.vue:16` | **调用** `// this.getDictCode(dictCode)` 被注释（方法定义在 `:40` 是活的，但没人调它） | fsc 自己不拉字典，只吃 `sessionStorage` 里的既有数据 |
| `cop-opr-ui/src/router/index.js:77-100` | 整个 `beforeEach` | 守卫改由 `utils/micro.js` 的 `loadGuards` 统一挂载 |

> 同一个 `IS_MOCK` 开关，三个应用**三种形态**，而且**结果各不相同**：
> **opr 会真加载 mock**（开关是 true、require 是活的），
> ucp 不会（开关 false、require 被注释），fsc 也不会（整块被注释）。
> 不要假设「改配置就能生效」，也不要假设「三个应用行为一致」。

---

## P11 🟡 `Object.assign` 回填表单会串数据

```js
Object.assign(this.formData, this.formParam)   // 既有写法
```

这是**就地修改**。如果 `formParam` 直接传的是列表行对象，表单里一改，
列表数据也跟着变了（编辑后取消，列表显示的还是改过的值）。

**安全写法**：

```js
Object.assign(this.formData, JSON.parse(JSON.stringify(this.formParam)))
// 或
this.formData = { ...this.formParam }
```

---

## P12 🟡 `userInfo` 结构三应用不一致

```js
JSON.parse(sessionStorage.getItem('userInfo')).userinfo    // ucp：小写嵌套
JSON.parse(sessionStorage.getItem('userInfo')).userNm      // opr / fsc：平铺
```

跨应用抄用户信息相关代码时不要照搬。

---

## P13 🟡 `src/utils/storeage.js` 的拼写与读写不对称（**三应用不一致**）

- 拼写就是 **`storeage`**（不是 `storage`），别"好心"改正——全仓都这么引用。
- `setItem(key, val)` **三个应用都是同时写 session 和 local**。
- `getItem(key)` **读法三应用不同**（`src/utils/storeage.js:57`）：

| 应用 | `getItem` 实现 | 效果 |
|------|---------------|------|
| `cop-ucp-ui` | `return sessionStorage.getItem(key)`（`\|\| localStorage.getItem(key)` 那半**被注释掉了**） | **只读 session** |
| `cop-opr-ui` | `return sessionStorage.getItem(key) \|\| localStorage.getItem(key)` | session 没有就**回落到 local** |
| `cop-fsc-ui` | 同 opr | 同 opr |

**含义**：写进去的数据刷新页面还在（local）。
**ucp** 读的时候只看 session，所以「清了 local 但没清 session」时会出现"看起来清掉了其实还在"；
**opr / fsc** 会回落到 local，**不存在这个现象**——把 ucp 的行为当全仓规律会在另两个应用上判断反。

**写跨应用复用的代码时，按 opr/fsc 的读法（带回落）来理解更安全。**

---

## P14 🟢 预期现象，不要当成 bug 排查

| 现象 | 真相 |
|------|------|
| 本地点侧边栏「租后中心」白屏 | `cop-lsc` **不在本仓库**，由其它仓库提供。属预期 |
| 点「智联网关」白屏 | 同上，`nbl-union` 也不在本仓库 |
| 运行时清单声明 4 个子应用，仓库只有 3 个工程 | `cop-ucp-ui/public/static/config.js:5` 的 `MICRO_ROUTER_INFO` 声明了 4 条 |
| 在 opr/fsc 直连调试时字典下拉是空的 | 字典由**基座**写入 `sessionStorage['dict_code']`，子应用自己不拉。先起一次基座 |
| 从 opr 拷到 fsc 的校验规则不生效 | 两个应用的 `validate.js` 规则集不同（见 P6） |
| 同一接口在 ucp 和 opr 本地行为不一样 | 两个应用的 devServer **代理指向不同后端** |

---

## P15 🟢 不要修改既有 `Dc*` 组件的源码

`src/plugin/` 在三个应用里**各有一份拷贝**：30 个文件 byte 级完全相同，15 个已经分叉
（`DcBaseTableColumn`、`DcFormItem`、`DcFtTable`、`DcTable`、`DcForm`、`DcSearchForm`、
`DcSelect`、`DcCard`、`DcDatePicker` 等）。

**你改的只是当前应用那一份，另外两个应用不会跟着变。**
一旦改了，三份的差异又多一处，后续更难收敛。

需要新能力 → 在页面层组合实现，或在自己的业务组件里包一层。

同理：**不要新增 `src/` 顶级目录**（三应用 `src/` 顶级 23 个条目逐字相同），
**不要另起一套 HTTP 层**（请求一律走 `@/axios`）。

---

## P16 🟢 两个已知的真实缺陷（不是你的代码问题）

**① `cop-ucp-ui` 的 401 队列在无 session 时 Promise 永不 settle**

```js
// cop-ucp-ui/src/axios/interceptors.js:167-170
return new Promise((resolve, reject) => {
  if (storeage.getItem('session') !== null) {
    requestList.push(() => { ... })
  }
  // ← session === null 时：既没 resolve 也没 reject
})
```

`session` 为 `null` 时会 `await` 永久挂起。**只有基座有这个队列**，
opr/fsc 走的是直接 `loginOut()`。

**② `http/file.js` 引用了 4 个不存在的 api 键**

`cop-ucp-ui/src/http/file.js` 里 `queryShipList`、`fscListAll`、`getVehicleFile`、`fscfileUpload`
四个方法转发到 `api.xxx`，但这些键在 `api` 对象里**要么不存在、要么被注释掉了**。
调用它们会**以 `undefined` 作为 url 发请求**——运行期才出错。

**③ `uploadFile(url, binary, headers)` 三应用实现都有缺陷**

```js
// cop-ucp-ui/src/axios/index.js:91 附近
function uploadFile (url, binary, headers) {
  return request(url, 'put', { headers })   // ← 把字符串 'put' 当成 config 对象传
}
```

而且全工程零调用。**别用它**——上传走 `requestPostImport`。

---

## P17 🔴 `dcType` 拼错 → 整个字段空白，且不报任何错

**症状**：表单里某个字段整行不见了，或者只剩 label、输入框是空的。控制台只有一条
`Unknown custom element` 之类的警告，很容易被忽略。

**原因**：`dcType` 是**查表**，不是标签名：

```js
// cop-ucp-ui/src/plugin/form-item/form-item.vue:129-147（这里是 ucp 的 16 个；
// opr 16 个在同一文件 183-203 行；fsc 18 个 —— 多 textDecimal / remoteSelect）
getComponentName() {
  const obj = { text: 'DcText', datePicker: 'DcDatePicker', /* ...16 个... */ }
  return obj[this.dcType]        // ← 查不到返回 undefined
}
```

模板是 `<component v-if="dcType" :is="getComponentName()">`：
`dcType` 非空所以 `v-if` 通过，但 `:is` 拿到 `undefined` → **什么都不渲染**。

**最容易写错的两个**：

| 写错 | 正确的是 | 说明 |
|------|---------|------|
| `dcType="date"` | `dcType="datePicker"` | **没有 `date` 这个值** |
| `dcType="dict"` | `dcType="dictSelect"` | 表格列才用 `dict`，表单项用 `dictSelect` |

> ⚠️ 反过来也成立：`dcType` **完全不写**时渲染的是默认插槽
> （`<slot v-else>`），可以用来塞任意自定义内容 —— 这是有意的用法，不是错误。

### 映射表**每个应用不一样**（这是最危险的一处）

| 应用 | 合法值个数 | 文件 |
|------|:---:|------|
| `cop-ucp-ui` | **16** | `src/plugin/form-item/form-item.vue:129-147` |
| `cop-opr-ui` | **16** | `src/plugin/form-item/form-item.vue:183-203` |
| `cop-fsc-ui` | **18** | 同上 —— 多 `textDecimal` / `remoteSelect` |

fsc 多出来的两个（对应 fsc 独有的 `base-text-decimal.vue` / `base-remote-select.vue`）：

```
cop-fsc-ui/src/views/operator-manage/operator-network-access/
  network-access-apply/components/detail/businessRateList/components/businessWarp.vue:170
      dcType="textDecimal"      ← fsc 合法，抄到 opr / ucp 就变成空白
cop-fsc-ui/src/views/operator-manage/bank-account-manage/
  account-manage/components/accountManageInfo.vue:57
      dcType="remoteSelect"     ← 同上
```

> ⚠️ 这两处在 fsc 里**是合法的、能正常渲染**，不是踩坑。
> 真正的坑是**把 fsc 的代码复制到 opr / ucp**——那两个应用的映射表里没有这两个 key，
> 字段会静默变空白。跨应用抄表单项时，逐个核对 `dcType`。
>
> 反过来，对**当前应用**的静态 `dcType` 做全量扫描，非法值的数量是 **0** ——
> 说明大家写基本都对，出错主要出在跨应用复制上。

`check-page.sh` 会从**当前应用**的源码现读合法表逐个校验，
所以这类跨应用复制的问题能被它拦住。

完整的合法值见 `components.md` 的 `dcType` 全表。

---

## P18 🟡 `dc-form` 没有 `@submit` 事件，自带的校验也拦不住提交

**症状**：绑了 `@submit="handleSubmit"`，点「保存」**什么都没发生**。
或者用自带按钮行时，**必填项没填也提交了**。

**原因**：`DcForm` 只 emit 两个事件，名字是 `submitForm` / `cancelForm`：

```js
// cop-ucp-ui/src/plugin/form/form.vue:40-54
submitForm() {
  console.log('submitForm')
  this.$emit('submitForm')            // ← 先 emit
  this.validate((valid) => {
    if (valid) { console.log('YES') }  // ← 校验回调里什么都没做
  })
},
cancelForm() { this.$emit('cancelForm') }
```

两件事：

1. **没有 `submit` 事件** —— 写 `@submit` 绑的是个不存在的事件，静默失效。
2. **`$emit` 在校验之前** —— 就算绑对了 `@submitForm`，校验不通过**照样触发**，
   而且 validate 回调里只有一句 `console.log`，校验结果没有任何消费方。

而且**全仓 0 个页面监听 `submitForm` / `cancelForm`** —— 真实业务页的做法是
`:clickButtonFlag="false"` 关掉自带按钮，自己渲染按钮、自己调校验：

```vue
<div style="text-align: right; padding: 10px">
  <dc-button @click="handleClose">返回</dc-button>
  <dc-button type="primary" @click="handleSubmit" v-if="actionType !== 'view'">保存</dc-button>
</div>
<dc-form :model="formData" ref="fromRule" :clickButtonFlag="false">
  <dc-form-item label="编号" prop="num" dcType="text" :rules="true" />
</dc-form>
```

```js
handleSubmit () {
  this.$refs.fromRule.validate((valid) => {     // ← 自己调，别指望组件
    if (valid) { /* 走新增/编辑 */ }
    else { this.$message.error('必填信息没有完成') }
  })
}
```

克隆出来的 `...Info.vue` 就是这个结构（`new-page.sh` 从哪个页面克隆 → [cloning.md](cloning.md)）。
