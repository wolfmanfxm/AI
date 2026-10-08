# KB Structure Comparison Report

> 同一套 `project-analyzer`（v1.3.1，两项目 `.claude/skills/` 均符号链接到同一份）在两个真实项目上的产出对比
> | 2 projects evaluated | 6 根因定位 | 3 处修复验证 | 2026-10-08 复核：畅行已回填至契约全绿（见 §1b / §3c）

## Summary

| Metric | Severity | Value |
|--------|----------|-------|
| 评估项目数 | — | 2 |
| 产出规模比（文件数） | 🔍 已收敛 | 160 : 110（1.5×）｜**修复前** 160 : 24（6.7×） |
| 产出规模比（md/yaml/json 行数） | 🔍 已收敛 | 40,010 : 26,414（1.5×）｜**修复前** 40,010 : 6,692（6.0×） |
| 契约目录符合度（东风汽金） | ❌ 缺陷 | 12/14 |
| 契约目录符合度（东风畅行） | ✅ 已收敛 | 14/14（2026-09-30 回填）｜**修复前** 1/14 |
| 固定根产物在位（汽金 / 畅行） | ✅ 已收敛 | 6/6 : 6/6｜**修复前** 6/6 : 1.5/6 |
| 声明 `completed` 但违反契约 | ❌ 缺陷 | 1/2（仅汽金）｜**修复前** 2/2 |
| 独立共现的产出结构清单 | ⛔ 硬冲突 | 5 处（目录集合各不相同） |
| 孤儿规格（零 stage 引用） | ⛔ 硬缺陷 | 2 份（`finish-workflow.md` / `capability-matrix.md`） |
| **静默删除的能力**（项目级 CLAUDE.md 入口） | ⛔ 硬缺陷 | 1 条规格（4 次削弱，见 R6） |
| `INDEX.md` / `index.md` 大小写分歧 | ❌ 缺陷 | 15 处 / 8 份文件写大写（`git grep -c` HEAD 实测） |
| 阻断式门禁 | — | 修复前 0 个 → 修复后 2 个 |
| `manifest.json` 满足 schema | ✅ 已收敛 | 汽金 ✅ : 畅行 ✅（回填后含 `contract`/`knowledge`/`verification` 段）｜**修复前** 畅行 ❌ 缺 4/5 required |

**结论（一句话）**：差异**不是** agent 能力问题，也**不是** skill 版本问题——是**技能规格自相矛盾**：
「产出哪些目录」在 5 处各自声明且互不相同，唯一规定「4 个根 JSON 每次必生成」的规格文档是孤儿，
而所有既有检查都「只标注不阻断」。于是**产出形态由 agent 的临场取舍决定**，两个项目各选了一份清单。

**复核补充（2026-10-08）**：修复落地后，**畅行被回填重建为契约全绿**（14/14 目录 + 6/6 根产物，
规模 24 → 110 文件）——即两个项目不再各选一份清单，而是收敛到同一份契约。这是本报告唯一一条
**来自真实项目的行为改变证据**（详见 §1b / §3c）。汽金因是**人工维护的可持续库**，未被本轮修复回溯
（仍 12/14，缺 `recommendations/` `conventions/`）。

**R6 补充（2026-10-08）**：同一病理还有更隐蔽的一面——**规格生效过，然后被删**。项目级 CLAUDE.md
入口能力在 4 次「优化」提交中被逐级削掉（创建 → 检查 → 更新统计数字），全程无人察觉，
因为**规格里始终留着一条读起来像还在的动作名**。R2 是「规格没有调用方」，R6 是「规格被删后仍留着残句」。

---

## 1. 两个真实项目的产出对比（修复前快照：2026-09-30 之前）

> ⚠️ 本表是**修复前**快照。2026-09-30 畅行 KB 被回填重建，当前数字见 §1b。

