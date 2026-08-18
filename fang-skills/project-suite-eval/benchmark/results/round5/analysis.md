# Round 5 分析 — 架构清理轮次的验证

> 验证这次 session 的 6 项改动：哪些真的改变行为、哪些是「改了声明没改消费」、哪些引入回归。
> 与 round3/4 的「行为优化」不同，本轮大部分是架构清理，重点测「回归 + 关键行为是否还正确」。

## 结果总览

| # | 改动 | 判定 | 证据 |
|---|------|------|------|
| 1 | context_contract 语义化（query vs must_read） | ❌ **未生效** | M1：suite 仍直接读 .md（patterns/form.md、catalog.md、rules/*.md），未走 Query API |
| 2 | git_revert → edit_patch（refactorer） | ✅ 生效 | C2：suite 明确「回滚方式 = Edit 反向，非 git」 |
| 3 | Reuse Check primitive | ✅ 生效 | M1/C2：suite 结构化 REUSE/EXTEND/CREATE 裁决（native ad-hoc） |
| 4 | 增量分析（Incremental Analyzer） | ✅ 生效 | N5-INC：suite 只跑 5 个相关 Extractor，非全量 10 |
| 5 | Runtime Policy 迁移（skill-policy.yaml） | ✅ 回归通过 | S1：suite Quick Path 干净跑通 |
| 6 | Pressure Test 机制 | ✅ 机制有效 | N5-PT1：planner P1 的 RED→GREEN 区分明显 |

## 关键发现

### 1. #1 是「改了声明、没改消费逻辑」（最重要的负面发现）

M1 直接暴露：我把 `should_read: [patterns/vue.md, components/catalog.md]` 改成 `query: [patterns, components]`，只改了 skill.yaml 的字段名 + skills.generated.yaml。但 **SKILL.md 核心原则仍写「查 components/catalog.md」、前置条件仍写「.project-knowledge/index.md」、prompts 仍写「读 patterns/form.md」**——消费逻辑没改。

结果：suite agent 读到的还是 .md 路径，行为不变（直接读 .md，不走 `@adapter:knowledge.query`）。

**修复方向**：要把「语义 query」真正落地，需改三处消费逻辑：
1. SKILL.md 核心原则/前置条件：把「查 components/catalog.md」改成「@adapter:knowledge.query --type component」。
2. workflow-engine 的「Query API」声明要真正接到 skill 的 query 字段。
3. prompts 里的「读 patterns/form.md」改成语义查询。

### 2. #2 契约冲突已解决，但行为测试被约束混淆

C2 证明 refactorer skill 的「Edit 回滚」指令自洽（agent 明确说「Edit 反向，非 git」）。但「绝对禁止 git」的 benchmark 约束让 native/suite 都不碰 git，无法区分「skill 阻止 git」vs「prompt 阻止 git」。契约层（无 git_revert 残留）已静态验证通过，行为层的独立验证需一个不绑「禁止 git」的测试。

### 3. #3 reuse 的收益是「结构化」不是「结果」

L4（Vue2→Vue3）暴露：native 靠读 package.json 也能发现「已是 Vue3 → 零改动」，reuse-check 无强优势。但 M1/C2 里 suite 的结构化 REUSE/EXTEND/CREATE 裁决 + 证据链（查 catalog.md/graph.json + 语义判断）比 native 的 ad-hoc 复用更可追溯。印证 round1/2 结论「suite 价值 = 过程质量」。

### 4. #4 增量分析是这轮最有价值的行为验证

N5-INC 证明「增量分析」指令真的改变了行为：suite 只跑 5 个相关 Extractor（directory/architecture/glossary/pattern/api-pattern），明确跳过 framework/decision/principle/convention/risk/antipattern。这比 round3 的「知识缺口入口」（只解决跳过 vs 不跳过 Analyzer）更进一步，解决了「跑 Analyzer 时的粒度」问题。

### 5. #5 迁移是「挪位置」，不是「接入 runtime」

S1 回归通过（suite Quick Path 干净跑通），但 skill-policy.yaml 目前是**孤儿**——runtime 是 Protocol 非 Engine，没有任何代码 read skill-policy.yaml。迁移只是把字段挪到更合理的位置，运行时强制执行仍缺失（对应 roadmap「Enforced」状态一直为空）。

## 建议下一步

1. **修 #1（P0）**：把 SKILL.md/prompts 里的 .md 读取改成 `@adapter:knowledge.query` 语义调用，让 query 字段真正被消费。这是本轮唯一「改了没生效」的改动，且是架构一致性（「Query 唯一入口」）的核心。
2. **补 #2 行为测试（P1）**：一个不绑「禁止 git」的 refactor 测试，验证 refactorer 是否真的不用 git（而非被 prompt 约束）。
3. **补 #5 接入（P1）**：让 runtime 真正 read skill-policy.yaml（或明确标注「孤儿，待 Engine 接入」）。
4. **跑完整 pressure test（P2）**：15 个反例场景全跑（本轮只验证了 planner P1 一个，证明机制可行）。

## 本轮结论

架构清理大部分生效（#2/#3/#4 改变行为，#5 无回归），但 **#1 context_contract 语义化是「改声明未改消费」的典型**——只动了 yaml 字段名，没动消费逻辑。这印证了一个规律：**改配置（yaml/schema）不等于改行为，消费端（SKILL.md/prompts/engine）才是决定行为的点。**
