# 工程约定：接口 / 路由 / 字典 / 状态 / 本地启动

---

## 一、本地起服务

| 应用 | 命令 | 地址 | 说明 |
|------|------|------|------|
| `cop-ucp-ui`（基座） | `npm run dev` | **http://localhost:7000** | 主应用 |
| `cop-opr-ui` | `npm run dev` | **http://localhost:7003** | 子应用，也可单独直连 |
| `cop-fsc-ui` | `npm run dev` | **http://localhost:7017** | 子应用，也可单独直连 |

- 三个应用都只有 `dev` / `build:prod` / `lint`，**opr 和 fsc 没有 `build` 脚本**，
  生产构建一律 `npm run build:prod`。
- 端口写在**各应用自己的 `local-server.js`**，不在 `vue.config.js`
  （`vue.config.js` 末行是 `devServer: LOCAL_SERVER`）。
- `open: true` 会自动开浏览器；`host: '0.0.0.0'` 表示同网段可用 IP 访问。
- **`headers: {'Access-Control-Allow-Origin': '*'}` 是 qiankun 拉子应用资源必需的，不要删。**
- 三个 devServer 的代理目标是**不同的后端机器**：
  - `cop-ucp-ui` 代理最全（`/api/opr`、`/api/fsc`、`/api/dbcommon`、`/api/union`、
    `/iam`、`/ocr` 各有独立 target）
  - `cop-opr-ui` / `cop-fsc-ui` 代理极简，`/api` 指向同一台后端

> 常见困惑：「在 opr 本地调的接口为什么和 ucp 不一样」——
> 因为两个应用的 devServer 代理指向不同后端。不是前端代码的问题。

---

## 二、接口层

### 2.1 三种写法，按场景选

**（a）业务接口 —— 写在业务域的 `service.js` 里（最常用）**

```js
import { requestPost, requestPostDownload } from '@/axios'

const api = {
  // 模块名 + 动作，URL 后缀遵循 listPage / listAll / add / update / remove 惯例
  baseCtrctTemplateInfo: '/api/opr/web/baseCtrctTemplateInfo/listPage'
}

export default {
  baseCtrctTemplateInfo: (params) => {
    return requestPost(api.baseCtrctTemplateInfo, params)
  },
  downloadTmplate: (params) => {
    return requestPostDownload(api.downloadTmplate, params, 'blob')
  }
}
```

**统一形态**：`const api = {键: 'url'}` + `export default {方法: (params) => requestXxx(api.键, params)}`。
**不写 `async/await`，不写 `try/catch`。**

**（b）基础服务接口 —— `src/http/api.js`（URL 常量表）+ `src/http/service.js`（方法层）**

```js
// src/http/api.js
const prefix = '/oms'
export default {
  getLogin: '/api/ucpsys/auth/login',
  addFlow: prefix + '/uaa/frame/addFlow'
}

// src/http/service.js
import axiosUrl from '@/http/api'
export default {
  getLogin: (params) => { return requestPost(axiosUrl.getLogin, params) }
}
```

> 注意：URL 常量表是 `src/http/api.js` 的 default export（一个普通对象），
> **不是 `AxiosUrls.xxx`**。`src/http/` 里 `file.js` / `iam.js` / `record.js` **只有基座有**，
> 两个子应用只有 `api.js` + `service.js`。

**（c）直接调 `request` 单例的极少数场景** —— 一般不要，优先用上面两种。

### 2.2 请求函数清单

| 函数 | 用途 | 备注 |
|------|------|------|
| `requestGet(url, params, headers)` | GET，`params` 走 query | 三应用都有 |
| `requestPost(url, params, headers)` | POST，`params` 走 body | ucp 无第 4 参；opr 多一个 `timeout` |
| `requestPostImport(url, params)` | 导入文件 | 内部固定 `multipart/form-data` |
| `requestPostDownload(url, params, 'blob')` | 下载 | 第 3 参是 `responseType` |
| `requestAuthPost(url, params, headers)` | 华为云 IAM / OCR | **仅 opr / fsc**，只认 HTTP 200/201，不做业务码判断 |
| `requestPostfileDownload(url, params)` | 转发到 `requestPost` | **仅 opr / fsc** |
| `uploadFile` | ⚠️ **三应用实现都有缺陷，不可用** | 参数传法错误，且零调用 |