| 维度 | 东风汽金 `afc-newcore-web-frontend` | 东风畅行 `cop-workspace` |
|------|-----------------------------------|-------------------------|
| 本质 | **可持续知识库**（11 轮增量） | **一次性报告** |
| 文件数 | 160 | 24 |
| md/yaml/json 行数 | 40,010 | 6,692 |
| 体积 | 2.9M | 292K |
| 顶层目录数 | 15（契约内 12 + 契约外 3） | 5（契约内 1 + 契约外 4） |
| 契约目录 | 12/14（缺 `recommendations/` `conventions/`） | 1/14 |
| 固定根产物 | 6/6 ✅ | 1.5/6（`manifest.json` + 大写 `INDEX.md`） |
| `manifest.status` | `completed` | `complete` |
| manifest 满足 `manifest.schema.json` | ✅ | ❌ 缺 `skillVersion`/`schemaVersion`/`generatedBy`/`generatedAt` |
| 候选规模 | `candidates/accepted/` 10 维度 × (.yaml + .md) + `incr/` | 14 个 YAML（`accepted/`），按「应用 × 维度」切分 |
| 编译链路 | `knowledge-index.json` + `context-package.json` 齐备 | 无（从未编译） |
| 契约外目录 | `.scan/` `.sessions/`（运行时）、`ui-specs/`（未声明） | `component-inventory/`（未声明）、`graph/`（非 `graph.json`）、空 `extracted/` |

> 计数方法：`find -type f | wc -l`；行数对 `*.md` + `*.yaml` + `*.json` 求和。可复现。

### 1b. 复核（2026-10-08）：畅行已被回填至契约全绿

**这是本报告写作时（§3 诚实边界原文说「没有真实合规项目样本」）尚不知道的事实**，如实补记。

| 维度 | 汽金（未变） | 畅行（**已回填**） |
|------|-------------|-------------------|
| 文件数 | 160 | **110**（修复前 24） |
| md/yaml/json 行数 | 40,010 | **26,414**（修复前 6,692） |
| 体积 | 2.9M | **1.1M**（修复前 292K） |
| 契约目录 | 12/14（缺 `recommendations/` `conventions/`） | **14/14**（修复前 1/14） |
| 固定根产物 | 6/6 | **6/6**（修复前 1.5/6） |
| `manifest.status` | `completed` | `completed`（修复前 `complete`） |
| `check-kb-contract.sh` | exit 1 | **exit 0** ← 首个真实 GREEN 臂 |

**回填的出处是自证的**——畅行 `manifest.json` 写有 `contract` 段（原文）：

```json
"scan_type": "contract-backfill + incremental",
"contract": {
  "authority": "shared/schemas/knowledge-directories.yaml",
  "version": "1.0.1",
  "directories": "14/14",
  "root_artifacts": "6/6",
  "gate": "check-kb-contract.sh",
  "baseline_violations": 18,
  "resolved_violations": 18,
  "note": "上一轮扫描产出 1/14 目录 + 0/5 根 JSON（18 项违约），本轮重组为契约布局"
}
```

**两处可机械核对的一致性**：
1. `baseline_violations: 18` 与 §3 中 `check-kb-contract.sh` 对畅行旧布局的 **REAL-2 臂实测 `⛔ 18 项违约`** 完全吻合——
   回填者用的正是这个门禁的诊断口径，而不是自己另数一遍。
2. `last_scan: 2026-09-30`、manifest mtime `Sep 30 14:17:21`——与 v1.3.2（门禁落地）**同一天**。

> ⚠️ **诚实的因果边界**：manifest 自报 `server_name: project-analyzer`，并显式引用契约版本与门禁名，
> 指向「加载新规格的 agent 回填」；但本机**无受控实验**，无法排除人工介入。台账据此**不**由
> `untested` 改判——它把这条记为**半自然证据**（真实项目、方向正确、但无对照臂）。
> 它至少证伪了 §3 原文的「没有真实合规样本」。

### 谁的结构更好？——**分项结论：各有一半更优**

**汽金更优（骨架层）**：完整的契约骨架 + 机器可读链路（`graph.json`/`search-index.json`/`knowledge-index.json`/
`context-package.json`）齐备，下游 skill 真的能按目录读到知识；11 轮增量说明它**可持续**——这正是
skill 的核心目标（「产出可持续项目知识库」）。

**畅行更优（节点层）**：单条候选的质量显著更高。对比同一维度的两种写法：

```yaml
# 畅行 candidates/accepted/base-architecture.yaml  —— 一条 claim 一个对象
- id: UCP-ARCH-001                      # ← 可被下游按 id 引用
  type: architecture
  name: 基座动态注册子应用且配置来自运行时 window 变量
  claim: <完整叙述：谁调谁、何时调、为何这样>   # ← 单条原子结论
  evidence:
    - path: cop-ucp-ui/src/micros/index.js
      line: 27                          # ← 显式行号
      count: 1
      note: "const appConfigs = window.baseConfigParam.MICRO_ROUTER_INFO"   # ← 真实代码，自证
  confidence: 0.92
  non_obvious: true                     # ← 机器可读的「非显然」标记
```

