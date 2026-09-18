# Round 12 分析 — Producer 侧契约字段修复验证

> 验证 2026-09-17 第二批改动：`constraint` / `statement` 的 **Producer 侧修复** + Knowledge Directory Contract。
> suite-only，最小集 2 项（A1 analyzer 实跑 / C1 契约驱动编译器）。
> 目标项目 `afc-newcore-web-code`，分支 `benchmark/20260813`，全程零 git 操作。

## 结果总览

| # | 改动 | 判定 | 证据 |
|---|------|------|------|
| 1 | `constraint` Producer 修复（evidence-header 模板 + output-format 字段表） | ✅ **生效** | 新建 3 个 `decisions/` 文件 **3/3** 含 `constraint:`，值均为真硬约束 |
| 2 | `statement` Producer 修复（output-format 字段表 + knowledge-builder 的 frontmatter 契约门） | ✅ **生效** | 新建 `patterns 3/3`、`components 1/1`、`api 1/1` 含 `statement:`，值为可注入的一句话摘要 |
| 3 | verifier Verify 6（契约字段齐备，产不出即 Reject） | 🟡 已执行，未触发拒绝 | agent 报告 V6「均可产出，无因缺字段被拒」——**与产物一致**（8/8 都有字段），故无法区分「V6 起了作用」还是「本来就写得出」 |
| 4 | Knowledge Directory Contract（I1 运行时 + I2/I3/I4 静态） | ✅ **生效** | C1：真实项目上 I1 通过（扫描列表 == 契约）；硬校验按 `KD_ENFORCED` 报缺字段 |

## A1：Producer 真的写契约字段了（核心结论）

**判定方式：不采信 agent 自报，用跑前备份做 diff，新文件与旧文件分开计算。**

| 目录 | 必需字段 | 新建合规 | 旧文件合规 |
|------|---------|---------|-----------|
| `patterns/` | `statement` | **3 / 3** | 0 / 14 |
| `components/` | `statement` | **1 / 1** | 0 / 2 |
| `api/` | `statement` | **1 / 1** | 0 / 3 |
| `decisions/` | `constraint` | **3 / 3** | 0 / 4 |

**新建 8/8 合规，旧文件 0/23 不变。** 这正是预期形态：修复只对**新产出**生效，不追溯存量（见下「存量迁移」）。

**字段值有实质**（不是为过检而写的空壳）——抽查：

| 文件 | 字段值（截断） |
|------|--------------|
| `patterns/quota-end-split.md` | `statement: "双端同源页面靠 window.history.state.pageType 判定 TOE/TOB，同一功能成对调 web/employee/** 与 web/business/** 接口…"` |
| `patterns/quota-limit-category.md` | `statement: "额度种类 limitCategory（01-07）是渲染分区与提交项的主键，limitTypeName 仅作展示；新增额度种类必须同时改…"` |
| `decisions/ARCHITECTURE-quota-limit-category.md` | `constraint: "额度分区、依赖判断与提交项构造一律以 limitCategory（01-07）为键，禁止以 limitTypeName 或…"` |
| `decisions/ARCHITECTURE-quota-mock-hook-drift.md` | `constraint: "接入真实保证金/风险敞口/WFMS 接口时，必须同时删除 useDeposit 与 useExposure 内的前端计算…"` |

`statement` 是可被直接注入的摘要，`constraint` 是「必须 / 禁止 …」的硬约束——与两个字段的设计语义吻合。

> **A1 的 prompt 未提 `statement` / `constraint`**（只给「增量分析 quotaManage 模块 + 写入知识库 + 按 analyzer 流程」）。
> 因此这一结果测的是**skill 文档本身**是否足以让 agent 写出契约字段——不是被 prompt 点名所致。

## C1：契约驱动的编译器在真实项目上成立

| 检查 | 结果 |
|------|------|
| I1（本脚本扫描列表 == 契约 `KD_INDEXED`） | ✅ 通过，无报错 |
| 硬校验按 `KD_ENFORCED` 报缺 | ✅ 报出 8 个（4 `rules/` + 4 `decisions/`），消息含 `KD_ENFORCED="rules:constraint decisions:constraint"` |
| 是否产出 index | ❌ 未产出（被上述 8 个**存量**文件拦下——**预期内**） |
| `statement` 是否被误纳入硬校验 | ✅ 未纳入（`KD_ENFORCED` 只有 constraint）——否则真实项目全部编译失败 |

## 存量迁移（本轮暴露的运维成本，非本轮改动失败）

`constraint` 是**硬校验**，所以任何既有知识库在补上该字段前**都编译不了**——本项目 8 个、前端项目 2 个。

- Producer 修复解决的是「以后不再产出不合规文件」
- **没有解决**「已经存在的不合规文件怎么办」

编译器报错会逐个点名文件、并指向契约与字段写法文档，**是可操作的**，但**迁移动作本身还没做**。建议二选一：
① 提供一次性迁移脚本（为存量 `rules/` `decisions/` 补 `constraint`，内容需人工确认或由 analyzer 反推）；
② 在 analyzer 的增量分析里加一步「顺手补齐存量文件缺失的契约字段」。

## 附带观察（来自 A1 的运行过程）

1. **Phases 6–8（Classifier / Instinct Extract / Promotion Review）未执行**——agent 明确报告既有 `classification-report.yaml` / `instincts.yaml` / `promotion-review.yaml` 是上一次全量扫描的产物，**未覆盖本次 10 个新 candidate**，并说明「不替它们补分数，因为跨项目晋升评分需要独立口径，凭模块级信息补写会污染晋升链」。这是一个**真实的覆盖缺口**，需要显式指派才有人做。
2. **运行环境无 YAML 解析器**（无 pyyaml / yq）——agent 只能对手写 YAML 做结构性检查（缩进/引号配平），无法 parse 验证。这正好印证 check-yaml.sh 采用「宿主有解析器才生效，否则显式跳过并告警」的设计取向是对的：不能假设宿主一定有。
3. 目标项目 KB 是 `afc-newcore-web-frontend` KB 的副本（`manifest.projectName` 一致），与 round1 的既有事实一致。

## 台账判定口径

本轮仍是 **suite-only（无 native 臂）**，故 `pass_fail` 按定义不能填 `pass`。本轮提供的是「Producer 修复后行为确实改变」的正向证据（新建 8/8 vs 基线 0/23），已记入台账。