### 2.3 🔴 最重要的一条：失败时 Promise 不会 reject

**成功判断不在拦截器里，而在每个 `requestXxx` 函数体内**，且是**多个白名单 OR 起来**的：

- HTTP 层：`result.status === 200`
- 业务码白名单 `result.data.code`（**三个应用、`requestGet` 与 `requestPost` 各不相同**）
- `result.data.token_type === 'bearer'`（OAuth 令牌响应）
- `result.data.success === true` / `=== false`（仅 opr / fsc 的 `requestPost`）

**落到 else 分支时，函数只调用 `authError(...)` 弹一个全局 toast，
既不 `resolve` 也不 `reject`** —— 返回的 Promise **永远 pending**。

后果链条（最常见的报障：「点了没反应」）：

```
接口返回业务错误码（不在白名单）
  → Promise 永不 settle
    → .then 不执行 → this.loading 保持 true（.finally 也不执行）
      → 之后所有查询被 if (this.loading) return 挡掉
        → 页面转圈不停，之后再也查不出数据
```

**写代码时的应对**：不要指望 `.then` 里的 `else` 分支兜底（几乎走不到）；
页面级错误处理要看全局 toast，不要依赖本地 catch。

**业务成功码是 `'S000000'`**，但白名单里还有 `'0000'`、`'000000'`、`'0000000'`、`'200'`、
`'401'`、`'F00000044'`、`'F00000045'` 以及各域特有的错误码——这是历史遗留的宽容判断，
**照抄既有页面的判断写法，不要自己发明**。

### 2.4 路径前缀 → 后端服务

| 前缀 | 服务 |
|------|------|
| `/api/ucp/web/…` | 用户中心公共（字典、机构、附件） |
| `/api/opr/web/…` | 运营域（cop-opr-ui） |
| `/api/fsc/web/…` | fsc 域（cop-fsc-ui） |
| `/api/dbcommon/web/…` | 公共文件 / 导出 |
| `/api/ucpsys/…` | 门户 / 系统（登录、菜单、参数） |
| `/oms/uaa/frame/…` | 工作流（`const prefix = '/oms'`） |
| `/iam/v3/auth/tokens` | 华为云 IAM（直连，走 `requestAuthPost`） |
| `/ocr/v2/…` | 华为云 OCR（直连，走 `requestAuthPost`） |

⚠️ **同一业务接口在不同应用前缀可能不同**，例如登录：
`/api/ucp/web/auth/login`（ucp）、`/api/ucpsys/auth/login`（opr/fsc）。
**新建 service 时先 grep 一下同功能在别的应用怎么写的。**

**跨域调用是允许的**——opr 的 service 里直接写 `/api/fsc/web/...` 是常态。

### 2.5 请求头

由拦截器自动注入，**业务代码不需要手动加**：
`logintoken` / `access_token` / `Authorization` / `instCode`，
以及语言头 `Accept-Language`、链路追踪头。

---

## 三、路由

### 3.1 新增一个页面，要改几处？

**四处。缺任何一处都可能 404 或菜单点不进去。**

**① 建 `.vue` 文件 —— 路径必须等于后端下发的 `menuUrl`**

`utils/router.js` 的 `formatRoutes` 是这样动态导入的：

```js
component: () => {
  return import(/* webpackChunkName: "[request]" */ `@/views${menuUrl}.vue`)
}
```

所以后端菜单里的 `menuUrl` 是 `/operator-manage/operator-info/index`，
就必须存在 `src/views/operator-manage/operator-info/index.vue`。**路径不一致 → webpack 报模块找不到。**

**② 域内路由文件加静态条目**（本地直连、非 qiankun 模式靠它）

`src/views/<业务域>/<业务域>-router.js`：

```js
export default [
  {
    path: 'yourModule',            // 不带前导 /
    name: '你的页面中文名',         // 中文，全仓不能重名
    component: () => import('./yourModule/index.vue'),
    meta: { title: '你的页面中文名', noTag: false }
  }
]
```

