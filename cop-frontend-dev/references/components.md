# Dc* 组件速查

页面里直接写 kebab-case 标签，**不需要 import** —— 因为 `src/plugin/` 是**全局注册**的。

```js
// cop-ucp-ui/src/plugin/index.js:1-11（三个应用逐字一致）
const components = require.context('./', true, /\.vue$/)
export default {
  install: function (app) {
    components.keys().forEach((key) => {
      const val = components(key).default
      const name = val.name || key.replace(/(.*\/)*([^.]+).*/gi, '$2')
      app.component(name, val)
    })
  }
}
```

装配点（`cop-ucp-ui/src/utils/micro.js:232`）：

```js
Vue.use(ElementUI).use(globalComponents).use(commonComponent)
```

⚠️ **变量名和目录是反的，别记错**：

| 变量 | 实际指向 | 注册了什么 |
|------|---------|-----------|
| `globalComponents` | `@/components` → `src/components/` | 该目录下全部 `.vue`（递归） |
| `commonComponent` | `@/plugin` → `src/plugin/` | **`Dc*` 全家桶** |

**所以全局注册有两个根**，不只是 `plugin/`：

1. `src/plugin/**/*.vue` —— `Dc*` 组件（45 / 45 / 47 个）
2. `src/components/**/*.vue` —— 各应用自己的公共组件

子应用还多一个：`src/views/components/**/*.vue`（opr / fsc）。

> 💡 实用推论：**往 `src/components/` 里丢一个 `.vue`，它就自动全局可用**，不用 import。
> `<signTable>` 就是这么来的 —— `signTable.vue` 里没有 `name:`，
> 靠 `name` 缺失时的**文件名兜底**注册成了 `signTable`。
>
> `src/plugin/` 下 45 个文件**全都写了 `name:`**，所以那条兜底逻辑在 `plugin/` 里
> 从未真正触发过。但兜底只看文件名、**不做 `Dc` 前缀转换**，
> 所以真触发了会得到 `ft-form` 这种名字（而不是 `dc-ft-form`）—— 别依赖它。
>
> 兜底表达式 `key.replace(/(.*\/)*([^.]+).*/gi, '$2')` 的实际效果 = **取文件名去扩展名**。

---

## 选型速查

| 我要做 | 用 | 不要用 |
|--------|---|-------|
| CRUD 骨架最外层 | `DcFormTable` | `div` / `el-form` |
| 页面分组 / 卡片 | `DcCard` | `el-card` |
| 查询区 | `DcSearchForm` + `DcFormItem` | `el-form` |
| 列表页数据表 | `DcFtTable` | `el-table` |
| 详情页 / 弹窗内的小表 | `DcTable` | `el-table` |
| 表格数据列 | `DcBaseTableColumn` | `el-table-column` |
| 表格操作列 / 多选列 | `DcTableColumn` | — |
| 列显隐设置 | `DcTableColumnSetting` | 自己写 |
| 表单主体 | `DcForm` | `el-form` |
| 弹窗 | `DcDialog` | `el-dialog` |
| 按钮 | `DcButton` | `el-button`（**操作列内例外**） |
| 只读文本 | `DcText` | `span` |
| 折叠面板 | `DcCollapse` + `DcCollapseItem` | `el-collapse` |
| 右侧详情抽屉 | `DcDrawer` | `el-drawer` |

---

## DcFormTable — 骨架粘合剂

**CRUD 页的最外层容器，一天都少不了的组件。**

```vue
<dc-form-table>
  <dc-card class="box-card"> ... </dc-card>
</dc-form-table>
```

它只做一件事——用 `provide` 把自己暴露给后代：

```js
// cop-ucp-ui/src/plugin/form-table/form-table.vue:16-23
name: 'DcFormTable',
mixins: [asyncDictMixins, tableMixins],
provide() {
  return { dcFormTable: this }
}
```

`DcSearchForm` / `DcFtTable` 都 `inject: ['dcFormTable']`，靠它互相找到对方。
**外层不是它 → 查询按钮失效。**

---

## DcCard — 分组容器

最常用的布局件（全仓 267 次命中）。两种用法：

```vue
<!-- 带标题行 + 右上角工具按钮 -->
<dc-card class="box-card">
  <div slot="header" class="clearfix">
    <div class="right-button">
      <dc-button type="primary" @click="handleAdd">新增</dc-button>
    </div>
  </div>
  <dc-ft-table ... />
</dc-card>

<!-- 纯包裹 -->
<dc-card class="box-card"> ... </dc-card>
```

---

## DcSearchForm — 查询区

**全局注册名 `DcSearchForm`，源码在 `plugin/form/ft-form.vue`。**

