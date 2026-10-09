# CRUD 页逐字骨架

本文件所有代码**逐字抄自仓库既有页面**，可直接改字段名复用。
样本来源见每节标注。

---

## 一、目录结构

```
src/views/<业务域>/<模块名>/
├── index.vue                      ← 容器：在"列表"和"表单"之间切换（36 行）
└── components/
    ├── <模块名>List.vue           ← 列表 + 查询 + 操作列（206 行）
    └── <模块名>Info.vue           ← 新增/编辑/查看表单（113 行）
```

接口文件二选一（就近优先）：

- `src/views/<业务域>/service/service.js` —— 域级，多模块共用
- `src/views/<业务域>/<模块名>/service.js` —— 模块级私有

---

## 二、容器 `index.vue`

样本：`cop-opr-ui/src/views/contractManage/contractTemplateManage/contractTemplateConfig/index.vue:1-36`

```vue
<template>
   <!-- 合同模板配置 -->
  <div>
    <component :is="params.where" @jump="jump" :params="params" :formParam="formParam" :actionType="actionType" @back="back" />
  </div>
</template>
<script>
export default {
  data () {
    return {
      params: {
        where: 'contractTemplateConfigList'
      },
      actionType: '',
      formParam: {}
    }
  },
  components: {
    contractTemplateConfigList: () => import('./components/contractTemplateConfigList.vue'),
    contractTemplateConfigInfo: () => import('./components/contractTemplateConfigInfo.vue')
  },
  methods: {
    jump (params, actionType, formParam) {
      this.params.where = params
      this.formParam = formParam
      this.actionType = actionType
    },
    back () {
      this.params.where = 'contractTemplateConfigList'
    }
  }
}
</script>

<style lang='scss' scoped>
</style>
```

**注意**：所有组件都用 `() => import(...)` 懒加载；`params.where` 的初值 = 列表组件的注册名。

---

## 三、列表页 `<template>`

样本：`cop-opr-ui/src/views/contractManage/contractTemplateManage/contractTemplateConfig/components/contractTemplateConfigList.vue:1-73`

```vue
<template>
  <div class="custom-table standard-table-list">
    <dc-form-table>
      <dc-card class="box-card">
        <dc-search-form
          idKey="multipleTable"
          cachePageKey="contractTemplateConfigList"
          :model="searchFormData"
          ref="fromRule2"
          :dcColspan="8"
          @refreshTable="refreshTable"
        >
          <dc-form-item label="模板名称" maxlength="128" prop="tpltNm" dcType="text" />
          <dc-form-item label="模板编号" maxlength="64" prop="tpltNum" dcType="text" />
          <dc-form-item label="模板类型" prop="tpltTpCode" dcType="dictSelect" dictCode="COP0109" />
        </dc-search-form>
      </dc-card>
      <br />
      <dc-card class="box-card">
        <div slot="header" class="clearfix">
          <div class="right-button">
            <dc-button type="primary" @click="handleAdd">新增</dc-button>
          </div>
        </div>
        <dc-ft-table
          :key="reloadTable"
          idKey="multipleTable"
          :height="tableHeight"
          border
          :data="tableData"
          :columnSetting="columnSetting"
          style="width: 100%"
          highlight-current-row
          ref="multipleTable"
          tooltip-effect="dark"
          v-loading="loading"
          :pgPageSize="paginationParam.pageSize"
          :pgCurrentPage="paginationParam.currentPage"
          :pgTotal="paginationParam.total"
          @pageChange="pageChange"
          @select="handleSelectRow"
          @select-all="handleSelectAll"
          @row-click="(row, column, event) => rowClick(row, column, event, 'hoverBox')"
          @selection-change="handleSelectionChange"
        >
          <dc-table-column type="selection" width="50" fixed="left" v-if="multiSelectFlag" />
          <dc-base-table-column label="序号" type="countNumber" />
          <dc-base-table-column prop="tpltNm" label="模板名称" />
          <dc-base-table-column prop="tpltNum" label="模板编号" />
          <dc-base-table-column prop="tpltTpCode" label="模板类型"  type="dict" :inputParam="{ dictCode: 'COP0109' }"/>
          <dc-base-table-column prop="vrsnNum" label="版本号" />
          <dc-base-table-column
            prop="staSteCode"
            label="状态"
            type="dict"
            :inputParam="{ dictCode: 'COP0002' }"
          />
          <dc-base-table-column prop="updUserNm" label="维护人" />
          <dc-base-table-column prop="creaTm" label="创建时间" />
          <dc-base-table-column prop="updTm" label="维护时间" />
          <dc-table-column fixed="right" label="操作" width="180">
            <template slot-scope="scope">
              <el-button v-if="scope.row.staSteCode === '2'" @click="handleEdit(scope.row)" type="text" size="small">编辑</el-button>
              <el-button v-if="scope.row.staSteCode === '0'||scope.row.staSteCode === '2'" @click="handleDelete(scope.row,'enable')" type="text" size="small">启用</el-button>
              <el-button v-if="scope.row.staSteCode === '1'" @click="handleDelete(scope.row,'disable')" type="text" size="small">停用</el-button>
              <el-button @click="viewrate(scope.row)" type="text" size="small">查看</el-button>
            </template>
          </dc-table-column>
        </dc-ft-table>
      </dc-card>
    </dc-form-table>
  </div>
</template>
```