```yaml
# 汽金 candidates/accepted/antipatterns.yaml  —— 一条 claim 聚合 88 个对象
candidate: { id: workspace-antipatterns, category: quality.antipattern, extracted_by: ..., extracted_at: ... }
claim:
  statement: "workspace/ 存在88个God Object(>800行)、3,775个any、1,985个as强转…"   # ← 聚合
  confidence: 0.94
evidence:
  - path: workspace/components/common/FilePreviewUpload/index.vue
    type: count
    pattern: "3,742 lines — largest single file"    # ← 描述，非行号；无 note 代码
```

畅行格式胜在三点：**① 一条 claim 一个对象**（原子、可按 id 被下游引用）；**② `line` + `note` 直接给出真实代码**（证据自证，不必打开源文件）；**③ `non_obvious` 是可被程序消费的字段**。
汽金格式的 `evidence[].type: count` + 散文 `pattern` 无法机械核验，且聚合式 claim 让 88 个问题共享一个 id，下游无法单独引用或消解其中任意一条。

> **本轮范围边界**：节点格式的改进**未纳入本次修复**（用户已确认范围 = 根因 + 机器门禁）。
> 此处仅记录事实，作为后续候选。

---

## 2. 五个根因（均有 file:line 证据）

> ⚠️ 行号指**修复前**（2026-09-30 之前）的版本。

| # | 根因 | 修复前证据 | 修复后状态 |
|---|------|-----------|-----------|
| R1 | **产出结构在 5 处各自声明且互相矛盾**——目录集合各不相同 | `main.md:19-26` 只列 6 个目录；`validation.md:16` V7 只查 4 个；`knowledge-builder.md:52-66` Gate 只有 10 行；`capability-matrix.md:30,53` 第 6 份清单；`output-format.md:86-107` 树缺 `recommendations/` `conventions/` `candidates/` `context.json` | ✅ 已收敛：全部改为**引用契约**，唯一人读视图留在 `output-format.md` |
| R2 | **`finish-workflow.md` 是孤儿**——它规定「statistics/context/graph/search-index 每次扫描必定执行」，但**零个 stage 引用它** | `skill.yaml:40` `stages=[discovery,execution,validation,delivery]` 无 `finish`；全仓 grep 只有一处提及，且是散文旁注非阶段调用（`runtime/state/schemas/knowledge-lifecycle.md:10`「analyzer Finish 阶段写入，见 finish-workflow.md」）。**这直接解释畅行 0 个根 JSON** | ✅ 已接线：`delivery.md` Action 0 调用其 Phase A/B；文件头写明调用方 |
| R3 | **`INDEX.md` vs `index.md` 大小写分歧** | **15 处 / 8 份文件**写大写（`git grep -c "INDEX\.md" HEAD`）：`verifier.md`×4、`execution.md`×3、`index-generator.md`×2、`validation.md`×2、`classifier.md`×1、`SKILL.md`×1、`skill-ir.yaml`×1、`shared/conventions/vault-sync.md`×1；写小写：`output-format.md:86,105,117` / `capability-matrix.md:30,53`。契约树用小写。**畅行跟了前者** | ✅ 已统一为 `index.md`（`grep -rn "INDEX\.md" skills/project-analyzer/` → 0 命中） |
| R4 | **门禁不阻断** | `validation.md:16` V7 缺目录只「标注」；`finish-workflow.md:45` Phase D 明写「**不阻断**」→ **13/14 目录缺失仍能声明 `completed`** | ✅ 已改为**阻断**：`check-kb-contract.sh` exit 1 → 不可声明 `completed` |
| R5 | **Coverage Gate 漏 `recommendations/`**，且 `principles`/`decisions` 落点与契约不符 | `skill.yaml:33` + `SKILL.md:13` + `instinct-extractor.md:108` 三处都声称产出 `recommendations/`，但 `knowledge-builder.md:52-66` 的 Gate 无此条目。**两个项目都缺该目录——证明是 Gate 没覆盖**。落点：Gate 写 `conventions/principles.md`，而实测产出在 `rules/principles.md`（带 `constraint:`） | ✅ 已修：Gate 按契约重组 + 补**骨架行**；`recommendations/` 与骨架同时进门禁 |
| R6 | **「确保 CLAUDE.md 规则」被静默删除**——项目级 agent 入口能力在 4 次「优化」中逐级削掉，最终只剩一个预设文件已存在的动作名 | 见下方专节（含 `git log -S` 溯源）：2026-07-24 `7aa51f9` 引入完整语义（创建 + 幂等追加）；**同日** `0afd51b` 删正文只剩一行清单；2026-07-28 `7323eeb` 由「检查/创建」降为「只检查」；2026-08-02 `bb59bb1` 降为「更新一个**已存在文件**的统计数字」。此后 3 个月无人恢复 | ✅ 已恢复并加固：`finish-workflow.md` 步骤 13（幂等三态）+ 步骤 17 门禁 `check-claude-md.sh`；`delivery.md` Action 7 / `validation.md` V8 |

