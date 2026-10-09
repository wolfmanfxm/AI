# Darwin Skill 2.0 — Phase 3 优化报告：`cop-frontend-dev`

> 时间：2026-09-30
> 模式：**Production**（yao-meta-skill）
> 版本控制：**文件备份**（仓库非 git，且用户明确「不要使用 git 提交任何代码」）
> 回滚点：`.claude/skills/.darwin-backups/cop-frontend-dev.20260930-1645/`

---

## ⚠️ 先读这一节：本报告的三条方法论限制

写在前面的原因是——**这三条限制决定了下面所有分数该怎么读**。不先读它们，分数会被误读成它不支持的结论。

### 限制 1：前测与后测**不是同一批评委**

darwin 的棘轮机制假设「同一个评委、前后各评一次」。本次**不满足**这个假设：

| | 前测 | 后测 |
|---|---|---|
| 评委 A / 1 | 76.5 | 79.3 |
| 评委 B / 2 | 64.1 | 72.2 |

**两组评委是不同的 agent 实例。** LLM-as-judge 的评分本身方差很大（SkillLens 论文实测准确率仅 46.4%），
所以「79.3 > 76.5」这个差值里，**有多少来自改动、有多少来自评委换人，无法分离**。
正确的读法是：**两组独立评分都落在 70–80 区间，没有出现退化**；而不是「精确提升了 5.5 分」。

### 限制 2：后测评的是**已修好 menuUrl 的版本**，而 round-2 的修复发生在**评分之后**

时序：

```
round-1 评委评分  →  按评委意见修  →  round-2 复评  →  又修了一批（未再评分）
                                          ↑                         ↑
                                     分数来源                  当前交付版本
```

**当前磁盘上的版本，没有被任何评委评过分。** 后测分数对应的是一份中间态。

### 限制 3：`eval_mode` 的诚实标注

darwin 规定 `eval_mode` ∈ {`full_test`, `dry_run`}，并要求 dry_run 比例 > 30% 触发评估失效警告。
本次：**有真实评测**（iteration-1 三用例实跑，见 `reports/output_quality_scorecard.md`），
但**该评测跑的是优化前的版本**，不是优化后的版本。

因此这一行在 results.tsv 里标 `full_test`（确实跑了子 agent 实测），
**但报告在此明确声明：它验证的是旧版本，对新版本不构成证据。**
这不算 dry_run，但也不等于「优化后已验证」——这是个 darwin 两分法覆盖不到的状态。

---

## 一、总览

| 项 | 值 |
|---|---|
| 优化 skills 数 | **1**（`cop-frontend-dev`） |
| 评审轮次 | 2 轮（round-1 基线 + round-2 复评），每轮 2 名独立评委 |
| 评委 agent 总数 | 4（去重后 4 个独立实例，无自评——满足黑名单 #1） |
| 保留改进 | **8 项**（全部保留，0 项被驳回） |
| 回滚次数 | **0** |
| 实测验证 | 1 次完整评测（iteration-1：3 用例 × 2 组 = 6 次实跑）+ 3 页真实仓库回归 —— ⚠️ 评测沙箱与评分器已于 2026-09-30 清理，见 §八 |
| 交付版本是否经评委评分 | ❌ **否**（见限制 2） |

---

## 二、分数变化

```
┌──────────────────────┬────────┬────────┬────────┐
│ Skill                │ Before │ After  │ Δ      │
├──────────────────────┼────────┼────────┼────────┤
│ cop-frontend-dev     │  70.3  │  75.8  │  +5.5  │  ← 均值（口径见下）
│   ├─ 评委 A → 1      │  76.5  │  79.3  │  +2.8  │
│   └─ 评委 B → 2      │  64.1  │  72.2  │  +8.1  │
└──────────────────────┴────────┴────────┴────────┘
       ⚠️ 每一行的前后是不同评委，Δ 不可作精确提升量读（限制 1）
```

**结论（严格表述）**：两轮独立评分均落在 70–80 区间，
**没有证据表明本次优化造成了质量退化**；
**也没有足够证据表明它带来了可量化的提升**。后者需要同批评委的前后测，本次未做。

---

## 三、主要改进（8 项，全部保留）