**③ `src/views/view-router.js` 聚合**（新业务域才需要）

```js
import YourDomainRouter from './your-domain/your-domain-router'

export default [
  // ...
  { path: 'your-domain', component: RouterEnter, children: YourDomainRouter }
]
```

`RouterEnter` = `@/components/RouterEnterComponent.vue`。

**④ 后端配菜单** —— 侧边栏入口是后端菜单树渲染的，前端挂好路由不会自动出现菜单项。

### 3.2 URL 形态

```
/view/<业务域>/<模块>            ← 直连
/cop-opr/view/<业务域>/<模块>    ← qiankun 下（子应用 base = /cop-opr/）
```

### 3.3 跨应用跳转

基座 `cop-ucp-ui/src/router/index.js` 里**手工硬编码了一批跨应用重定向路由**，
例如 `shipping-manage/pickupAudit` → `/cop-opr/view/...`。
新增跨应用跳转要在这里加，**不是加在业务域的 router 文件里**。

### 3.4 后端菜单数据结构（`formatRoutes` 期望的字段）

```js
const {
  appName, path, fileName, text, componentName, directory, id, icon,
  children, buttonChildren,
  menuUrl, menuNm, menuUrlLv1, menuUrlLv2, noTag, menuicn
} = oMenu
```

实际参与路由生成的：

| 字段 | 用途 |
|------|------|
| `menuUrl` | 路由 `path`，**同时决定 `.vue` 文件路径** |
| `menuUrlLv2` | 路由 `name` |
| `menuNm` | `meta.title` |
| `id` | `meta.menuId` |
| `appName` | 区分主应用路由 / 子应用 `micro` 组件 |
| `menuicn` | 路由 icon |
| `noTag` | `meta.noTag` |
| `buttonChildren` | `meta.btnPermission`（按钮级权限码数组） |
| `children` | 有子节点时，首个子节点的 `menuUrl` 作为 `redirect` |

> `dealTreeData`（`utils/getTreeData.js`）会做新旧字段名兼容映射
> （`aplCode→appName`、`menuCode→id`、`menuIcn→menuicn`、`menuTpCode→menutp`、
> `menuWthrDisp→visible`），说明后端菜单字段名改过一轮。

### 3.5 登录守卫

`guards.js` 的 `loginGuard` 判断 `store.getters['velaApp/username'] || sessionStorage` 里的用户名，
未登录跳 `/glogin`（ucp）或 `/login`（opr/fsc）。

`loginIgnore.includes(route)` 的豁免白名单**三个应用不同**：

| 应用 | 豁免的第三段路径 |
|------|-----------------|
| ucp | `nbl-cet` / `nbl-ibc` / `cop-ucp` / `nbl-union` |
| opr | `cop-opr` |
| fsc | `nbl-cet` / `nbl-ibc` / `cop-fsc` |

---

## 四、字典

### 4.1 机制：基座写，子应用读

```
cop-ucp-ui 启动
  → dictStore/getDictCode 批量拉全量字典（206 条码值）
    → 写入 sessionStorage['dict_code']  +  commit SET_DICT_ALL
      → 子应用启动时 App.vue commit RESET_DICT，从 sessionStorage 回填 dictMap
        → DcDictSelect / filterDict 从 dictMap 同步读
```

**子应用自己不请求字典。** 结构：`state.dictStore.dictMap[码值] = [{label, value}]`，
`label ← dicItemNm`，`value ← dicItemVal`。

### 4.2 三种用法（都不需要自己请求）

**① 表单 / 查询项**

```vue
<dc-form-item label="模板类型" prop="tpltTpCode" dcType="dictSelect" dictCode="COP0109" />
```

**② 表格列**

```vue
<dc-base-table-column prop="staSteCode" label="状态" type="dict"
  :inputParam="{ dictCode: 'COP0002' }" />
```

**③ 模板里翻译显示**

```vue
{{ scope.row[prop] | filterDict('COP0002', $store) }}
```

需要原始数组时：

```js
const dictList = this.$store?.state?.dictStore?.dictMap?.['COP0119'] || []
```

### 4.3 三应用差异（重要）