### 两个孤儿规格的成因（R2 的推广）

`references/finish-workflow.md` 与 `references/capability-matrix.md` **均为零引用**。前者是「4 个根 JSON 每次必生成」的**唯一规格来源**；后者是第 6 份产出清单 + 覆盖策略。
**规格写在没有任何阶段调用的文件里，等于没有生效的规格**——这解释了为什么「规格明明写了目录初次全部创建」而真实产出仍有 13/14 缺失。

### R6 专节：一条能力如何被四次「优化」削掉（`git log -S` 溯源）

R2 说的是「规格从没生效」；R6 更隐蔽——**规格生效过，然后被删，而删的过程没有任何一次提交说明自己删了什么**。

| # | 提交 / 日期 | 关于项目级 `CLAUDE.md` 的原文 | 动作语义 |
|---|---|---|---|
| 1 | `7aa51f9` 2026-07-24 09:59 **引入** | `### Step 4.5：确保 CLAUDE.md 规则` — **若不存在：创建 `CLAUDE.md`，内容指引 Claude 在编码前先读取 `.project-knowledge/` 中的知识文档（按任务类型匹配对应的 1-3 份文档）** / **若已存在：检查是否包含 `.project-knowledge/` 引用，若无则追加「开发前必读」段落** | **创建 + 幂等追加** |
| 2 | `0afd51b` 2026-07-24 14:52「优化(GPT)」 | Step 4.5 正文**整段删除**，只剩清单一行 `8. 检查/创建 .claude/CLAUDE.md` | 动作名还在，**写什么内容没规格了** |
| 3 | `7323eeb` 2026-07-28 09:51 `project_analyzer_rename` | `7. 检查 .claude/CLAUDE.md → manifest status 置为 completed` | **「检查/创建」→ 只「检查」**，创建动作消失 |
| 4 | `bb59bb1` 2026-08-02 00:28 | `13. CLAUDE.md 统计数字更新 — 读第一行，替换为 statistics.json 最新源文件数+代码行数` | 变成**更新一个已存在文件**——**预设文件已存在** |
| 5 | HEAD（至 2026-10-08） | 与 #4 一字未改 | 同 #4，持续 3 个月 |

机械证据（可复现）：
- `git log -S "确保 CLAUDE.md" --all` → 只有 `7aa51f9`（引入）与 `0afd51b`（删除）两个提交
- `git log -S "检查/创建" --all` → 最后一次出现在 2026-07-27；`7323eeb` 之后再无此串
- `git log -S "统计数字更新" --all` → 只有 `bb59bb1`

**为什么没人发现**：每次都是「优化」，没有一次提交说明提到删除能力；而规格里**始终留着一条读起来
像还在的动作名**（「CLAUDE.md 统计数字更新」）。它与 R2 是同一病理的另一面——
R2 是「规格没有调用方」，R6 是「规格被删后仍留着一个看起来无害的残句」。

**实测后果**：东风汽金 `.claude/CLAUDE.md` 存在（git 历史显示人工引入，且其内容形态与 #1 那条规格
的描述吻合）；东风畅行 2026-09-30 首扫后 `.claude/` 下只有 `skills/`。
**同一套 skill（两项目符号链接到同一份），产出差一个 agent 入口。**

