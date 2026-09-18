# Round 11 分析 — YAML 修复 + 声明收口 + compiler change-detection + 路由行为验证

> 验证 2026-09-17 一批改动。**suite-only**（无 native 臂），最小验证集 3 项 + 路由 7 例。
> 目标项目 `afc-newcore-web-code`，分支 `benchmark/20260813`，全程零 git 操作、零代码改动（已独立核对）。

## 结果总览

| # | 改动 | 判定 | 证据 |
|---|------|------|------|
| 1 | compiler change-detection（编译器身份 + 每源路径/内容摘要） | ✅ 生效（**副本**上） | K1：重命名 → `.hash` 变 → 重扫 → index source 跟随、旧路径消失；`.hash` 64 字节；产物均在 `.project-knowledge/` |
| 2 | verifier V2 REUSE 证据要求 + 零改动合法 | ✅ 生效 | G1：裁决带 `命中`+`依据`（6 条来源）；**0 文件改动**（git 独立核对属实）；逐字引用新条款 |
| 3 | orchestrator `consumes` 8 → `[]` | ✅ 生效 | O1：引 `capability-routing.yaml:91` 读出 `needs: []`，判定「pipeline 执行**前**运行」，并指出依据是 skill.yaml 的显式注释而非仅靠空 needs 推断 |
| 4 | 触发词收紧 + EN 词边界 + 严重度分层 | 🟡 部分 | R1–R7：路由命中 **5/6**（可路由项），另发现 **2 处缺陷**（见下） |
| 5–7 | artifact-types 补 recommendation / YAML 修复 + 门禁 / atlas 收缩 | ✅ 静态 | check-yaml 44/44；check-io-connectivity、check-consistency(含 L0)、check-conformance 全绿 |

---

## ⚠️ 重大发现：知识链在真实项目上**整条是断的**（非本轮引入）

K1 在目标项目上**跑不起来**：

```
❌ 8 个 rules/decisions 缺少 constraint 字段（REQUIRED，拒绝生成 index）
```

编译器对 `rules/**` 与 `decisions/**` **硬性要求** frontmatter 含 `constraint:`（`knowledge-compiler.md` 第 58-59 行 + 脚本自校验），缺失即 `exit 1`，**不产出任何 index/hash**。

但**没有任何 Producer 负责写这个字段**：

| 检查 | 结果 |
|------|------|
| analyzer 的 prompt 是否要求产出 `constraint:` | ❌ 无。`knowledge-builder.md` 只提 body 内的 `constraints`（复数，pattern 用） |
| 其余 skill 的 prompt 是否要求 | ❌ 全无匹配 |
| 真实项目实测 | 目标项目 **8 个**文件缺失（其中 `decisions/*.md` 的 `generatedBy: project-analyzer`）；前端项目 **2 个** |

**推论链**（每步有证据）：编译器要求 → 无 Producer 产出 → 真实项目 `exit 1` → 无 `knowledge-index.json` / `context-package.json` → 下游只能手写 index（前端项目那个带 `observations` 桶、时间戳为 `+08:00` 的 index 即此类）→ **整条声明的知识注入链（Compiler→Resolver→context-package）在真实项目上没有运行**。

**为什么 suite 自己的测试没发现**：`check-knowledge-pipeline.sh` 用 **fixture**，而 fixture 的 rules/decisions 恰好带着 `constraint:`。测试通过，真实项目全挂 —— 典型的 **fixture 掩盖契约断链**。

**旁证**：本轮 G1 的 agent 报告「无 context-package.json → 走 Discovery 的 Fallback 直读 rules/decisions/experience」——它不得不绕过整条知识链，因为链子是断的。

> 这一条比本轮所有被验证的改动都重要：**被验证的机制都生效了，但承载它们的知识链本身没在跑。**

---

## 路由验证（R1–R7）