> 文件名是 `ft-form`，但注册用的是 `name: 'DcSearchForm'`，不是文件名
> （`plugin/index.js` 优先取 `name`）。所以**标签写 `<dc-search-form>`**，
> Vue 会做 kebab → PascalCase 匹配。全仓业务页用了 94 次 `<dc-search-form>`，
> `<dc-ft-form>` **0 次**——别被文件名误导。
>
> 同目录还有个 `ft-form.bak`，`require.context` 只匹配 `.vue`，**它不会被注册**，
> 是旧版本的死文件（旧版用 `showExpandFlag`，新版用 `dcTotal`）。

```js
// cop-opr-ui/src/plugin/form/ft-form.vue:25-55
name: 'DcSearchForm',
extends: Form,
props: {
  commonRule: [Object, Array],
  idKey: String,                    // ← 必须与表格的 idKey 一致
  dcColspan: { type: Number, default: 6 },      // 每个查询项占的栅格宽度
  dcTotal: { type: Number, default: 3 },        // 默认显示几个，超出折叠成"展开"
  hideButtons: { type: Boolean, default: true }, // 是否隐藏搜索/重置按钮
  cachePageKey: { type: String, default: '' }    // 缓存 pageKey，优先级高于 idKey
},
inject: ['dcFormTable'],
```

### 点「查询」之后发生了什么（三应用走法不同，结果相同）

**基座 ucp** —— 走 `refreshTable`：

```
点查询 → ft-form.queryForm() → $emit('refreshTable')
       → 页面 refreshTable()  [tableMixins] → saveSearchData() + queryList()
```

**opr / fsc** —— `$emit('refreshTable')` 那一行**被注释掉了**，改走 `pageChange`：

```js
// cop-opr-ui/src/plugin/form/ft-form.vue:106   ← 注意是注释
// this.$emit('refreshTable')
```
```
点查询 → ft-form.queryForm() → 找到表格 → _table.handleQueryChange()
       → currentPage = 1 + $emit('pageChange', {currentPage:1, pageSize})
       → 页面 pageChange()    [tableMixins] → saveSearchData() + queryList()
```

**两条路殊途同归**：搜索条件都会存缓存、页码都回到第 1 页、列表都会重查。
所以你**不需要**为此写任何额外代码，模板里 `@refreshTable` 和 `@pageChange` 都绑上就行。

> ⚠️ 唯一要记住的是**调试时别被误导**：在 opr / fsc 里给 `refreshTable` 打断点
> 永远不会命中，那不是查询坏了。要断点就打在 `pageChange` 或 `queryList`。

### 🔴 一个真实的运算符优先级 bug（决定了你该怎么写 idKey）

`queryForm()` 里找表格的条件是 `(A && B && C) || D`，少了括号：

```js
// cop-ucp-ui/src/plugin/form/ft-form.vue:116-121
if (
 (element.idKey &&
  element.idKey === _idKey &&
  element.$options._componentTag === 'dc-ft-table') ||
  element.$options._componentTag === 'dc-table'      // ← 无条件命中
) {
  _table = element
}
```

**后果：页面里只要有一个 `<dc-table>`，它就会被无条件选中**，
`idKey` 写什么都不影响匹配。

**实操结论**：
- 用 `dc-ft-table`（推荐）→ `idKey` **必须**和查询区逐字一致
- 页面里混了 `dc-table` → 查询会打到 `dc-table` 上，`idKey` 形同虚设

`clearSort()` 用的是另一份更严格的递归实现（`getTableComponent`，`ft-form.vue:171-206`），
条件写成 `idKey === idKey && (tag === 'dc-ft-table' || tag === 'dc-table')`，**没有**这个漏洞。

```vue
<dc-search-form
  idKey="multipleTable"
  cachePageKey="xxxModuleList"
  :model="searchFormData"
  ref="fromRule2"
  :dcColspan="8"
  @refreshTable="refreshTable"
>
  <dc-form-item label="名称" prop="name" dcType="text" />
</dc-search-form>
```

> `dcTotal` 默认 3：**查询项超过 3 个会自动出现「展开/收起」**，不用自己写。

---

## DcFormItem — 表单项

搜索区和表单区通用。**整个骨架里最关键的组件。**

```js
// cop-ucp-ui/src/plugin/form-item/form-item.vue:58-73
props: {
  placeholder: String,     // 占位符
  dcType: String,          // ← 决定渲染成什么输入控件
  dcColspan: Number,       // 输入组件宽度
  labelTitle: Boolean,     // 是否展示 label 的 title
  disabled: Boolean,       // 置灰
  rules: { type: [String, Boolean, Object, Array], default: '' },
  suffixFlag: { type: Boolean, default: false }
}
```

> ⚠️ **ucp 只有这 7 个 prop**（213 行）。`showTooltip` / `forceTooltip` 是
> **opr / fsc 独有**的（510 / 512 行，多了一套 label 溢出检测 Tooltip）。
> 写了在当前应用不存在，只会变成无效属性。