### 🔴 高影响：两处会导致构建失败的缺陷

**1. `menuUrl` 语义错误 —— 全链路修正（5 处）**

原文档写「`menuUrl` 必须逐字等于 `/<业务域>/<模块>`」，**漏了 `/index`**。
真相：`router.js:94` 是 `` import(`@/views${menuUrl}.vue`) ``，所以 `menuUrl` **就是文件路径**。
生成的文件是 `src/views/<域>/<模块>/index.vue`，漏掉 `/index` → webpack 报模块找不到、页面直接打不开。

修正点：`SKILL.md` ×2、`scripts/new-page.sh` ×2、`references/pitfalls.md`（P9 重写 + 新增 `/view` 辨析小节）、
`scripts/check-page.sh` ×1。

同时澄清了一个高混淆点：URL 里的 `/view` 段属于**基座路由表**，**不属于 `menuUrl` 字段**。
（并发现仓库唯一的菜单样例 `mocks/.../userNav.json` 写的 `/view/show-case/table-up` **与代码不符**——
既多 `/view` 又少 `/index`。已作为**证据冲突**记录，要求交付时向后端菜单负责人确认，**未擅自断言**。）

**2. ucp 模板引用了不存在的文件 —— 新增专用变体**

> ⚠️ **后续变更（1.3.0，2026-10-08）**：`assets/` 整个目录已删除，骨架改为从各应用的一个**真实页面**克隆。
> 本段提到的两份模板文件在仓库里已不存在，本条修复被「按 app 克隆样板页 + 生成前样板守卫」取代。
> 现存做法见 [references/cloning.md](../references/cloning.md)。

`assets/list-page-template.vue` 里 `import searchCacheMixin from '@/mixins/searchCacheMixin.js'`，
但 **`cop-ucp-ui` 根本没有这个文件**（只有 opr/fsc 有）。用该模板在 ucp 建页 → 打包报模块找不到。

修正：新增 `assets/list-page-template.ucp.vue`（去掉缓存层的忠实变体），
`new-page.sh` 按 `--app` 自动选模板（ucp 用 ucp 版，opr/fsc 用原版）。
已验证：`--app ucp` 产出 `mixins: [asyncDictMixins, tableMixins]`；`--app opr` 产出含 `searchCacheMixin`。

### 🟡 结构性：让同类问题在自查阶段暴露

**3. `check-page.sh` 新增「import 模块存在性」通用守卫**

不只修掉上面那一个实例，而是补上**能拦住这一整类问题**的检查：
抓出所有 `from '@/...'` / `require('@/...')` / `import '@/...'`，
逐个在当前应用里找文件，找不到就报错。

**真实仓库回归验证（0 误报）**：

| 页面 | import 误报 | 自查小结 |
|---|:---:|---|
| `cop-ucp-ui/.../show-case/table-up` | **0** | ❌ 必须修 2 项 |
| `cop-opr-ui/.../contractManage/contractApply` | **0** | ❌ 必须修 0 项 |
| `cop-fsc-ui/.../operator-manage` | **0** | ❌ 必须修 64 项 |

且已验证它能抓到本应抓的那个缺陷：
`❌ import 的模块在本应用不存在：@/mixins/searchCacheMixin.js → 找不到 cop-ucp-ui/src/mixins/searchCacheMixin.js`

（`operator-manage` 的 64 项是**既有的历史写法偏差**，不是误报——该目录是旧代码，本就不符合新规范。）

**4. 补上「修复回路」** —— 两名评委都指出：原文说了「自查不通过不要提交」，
但**没说改完要重跑**。已在 `SKILL.md` 第 3 步 CHECKPOINT 补：按建议改 → **重跑同一条命令** → 直到退出码 0。

### 🟡 事实性：三应用差异的四处纠正

**5. 跨应用差异全表（`conventions.md` §八）新增 5 行 + 修正 3 处**

| 维度 | 纠正后 |
|---|---|
| `searchCacheMixin` | ucp **没有这个文件**（原文档未区分） |
| 搜索条件缓存使用处 | ucp **0** / opr 15 / fsc 11 |
| `storeage.getItem` | ucp **只读 session**；opr/fsc **回落 local**（原文档按 ucp 的写法当成了全仓规律） |
| `IS_MOCK` 实际行为 | **opr 真的会加载 mock**（开关 true + require 活的）；ucp/fsc 不会 |
| `type="slot"` | ucp 分支被注释；**opr/fsc 是活代码**（原文档写成「不能用」） |