| # | 用户措辞 | 预期 | 实际 top1 | top2 | 判定 |
|---|---------|------|-----------|------|------|
| R1 | 分析这个项目并告诉我哪里应该修改 | analyzer | **analyzer** | reviewer | ✅ |
| R2 | 帮我判断这个模块应该怎么设计 | architect | **architect** | planner | ✅ |
| R3 | 帮我拆解需求和任务 | planner | **planner** | architect | ✅ |
| R4 | 帮我检查这段实现有没有问题 | reviewer | **reviewer** | tester | ✅ |
| R5 | 帮我做个开发计划 | planner | **planner** | architect | ✅ |
| R6 | 从分析到发布帮我跑一遍 | orchestrator | **无匹配** | releaser | ⚠️ 缺口 |
| R7 | 更新一下 changelog | releaser | **documenter** | releaser | ❌ 误落 |

**R5 是对本轮改动的直接验证**：删掉 generator 的裸触发词 `开发` 后，「开发计划」不再被 generator 抢走。R5 的 top2 是 architect 而非 generator —— 冲突消失。

### 缺陷 1（R7）：documenter 的路由面与自身边界矛盾

根因不是字母串，是**声明自相矛盾**：

| 出处 | 关于 Changelog 的表述 |
|------|---------------------|
| `project-documenter/SKILL.md` **frontmatter description**（真正驱动路由） | 「生成和维护项目文档：API 文档、README、ADR、**Changelog**、组件文档」 |
| `project-documenter/references/trigger-words.md:32` | `"写 changelog" \| documenter vs releaser \| changelog 关联版本发布 → **releaser**` |
| `project-documenter/prompts/main.md:13`、`delivery.md:11` | 「Changelog → 参考 releaser skill」 |

即：**歧义早已被记录并判定给 releaser，但这个判定从未应用到 description**。路由按 description 走 → 落到 documenter。

这正是静态检查**永远抓不到**的一类缺陷：documenter 的 `triggers_cn` 里没有 changelog，子串/交叉检测都看不见——泄漏发生在 description 的**散文**里。

**修复后复测（同一 prompt、独立 agent）**：top1 = **project-releaser** ✅（原为 documenter）。
该 agent 的理由直接引用了新写的边界：「project-documenter 的 boundary 明确将 Changelog 划归 project-releaser」。
修复动作：从 SKILL.md description 移除 `Changelog` 并显式声明归属；同步收敛 `capability-matrix.md`（原声明「✓ Changelog 生成」）、
`boundary.md`（原有一条**「Changelog 生成时遗漏 breaking change」的失败模式**，即假定 documenter 会生成 Changelog）、
`prompts/discovery.md`、`artifact-types.yaml` 的 `documentation` 描述共四处残留。

### 观察 2（R6）：`pipeline-orchestrator` 未被装载 —— **宿主配置缺口，非 suite 缺陷**（判定修正）

初次记为「缺陷」，复核后**修正判定**：suite 明确自定位为 **Protocol 而非 Engine**（「Suite 不假装有强制能力，强制是 Host 的」），
且两处**有意**把 orchestrator 与其余 skill 区分开——`generate-registry.mjs` 不把它纳入 `capability_order`，
`check-consistency.sh` L3 显式跳过它的版本校验（注释写明「元执行器 pipeline-orchestrator 有意排除」）。

因此 `capability-routing.yaml` 声明 `PipelineOrchestration` 是**正确的协议声明**；该 skill 在某一台宿主没被 symlink 装载，
是**宿主安装配置**的事（且该 skill 还依赖 `workflow-protocol/`，需一并装载），suite 无权也无从强制。

> 真实影响仍在：「从分析到发布跑一遍」这类整链路意图，在**当前这台宿主**上无处可去。但修复动作在宿主侧（安装），
> 不在 suite 侧。**不要把协议声明删掉去迁就某一台宿主的安装状态。**

---

## 判定与建议

### 本轮改动：全部生效，无回归

#1/#2/#3 均有正向证据，#5–#7 静态全绿。K1 证明了重命名检测与产物落点；G1 证明了 REUSE 证据要求真的改变了产出形态（且「0 改动」被 agent 当作**规定产出**而非失败）；O1 证明了依赖图声明可被正确解读。