### `dcType` 全表

`dcType` **不是组件标签**，是一个字符串映射。源码：

> ⚠️ **映射表每个应用一份，且不完全一样**：
> `cop-ucp-ui` **16** 个（`form-item.vue:129-147`）、
> `cop-opr-ui` **16** 个（同文件 `183-203`）、
> `cop-fsc-ui` **18** 个（同文件，多 `textDecimal` / `remoteSelect`）。
> 下面列出的是 16 个公共值；两个 fsc 独有值单列在后面。

```js
getComponentName() {
  const obj = {
    text: 'DcText',                 select: 'DcSelect',
    dictSelect: 'DcDictSelect',     datePicker: 'DcDatePicker',
    checkbox: 'DcCheckbox',         cascader: 'DcCascader',
    radio: 'DcRadio',               switch: 'DcSwitch',
    timeSelect: 'DcTimeSelect',     timePicker: 'DcTimePicker',
    textarea: 'DcTextarea',         checkboxGroup: 'DcCheckboxGroup',
    blankRow: 'BlankRow',           isThounsand: 'DcThousandSeparator',
    dictCheckbox: 'DcDictCheckbox', dictRadio: 'DcDictRadio'
  }
  return obj[this.dcType]
}
```

| `dcType` | 渲染 | 全仓用了多少次 |
|----------|------|--------------|
| `text` | 文本输入框 | **515** |
| `dictSelect` | 字典下拉（配 `dictCode`） | **265** |
| `datePicker` | 日期选择（**不是 `date`**） | 71 |
| `select` | 普通下拉（配 `:optionList`） | 67 |
| `cascader` | 级联选择 | 53 |
| `textarea` | 多行文本 | 33 |
| `radio` | 单选组 | 27 |
| `isThounsand` | 千分位（**源码就是这个拼写**） | 20 |
| `switch` | 开关 | 13 |
| `checkboxGroup` | 多选框组 | 11 |
| `timeSelect` / `timePicker` | 时间选择 | 9 / 9 |
| `checkbox` | 单个复选框 | 9 |
| `blankRow` | 占位/换行（**不是 `BlankRow`**） | 2 |

#### 只有 `cop-fsc-ui` 有（16 + 2 = 18）

| `dcType` | 渲染 | 底层组件文件 |
|----------|------|-------------|
| `textDecimal` | 小数输入框 | `cop-fsc-ui/src/plugin/input/base-text-decimal.vue`（`name: 'DcTextDecimal'`） |
| `remoteSelect` | 远程搜索下拉 | `cop-fsc-ui/src/plugin/input/base-remote-select.vue`（`name: 'DcRemoteSelect'`） |

> 🔴 **`dcType` 拼错是静默失败**：`v-if="dcType"` 只判真假，查表失败返回 `undefined` →
> `<component :is="undefined">` → **该字段整个消失**，页面不报错、lint 不报错、接口照发空值。
>
> 两种踩法：
> - **本应用内写错**（常见 `date` 应为 `datePicker`、`dict` 应为 `dictSelect`）
> - **跨应用抄上表两个 fsc 专属值**（`textDecimal` / `remoteSelect`）——
>   在 fsc 合法且正常渲染，抄到 opr / ucp 就没有这两个 key
>
> 对**单个应用自己**的静态扫描，非法 `dcType` 数量是 **0**，出错几乎只发生在**跨应用复制**这一步。
> `check-page.sh` 从当前应用的源码现读合法表逐个校验，能拦住。
> 完整清单与源码行号见 [pitfalls.md](pitfalls.md) **P17**。

### dcType 的三个易错点

```vue
<!-- 1. dcType 不传 → 渲染默认插槽，不是"默认输入框" -->
<dc-form-item label="自定义" prop="x"><el-input v-model="f.x" /></dc-form-item>

<!-- 2. dcType 写错值 → 该字段渲染成空白，且没有任何报错 -->
<dc-form-item dcType="date" />        <!-- ❌ 应为 datePicker，会变成空白 -->

<!-- 3. 选择类要用「请选择」而非「请输入」，不用自己写 placeholder -->
```

**placeholder 自动推断**（`form-item.vue:150-162`）：
`text` / `isThounsand` → 「请输入」；`dictSelect` / `select` / `datePicker` / `cascader` → 「请选择」；
`disabled` 时为空。优先级：`placeholder` prop > `ENTRY_MOTIF.publicPlaceholder` > 自动推断。

### 非 prop 属性会透传

`inheritAttrs: false` + `v-bind="$attrs"` + `v-on="$listeners"`，所以
`dictCode="COP0109"`、`value-format="yyyy-MM-dd"`、`:props="{...}"` 这些
**直接写在 `dc-form-item` 上就能生效**，会落到内部真实输入组件上。
`@change` 也是内部组件发的，不是 FormItem 发的。

