# Delivery Evidence — Suite Primitive v1.1.0

> Suite 一级「交付实证」原语。一次变更交付时，不只声明「改了什么」，还要给出**改前/改后证明对**与**合并风险分类**——让「看起来修好了」的假阳性在交付点无处藏。借鉴 Matt Pocock pr 思想。

## 定位：生产者 / 消费者

| 角色 | Skill | 职责 |
|------|-------|------|
| **Producer** | project-releaser（主）、project-generator / project-reviewer（可选） | 交付变更时产出 before/after 证明对 + 合并风险分类 |
| **Consumer** | 人工审查者 / 合并决策者 / 下游 skill | 据 proof pair 判断「真改好了」而非「看起来改好了」 |

> 使用方式：在 releaser delivery 阶段 `[引用](../../../shared/primitives/delivery-evidence.md)`。

## 为什么是 Suite 一级

本套件反复出现的失败模式是「**声明存在、运行路径上无 consumer**」与「**修复看似完成、实际没接入运行路径**」——本质都是「看起来对了，其实没执行/没验证」。现有机制在设计时防这道（Existential Gate / Reuse Check），convergence 在 skill 产出时要求 Evidence bound to Exit Criteria。

但**交付/交接点**缺一道：convergence 的 evidence 是 skill 自评「我的 Exit Criteria 通过了」，不是面向「这次变更到底有没有真生效」的**改前/改后对比**。本原语补的就是这道交付点实证——强制把「修复前 X 失败、修复后 X 通过」摆在交付物里，而不是只给一个 confidence 数值或一句「已完成」。

## 三段交付实证

> 与 releaser 现有产物的关系：Summary 已由 `CHANGELOG.md` 覆盖（不重复造）；本原语只补 **Evidence** 与 **Merge Danger** 两段，落到 `RELEASE-CHECKLIST.md` 或独立的交付摘要。

### 1. Summary（指向现有产物，不重复）

> 「改了什么」由 `CHANGELOG.md`（releaser 产出于 `.project-knowledge/reports/`）的 Added/Changed/Fixed/Deprecated/Removed 分组承载。本原语不另造摘要。
> 若变更涉及调用流/数据流/文件布局，可附**最小视图**（调用树 / 文件树 / diff 草图）使关键点一目了然——但只在与理解直接相关时才加，不为美观加图。

### 2. Evidence（改前/改后证明对）⚠️ 本原语核心

> 每个关键变更给一组**改前/改后实证**，证明它真的生效，而非「看起来改了」。
>
> | 层级 | 形式 | 何时用 |
> |------|------|--------|
> | **S-tier** | 截图/可视输出 改前 vs 改后 | 变更是可视的，且环境支持截图 |
> | **A-tier** | 测试/控制台输出 改前失败 vs 改后通过 | 大多数变更——给出**具体那条**测试或命令，不是笼统「测试通过」 |
>
> **规则**：
> - 不允许只写「测试通过」而无**具体哪条测试 / 改前是什么状态**。
> - 「修复前：Verify 未进入运行路径，测试应能复现失败；修复后：Verify 实际执行，测试通过」是合格实证；「已修复，测试全绿」不是。
> - 无可执行验证手段的变更（纯文档/重构）→ 标 `UNPROVEN`（无可执行实证），并列出**为何无法验证**，不假装有证据。

### 3. Merge Danger（合并风险分类）