> ⚠️ 汽金那份**同样不合规**：不含 `kb-stats` 标记，且首行 `~3,123 源文件` vs `statistics.json` 的
> `3,197`——即连 #4 那条残留规格在最近一轮扫描中也没执行。

---

## 3. 修复验证（机械可核，非 LLM 自报）

新增阻断门禁 `shared/scripts/check-kb-contract.sh`（目录集合从
`shared/schemas/knowledge-directories.yaml` 派生，不硬编码）。对**同一批既有产出**只读回放：

| 臂 | 输入 | 期望 | 实测 |
|----|------|------|------|
| GREEN | 构造的完全合规 fixture（14 目录 + 6 根产物） | exit 0 | ✅ `✅ 契约满足` |
| AMBER | 仅缺 `recommendations/` 的 fixture | exit 1 | ✅ `⛔ 1 项违约` |
| CASE | 其余齐全、只有 `INDEX.md`（大写） | exit 1 | ✅ 归类为「存在但**大小写不符**」而非「缺失」 |
| REAL-1 | 东风汽金（12/14 目录） | exit 1 | ✅ `⛔ 2 项违约`（`recommendations/` `conventions/`） |
| REAL-2 | 东风畅行（**修复前**布局，1/14 目录） | exit 1 | ✅ `⛔ 18 项违约`（13 缺目录 + 4 缺根产物 + 1 大小写） |
| GUARD | 非 `.project-knowledge` 参数 | exit 2 | ✅ 拒绝（避免报告落到项目根） |

**关键**：GREEN 臂 exit 0 证明门禁**不是恒失败**（恒失败的门禁没有判别力，无法证伪）。
修复前两个真实项目是天然的两个 RED 臂；**修复后畅行转为第三个真实 GREEN 臂**（见 §1b / §3c）。

> ⚠️ **诚实边界（2026-10-08 更正）**：本节原文曾断言「汽金本身不完全合规（12/14），因此本轮
> **没有「真实合规项目」样本**，合规臂只有构造 fixture」——**该断言已被证伪**：畅行于 2026-09-30
> 被回填，`check-kb-contract.sh` 现对其返回 **exit 0**（§1b / §3c）。
> 仍然成立的部分：本轮**未跑受控 LLM 臂**——证明的是「门禁能检出 + 一个真实项目确实从 18 项
> 违约收敛到 0」，**不**证明「在受控条件下加载新规格的 agent 必然补齐并重跑到绿」。台账据此仍标
> `pass_fail: untested`（见 `mechanism-verification-ledger.md`「机制：交付契约完成度门禁」），
> **不冒充已判定**。

### 3b. 项目级 CLAUDE.md 入口门禁 `check-claude-md.sh`（R6 的修复，2026-10-08）

同样的只读回放方式，9 个臂：

| 臂 | 输入 | 期望 | 实测 |
|----|------|------|------|
| GREEN | 合规 fixture（`kb-stats` 与 statistics 一致） | exit 0 | ✅ `✅ 入口满足` |
| NOFILE | 有 `.claude/` 但无 `CLAUDE.md` | exit 1 | ✅ 归类「`.claude/` 下无 CLAUDE.md」 |
| NODIR | 连 `.claude/` 都没有 | exit 1 | ✅ 归类「整个 `.claude/` 目录不存在」 |
| NOREF | 有文件但不提 `.project-knowledge/` | exit 1 | ✅ 3 项违约（无引用 + 无 index 链接 + 无标记） |
| NOMARKER | 有引用但无 `kb-stats` 标记 | exit 1 | ✅ 归类「缺 kb-stats 标记」 |
| STALE | 标记存在但数字过期 | exit 1 | ✅ 归类「kb-stats 与 statistics.json 不一致」 |
| CASE | 小写 `claude.md` | exit 1 | ✅ 归类「存在但**大小写不符**」而非「缺失」 |
| REAL-1 | 东风汽金 | exit 1 | ✅ **归类为「入口存在但缺 `kb-stats` 标记」**（准确——它不是没入口） |
| REAL-2 | 东风畅行 | exit 1 | ✅ 归类「整个 `.claude/` 目录不存在」 |
| GUARD | 非项目根参数（`/tmp`） | exit 2 | ✅ 拒绝 |

**这证明门禁有判别力，同样不证明 agent 会去创建入口。** 台账标 `untested`。

