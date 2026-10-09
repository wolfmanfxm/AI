---
name: cop-frontend-dev
description: 在东风畅行 cop-workspace 三应用（cop-ucp-ui 基座 / cop-opr-ui / cop-fsc-ui，Vue 2.7 + Element UI + qiankun 微前端）上做前端功能开发时使用。你读需求（后端接口文档 / 原型图 / PRD）写一份 page-spec；脚本布局克隆自真实页面、业务内容全按 spec 渲染，缺的字段/字典码/接口地址留 TODO，不静默猜。覆盖：新增列表页/详情页/新增编辑弹窗、给既有页面加字段或按钮、对接后端新接口、修前端 bug、跨应用复用组件。产出与现有代码逐字一致、优先复用既有 Dc* 组件。触发场景：新增页面、加个列表、加个查询、加个弹窗、加个字段、调接口、写 service、加路由、配菜单、表格列、表单校验、字典下拉、跨应用引用组件。
---

# cop-frontend-dev — 前端功能开发

这个仓库是 **一套源码、三个应用**：`cop-ucp-ui`（基座）+ `cop-opr-ui` / `cop-fsc-ui`（子应用）。

生成的页面**布局来自真实页面、内容来自需求**：脚本只克隆某个真实页面的**骨架**（imports /
生命周期 / 分页与弹窗管道 / 路由登记，逐字不动），业务内容（搜索项 / 表格列 / 表单项 / 字段
默认值 / 字典码 / 接口地址 / 按钮）**全部由你写的 spec 渲染**，业务的**逻辑不会被样板带过来**
（[references/cloning.md](references/cloning.md)）；缺的字段名 / 字典码 / 接口地址留显式
`TODO(需求缺失)` 标记，不静默猜、也不中断。

---

## 三个要弄清的问题

| # | 问题 | 怎么定 |
|---|------|--------|
| 1 | 属于**哪个应用**？ | `ucp`（基座/系统管理） / `opr`（运营） / `fsc`（金融） |
| 2 | 属于**哪个业务域**？ | 跑 `--list` 看该应用现有的业务域，挑最贴近的一个 |
| 3 | 模块叫什么、菜单叫什么？ | 模块用小驼峰英文（`vehicleInsurance`），菜单用中文（`车辆保险管理`） |

---

## 三步走

### 第 1 步：把需求写成 spec

把需求整理成一份 [references/page-spec.md](references/page-spec.md)：

```
app        opr
domain     contractManage
module     vehicleInsurance
title      车辆保险管理
search     vehicleNo | 车牌号 | text
column     vehicleNo | 车牌号
form       vehicleNo | 车牌号 | text | | required
api.page   /api/opr/web/vehicleInsurance/page
action     add|新增
```

写 spec 后自审：三处字段名**拼写一致**、api.* 齐全、widget 在词表里。拿不准的码**宁可空着留 TODO
也不要编**；语法与各应用词表见 [references/page-spec.md](references/page-spec.md)。

### 第 2 步：从 spec 生成骨架

```bash
sh .claude/skills/cop-frontend-dev/scripts/new-page.sh --app opr --list   # 先看有哪些业务域
sh .claude/skills/cop-frontend-dev/scripts/new-page.sh \
    --app opr --domain contractManage --module vehicleInsurance \
    --spec path/to/vehicleInsurance-spec.txt
```

> 🔴 **CHECKPOINT —— 第一次务必先 `--dry-run`。**
> 这个脚本**会改你的路由文件**（改前自动存 `.bak` 并打印 diff）。先加 `--dry-run` 只预览不落盘，
> 确认 diff 无误后再去掉它重跑。直接跑等于让脚本改你没看过的文件。

> 🛑 **STOP —— 这个脚本会先校验 spec。** widget 不在该应用词表里（比如 `textDecimal` 配 opr）→
> **在写任何文件之前**报错退出、不留半个目录。缺 `api.*` / 字典码不报错，而是留 `TODO` 标记、
> 收尾列出——那是「需求还没给齐」，不是「写错」。

不给 `--spec` 也能跑：生成同样骨架，但每个内容区是 `TODO(需求缺失: …)` 标记，检查逐条报缺——
需求还没到就先立骨架用。

### 第 3 步：机械自查

```bash
sh .claude/skills/cop-frontend-dev/scripts/check-page.sh \
   src/views/contractManage/vehicleInsurance --spec path/to/vehicleInsurance-spec.txt
```

```
应用 cop-opr-ui   合法 dcType 16 个   检查文件 4 个

❌ src/views/.../vehicleInsuranceList.vue:28
   idKey 两边不一致：查询区 "multipleTable"，表格 "tableMain" → 点查询没反应
   → 两边写成同一个值，仓库惯例是 multipleTable

小结：❌ 必须修 1 项   ⚠️ 确认一下 0 项
```

> 🔴 **CHECKPOINT —— 自查不通过就不要提交。**
> 退出码 `0` = 通过，`1` = 有必须修的问题，`2` = 用法/路径错。
> 传 `--spec` 会**顺带查「内容出处」**：产物里的字段 / 字典码 / pageKey 在 spec 里找不到 → ERR
> （说明有样板残留或 spec 拼写不一致）。它查的全是「打包不会失败、只是没反应」那类坑，**不要跳过**。
> ❌ 按每条「→」改完，**重跑同一条命令，直到退出码 0 再往下走**。

