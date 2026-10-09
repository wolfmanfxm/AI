# page-spec —— 一份页面的需求规格

> 核心思路：**布局来自真实页面，内容来自需求**。agent 读需求（聊天文字 + 后端接口文档 /
> 原型图截图·蓝湖·Figma / PRD 链接）把它写成一份 `page-spec`，脚本只克隆样板的**骨架**，
> 全部业务内容（搜索项 / 表格列 / 表单项 / 字段默认值 / 字典码 / 接口地址 / 按钮）**由 spec 渲染**。
>
> spec 是**行式文本**，用 `awk` 解析（POSIX sh，不引 Python、不引 YAML）。一份 spec 一个 CRUD 页面。
> **字段清单先审后生成**：写出来让人眼过一遍，比生成完再核对便宜得多。

## 语法总览

```
app        opr                 # 必填：opr / fsc / ucp
domain     contractManage      # 必填：业务域（跑 new-page.sh --list 看该应用现有哪些）
module     vehicleInsurance    # 必填：模块名（小驼峰英文）
title      车辆保险管理          # 必填：菜单中文名
pk         id                  # 必填：主键字段名（影响表格 rowIdKey / 行内编辑定位）
archetype  crud                # 默认 crud，本次只做这一种
pageKey    vehicleInsuranceList
search     vehicleNo  | 车牌号 | text
column     vehicleNo  | 车牌号
form       vehicleNo  | 车牌号 | text     |          | required
api.page   /api/opr/web/vehicleInsurance/page
api.add    /api/opr/web/vehicleInsurance/add
api.update /api/opr/web/vehicleInsurance/change
action     add|新增
action     delete|删除
```

`app/domain/module/title/pk/archetype/pageKey` 是**键行**，`键 SP 值`。
`search` / `column` / `form` / `action` / `api.*` 是**记录行**，字段之间用 `|` 分隔，
字段顺序固定、一个都不能少（缺的格子用空串占位，不能整行变短）。

> **`perm.*` 是硬错误。** 按钮权限码来自菜单配置，不是页面代码该管的事；
> skill 不往产物里写权限码。别在 spec 里写。

## 记录行逐类说明

### search（搜索项）

| 格子 | 含义 | 例子 |
|---|---|---|
| 1 prop | 提交给接口的字段名 | `vehicleNo` |
| 2 label | 搜索框左边的中文标签 | `车牌号` |
| 3 widget | `dcType` 值，必填 | `text` |
| 4 dictCode | 仅当 widget 是 `dictSelect` 时，跟在后面 | `COP0002` |

```
search     vehicleNo  | 车牌号 | text
search     staSteCode | 状态   | dictSelect | COP0002
```

### column（表格列）

| 格子 | 含义 | 例子 |
|---|---|---|
| 1 prop | 列表数据里的字段名 | `vehicleNo` |
| 2 label | 列头中文 | `车牌号` |
| 3 修饰 | `空` = 普通列；`dict` + 第 4 格 `COLUMN` = 字典列 | `dict` |
| 4 dictCode | 第 3 格是 `dict` 时的字典码 | `COP0002` |

```
column     vehicleNo  | 车牌号
column     staSteCode | 状态   | dict | COP0002
```

### form（新增 / 编辑弹窗的表单项）

| 格子 | 含义 | 例子 |
|---|---|---|
| 1 prop | 表单字段名 | `vehicleNo` |
| 2 label | 表单项中文标签 | `车牌号` |
| 3 widget | `dcType` 值，必填 | `text` |
| 4 dictCode | widget 是 `dictSelect` 时的字典码 | `COP0109` |
| 5 required | 标 `required` 则渲染必填校验 | `required` |

```
form       vehicleNo  | 车牌号 | text      |          | required
form       type       | 类型   | dictSelect| COP0109
form       remark     | 备注   | textarea
```

### action（按钮）

```
action     add|新增
action     edit|编辑
action     delete|删除
action     view|查看     # view 只读，够用了
```

CRUD 形态固定是「新增 + 行内编辑 / 删除」；`view` 会生成只读态。**导出 / 导入 / 批量删除
属于未实现的形态**（opr 有 `report-manage/*` 这类参照），这次不做。

### api.*（接口地址）

```
api.page   /api/opr/web/vehicleInsurance/page
api.add    /api/opr/web/vehicleInsurance/add
api.update /api/opr/web/vehicleInsurance/change
```

缺哪一条，哪条就渲染成 `CHANGE_ME` 占位并计入收尾清单。

## 三个应用的合法 widget 词表

词表不是写死的，是**从各应用的 `src/plugin/form-item/form-item.vue` 现读**的
（new-page.sh 与 check-page.sh 用同一段 awk，取法必须一致）。生成前校验：

- 词表里没有的 widget → **在写任何文件之前**报错退出（退出码 1），不留半个目录。
- 目前实测：opr / ucp 各 16 个、fsc 18 个。真值以脚本 `--list` 跑出来为准，
  别凭这份文档的数写进 spec。

## 缺项如何变成 TODO —— 两条路

有完整的 spec → 全量生成。缺字段名 / 字典码 / 接口地址一样可以用 spec 流程，只要按上面
「缺格子填空串」的规则占位，缺的就渲染成标记，不会中断：

| 缺什么 | 产物里出现什么 |
|---|---|
| 某个业务字段（搜索项 / 列 / 表单项整行都没给） | `<dc-form-item … 留 TODO(需求缺失: 表单项)>` |
| `api.*` 少给（如没有 `api.add`） | `service.js` 里 `CHANGE_ME` 占位 + 收尾清单列出来 |
| `dict` 列 / `dictSelect` 没给码 | 该处渲染 `TODO(需求缺失: 字典码)` |

`TODO(需求缺失)` 是**唯一可 grep 的字面量**，`check-page.sh` 按它判 ERR、收尾按它计数。
仓库里既有的裸 `TODO` 注释与此无关，不算。

## 给 agent：一份 spec 的验收

写完后自己先过一遍再生成：

1. **每个 prop 在 search / column / form 里拼写一致**——一个字段的三处名字必须长得一样。
2. **`api.*` 四条齐全**（不需要增删的动作可以把该格留成 `-`，但那也要显式写）。
3. **widget 都在该应用词表里**。
4. **dict 列 / dictSelect 都给了码**；没把握的码宁可空着留 TODO，不要编。
5. **title / module / pageKey 与该域现有页面的命名习惯一致**（跑 `--list` 看）。

## 完整示例（复用本文件开头那份）

```bash
sh .claude/skills/cop-frontend-dev/scripts/new-page.sh \
    --app opr --domain contractManage --module vehicleInsurance \
    --spec path/to/vehicleInsurance-spec.txt
```