> ⚠️ **本项最薄的一环**：门禁只**断言产出**，写入口的是 analyzer 自己（`finish-workflow.md` 步骤 13）。
> 「已存在的人工内容不被改写」这条**幂等性保证本轮无任何机械证据**——它是一条规格承诺，不是一个断言。
> （此前的另一薄环——落点是否会被自动加载——已于 2026-10-08 用哨兵探针关掉，见 §5.7。）

### 3c. 复核（2026-10-08）：畅行从 RED 变 GREEN，而本项目入口仍是 RED

用同一批门禁对**当前**两个真实项目只读回放（副本，`/tmp`）：

| 项目 | `check-kb-contract.sh` | `check-claude-md.sh` | 说明 |
|------|----------------------|---------------------|------|
| 东风汽金 | **exit 1**（缺 `recommendations/` `conventions/`） | **exit 1**（有入口但缺 `kb-stats` 标记） | 人工维护的可持续库，未被修复回溯 |
| 东风畅行 | **exit 0** ✅ | **exit 1**（`.claude/` 下仍只有 `skills/`） | KB 已回填全绿；**入口仍缺** |

**两个独立结论**：

1. **契约门禁终于有了真实 GREEN 臂**：畅行 2026-09-30 回填后 14/14 + 6/6，exit 0。这证伪了 §3
   原文「没有真实合规样本」的说法，并使门禁的真实判别力从「只见过它拦」升级为「也见过它放行
   一个真实项目」。
2. **R6 的新机制仍缺真实 GREEN 臂**——畅行 KB 全绿却**依然没有** `.claude/CLAUDE.md`。
   这恰好是本轮恢复该机制要解决的目标：**一个已经通过旧门禁的项目，仍在「知识不送达 agent」
   这一维度上为 RED**。`check-claude-md.sh` 对它的判定是「整个 `.claude/` 目录不存在」——
   精确且非误报。

> ⚠️ **因果归属**：畅行的回填可确证（manifest 自证 + 数字与门禁诊断吻合），但**不能**确证是
> 加载新规格的 agent 所为（无对照臂）。而畅行 `.claude/` 至今为空，说明**恢复的 R6 机制尚未在
> 真实项目上跑过一次**——它的 GREEN 臂仍然只在 fixture 上成立。

### 回归锁（全绿）

```
check-yaml               44 个 .yaml 全部可解析
check-consistency        声明链各层一致
check-conformance        all gates green
check-io-connectivity    I1/I2/I3/I4 全绿（含 I2 4.4 全 skill 规格扫描）
check-knowledge-pipeline Pass=12 Fail=0
check-artifacts          无输入时 SKIP（非 drift）
check-approval-audit     无 state.json 时 nothing to audit
check-drift              20 通过 / 0 drift
check-e2e-smoke          主链 wiring 完整
```

---

## 4. 附带发现（本轮修复顺带，非计划内）

| 发现 | 严重度 | 说明 |
|------|--------|------|
| `generate-skill-ir.sh <skill>` **静默无效** | ❌ | `gen` 对不存在的目录走 `[ ! -f "$y" ] && return`，而 `[ ! -f ]` 为真时 `return` 退出码为 **0** → `||` 短路 → 文档化的单 skill 调用**什么都不做**（实测）。已改为显式 `-d` 判定 |
| `compatibility.yaml` 版本未随 `skill.yaml` 同步 | ❌ | 该文件注释称「从 skill.yaml 提取，自动同步」，但**没有任何生成器同步它**——靠 `check-consistency` 断言。改版本时易漏 |
| `pressure-tests/project-analyzer.yaml` **不是合法 YAML** | ⛔ | P2 的 `skill_mechanism: verification.mode: candidate-verify-accept（…）` 是含 `: ` 的裸标量 → 解析报错。**设计层（预测）从写入起就无法被任何工具读取**。已加引号修好；其余 8 份 pressure-test 文件均合法 |
| `vault-sync.md` 的产出树与契约矛盾 | ❌ | 把 `glossary.md` `principles.md` 放在 KB **根目录**（二者实属 `architecture/` 与 `rules/`），且写 `INDEX.md`。这是 R1/R3 的又一处实例，且该文件位于 `shared/` 影响面更广 |

---

## 5. 已知缺口（本轮未修，记录待办）