> 🛑 **STOP —— 提交前删掉路由备份**：`rm -f <路由文件>.bak`。
> 它只是给你出问题时对照用的。留着不删，`git add .` 会把它一起提交进去。

最后让后端把菜单配上：`menuUrl` **要等于页面文件在 `src/views/` 之后的路径、去掉 `.vue`**——
即 `/<业务域>/<模块>/index`。**漏掉 `/index` → webpack 报模块找不到、页面打不开**（不是"没入口"那么轻）。

---

## 🛟 卡住了怎么办

按现象查。**一线修复**试完还不行，再走**兜底**——兜底那列是「不要再自己猜」的信号。

| 现象 | 一线修复 | 仍失败兜底 |
|------|---------|-----------|
| `new-page.sh` 报「找不到仓库根目录」 | 你大概在子应用目录里跑。`cd` 到仓库根再跑 | 确认根目录同时含 `cop-ucp-ui` 和 `cop-opr-ui` 两个目录 |
| `check-page.sh` 报「路径不存在」 | 站在仓库根要用 `<应用>/src/views/...`；站在子应用里用 `src/views/...` | 用 `new-page.sh` 输出里那条原样命令，别自己拼 |
| 点「查询」没反应 | `dc-search-form` 与表格的 `idKey` 写成同一个值 | 查 [pitfalls.md](references/pitfalls.md) **P2** |
| 列表一直转圈、之后再也不查 | 接口返回的 code 不在白名单 → Promise 永不 settle | 让后端确认返回 `'S000000'`；查 **P1** |
| 某个表单字段整行空白 | `dcType` 写错了（**不报错**） | 跑 `check-page.sh`；对照 [components.md](references/components.md) 的 `dcType` 全表 |
| 字典列显示 `0`/`1` 或整格空白 | `type="dict"` 与 `:inputParam="{ dictCode }"` **两层都要写** | 确认码在 `dictCode.js` 白名单里；查 **P5** |
| 点了「保存」没反应 | 表单上绑了不存在的 `@submit`——去掉它，改自己 `ref.validate()` 调 | 查 **P6** |
| 列显示/隐藏设置不生效 | 表格绑上 `:key="reloadTable"` | 查 **P3** |
| 表格高度塌陷 / 列设置为空 | 表格 `ref` 必须叫 `multipleTable` | 查 **P3** |
| 多选跨页错乱 | `rowIdKey` 还在用模板遗留的 `'pyhid'` | 改成接口真实主键字段名；查 **P3** |
| 子应用页面崩溃 `TypeError` | `window.commonComponent` 消费点加判空 `\|\| {}` | 确认该组件真在 `commonComponent`（**只有 3 个成员**）；查 **P8** |
| 点菜单报「模块找不到」/ 页面打不开 | 菜单 `menuUrl` 与文件路径不符——必须等于 `src/views/` 之后的路径去掉 `.vue`（本脚本生成的页面是 `/<域>/<模块>/index`） | 查 **P9**；直接手输完整 URL 验证路由本身是通的 |
| 侧边栏根本没有这个菜单 | 后端还没把菜单配进 `userNav` | 手输完整 URL 能打开即证明前端已就绪，只差菜单数据 |
| 点某个菜单白屏 | `cop-lsc` / `nbl-union` **不在本仓库**，属预期现象 | **不要**去改 baseURL / ENV / 代理——那不是环境问题 |
| 改了路由但访问 404 | 看 `new-page.sh` 打印的 diff，确认条目真追加进去了 | 从 `.bak` 还原路由文件，重跑一次 |

---

## 三条铁律

1. **不修改 `src/plugin/` 下既有 `Dc*` 组件的源码。** 三个应用各有一份拷贝，你改的只是当前那份。
2. **不新增 `src/` 顶级目录，不另起 HTTP 层。** 请求一律走 `@/axios`，URL 一律放 `service.js`。
3. **不照抄注释掉的代码。** 仓库里大量「注释掉但看起来是活的」代码，**都是死的**。

---

## 参考文件（遇到具体问题再查，不要通读）

| 文件 | 什么时候看 |
|------|-----------|
| [references/page-spec.md](references/page-spec.md) | **写 spec 之前**——语法、每类行、合法 widget 词表、缺项怎么变 TODO、验收清单 |
| [references/pitfalls.md](references/pitfalls.md) | 上面「卡住了」表里指向 P1–P18 的那些，或线上出现「没反应」类问题时（每条带源码行号） |
| [references/components.md](references/components.md) | 想知道某个 `Dc*` 组件有哪些 props / 事件 / 槽位，或查合法 `dcType` 值时 |
| [references/conventions.md](references/conventions.md) | **脚本盯住的 11 条静默失败规则**、**三应用差异全表**、service/路由/字典/校验/分页/导出的完整约定 |
| [references/crud-page.md](references/crud-page.md) | 想手改骨架、或要写弹窗式的页面时 |
| [references/checklist.md](references/checklist.md) | 提交前人工过一遍 |
| [references/cloning.md](references/cloning.md) | 想知道骨架从哪来、内容从哪来、样板退化了怎么办、残余怎么判 |

> 如果你在代码里看到与本文档不符的写法，**以代码为准**，并优先照抄离你最近的那个既有页面。