> 不只是「有回滚方案」（RELEASE-CHECKLIST 已含），还要分类变更的**可逆性**与**影响面**。
>
> **Door（门）**：
> - **Two-way（双向门）**：可走回——回滚成本低。常规 bug 修复、新增功能。低审查强度。
> - **One-way（单向门）**：不可逆或回滚成本高——destructive migration、删数据、改 schema、改公开 API 契约、发版到生产。**必须更高审查强度 + 显式迁移步骤 + 回滚预案**。
>
> **Blast Radius（影响面）**：一句话描述潜在波及——layout shift / 消费方 breakage / 跨模块契约影响。来源优先用 reviewer 的 `findConsumers(<变更文件>)` graph 查询结果，不拍脑袋。
>
> **Safety Invariant（安全不变式）— 仅 one-way / 高风险**：这次变更之所以安全，依赖的**关键事实**是什么？
> 不是「影响了谁」，而是「哪条前提必须成立，安全才成立」。例：改 Task 并发隔离 → 不变式是
> 「同一 Task 不会发生两个相同 Skill 的并发写入」。写不出来 = 还没想清楚这次改动靠什么成立。
>
> **Proof（证明）— 仅 one-way / 高风险**：**实际执行**的验证，不是推理。格式固定为
> 「同一命令 / 同一场景：改前 <失败/现象> → 改后 <通过/现象>」；并发/隔离类不变式给出实际并发或隔离测试结果。
> - 没有真实执行 → 标 `UNPROVEN` + 写清为何无法执行。**不得用「逻辑上应该没问题」代替。**
> - `UNPROVEN` **不等于 PASS**：必须在交付摘要里单独可见，不能被其他项的通过稀释。
>
> 只对 one-way / 高风险变更要求这两个字段。全量加到每个变更上是流程税，会让字段退化成一句套话。
> 证据：eval ledger · `delivery-safety-invariant`（合成迁移场景）。
>
> **规则**：one-way door 必须在交付摘要显式标注，不得与 two-way 混为一谈。

## 与现有机制的关系

| 现有机制 | 本原语的关系 |
|---------|-------------|
| CHANGELOG.md | 承载 Summary（改了什么），本原语不重复 |
| RELEASE-CHECKLIST.md（回滚方案） | 承载 Merge Danger 的回滚侧；本原语补 Door 分类 + Blast Radius |
| convergence（skill 级 Evidence） | convergence 是 skill 自评 Exit Criteria；本原语是交付级改前/改后对比，面向「变更真生效」 |
| reviewer findConsumers | Blast Radius 的证据来源 |
| Breaking Change 显式标注（releaser 原则） | one-way door 的子集——单向门不限于 breaking change（如 destructive data migration 可能不破坏 API 但不可逆） |

## 输出格式

每次关键变更的交付实证（写入 RELEASE-CHECKLIST.md 或交付摘要）：

```markdown
Delivery[变更]: <一句话变更>
  Evidence:
    Before: <改前状态——失败测试/错误输出/截图，具体到哪条>
    After:  <改后状态——通过测试/正确输出/截图>
    (无可执行实证 → UNPROVEN + 原因，不假装)
  Merge Danger:
    Door: <two-way | one-way>
    Blast Radius: <一句话 + reviewer findConsumers 依据>
    Safety Invariant: <仅 one-way / 高风险：这次变更安全所依赖的关键事实>
    Proof: <同一命令：改前失败 → 改后通过；无可执行手段 → UNPROVEN + 原因>
    Rollback: <回滚方案，或指向 RELEASE-CHECKLIST 条目>
```

## 反例

| ❌ 反模式 | ✅ 正确做法 |
|-----------|-----------|
| 只写「测试通过」无具体哪条 | 给出具体测试名 + 改前失败状态 |
| 「已修复」+ confidence 数值，无改前/改后对比 | 改前 X 失败 → 改后 X 通过的实证对 |
| 无可执行验证却假装有证据 | 标 `UNPROVEN` + 原因 |
| one-way door 当 two-way 处理 | destructive/schema/API 契约变更显式标 one-way + 迁移步骤 |
| blast radius 拍脑袋 | 用 reviewer findConsumers graph 结果 |
| 用「逻辑上应该没问题」代替 Proof | 实际跑一次；跑不了就标 `UNPROVEN` + 原因 |
| 把 `UNPROVEN` 混进「全部通过」 | `UNPROVEN` 单独列出，不参与 PASS 计数 |
| 每个变更都加 Safety Invariant/Proof | 只对 one-way / 高风险加，否则退化成套话 |
| 重复造一份 CHANGELOG 摘要 | Summary 指向 CHANGELOG.md，不重复 |
