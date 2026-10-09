# 骨架从哪来，内容从哪来

> 这份文档是**维护者视角**，讲克隆模型的骨架/内容来源、样板页是哪几个、
> 内容区在哪、残余怎么判、换代了怎么办。使用者只需要：读需求 → 写 `page-spec` → 生成。

## 0. 一句话模型

**布局来自真实页面，内容来自需求。**

- **布局**（imports / mixins / 生命周期 / 分页与弹窗管道 / 容器与路由登记）→ 从一把**样板页**逐字克隆。
- **内容**（搜索项 / 表格列 / 表单项 / 字段默认值 / 字典码 / 接口地址 / 按钮）→ 全部由 `page-spec` 渲染。
- 需求里还没有的东西 → 留显式 `TODO(需求缺失)` 标记，不静默猜、也不中断。

## 1. 为什么内容不随样板带过来

样板页里 **31%–34% 的行是业务内容**，并散落在 **6 处以上**：

| 业务内容位置 | 样例 |
|---|---|
| ① 搜索项 markup（`<dc-form-item …/>` 段） | List.vue 里 `dc-search-form` 内 |
| ② 表格列 markup（`<dc-base-table-column …/>` 段） | 表格标签内 |
| ③ 表单项 markup（`<dc-form-item …/>` 段） | Info.vue / form.vue 的 `dc-form` 内 |
| ④ `data()` 里 `searchFormData` / `formData` 默认值 | 对象字面量 |
| ⑤ 查询 / 分页方法里的字段映射 | 方法体内 |
| ⑥ 硬编码常量（字典码、角色码数组、`pageKey`、`cachePageKey`、校验规则、确认弹窗文案） | 散落各处 |

实测比例（整份 `*List.vue` + `*Info.vue` / 对应 ucp 文件）：opr 355 行里约 **110** 行、
fsc 773 行里约 **238** 行、ucp 715 行里约 **245** 行。所以「克隆整份再逐项清理」是把 6 处人工核对
推给读不了 Vue 的后端使用者——与 skill 的定位直接冲突。

因此脚本**只克隆骨架**（上面那些 imports / 生命周期 / 管道，逐字不动），
业务内容**全部由 spec 渲染**，缺的留 TODO。于是**残余判定变成可计算的**：
产物里的业务标识符必须都能在 spec 里找到（见 §6）。

## 2. 样板页：三个应用各一把（形态注册表）

表单注册表在 `scripts/new-page.sh` 的 `exemplar_for()`（`case "$APP:$ARCHETYPE"`）：

| 应用:形态 | 样板页 | 产出 |
|---|---|---|
| `opr:crud` | `src/views/contractManage/contractTemplateManage/contractTemplateConfig` | `index.vue`(容器) + `components/<M>List.vue` + `components/<M>Info.vue` + `service.js` |
| `fsc:crud` | `src/views/region-manage/region-manageInfo` | 同 opr |
| `ucp:crud` | `src/views/system-manage/organization-manage/role-manage/role-group` | `index.vue`(**列表**) + `form/form.vue`(**新增/修改**) + `service.js` |

**三个应用是三套不同结构，一份模板覆盖不了**：

| | 切换 List / 表单的方式 | 证据 |
|---|---|---|
| `opr` / `fsc` | 容器 `index.vue` 内 `<component :is>` + `@jump` / `@back` | `index.vue` 里绑 `@jump` 的：opr 14 个、fsc 16 个、**ucp 0 个** |
| `ucp` | 列表与表单是**两条独立路由**，表单在 `form/form.vue` | `form/` 子目录：**ucp 8 个、opr/fsc 0 个** |

## 3. 内容区边界与渲染规则

内容区替换的是「标签的**子元素**」，不是整个标签。样板开标签的属性是**骨架**，逐字保留。
例如 opr 的 `contractTemplateConfigList.vue`（约 5–16 行）：`<dc-search-form>` 的开标签属性
（`idKey` / `ref` / `:model` / `:dcColspan` / `@refreshTable`）逐字保留；
被替换的是它下面那几个 `<dc-form-item …/>` 子元素。这些子元素是**带 props 的自闭合单行
**（`dcType="text"` / `dcType="dictSelect" dictCode="COP0109"`），从 spec 行渲染是可靠的字符串拼接，
不需要解析嵌套模板。

| 内容区 | opr / fsc | ucp | 脚本动作 |
|---|---|---|---|
| 搜索项 | `List.vue` 里 `<dc-search-form>` 到 `</dc-search-form>` 之间的 `dc-form-item` 段 | `index.vue` 同位置 | **整体替换** |
| 表格列 | `List.vue` 表格内的 `<dc-base-table-column>` 段（selection 列保留） | `index.vue` 同位置 | **整体替换** |
| 表单项 | `Info.vue` 的 `dc-form-item` 段 | `form/form.vue` 的 `dc-form-item` 段 | **整体替换** |
| `data()` 默认值 | `searchFormData:` / `formData:` 对象字面量 | 同 | **整体替换**（键来自 spec） |
| `service.js` | 3 个导出 + spec 给的 URL | 同 | **整份生成** |
| `pageKey` / `cachePageKey` | 按模块名算 | 同 | 替换 |
| 查询/分页方法体内的字段映射 | 方法体 | 同 | **删样板特有的 + 只报告**——需求特有的由 agent 补 |
| 业务条件（`staSteCode === '2'`、`roleCodes:[…]` 等） | 表达式 | 同 | **删掉并留 TODO**——别把别人的业务逻辑带过来 |