### 但优先级应让位给三条链外缺陷

| 优先级 | 缺陷 | 建议动作 |
|--------|------|---------|
| **P0** | 编译器要求 `constraint:` 而**无 Producer 产出** → 真实项目知识链全断 | 补 Producer：在 `shared/templates/evidence-header.md` + analyzer 的 `output-format.md` 写明该字段是 rules/decisions 的硬要求。**不降级编译器**——`constraint` 是 blocking 约束的机器可读文本，降级即失去强制力 |
| **P0** | `check-knowledge-pipeline.sh` 的 fixture 掩盖了上面这条 | 新增第 5 节：缺 constraint 必须硬失败且点名文件 + 补齐后恢复编译 |
| **P1** | documenter 的路由面与自身边界矛盾（R7） | 从 SKILL.md description 移除 `Changelog` 并显式声明归属；同步收敛 capability-matrix / boundary / discovery / artifact-types 四处残留 |
| **P1** | pipeline-orchestrator 未装载 → 整链路意图无入口（R6） | **宿主侧**：安装该 skill（连带 `workflow-protocol/`）。**不要改 suite 声明**——协议声明是对的 |
| **待定** | **（新发现，超出本轮范围）** Producer/Consumer 的**目录集合**本身不一致 | 见下方「更深一层」 |

### 更深一层（本轮新发现，**未修**，属设计决策）

修 `constraint` 时读到 analyzer 的产出规格，发现 Producer 与 Consumer 的**目录集合本身就不一致**：

| 目录 / 文件 | analyzer 的产出规格 | compiler 扫描 | 结果 |
|---|---|---|---|
| `observations/` | ✅ `knowledge-builder.md` 写 `risks.md` `antipatterns.md` | ❌ 不扫 | **写了但从不索引**——这正是前端项目那份手写 index 里「observations 桶」的来源 |
| `conventions/` | ✅ 写 | ❌ 不扫 | 同上 |
| `decisions.md`（根文件）/ `architecture/decisions.md` | ✅ `knowledge-builder.md:25` 明确映射到 `architecture/decisions.md` | ❌ 只扫 `decisions/` **目录** | 决策进不了 `decisions` 桶；且会被当作 `architecture`（type=pattern）索引 |
| `principles.md` / `glossary.md` / `risks.md` / `antipatterns.md` / `INDEX.md`（根文件） | ✅ 写 | ❌ 不扫 | 全部不索引 |
| `decisions/`（目录） | `output-format.md:69` 标「**人工**」，analyzer 只建 index.md | ✅ 扫 | **声明与实现相反**（真实项目里它是 analyzer 产出的） |
| `rules/` `experience/` `playbooks/` | 标「人工」 | ✅ 扫 | 一致（Producer 是用户） |

**这不是 `constraint` 一个字段的问题，是两侧对「知识有哪些目录」没有共同契约。** 后果与 `constraint` 同源：analyzer 辛苦产出的
`observations/` `conventions/` 等**永远到不了下游**，而 compiler 期待的 `decisions/` 内容又没人按格式写。

**建议**（需你拍板，涉及知识模型）：把「知识目录集合」定义成**单一权威**（如 `shared/schemas/` 下的一张表或
`artifact-types.yaml` 的知识子集），让 analyzer 的 `output-format.md`、`knowledge-builder.md` 与 compiler 的
`emit_one` 列表都从它派生，并由 `check-io-connectivity.sh` 增加「Producer 目录 ⊆ Consumer 扫描目录」的断言。
**本轮不动**——它决定了知识模型长什么样，不该由我顺手定。

### 台账判定口径说明

本轮**无 native 臂**，因此按台账定义（`pass` 需 native 漏做 / suite 做对的 delta），跨 Skill 路由的 RED 仍**不能填 pass**。本轮提供的是 suite 侧行为数据（5/6 命中 + 2 缺陷），已记入台账但不冒充已判定。