**`rules` 三态**：

```vue
<dc-form-item :rules="true" />                     <!-- 只必填 -->
<dc-form-item :rules="verifyRule.AZazNum" />       <!-- 引用共享规则 -->
<dc-form-item required :rules="verifyRule.version" /> <!-- 必填 + 格式 -->
```

---

## DcFtTable — 列表页数据表

**全局注册名 `DcFtTable`，源码在 `plugin/table/dc-ft-table.vue`。**

```js
// cop-opr-ui/src/plugin/table/dc-ft-table.vue:126-175
props: {
  size: { type: String, default: ENTRY_MOTIF.domSize },
  idKey: String,                              // ← 与 DcSearchForm 对齐

  // 分页配置
  pagination: { type: Boolean, default: true },
  pgBackground: { type: Boolean, default: true },
  pgPageSize: { type: Number, default: 10 },
  pgCurrentPage: { type: Number, default: 1 },
  pgPageSizes: { type: Array, default: () => [10, 20, 30, 40, 50, 100] },
  pgLayout: { type: String, default: 'total, sizes, prev, pager, next, jumper' },
  pgTotal: { type: Number, default: 1 },
  pgPagerCount: { type: Number, default: 7 },

  columnSetting: { type: Array, default: () => [] },   // 列显隐配置
  highlightCurrentRow: { type: Boolean, default: true }
}
```

**事件**：只暴露一个分页事件 `@pageChange`，参数是对象 `{ currentPage, pageSize }`。
Element 原生的 `handleSizeChange` / `handleCurrentChange` 被它内部吞掉了。

**必须的三件套**：

```vue
<dc-ft-table
  :key="reloadTable"          <!-- 列显隐要重建表格 -->
  idKey="multipleTable"       <!-- 与查询区一致 -->
  ref="multipleTable"         <!-- tableMixins 硬依赖这个名字 -->
  :data="tableData"
  :columnSetting="columnSetting"
  :pgTotal="paginationParam.total"
  :pgPageSize="paginationParam.pageSize"
  :pgCurrentPage="paginationParam.currentPage"
  @pageChange="pageChange"
  @selection-change="handleSelectionChange"
>
```

---

## DcTable — 基础表格

`plugin/table/dc-table.vue`，`name: 'DcTable'`，`extends: Table`（继承 element-ui Table 再改写）。

与 `DcFtTable` 的**全部**区别：

| | DcFtTable | DcTable |
|---|---|---|
| 用途 | 列表页主表（**新页面用这个**） | 详情页 / 弹窗内小表 |
| **`idKey` prop** | ✅ 有 | ❌ **没有** |
| `inject: ['dcFormTable']` | ✅ 有 | ❌ 没有 |
| `pgTotal` 默认值 | `1` | `0` |
| `pgPagerCount` | ✅ 默认 7 | ❌ 没有 |
| `highlightCurrentRow` | ✅ 默认 `true` | ❌ 未声明（随 element 默认 `false`） |

> ⚠️ **`DcTable` 没有 `idKey`**，所以它只能靠前面那个优先级 bug 被 `dc-search-form` 命中
> （见上一节）。新页面一律用 `dc-ft-table`。
>
> `pgTotal` 默认值 `1` vs `0` 是**迁移时的隐式行为变更**——从 `dc-table` 换成
> `dc-ft-table` 而没传 `pgTotal`，空数据时下方分页条会从「0 条」变成「1 条」。

---

## DcBaseTableColumn — 表格数据列

**全仓用得最多的组件（1269 次命中）。**

```js
// cop-ucp-ui/src/plugin/table-column/dc-base-table-column.vue:98-116
name: 'DcBaseTableColumn',
props: {
  prop: String,                                        // 绑定字段
  label: String,                                       // 列标题
  width: [String, Number],
  type: String,                                        // ← 处理类型
  align: String,
  inputParam: { type: Object, default: () => {} },      // ← 类型参数（字典码放这里）
  iconType: { type: Boolean, default: false },          // 是否用 el-tag 展示
  sortable: { type: Boolean, default: true }            // ⚠️ 默认 true
}
```

> ⚠️ **`sortable` 默认 `true`，而且每个分支都绑了 `:sortable='sortable'`** ——
> 意味着**每一列默认都带排序箭头**。业务页几乎没人管它
> （全仓 `<dc-base-table-column` 开标签 1269 处，`:sortable` 出现不到 200 处——
> 想自己复核就 `grep -rhoF '<dc-base-table-column' cop-*/src | wc -l`，
> 别信写死在文档里的数字，代码会变）。
> 不想让某列可排序才显式写 `:sortable='false'`。

### `type` 取值（源码 `dc-base-table-column.vue:12-93`）