**6. 数字纠错**（原文档的数字与代码不符）

`109 → 230`（两处）、`91 → 94`、`207 → 206`、`136/52 → 149/52`、`400 → 52`。
其中一处改为**不写死数字**并给出复核命令——因为写死的数字一定会再次过期。

**7. `components.md` 的一处自相矛盾** —— 原文同时写「全仓 1372 处」和「21 处 `:sortable`」，无法同时成立。
改为可复核的表述。

### 🟢 工程化

**8. 两份新报告 + `manifest.json`**

- `reports/context_budget_deviation.md`：**如实记录一项未消解的偏离**（见下节）
- `reports/output_quality_scorecard.md`：逐用例评测结果 + 计算口径 + `missing evidence` 清单
- `manifest.json`：`input_files` 13 条、`context_budget_note` / `context_budget_measure`

---

## 四、未完成项 / 待人工裁决

> 以下**不是「已解决」**，是**明确挂起**。列在这里是为了不让它们被「报告写完」掩盖。

| # | 事项 | 状态 |
|---|---|---|
| 1 | **SKILL.md 上下文预算超标** | 🔴 **未消解**。yao Production 上限 1000 token，实测 **~1980（1.98×）**。已从 182 行 / 2336 压到 135 行 / 1980（挪走两张表 + 2026-10-08 措辞清理）。进一步压缩会牺牲可用性。**本报告不主张该偏离已被批准**，需人工裁决 |
| 2 | **交付版本未经评委评分** | 🟡 见限制 2 |
| 3 | **前后测非同一评委** | 🟡 见限制 1，Δ 不可精确读 |
| 4 | **评委 2 指出的 `promised_but_missing`** | 🟡 frontmatter 承诺但正文薄弱：①「导入」仅 §2.2 一行、检查清单无此项 ②「给既有页面加字段/按钮」无专章 ③「详情页」`crud-page.md` 未覆盖只读形态 ④**配菜单字段语义**只写了组件怎么消费，**没写后端该填什么**（`menuNm`/`menuUrlLv1`/`menuUrlLv2`/`menuicn`/`noTag`/`buttonChildren`） |
| 5 | **文档冗余（评委 2 指出）** | 🟡 未清理：「三条铁律」在 `SKILL.md:114-118` 与 `conventions.md:377-381` **逐字重复**；`components.md:295` 与别处同名标题内容不同；`dcType` 警告重复 5 处；`dcTotal 默认 3` 重复 2 处；`closeOnClickModal` 重复 2 处 |
| 6 | **`userNav.json` 与代码不符** | 🔴 需**向后端菜单负责人确认**后方可定稿（见改进 #1） |

---

## 五、回滚说明

**本次 0 次回滚。** 8 项改动全部保留。

回滚机制已就位但**从未触发**：仓库非 git，故按 darwin 的降级路径用**文件备份**代替 `git revert`。
回滚点已从易失的 `/tmp` **迁移到持久位置**并校验一致：

```
.claude/skills/.darwin-backups/
├── SKILL.md.bak.20260930-1645
└── cop-frontend-dev.20260930-1645/     ← 全量快照，12 个文件，与 /tmp 原件 diff 一致
```

**一键回滚**：

```sh
cp -R .claude/skills/.darwin-backups/cop-frontend-dev.20260930-1645/. \
      .claude/skills/cop-frontend-dev/
```

> 备份放在**技能目录之外**（`.claude/skills/.darwin-backups/`），
> 避免其中的 `SKILL.md` 被技能加载器当成第二个技能。

---

## 六、零 git 写入声明

全流程**未执行任何 git 写操作**。仅用过只读查询（`git status` / `git ls-tree` / `git log`）来核实
`src/views/view/` 从未存在、以及三个应用工作树干净。符合用户约束「不要使用 git 提交任何代码」。

---

## 七、成果卡片