### 五个必须记住的点

1. **`<dc-form-table>` 是最外层**，里面包 `<dc-card>`。
   `DcSearchForm` 靠 `inject: ['dcFormTable']` 反向找表格，外层不是它 → 查询失效。
2. **`idKey` 在 `dc-search-form` 和 `dc-ft-table` 上必须写同一个值**。
   `ref` 必须叫 `multipleTable`（`tableMixins` 硬依赖这个名）。
3. **表格必须 `:key="reloadTable"`**，否则列显隐设置不重建表格。
4. **操作列用 `<dc-table-column>` + `slot-scope="scope"`，按钮用原生 `el-button type="text"`**，
   不用 `dc-button`。数据列才用 `dc-base-table-column`。
5. **字典列是 `type="dict"` + `:inputParam="{ dictCode: 'xxx' }"`**——两层都要写，
   `dictCode` 必须放在 `inputParam` **对象里面**。
   写成平铺的 `dictCode="xxx"` 会落进默认分支，**显示原始码值** `0`/`1`/`2`；
   而 `type="dict"` 配一个没有 `dictCode` 的 `inputParam` 则是**整格空白**；
   `inputParam` 完全不传会**抛 TypeError**（它的 prop 默认值有 bug，见 `pitfalls.md` P5）。

---

## 四、列表页 `<script>`

样本同上 `:75-206`

```js
<script>
import asyncDictMixins from '@/mixins/asyncDictMixins.js'
import tableMixins from '@/mixins/tableMixins.js'
import httpService from '@/views/contractManage/service/service.js'
import searchCacheMixin from '@/mixins/searchCacheMixin.js'

export default {
  mixins: [asyncDictMixins, tableMixins, searchCacheMixin],
  updated () {
    // 框架列表页面底部分页高度
    this.dealHeight('multipleTable')
  },
  data () {
    return {
      // 配置缓存参数（唯一 pageKey）
      searchCacheOptions: {
        pageKey: 'contractTemplateConfigList' // 每个列表页唯一标识
      },
      tableData: [], // 表格数据
      multipleSelection: [], // 选中数据
      loading: false,
      multiSelectFlag: false, // 表格是否可多选
      rowIdKey: 'pyhid', // 列表行数据唯一标识  ← ⚠️ 见下
      searchFormData: { tpltNm: '', tpltNum: '', tpltTpCode: ''} // 搜索数据
    }
  },
  mounted() {
    this.init()
  },
  methods: {
    // 初始数据
    init() {
      // 表格数据
      this.queryWithCache(() => this.queryList())
    },
    /**
     * @description: 获取表格数据
     * @param: paginationParam:分页参数
     */
    queryList() {
      if (this.loading) return
      this.loading = true
      const { paginationParam } = this
      this.tableData = []
      const params = {
        pageSize: paginationParam.pageSize,
        pageNum: paginationParam.currentPage,
        param: {
          ...this.searchFormData
        }
      }
      httpService
        .baseCtrctTemplateInfo(params)
        .then(res => {
          this.tableData = res.data
          this.paginationParam.total = res.total
          this.currentRow = {}
          // 多选时跨页保留勾选状态，单选时不需要
          this.setTableSelected()
        })
        .finally(() => {
          this.loading = false
        })
    },
    // 勾选表格
    handleSelectionChange(val) {
      this.multipleSelection = val
    },
    // 新增
    handleAdd() {
      // 触发jump事件 跳转到新增页面
      this.$emit('jump', 'contractTemplateConfigInfo', 'add', '')
    },
    // 修改
    handleEdit(row) {
      this.jumpWithCache(() => {
       this.$emit('jump', 'contractTemplateConfigInfo', 'edit', row)
      })
    },
    // 查看
    viewrate(row) {
      this.jumpWithCache(() => {
       this.$emit('jump', 'contractTemplateConfigInfo', 'view', row)
      })
    },
    // 启用、停用
    handleDelete(row, type) {
      let tip = ''
      let tipTitle = ''
      let param = row
      switch (type) {
        case 'enable':
        tip = '请确定是否启用该合同模板！'
        tipTitle = '合同模板启用'
        param = {...row, staSteCode: 1}
          break
        case 'disable':
        tip = '请确定是否停用该合同模板！'
        tipTitle = '合同模板停用'
        param = {...row, staSteCode: 0}
          break
        default:
          break
      }
      this.$confirm(tip, tipTitle, {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning',
        closeOnClickModal: false
      })
        .then(() => {
          httpService.baseCtrctTemplateInfoUpdate(param).then(res => {
            if (res.code === 'S000000') {
              this.$message.success(res.msg)
              this.queryList()
            } else {
              this.$message.error(res.msg)
            }
          })
        })
        .catch(() => {
          this.$message({
            type: 'info',
            message: '已取消操作'
          })
        })
    }
  }
}
</script>
<style lang="scss" scoped>
</style>
```