| `type` | 效果 | 关键点 |
|--------|------|--------|
| `dict` | 字典翻译 | 需 `inputParam.dictCode`，**否则整格空白** |
| `countNumber` | 序号列 | 渲染 `scope.$index + 1` |
| `multipleCheck` | 多选列（`type="selection"`） | — |
| `singleCheck` | 单选列（`el-radio`） | 选中值经 `inputParam.currentRow` **回写**，无事件 |
| `actionFold` | 操作列 · 折叠进 popover | 插槽名 `actionFold` |
| `actionUnfold` | 操作列 · 行内平铺 | 插槽名 `actionUnfold` |
| `customHeader` + `inputParam.slot` | 自定义表头 + 内容插槽 | 插槽名 `customHeader` |
| `customHeader` | 仅自定义表头 | 配 `inputParam.tooltip` |
| `isThounsand` | 千分位（**源码就是这个拼写**） | — |
| `text` | 纯文本 | **额外作用是关掉自动千分位** |
| 不传 / 其它值 | 默认分支 | 渲染默认插槽 `{ row, index }` |

> ⚠️ **`type="slot"` 三应用不一致**：`dc-base-table-column.vue` 里 `type === 'slot'` 那个分支，
> **只有 ucp 是注释掉的**（`cop-ucp-ui/.../dc-base-table-column.vue:78` 整行在 HTML 注释里）；
> **opr 与 fsc 是活代码**（`cop-opr-ui` 同文件 `:78`、`cop-fsc-ui` 同文件 `:99`），
> 传 `type="slot"` 会正常渲染作用域插槽。
> **写跨应用复用的代码时不要用它**（在 ucp 下静默失效）；想要自定义单元格，
> **什么都不用传**，默认分支本来就给你默认插槽：
> ```vue
> <dc-base-table-column prop="x" label="自定义">
>   <template slot-scope="{ row, index }"> ... </template>
> </dc-base-table-column>
> ```

> ⚠️ **默认分支会自动加千分位**（`:88`）：
> `isNumber(scope.row[prop]) && type !== 'text'` → 走 `thousandConve` 过滤器。
> 数字字段想原样显示，就得写 `type="text"`。

> fsc 额外多了两个 type：`notooltip`（不显示溢出 tooltip）、`mustHeader`。
> **只有 fsc 有**，另外两个应用写了会落到默认分支。

### 最常用的三个

```vue
<!-- 序号 -->
<dc-base-table-column label="序号" type="countNumber" />

<!-- 普通文本 -->
<dc-base-table-column prop="tpltNm" label="模板名称" />

<!-- 字典（两层都要写） -->
<dc-base-table-column prop="tpltTpCode" label="模板类型" type="dict"
  :inputParam="{ dictCode: 'COP0109' }" />
```

字典列的渲染逻辑：

```vue
<!-- dc-base-table-column.vue:12-16 -->
<dc-table-column :prop="prop" :label="label" v-if="type === 'dict'">
  <template slot-scope="scope" v-if="inputParam.dictCode">
    <span v-if="!iconType">{{ scope.row[prop] | filterDict(inputParam.dictCode, $store) }}</span>
    <el-tag v-else :type='typeObj[scope.row[prop]]'>{{ ... }}</el-tag>
  </template>
</dc-table-column>
```

🔴 **`v-if="inputParam.dictCode"` 在 `template` 上，三种写错法、三种症状**：

| 写错的方式 | 结果 |
|-----------|------|
| `type="dict"` 漏了（或写成 `dictSelect`） | 落到默认分支 → **显示原始码值** `0`/`1`/`2` |
| `type="dict"` 有，`inputParam="{...}"` 里没有 `dictCode` | `dictCode` 为 `undefined` → 模板不渲染 → **整格空白** |
| `type="dict"` 有，**`inputParam` 整个没传** | `inputParam` 是 `undefined` → `undefined.dictCode` → **渲染时抛 TypeError** |

> ⚠️ 第三种是个**潜伏 bug**：`inputParam` 的默认值写成了 `default: () => {}`
> ——箭头函数体是空块，返回 `undefined`，而不是空对象（应为 `() => ({})`）。
> 已实测确认：不传时 `inputParam === undefined`。
> 全仓 230 处 `type="dict"`（ucp 38 / opr 109 / fsc 83）都传了 `inputParam`，所以这个坑目前没人踩到。

> ⚠️ 示例页 `show-case/table-up/index.vue:52,73` 写的是 `type="dictSelect"` —— **那是错的**。
> `dictSelect` 不匹配任何 `v-if` 分支，会落到默认分支，**不做字典翻译**。
> 表格列要翻译必须写 **`type="dict"`**。（`dictSelect` 是 `dc-form-item` 的 `dcType` 值，
> 两者容易串。）