同一个 `<dc-card>` 的 `slot="header"` 里那排按钮（`新增` + 行内`编辑/删除`）属于**骨架**
（CRUD 形态固定），不是内容区。`button 清单` 这个 spec 键不存在；需求要「导出 / 导入 / 批量删除」
属于未实现的形态，按 §2 的诚实说明，不做。

## 4. 克隆哪些文件：走引用图，不是写死清单

`collect_reachable()` 从样板 `index.vue` 出发，顺着引用收集文件：

- **相对引用** `'./x'` `'../x'` —— 走文件系统
- **绝对引用** `'@/views/...'` —— **只跟指向样板自己目录的那些**。
  指向别处的（业务域级共享 `service/service.js`、`@/mixins`、`@/utils`）不跟：那是仓库公共资源。

写死「index + List + Info」会漏掉辅助文件。走引用图就不会漏；样板里没人引用的孤立文件
也不会被带进来。因内容区整体替换成功后，样板自己的字段/字典码天然不进场。

## 5. 残余判定：可计算的内容出处检查（交付判据）

`check-page.sh <模块> --spec <spec>` 新增「内容出处」检查：把产物里**承载业务含义的标识符**抽出来，
逐个要求能在 spec 里找到——

- `searchFormData.X` / `formData.X` 的键
- `prop="X"`（内容区里的 prop）
- `dictCode="X"` / `dictCode: 'X'`
- `pageKey` / `cachePageKey` 的值

抽出的任何一个不在 spec 里 → **ERR**（按构造不该有样板残留）。
不传 `--spec` 时跳过该项并明确说「未校验内容出处」（无 spec 阶梯，见 §7）。

**盲点（写进文档，不假装全覆盖）**：方法体里的业务条件（`scope.row.staSteCode === '2'`）不在上述
任何一类，抽不出来。脚本对它只能「删样板的 + 留 TODO」，无法判断 agent 后补的逻辑对不对。
这是明确不做全覆盖的边界。

## 6. TODO 字面量协议

`TODO(需求缺失)` 是唯一可 grep 的标记字面量，仓库里既有的裸 `TODO` 注释不算。
模板里写 `<!-- TODO(需求缺失): 搜索项 -->`、`service.js` 里写 `// TODO(需求缺失): api.add`。
`check-page.sh` 按这个字面量判 ERR，不与既有注释混淆。

## 7. 两条路：有 spec / 没 spec

- 有 `--spec spec.txt` → 完整生成，内容全部来自需求，收尾只列真正的缺项。
- 不给 `--spec` → 生成同样骨架，但每个内容区只有 `TODO(需求缺失: 搜索项)` 这类标记——
  需求还没到就先把骨架立起来用。

两条路都不产生「样板带过来的东西」清单——那个清单连同它的失败模式一起消失。

## 8. BSD awk 的坑（维护 new-page.sh / check-page.sh 时看）

macOS 自带的 BSD awk 与 GNU 不一样，改脚本前要知道：

- **`\(` `\{` 在动态正则里报「illegal primary」。** 要匹配字面括号就写字符类 `[(]` `[{]`。
- **空 pattern `$0 ~ ""` 匹配一切。** 别用它当跳过条件。
- **`while read` 会跳过没有结尾换行的最后一行。** 收尾用 `printf '%s\n'` 兜底。
- **shell 词分裂会拆掉含空格的 pattern。** 用 `split_list` + `while IFS= read -r`。
- **`replace_region_excl()` 两端都删。** anchor 行本身也被吃掉——所以 fsc 的内容区结束锚
  要写成 `'^ *</dc-form>$'`（连开标签一起删，不然旧 `<dc-form ` 开标签把新区域带错位）。
- **`drop_lines()` 按子串删行，遇带不配平花括号的方法签名会错位。** 已加净花括号断言，
  非零即报错；要删整个方法请配 `INFO_DROP_HOOKS` / `drop_brace_block`。

## 9. 样板页换代了怎么办

1. 按 §2 的注册表挑新样板（结构对 + 内容区锚点在这类结构里成立 + 自成一体 + 体量小）。
2. 改 `new-page.sh` 里 `exemplar_for()` 与 `case "$APP"` 的常量
   （`EXEMPLAR_REL`、三个内容区的锚点行、`IDENTITY_SUBST` / `TITLE_LITERALS`）。
3. 改 `check-page.sh` 里内容出处抽取若依赖样板特有写法的地方。
4. 更新本文档 §2 的表与 §3 的差异清单。
5. 在 `/tmp` 的仓库副本上三应用各跑一次 `--dry-run` + 真跑 + `check-page.sh --spec`，
   确认产物结构对、样板标识符 0 命中。

> **新形态（树+列表、主从详情）不是加一行 case 的事。** 每个形态都要定义自己的内容区与渲染规则。
> opr 侧已确认存在的候选（`report-manage/*` 导出型、`*-audit` 只读型）记在 §2 的诚实说明里
> 备查，本次不实现。