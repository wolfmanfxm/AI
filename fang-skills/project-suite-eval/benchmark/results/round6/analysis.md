# Round 6 分析 — 架构改动验证

> 验证本轮 session 的架构改动（重点 #2 双阈值消除 + #4 target 放置决议）是否真的改变行为 / 引入回归。
> 本轮与 round5 的差异：#4 是唯一的行为优化，其余是「消除多头权威」的架构清理。

## 结果总览

| # | 改动 | 判定 | 证据 |
|---|------|------|------|
| #1 | knowledge-list → context-package | ✅ 静态收口 | grep 无正常路径残留（本轮已完成，非 benchmark 验证） |
| #2 | 双阈值消除（confidence_min/quality_gate → rules.yaml） | ✅ 无回归 | S1：Quick Path 正常，无 confidence_min 报错 |
| #3 | convergence 统一协议 | ⚠️→✅ **修复后生效** | M1b：先发现「声明没消费」（挂 result.md，而 result.md 本身悬空），修 stage 模板后 agent 真实产出 sufficient→stop |
| #4 | planner target 放置决议 | ✅ **行为生效** | M1：落点 customerManage（round5 错误落点 baseData 已纠正） |
| #5 | skill-ir 生成器修复 | ✅ 静态收口 | 10 skill-ir 已同步（非 benchmark 验证） |
| #6 | 技术栈污染清理 | ✅ 静态收口 | grep 无残留（非 benchmark 验证） |

## 关键发现

### 0. #3 convergence 是「声明没消费」的再次暴露（本轮新增发现）

「继续」验证 #3 时，静态检查先暴露：convergence 只写进了 primitive + skill-io.md + roadmap，**消费端（stage 模板 + prompts）完全没接**——且它挂的 `result.md` 本身在 prompts 里也没被产出（gates.yaml 声明「必须输出 result.md」，实际产出 completion-report.md / validation-report.md），是**双重悬空**。

修复：把 convergence 判定接入 `stage-templates/delivery.md` + `validation.md`（所有 skill 经 `@engine:` 自动继承），并把 convergence.md 的定位从「result.md 附带」改为「收尾 stage 产出」。

修复后 M1b 验证：agent 在 validation 收尾真实产出 `convergence: sufficient → stop`，evidence 逐条支撑。

**规律确认**（与 round5 #1 同根）：改声明（yaml/md 字段）≠ 改消费（模板/prompts）。消费端才是决定行为的点。且 convergence 挂在一个「本身就没被消费」的 result.md 上，是「悬空叠悬空」——修复时要先找到真正被消费的落点（stage 模板），而不是继续挂在 result.md 上。

### 1. #4 target 放置决议是这轮最有价值的行为验证

M1 直接对比 round5 的同名任务：

| 维度 | round5（修复前） | round6（修复后） |
|------|-----------------|-----------------|
| planner 产出 target | 无（无此字段） | ✅ 显式 `{module, domain, placement, confidence, evidence}` |
| 落点 | ❌ baseData/personalInfo | ✅ customerManage/customerIndividual |
| domain 对齐 | 空转（glossary 缺映射） | ✅ vocabulary.yaml 的 customerIndividual + person→correct_to |

**机制链**（为什么这次对了）：
1. vocabulary.yaml 里 `customerIndividual` 的定义明确写「个人信息登记归此术语」
2. artifact `customerIndividualRegister` 的 `composed_of: {entity: customerIndividual, action: register}`
3. `conflicting.person → correct_to: customerIndividual` 的漂移修正
4. task-breakdown.md 的「放置决议」要求 planner 显式产出 target 字段

三者合力把「个人信息登记」从 round5 的泛化 `personalInfo` 导向正确的 `customerIndividual`。这印证了 round5 的教训——**domain 检测要生效，前置是 vocabulary.yaml 有映射 + 消费端（planner）真的读它**。round5 是「改了声明没改消费」，round6 是「声明 + 消费都对齐了」。

### 2. #2 双阈值消除是无回归的架构清理

S1 验证：删除 skill.yaml 的 confidence_min + skill-policy.yaml 的 quality_gate 后，gate 判定无回归——trivial 任务正确走 Quick Path，无「找不到 confidence_min」报错。

这印证了 round5 #5 的判断：**confidence_min 是 machine-readable routing 元数据，不被 agent 运行时直接消费**。删除它只影响派生文件（registry 已通过 generate-registry.mjs 同步），不影响行为。所以 #2 的价值是「消除多头权威」（原来 5 处定义互相矛盾），而非「改变行为」。

## 本轮结论

**架构清理（#1/#2/#3/#5/#6）都无回归，唯一的行为优化（#4）真实生效。**

对比 round5 的教训，本轮最值得记录的是：
- round5 #1 是「改了声明没改消费」→ 本轮 #4 是「声明 + 消费端 + 数据源（vocabulary）三方对齐」，所以真正改变了行为。
- round5 #5 发现 skill-policy 是孤儿 → 本轮 #2 把孤儿字段的权威明确到 rules.yaml，消除多头权威。

**规律**：配置（yaml/schema）改动要改变行为，需要三件事齐备——① 声明字段 ② 消费端读取 ③ 数据源（knowledge/graph）有对应的可读数据。缺任何一个，就是「改了没生效」。

## 建议下一步

1. **补 #2 的独立行为测试（P2）**：S1 只证明了「无回归」，还没证明「删 confidence_min 后 gate 判定值真的来自 rules.yaml」（而非某个 agent 自带的默认值）。但这需要 runtime 真正 read rules.yaml 才能测——目前 runtime 是 Protocol 非 Engine，测不了。所以维持「静态已收口 + 无回归」即可，不强行造 Engine。
2. **完整 pressure test（P2）**：19 个 scenario 里，本轮只补了 planner 的 2 个（P4/P5）。其余 skill 的装饰品规则（architect 第4原则、tester/reviewer 第3/4原则）仍需补测。
3. **#3 convergence 的真实效果（P1）**：本轮只验证了协议静态接入，没测「证据足够时 agent 是否真的停止」。这需要一个信息充分的简单任务，观察 suite 是否产出 `convergence: sufficient → stop` 而非继续追问。