### `inputParam` 的三种结构

| 用途 | 写法 |
|------|------|
| 字典 | `:inputParam="{ dictCode: 'CDPR0108' }"` |
| 自定义表头 | `:inputParam="{ slot: true, tooltip: '说明文字' }"` |
| 单选 | `:inputParam="{ key: 'xxx', currentRow: {} }"` |

### 它靠 `$parent` 偷表格数据

```js
// dc-base-table-column.vue:151-157
tableData()     { return (this.$parent && this.$parent.tableData) || [] },
columnSetting() { return (this.$parent && this.$parent.columnSetting) || [] }
```

**所以 `<dc-base-table-column>` 的父级必须是那个持有 `tableData` 的页面组件**
（也就是 `dc-form-table` 的直接子层）。中间多包一层组件，宽度自适应的算法就失效了。

列宽算法：中文按 16px、其他按 9px 累加，取 `max(表头宽, 内容宽)`（`:224-244`）。

---

## DcTableColumn — 极简列

`plugin/table-column/table-column.vue`，33 行，`extends TableColumn`，
默认 `showOverflowTooltip: true`。用于**操作列、多选列**：

```vue
<!-- 多选列 -->
<dc-table-column type="selection" width="50" fixed="left" v-if="multiSelectFlag" />

<!-- 操作列 -->
<dc-table-column fixed="right" label="操作" width="180">
  <template slot-scope="scope">
    <el-button @click="handleEdit(scope.row)" type="text" size="small">编辑</el-button>
  </template>
</dc-table-column>
```

> **`tableMixins.getColumnsInfo` 只收集 `dc-base-table-column`**
> （按 `$options._componentTag` 过滤），所以操作列用 `dc-table-column` 不会进列显隐清单——这是刻意的。

---

## DcTableColumnSetting — 列显隐

表头右侧的齿轮按钮，勾选显示哪些列。

```vue
<dc-table-column-setting :columnSetting="columnSetting" />
```

- 读 `columnSetting` 数组（由 `tableMixins.getColumnsInfo()` 自动生成）。
- 内部用 `DcPopover`（页面不用管）。
- 保证至少保留一列。

**配套**：表格要绑 `:key="reloadTable"`，否则切换列之后表格不重建、设置不生效。

---

## DcForm — 表单主体

```js
// cop-ucp-ui/src/plugin/form/form.vue:19-35
props: {
  commonRule: [Object, Array],
  dcColspan: Number,
  labelTitle: Boolean,
  clickButtonFlag: { type: Boolean, default: true },   // 是否显示自带的"保存/返回"按钮行
  suffixFlag: { type: Boolean, default: false },
  labelWidth: { type: String, default: '140px' }
}
```

### 仓库惯例：**关掉自带按钮，自己渲染**

自带按钮行由 `clickButtonFlag` 控制（`form.vue:7-10`，文案走 i18n `$t('save')` / `$t('back')`）。
但**真实业务页几乎都写 `:clickButtonFlag="false"`**，然后在表单上方自己放按钮：

```vue
<div style="text-align: right; padding: 10px">
  <dc-button @click="handleClose">返回</dc-button>
  <dc-button type="primary" @click="handleSubmit" v-if="actionType !== 'view'">保存</dc-button>
</div>
<dc-form :model="formData" ref="fromRule" :dcColspan="8"
         :clickButtonFlag="false" :disabled="actionType === 'view'">
  <dc-form-item ... />
</dc-form>
```

### 🔴 没有 `@submit` 事件

`DcForm` 只 `$emit('submitForm')` 和 `$emit('cancelForm')`（`form.vue:42,54`），
而且**全仓 0 个页面监听它们**。

更麻烦的是 `submitForm()` 的写法：

```js
// cop-ucp-ui/src/plugin/form/form.vue:40-48
submitForm() {
  console.log('submitForm')
  this.$emit('submitForm')          // ← 先 emit
  this.validate((valid) => {
    if (valid) { console.log('YES') }  // ← 校验回调里什么都没做
  })
}
```

**校验不通过也会 emit**，且校验结果没有任何消费方。

**所以别绑 `@submit`（不存在），也别指望自带的校验拦截**——
直接照抄真实页面，自己拿 `ref` 调校验：

```js
handleSubmit () {
  this.$refs.fromRule.validate((valid) => {
    if (valid) { /* 走新增/编辑 */ }
    else { this.$message.error('必填信息没有完成') }
  })
}
```

- `:disabled="actionType === 'view'"` 是查看态的置灰方式。
- **表单 `ref` 不要和查询表单重名**（仓库惯例：表单 `fromRule`，查询 `fromRule2`）。

---

## DcDialog — 弹窗

`plugin/dialog/dialog.vue`，`name: 'DcDialog'`，`extends: Dialog`，37 行。
**template 是从 element-ui Dialog 整段抄过来的，逐行一致**，只多声明了一个 prop：

