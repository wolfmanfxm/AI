# KB Structure Comparison Report

> 同一套 `project-analyzer`（v1.3.1，两项目 `.claude/skills/` 均符号链接到同一份）在两个真实项目上的产出对比
> | 2 projects evaluated | 5 根因定位 | 2 处修复验证

## Summary

| Metric | Severity | Value |
|--------|----------|-------|
| 评估项目数 | — | 2 |
| 产出规模比（文件数） | ⛔ 结构性差异 | 160 : 24（6.7×） |
| 产出规模比（md/yaml/json 行数） | ⛔ 结构性差异 | 40,010 : 6,692（6.0×） |
| 契约目录符合度（东风汽金） | ❌ 缺陷 | 12/14 |
| 契约目录符合度（东风畅行） | ⛔ 硬缺陷 | 1/14 |
| 固定根产物在位（汽金 / 畅行） | ⛔ 硬缺陷 | 6/6 : 1.5/6 |
| 声明 `completed` 但违反契约 | ⛔ 假完成 | 2/2 项目 |
| 独立共现的产出结构清单 | ⛔ 硬冲突 | 5 处（目录集合各不相同） |
| 孤儿规格（零 stage 引用） | ⛔ 硬缺陷 | 2 份（`finish-workflow.md` / `capability-matrix.md`） |
| `INDEX.md` / `index.md` 大小写分歧 | ❌ 缺陷 | 15 处 / 8 份文件写大写（`git grep -c` HEAD 实测） |
| 阻断式门禁 | — | 修复前 0 个 → 修复后 1 个 |
| `manifest.json` 满足 schema | ❌ 缺陷 | 汽金 ✅ : 畅行 ❌（缺 4/5 required） |

**结论（一句话）**：差异**不是** agent 能力问题，也**不是** skill 版本问题——是**技能规格自相矛盾**：
「产出哪些目录」在 5 处各自声明且互不相同，唯一规定「4 个根 JSON 每次必生成」的规格文档是孤儿，
而所有既有检查都「只标注不阻断」。于是**产出形态由 agent 的临场取舍决定**，两个项目各选了一份清单。

---

## 1. 两个真实项目的产出对比

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

### 两个孤儿规格的成因（R2 的推广）

`references/finish-workflow.md` 与 `references/capability-matrix.md` **均为零引用**。前者是「4 个根 JSON 每次必生成」的**唯一规格来源**；后者是第 6 份产出清单 + 覆盖策略。
**规格写在没有任何阶段调用的文件里，等于没有生效的规格**——这解释了为什么「规格明明写了目录初次全部创建」而真实产出仍有 13/14 缺失。

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
| REAL-2 | 东风畅行（1/14 目录） | exit 1 | ✅ `⛔ 18 项违约`（13 缺目录 + 4 缺根产物 + 1 大小写） |
| GUARD | 非 `.project-knowledge` 参数 | exit 2 | ✅ 拒绝（避免报告落到项目根） |

**关键**：GREEN 臂 exit 0 证明门禁**不是恒失败**（恒失败的门禁没有判别力，无法证伪）。
两个真实项目即天然的两个 RED 臂。

> ⚠️ **诚实边界**：汽金本身**不完全合规**（12/14），因此本轮**没有「真实合规项目」样本**，
> 合规臂只有构造 fixture。且本轮**未跑 LLM 臂**——证明的是「门禁能检出」，**不**证明
> 「加载新规格的 agent 会去补齐并重跑到绿」。台账据此标 `pass_fail: untested`（见
> `mechanism-verification-ledger.md`「机制：交付契约完成度门禁」），**不冒充已判定**。

### 回归锁（全绿）

```
check-yaml              44 个 .yaml 全部可解析
check-consistency       声明链各层一致
check-conformance       all gates green
check-io-connectivity   I1/I2/I3/I4 全绿（含 I2 4.4 全 skill 规格扫描）
check-knowledge-pipeline  Pass=12 Fail=0
check-e2e-smoke         主链 wiring 完整
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
3. **`manifest.json` 的 schema 无人门禁**：畅行 `manifest.json` 缺 4/5 required 字段，无任何检查报出。
   `check-artifacts.sh` 需要参数才跑该断言。
4. **节点格式未改进**：见 §1 的三点差距（原子 claim / `line`+`note` / `non_obvious`）。
5. **`candidates/` 三态缺口**：规格声明 `accepted/` `rejected/`，实测存在 `candidates/incr/`
   （汽金）等未声明的子目录。

---

## 附：可复现命令

```bash
# 门禁对两个真实项目的判定（只读回放——勿对真实目录跑，门禁会在其中写报告）
cp -R "<project>/.project-knowledge" /tmp/kbgate/<name>/.project-knowledge
bash shared/scripts/check-kb-contract.sh /tmp/kbgate/<name>/.project-knowledge; echo $?

# 全量回归锁
for s in check-yaml check-consistency check-conformance check-io-connectivity \
         check-knowledge-pipeline check-e2e-smoke; do bash shared/scripts/$s.sh; done
```