### 关键约定

- **数据字段名必须是 `searchFormData`**——`searchCacheMixin` 默认按这个 key 存取缓存，
  改名 → 搜索条件缓存恢复失效。同时 `queryList` 里直接 `...this.searchFormData`。
- **`searchCacheOptions.pageKey` 每个列表页必须唯一**，两个页面用同一个 → 搜索条件串页。
- **分页字段名会变形**：组件内是 `paginationParam.currentPage` / `.pageSize`，
  **发给后端要叫 `pageNum` / `pageSize`，业务条件塞进 `param` 对象**。
- **响应解构**：`res.data` = 列表数组，`res.total` = 总条数。
- **成功码 `'S000000'`**。
- **`rowIdKey` 默认 `'pyhid'` 是模板遗留值**：如果接口返回的行数据里没有 `pyhid` 字段，
  跨页勾选比对会退化成 `undefined === undefined`，**多选错乱**。
  用多选表时**必须改成你接口里真实存在的主键字段名**。

---

## 五、表单页 `Info.vue`

样本：`.../contractTemplateConfigInfo.vue`

> 🔴 **下面这个样本是仓库里另一种「历史写法」，不是脚手架克隆给你的那种。**
> 实测：真实 opr 仓库的 24 个 `Info.vue` 里，**12 个套了 `<dc-form-table>` / `<dc-card>`、12 个没套**——
> 两种都存在。`new-page.sh` 克隆的 `contractTemplateConfigInfo.vue` 属于「**没套**」那一种；
> 而 `check-page.sh` 对「套了容器」和「`:clickButtonFlag` 不是 `false`」各报一条 ⚠️。
>
> **下面样本只用来看懂既有页面为什么长这样。** 新页面以克隆出来的那份为准
> （`:clickButtonFlag="false"`、按钮自己渲染）；要照抄也别照抄这一段。

```vue
<template>
  <dc-form-table>
    <dc-card>
      <dc-form
        :model="formData"
        ref="fromRule"
        :rules="formRules"
        :clickButtonFlag="actionType !== 'view'"
        :disabled="actionType === 'view'"
        labelWidth="140px"
      >
        <dc-form-item :maxlength="64" label="模板编号" prop="tpltNum" dcType="text" required :rules="verifyRule.AZazNum"/>
        <dc-form-item :maxlength="128" label="模板名称" prop="tpltNm" dcType="text" :rules="true"/>
        <dc-form-item :maxlength="128" label="模板类型" prop="tpltTpCode" dcType="dictSelect"  dictCode="COP0109" :rules="true"/>
        <dc-form-item :maxlength="64" label="版本号" prop="vrsnNum" dcType="text" required :rules="verifyRule.version" style="height:60px;"/>
      </dc-form>
    </dc-card>
  </dc-form-table>
</template>

<script>
import httpService from '@/views/contractManage/service/service.js'
import { verifyRule } from '@/validator/validate.js'
export default {
  data () {
    return {
      verifyRule,                       // ← 必须放进 data 才能在模板里用
      actionType: '',
      formParam: {},
      formData: {},
      formRules: {}
    }
  },
  methods: {
    handleSubmit() {
      this.$refs.fromRule.validate((valid) => {
      if (valid) {
        if (this.actionType === 'add') {
          this.handleAdd()
        } else {
          this.handleEdit()
        }
      } else {
        this.$message.error('必填信息没有完成')
      }
    })
    }
  }
}
</script>
```