| 应用 | 字典行为 |
|------|---------|
| `cop-ucp-ui` | **写入方**。`dictStore` 有 `getDictCode` action，`utils/dictCode.js` 有 206 条码值 |
| `cop-opr-ui` | 只读。**没有 `utils/dictCode.js`**，完全依赖 `sessionStorage['dict_code']` 里的既有数据 |
| `cop-fsc-ui` | 只读。`App.vue:16` 里 `this.getDictCode(dictCode)` 调用**被注释掉**（定义在 `:40` 是活的但没人调），`utils/dictCode.js` 只有 34 条 |

**实践含义**：
- 在 opr/fsc 单独直连调试时，如果没先跑过基座，`dict_code` 可能不存在 → 下拉是空的。
  **这不是你代码的问题，先起一次基座把字典灌进去。**
- 新增一个字典码值时，要确认它在**基座的 `utils/dictCode.js` 清单里**，否则拉不下来。

---

## 五、Vuex

`src/store/modules/` 下**只有两个模块**，都是 `namespaced: true`：

| 模块 | 命名空间 | 内容 |
|------|---------|------|
| `app.js` | `app` **和** `velaApp`（`store/index.js` 里重命名注册了一份） | `username`、`userInfo`、`navTree`、`settings`（主题/分页条数）、`loginCors`（登录用户所在机构） |
| `dictStore.js` | `dictStore` | `dictMap` |

注册机制是 `require.context('./modules', true, /\.js$/)` 自动扫描，**文件名即模块名**。

常用读法：

```js
this.$store.getters['velaApp/username']   // 登录用户名
this.$store.state.dictStore.dictMap['COP0119']
this.$store.getters['velaApp/pageSize']   // 全局表格默认条数
```

token 读法：`storeage.getItem('token')` / `'access_token'` / `'refresh_token'` / `'session'`。

> ⚠️ `src/utils/storeage.js` 拼写就是 **`storeage`**（不是 storage）。
> `setItem` **三个应用都是同时写 session + local**；但 `getItem` **三应用不一致**：
> ucp **只读 session**（回落 local 那半被注释掉了），opr/fsc 是
> `sessionStorage.getItem(key) || localStorage.getItem(key)`（**会回落到 local**）。
> 详见 [pitfalls.md](pitfalls.md) **P13**。

> ⚠️ `userInfo` 的字段结构三应用不一致：ucp 取 `JSON.parse(...).userinfo`（小写），
> opr/fsc 直接取 `.userNm` / `.instCode`。跨应用抄代码时不要照搬。

---

## 六、导出

```js
import { commonExport, EXPORT_TP_CODE } from '@/utils/exportUtil.js'
```

`commonExport(exportTpCodeKey, param, fileName)` 内部调 `httpService.commonExport`，
拿到 blob 后用 `<a download>` 触发下载。

> `exportUtil.js` **只有 opr 有**。在 ucp/fsc 做导出要先确认有没有对应工具，
> 否则用 `requestPostDownload(url, params, 'blob')` 自己接。

⚠️ **下载失败的错误解包三应用不一致**：
只有 `cop-fsc-ui` 实现了 `checkBlobResponse`（服务端返回 200 但 body 是错误 JSON 时能识别并提示）。
**ucp 和 opr 会把错误 JSON 当文件下载，用户得到一个打不开的文件且没有任何提示。**
在 ucp/opr 做下载功能时，这块要自己补。

---

## 七、脚手架与自查盯住的 11 条静默失败规则

> 这一节原是 SKILL.md 正文里的速查表，为把 SKILL.md 的初始载入压到预算内而移到这里。
> `new-page.sh` 生成时已按这些规则写对，`check-page.sh` 会逐条复查 —— 所以正常情况下
> 你**不需要背**；只有自查报错、或你要手改骨架时才回来查这张表。