```js
// cop-ucp-ui/src/plugin/dialog/dialog.vue:28-35
{
  name: 'DcDialog',
  extends: Dialog,
  props: {
    checkLabel: { type: String, default: '' }   // ⚠️ 死 prop，模板里从没用过
  }
}
```

**`checkLabel` 传了没有任何效果**（它属于 `DcCheckbox`，不属于弹窗）。

属性 / 事件 / 插槽全部继承 element-ui Dialog：
`:visible.sync`（就是 v-model）、`title`、`width`、`before-close`、`show-close`、
`close-on-click-modal`、`close-on-press-escape`、`center`、`append-to-body`、
`destroy-on-close`；事件 `open` / `opened` / `close` / `closed`；插槽默认 / `title` / `footer`。

> ⚠️ 示例代码里出现的 `:wrapperClosable="false"` **不是 element-ui 的 prop**，
> 会被当普通属性丢到根元素上，**没有任何效果**。
> 要禁用点遮罩关闭，正确写法是 `:close-on-click-modal="false"`。
>
> Element Dialog 的全局默认 `closeOnClickModal` 已被框架改成 `false`
> （`cop-opr-ui/src/utils/micro.js:57`），业务代码里再写一次是冗余但无害。

```vue
<dc-dialog
  title="新增纸签白名单"
  v-if="addDwConfig.visible"
  :visible.sync="addDwConfig.visible"
  width="600px"
  :before-close="handleDialogClose"
>
  <div class="xin-dw-main">
    <div class="xin-dw-content">
      <dc-form :clickButtonFlag="false" ...> ... </dc-form>
    </div>
    <div class="xin-dw-footer">
      <dc-button @click="handleDialogClose">取消</dc-button>
      <dc-button type="primary" :loading="submitLoading" @click="handleDialogConfirm">确认</dc-button>
    </div>
  </div>
</dc-dialog>
```

**`v-if` 与 `:visible.sync` 同时写是仓库惯例，照抄。**

关闭流程：

```js
handleDialogClose () {
  this.addDwConfig.visible = false
  this.$nextTick(() => {
    this.$refs.addForm.resetFields()
  })
}
```

---

## DcButton — 按钮

**防连点**是它的核心价值。多一个 `timeOut` prop，默认 1000（毫秒）。

```js
// cop-ucp-ui/src/plugin/button/button.vue:48-54
handleTimeOut() {
  let newTime = new Date()
  if (newTime - this.lastTime > this.timeOut) {
    this.handleClick()
  }
  this.lastTime = newTime      // ← 注意：无条件更新
}
```

> ⚠️ **`lastTime` 是「判断之后无条件更新」的**——被吞掉的点击也会把计时往后推。
> 所以这不是「距首次点击 1 秒」，而是「距**最后一次**点击 1 秒」。
> 手指一直点，按钮就一直不响应；被吞的点击也**不会** `$emit('click')`。
>
> 需要「快速连点递增」的场景（数量 +1、翻页）别用它，用原生 `el-button`
> 或传 `:timeOut="0"`。

```vue
<dc-button type="primary" @click="handleAdd">新增</dc-button>
<dc-button @click="handleCancel">取消</dc-button>
<dc-button type="primary" :loading="submitLoading" @click="handleConfirm">确认</dc-button>
```

> ⚠️ `@click` 回调收到的参数是 **`undefined`**（`handleTimeOut()` 调 `handleClick()`
> 时没把原生 event 传下去），不是 DOM 事件对象。

> **唯一例外**：表格**操作列**内的按钮，仓库统一用原生 `<el-button type="text" size="small">`。
> 照抄既有页面即可。

---

## DcDictSelect — 字典下拉

通常不直接用，而是通过 `<dc-form-item dcType="dictSelect" dictCode="xxx">` 间接使用。

直接从 Vuex 读字典，**自己不请求**：

```js
// cop-opr-ui/src/plugin/input/base-dict-select.vue:97-107
computed: {
  ...mapState({ dictMap: state => state.dictStore.dictMap }),
  dictOptions () {
    let { dictCode, isDictFilter, excludeCodes, includeCodes, prependOptions, appendOptions } = this
    if (!dictCode || dictCode === '') {
      return [...prependOptions, ...appendOptions]
    }
    let list = this.dictMap ? this.dictMap[dictCode] : []
    // ...
  }
}
```

字典结构：`dictMap['COP0119'] = [{ label, value }]`，
默认 `labelKey='label'` / `valueKey='value'`。

> ⚠️ 这是唯一被 **PascalCase** 书写的组件——基座 `views/home/loanCalc.vue` 里写了
> `<DcDictSelect>`。其余组件标签一律 kebab-case。

---

## 其他常用件