1. **门禁是单向的**：只检「契约目录**缺失**」，不检「**契约外**目录」。实测汽金产出 `ui-specs/`、
   畅行产出 `component-inventory/`，均无人拦。`check-io-connectivity.sh` 的 I2 只管**规格**里声明的目录，
   管不到真实产出新增的目录。
2. **根产物清单没有 SSOT**：`knowledge-directories.yaml` 只声明**目录**，不声明根文件；
   `artifact-types.yaml` 只声明了 `context`/`graph`/`knowledge` 三个类型。于是
   「6 个固定根产物」目前写在 `output-format.md` 的树里，并由 `check-kb-contract.sh` 复述一份——
   **这是修复中被容忍的最后一处重复**，正确做法是让契约新增 `root_artifacts:` 段
   （本次因「不改契约」的范围约束未做）。
3. **`manifest.json` 的 schema 无人门禁**：修复前畅行 `manifest.json` 缺 4/5 required 字段（缺
   `skillVersion`/`schemaVersion`/`generatedBy`/`generatedAt`），无任何检查报出——它仍声明
   `complete`。回填后字段已补（含 `contract`/`knowledge`/`verification` 段），**但这是产出侧的自发
   改善，不是被门禁强制的**：`check-artifacts.sh` 需要参数才跑该断言。缺口本身（无 schema 门禁）仍在。
4. **节点格式未改进**：见 §1 的三点差距（原子 claim / `line`+`note` / `non_obvious`）。
5. **`candidates/` 三态缺口**：规格声明 `accepted/` `rejected/`，实测存在 `candidates/incr/`
   （汽金）等未声明的子目录。
6. **R6 的幂等性无机械证明**：`check-claude-md.sh` 只断言**产出**，写入口的是 analyzer 自己。
   「已存在的人工内容不被改写」是规则承诺，不是断言。<u>可补的机械臂</u>：构造一个含人工段落的
   `CLAUDE.md`，跑写入流程后 diff 断言人工段落逐字未变——本轮未做。
7. **R6 的落点自动加载性——【已关闭，2026-10-08 本机实证】**：曾因 `docs.claude.com` 被网络策略拦截而无法
   从官方文档验证，仅得第三方镜像说法。已改用**本地 3 臂探针**关闭：在 `/tmp` 构造含唯一哨兵
   `ZZQX-7742-KESTREL` 的 `.claude/CLAUDE.md` 与 `./CLAUDE.md` 两个独立目录，各开一次 `claude -p`
   （v2.1.285）探针 → **两个落点都逐字回诵哨兵**；空目录**负对照**回 `NONE`。结论：会话启动确实自动加载
   `.claude/CLAUDE.md`，「文件写了、没人读」的装饰品风险已证伪。R6 机制要真正生效，剩下唯一的前提
   是「agent 真的会去写入口」（无保持 `untested`）。
8. **门禁仍未覆盖「入口内容是否**有用**」**：只查存在 + 引用 + 数字一致，不查路由表里的链接是否真实可达。
   与 §5.1 同型——单向断言。

---

## 附：可复现命令

```bash
# 门禁对两个真实项目的判定（只读回放——勿对真实目录跑，门禁会在其中写报告）
cp -R "<project>/.project-knowledge" /tmp/kbgate/<name>/.project-knowledge
bash shared/scripts/check-kb-contract.sh /tmp/kbgate/<name>/.project-knowledge; echo $?

# 项目入口门禁（参数是**项目根**，不是 .project-knowledge）
cp "<project>/.project-knowledge/statistics.json" /tmp/kbgate/<name>/.project-knowledge/
mkdir -p /tmp/kbgate/<name>/.claude && cp "<project>/.claude/CLAUDE.md" /tmp/kbgate/<name>/.claude/
bash shared/scripts/check-claude-md.sh /tmp/kbgate/<name>; echo $?

# R6 的规格删除溯源
git log --all --format='%h %ci %s' -S "确保 CLAUDE.md"
git log --all --format='%h %ci %s' -S "检查/创建"
git log --all --format='%h %ci %s' -S "统计数字更新"

# 全量回归锁
for s in check-yaml check-consistency check-conformance check-io-connectivity \
         check-knowledge-pipeline check-artifacts check-approval-audit check-drift \
         check-e2e-smoke; do bash shared/scripts/$s.sh; done
```