darwin 的 `templates/result-card.html` **未随该 skill 一起提供**（已核验：bundled 内容只有 `SKILL.md`、
`results.tsv`、`references/runtime-neutrality.md`、`references/skilllens-evidence.md`、`scripts/screenshot.mjs`）。

**故本次不生成可视化成果卡片**——自己造一个 darwin 未定义的格式没有意义。
本 Markdown 报告即为交付物。

---

## 八、清理记录（2026-09-30 追加）

用户要求「清理冗余内容，还有测试案例相关残留也一起清理」。两件事分开做：

### 8.1 文档冗余（6 处，全部消解）

| # | 冗余 | 处理 |
|---|------|------|
| 1 | 「三条铁律」在 `SKILL.md:116` 与 `conventions.md:380` **逐字重复** | 保留 `SKILL.md` 为唯一正本；`conventions.md` 改为指向 `../SKILL.md` 的短引用 |
| 2 | `components.md` 里的 `### 三条铁律` **与上条同名但内容无关**（实为 dcType 三个易错点） | 标题改为 `### dcType 的三个易错点`，消除撞名 |
| 3 | `dcTotal 默认 3` 在 `components.md` 出现 2 次（逐字相同） | 保留紧邻 `dc-search-form` 示例的那处，删另一处 |
| 4 | `closeOnClickModal 已被框架改成 false` 在 `components.md` 出现 2 次 | 保留讨论 `:close-on-click-modal` 的那处，删另一处 |
| 5 | `components.md` **自身**在相距 20 行处有两个近乎相同的 `dcType` 静默失败警告块 | 合并为一个，并指向 `pitfalls.md` **P17** 作为完整正本 |
| 6 | 跨应用 dcType 警告散落 3 处 | `pitfalls.md` P17 为正本；`components.md` / `conventions.md §八` 各自保留一行短引用（属查阅点的正当重复） |

> 复核方式：对 6 个文档做「长度 > 30 的非平凡行跨文件比对」，**已无逐字重复**。

### 8.2 测试案例残留（全部移除）

| 目标 | 体积 | 说明 |
|------|------|------|
| `.claude/skills/cop-frontend-dev-workspace/` | 488K / 50 文件 | **评测沙箱泄漏进了真实仓库**。内含 3 个 **Python 评分器**（`graders/grade_eval*.py`）、`iteration-1/benchmark.{json,md}`、6 个 `with_skill`/`without_skill` 沙箱输出 |
| `cop-frontend-dev/evals/` | 8K | 用例定义 |
| `cop-frontend-dev/test-prompts.json` | 4K | 用例摘要——**是 `evals.json` 的派生副本，纯冗余** |
| `/tmp/cop-eval/` | **455M** | 六个评测沙箱 |
| `/tmp/cop-frontend-dev-workspace/`、`/tmp/cop-opt/` | 192K | 草稿与已迁移的备份副本 |
| `.claude/skills/.DS_Store` | 8K | macOS 垃圾文件 |

**两点必须说明**：

1. **Python 评分器出现在仓库里本身就是个缺陷** —— 用户明确要求过「脚本不要使用 Python，后端不一定安装了」。
   那三个 grader 是我自己的测量工具、不进交付路径，但既然落在仓库里且技能目录旁边，就是隐患。已删。
2. **删掉后，评测数字暂时无法在本机复现。** 已在 `manifest.json` 用 yao 的字面标签如实标注：
   `"reproducibility": "missing evidence —— 评分器与沙箱已删除，上述数字目前无法在本机重跑复现"`。
   用例定义 `evals/evals.json` 在回滚快照 `.claude/skills/.darwin-backups/cop-frontend-dev.20260930-1645/evals/`
   里留有副本，需要时可取回。

**未删除**：`cop-*/src/plugin/form/ft-form.bak`（已 `git ls-files` 确认是**仓库既有的被跟踪文件**，不是测试残留）；
`.claude/skills/.darwin-backups/`（回滚点，见 §五）。

### 8.3 清理后的连带修复

- `manifest.json`：删掉指向已不存在文件的 `evals` 键，改为 `verification_history`（保留结果、标注不可复现）
- `output_quality_scorecard.md`：沙箱与评分器行加「已删除」标注
- `agents/interface.yaml`：`version` 1.1.0 → 1.2.0（原本已过期）
- 全部相对链接复核可达