括号内是**直接写标签**的次数。很多组件平时不直接写标签，而是通过
`<dc-form-item dcType="...">` 间接使用（见下面那张表）。

| 组件 | 用途 | 直接使用 |
|------|------|---------|
| `DcCard` | 卡片容器 | **267** — 最常用的布局件 |
| `DcCollapseItem` / `DcCollapse` | 折叠面板（表单分组） | 149 / 52 |
| `DcText` | 只读文本 | 45 |
| `DcDrawer` | 右侧详情抽屉 | 45 |
| `DcSelect` | 普通下拉（配 `:optionList`） | 32 |
| `DcInputButton` | 输入框 + 按钮组合 | 23 |
| `DcTabPane` / `DcTabs` | Tab 切换 | 20 / 10 |
| `DcUpload` | 上传 | 11 |
| `DcDatePicker` | 日期选择 | 9 |
| `DcThousandSeparator` | 金额千分位 | 7 |
| `DcPopover` | 气泡卡片 | 3 |

> 注意 `DcDatePicker` 直接写标签只有 9 次，但 `dcType="datePicker"` 用了 **71** 次。
> **表单里的输入类组件，优先走 `dcType`，不要直接写标签。**

### 间接使用（只经 `dcType` 到达）

这些组件在**三个应用里都存在**，但页面几乎不直接写标签，而是：

| `dcType` | 组件 | `dcType` 用了多少次 |
|----------|------|-------------------|
| `checkbox` | `DcCheckbox` | 9 |
| `checkboxGroup` | `DcCheckboxGroup` | 11 |
| `radio` | `DcRadio` | 27 |
| `switch` | `DcSwitch` | 13 |
| `cascader` | `DcCascader` | 53 |
| `timeSelect` | `DcTimeSelect` | 9 |
| `timePicker` | `DcTimePicker` | 9 |
| `textarea` | `DcTextarea` | 33 |
| `blankRow` | `BlankRow` | 2 |
| `dictRadio` | `DcDictRadio` | 1 |
| `dictCheckbox` | `DcDictCheckbox` | 1 |
| `isThounsand` | `DcThousandSeparator` | 20 |

### 真正没人用的（**别用**）

`DcDivider`、`DcSettingSearchForm` —— 全仓 **0 处**引用。

`DcMenu` / `DcMenuItem` / `DcSubMenu` —— 只有 3 处，别拿来搭新菜单。

> `DcTextDecimal` / `DcRemoteSelect` **不在这一档**：它们只在 `cop-fsc-ui` 注册
> （`base-text-decimal.vue` / `base-remote-select.vue`），直接写标签 0 处，
> 但通过 `dcType="textDecimal"` / `"remoteSelect"` 实际在用。
> ucp / opr 里**根本没有这两个组件**，别引用。

> 两个 fsc 独有值：`dcType="textDecimal"` / `dcType="remoteSelect"`，在 `cop-fsc-ui` **合法**，
> 在 `cop-opr-ui` / `cop-ucp-ui` 的映射表里**不存在** → 字段渲染成空白（见 `pitfalls.md` P17）。
> 跨应用复制表单项时逐个核对 `dcType`。

---

## 跨应用共享的业务壳

**只由基座注册**（`cop-ucp-ui/src/main.js:12-16`）：

```js
window.commonComponent = { FileDirectory, OperationRecord, signInfoDialog }
```

| 成员 | 用法 | 消费方 |
|------|------|--------|
| `OperationRecord` | `components: { operationRecord: window.commonComponent.OperationRecord }` 然后当标签用 | opr 4 处 / fsc 2 处 |
| `signInfoDialog` | 命令式：`signInfoDialog({ type, query })` | opr 5 处 |
| `FileDirectory` | 已注册，**子应用从未消费** | 仅基座演示页 |

**一律判空**：

```js
const { OperationRecord, signInfoDialog } = window.commonComponent || {}
```

> ⚠️ **`pdfViewDialog` 不在这个对象里**（只有 3 个成员）。
> 三个应用各自实现了一套 PDF 预览——ucp 有基座版，
> opr 自己重写了一份 `viewPdfDialog.vue`，fsc 用 `<object>` 标签。

---

## 修改组件时的铁律

`src/plugin/` 在三个应用里**各有一份拷贝**：45 / 45 / 47 个 `.vue`，
其中 **30 个 byte 级完全相同**、**15 个已经分叉**。

**改之前想清楚**：你改的是当前应用的那一份，另外两个不会变。
`DcBaseTableColumn` 的列宽算法、`DcFormItem` 的 label 折行逻辑、
`DcFtTable` 的分页默认值——都已经在三个应用里长得不一样了。

**需要新能力时**：在页面层组合实现，或在自己的业务组件里包一层。
**不要往公共组件里加业务逻辑。**