### 校验规则的三态

`dc-form-item` 的 `rules` 接受 `String | Boolean | Object | Array`：

| 写法 | 含义 |
|------|------|
| `:rules="true"` | 只表示必填 |
| `:rules="verifyRule.AZazNum"` | 引用 `@/validator/validate.js` 的共享规则 |
| `required` + `:rules="verifyRule.version"` | 必填 + 格式校验 |

`verifyRule` 是一个约 60 条规则的对象（`AZazNum`、`mobile`、`IDNo`、`email`、`uscc`、
`postalCode`、`version`、`pDecimal`、`cnapsCode` 等）。**先 grep 有没有现成的，再考虑自己写正则。**

```bash
grep -n "  [a-zA-Z]*:" src/validator/validate.js | head -60
```

> ⚠️ `cop-fsc-ui` 的 `validate.js` 是 `cop-opr-ui` 的**子集**：
> 缺 `positiveNumber`、`positiveNumberOrZero`、`version`，多 `posInter`、`noAnySpace`。
> 在 fsc 里引用了 opr 才有的规则名 → 校验静默失效。

---

## 六、弹窗（两种模式，照抄同域邻居）

### 模式 A：动态组件切换（主力）

`index.vue` 用 `<component :is="params.where">` 切换，列表 `$emit('jump', 组件名, actionType, row)`。

**回列表刷新机制**：容器切回列表时列表组件**被重建**，触发 `mounted → init() → queryWithCache`
重新查询并恢复搜索条件。表单页的 `handleClose()` **不主动通知列表刷新**——
所以列表组件**不能被 `keep-alive` 缓存**，否则保存后列表不更新。

### 模式 B：列表页内联 `<dc-dialog>`

样本：`cop-fsc-ui/src/views/operator-manage/operator-paperbased-whitelist/white-list/components/whiteList.vue:62-102`

```vue
  <!-- 新增弹框 -->
  <dc-dialog
    title="新增纸签白名单"
    v-if="addDwConfig.visible"
    :visible.sync="addDwConfig.visible"
    width="600px"
    :before-close="handleDialogClose"
  >
    <div class="xin-dw-main">
      <div class="xin-dw-content">
        <dc-form
          :model="addFormData"
          ref="addForm"
          :dcColspan="24"
          :clickButtonFlag="false"
          :rules="addFormRules"
        >
          <el-col>
            <dc-form-item
              label="运营商名称"
              prop="operatorNum"
              dcType="select"
              :optionList="operatorOptionList"
              filterable
              :rules="true"
            />
          </el-col>
        </dc-form>
      </div>
      <div class="xin-dw-footer">
        <dc-button @click="handleDialogClose">取消</dc-button>
        <dc-button type="primary" :loading="submitLoading" @click="handleDialogConfirm">确认</dc-button>
      </div>
    </div>
  </dc-dialog>
```

- `v-if="...visible"` 与 `:visible.sync="...visible"` **同时写是刻意的**，照抄。
- 关闭时要手动重置并在 `$nextTick` 里 `resetFields()`：

```js
handleDialogClose () {
  this.addDwConfig.visible = false
  // 重置数据
  this.$nextTick(() => {
    this.$refs.addForm.resetFields()
  })
}
```

- **确认成功后直接调 `this.queryList()`** 刷新列表——这是与模式 A 最大的差别。
- 表单弹窗里用 `:clickButtonFlag="false"` 关掉 `DcForm` 自带的保存/返回按钮行，
  改由 `xin-dw-footer` 自己渲染按钮。

---

## 七、新增/编辑/查看三态

一个表单组件承载三种动作，靠 `actionType` 区分：

| actionType | 进入方式 | 行为 |
|-----------|---------|------|
| `'add'` | `$emit('jump', 组件名, 'add', '')` | 空表单 |
| `'edit'` | `$emit('jump', 组件名, 'edit', row)` | 回填 row |
| `'view'` | `$emit('jump', 组件名, 'view', row)` | 回填 + `:disabled="actionType === 'view'"` + 隐藏保存按钮 |

回填用 `Object.assign(this.formData, this.formParam)`——**这是就地修改**，
如果 `formParam` 直接传的是列表行对象，改表单会串到列表数据上。
建议 `Object.assign(this.formData, JSON.parse(JSON.stringify(this.formParam)))` 或用展开运算符。
（既有代码直接赋值，照抄时留意这一点。）