| 规矩 | 写错了会怎样 |
|------|-------------|
| `<dc-form-table>` 必须是最外层 | 查询区找不到表格，点「查询」毫无反应 |
| `dc-search-form` 和表格的 `idKey` 必须是同一个值 | 同上，静默失效 |
| 表格必须 `ref="multipleTable"` | 列设置为空、跨页勾选报错、表格高度塌陷 |
| 表格必须 `:key="reloadTable"` | 列显示/隐藏设置不生效 |
| 搜索数据字段必须叫 `searchFormData` | 搜索条件缓存恢复失效 |
| 分页只对外暴露 `@pageChange` | 页面里没有 `handleSizeChange` / `handleCurrentChange` |
| 发给后端的是 `pageNum` / `pageSize`，业务条件包在 `param` 里 | 组件内部叫 `currentPage`，直接发会变形 |
| 成功码判断用 `'S000000'` | 用别的值判断 → 成功也走失败分支 |
| `dc-form` **没有** `@submit` 事件 | 绑了它点「保存」没反应；校验要自己 `ref.validate()` 调 |
| 表单字段的 `dcType` 必须是合法值 | 写错**整个字段空白且不报错**（常见：`date` 应为 `datePicker`，`dict` 应为 `dictSelect`） |
| 字典列是 `type="dict"` + `:inputParam="{ dictCode }"` **两层** | 少一层 → 显示原始码值 `0`/`1` 或整格空白 |

> 另外三条铁律（**不改 `Dc*` 源码 / 不新增 `src/` 顶级目录 / 不照抄注释掉的代码**）
> 是全局行为约束，写在 [SKILL.md](../SKILL.md) 正文里。
> **本文不再重复**——同一段内容放两处维护，迟早会漂移成两个版本。

---

## 八、三应用差异全表

> 同上一节：原在 SKILL.md 正文，为压初始载入移来此处。
> **跨应用抄代码前必须对照这张表。**

| 维度 | cop-ucp-ui（基座） | cop-opr-ui | cop-fsc-ui |
|------|:---:|:---:|:---:|
| `src/` 顶层结构 | 相同 | 相同 | 相同 |
| `src/plugin/` 组件 | 45 个 | 45 个 | **47 个**（多 `base-remote-select` / `base-text-decimal`） |
| 合法 `dcType` 值 | 16 个 | 16 个 | **18 个**（多 `remoteSelect` / `textDecimal`） |
| axios 超时 | ✅ 有 | ✅ 有 | ❌ **整行被注释** |
| 字典写入方 | **写入方** | 只读 | 只读 |
| `window.commonComponent` | **写入方** | 消费 | 消费 |
| 下载错误解包 | ❌ | ❌ | ✅ 有 `checkBlobResponse` |
| 401 处理 | 刷新队列 + 重放 | `loginOut()` | `loginOut()` |
| `verifyRule` 规则 | — | 全量 | 缺 `positiveNumber` / `version` 等 |
| `exportUtil.js` | ❌ 无 | ✅ 有 | ❌ 无 |
| `@/mixins/searchCacheMixin.js` | ❌ **没有这个文件** | ✅ 有 | ✅ 有 |
| 搜索条件缓存（`searchCacheOptions`） | ❌ 0 处使用 | ✅ 15 个文件 | ✅ 11 个文件 |
| `storeage.getItem` 读法 | **只读 session**（回落那半被注释） | session 没有就**回落 local** | 同 opr |
| `IS_MOCK` 实际会不会加载 mock | ❌ 不会（`require` 被注释） | ⚠️ **会**（开关 `true` + `require` 是活的） | ❌ 不会（整块被注释） |
| `dc-base-table-column` 的 `type="slot"` | ❌ 分支被注释 | ✅ **活代码** | ✅ **活代码** |

> ⚠️ **从 fsc 抄到 opr/ucp 时最危险的一处**：`dcType="remoteSelect"` / `"textDecimal"`
> 在 fsc 合法，在 opr/ucp **不存在** → 字段空白且不报错。
> `check-page.sh` 会按当前应用的合法表逐个校验，能拦住。

### 跨应用复用组件的唯一正确姿势（子应用消费基座能力）

```js
// ✅ 必须判空——子应用可以脱离基座独立运行，那时 window.commonComponent 是 undefined
const { OperationRecord } = window.commonComponent || {}
```

> `window.commonComponent` **只有 3 个成员**：`FileDirectory` / `OperationRecord` / `signInfoDialog`。
> 想要别的东西（例如 PDF 预览 `pdfViewDialog`）它里面**没有**，得另找路子。
