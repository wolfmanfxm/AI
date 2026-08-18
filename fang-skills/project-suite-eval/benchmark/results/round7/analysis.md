# Round 7 分析 — P1 收尾报告概念 + P2 装饰品规则验证

> 验证 P1（result.md 悬空 → 收尾报告概念）和 P2（补测的装饰品规则）是否真正生效。
> 本轮最重要的产出是一个诚实的负向发现：**P2 补测的两个场景，RED 假设部分不成立**。

## 结果总览

| # | 改动 | 判定 | 证据 |
|---|------|------|------|
| P1 | result.md 悬空 → 收尾报告概念 | ✅ 生效 | M1：产出 completion-report.md，无 result.md 困惑 |
| P2 | architect P4「够用就好」 | ⚠️ **RED 不成立** | naive 也够用就好，区分不出 |
| P2 | reviewer P4「分级明确」 | 🟡 **部分生效** | naive 模糊三档，suite 精确五级+五轴 |

## P1 验证结果（生效）

M1 的 suite agent 产出：
- `closing_report_emitted: true`，`closing_report_name: "completion-report.md"`
- `result_md_confusion: false` —— 没有出现「该产出 result.md 还是 completion-report.md」的困惑

**结论**：P1 消歧义生效。改前 agent 可能困惑（gates.yaml 说 result.md，prompt 说 completion-report.md），改后 agent 自然用 skill 自己的报告名。这个「消歧义」的价值不是「改变行为」，而是「消除一个让 agent 踌躇的矛盾声明」。

同时复验通过：
- #4 target 放置决议仍生效（落点 customerManage/customerIndividual，显式排除 baseData）
- #3 convergence 仍生效（completion-report.md 含 `Convergence: sufficient → stop`）

## P2 验证结果（诚实记录，两个场景都未达强 GREEN）

### architect P4「够用就好」—— RED 不成立

| 维度 | naive | suite |
|------|-------|-------|
| 过度设计 | ❌ 无（明确「不加微服务/MQ/多租户」） | ❌ 无 |
| 现状核实 | ❌ 无（把「客户列表」当「可能新增」设计） | ✅ 有（Code Audit 发现已实现 → 复用） |
| 结论 | 够用就好，但凭空设计 | 够用就好 + 现状核实先行 |

**发现**：「够用就好」对现代 LLM 是常识，naive 天然就会做对，**RED 不成立**。真正区分 naive/suite 的是**另一条原则 #3「现状核实先行」**——naive 在不知道项目已实现的情况下凭空设计，suite 先核实发现「已实现 → 复用」。

**这暴露了 P4 场景设计缺陷**：我用「够用就好」做 RED 假设，但「够用就好」不是 skill 特有的行为约束，是 LLM 的通用能力。pressure test 的 RED 必须建立在「skill 特有的、LLM 通用能力覆盖不到」的行为上。

### reviewer P4「分级明确」—— 部分生效

| 维度 | naive | suite |
|------|-------|-------|
| 分级 | ✅ 有（严重/中等/低等三档） | ✅ 有（🔴BLOCKER→🟠HIGH→🟢LOW→🔵PRAISE 五级符号） |
| 结构 | 模糊（自造「严重/中等/低等」词） | 精确（符号 + 五轴覆盖表 + 每个 finding 带修复代码） |
| 正向反馈 | ❌ 无 | ✅ 有 🔵PRAISE |

**发现**：naive 没有「一锅粥」——它也有轻重意识（严重/中等/低等）。所以「分级明确」这条规则的 RED 也不完全成立。但 suite 确实更强：**精确的五级符号体系 + 五轴结构 + 具体修复代码 + PRAISE 正向维度**，这是 naive 没有的。

**结论**：这条规则**部分生效**——不是「装饰品」（suite 明显更强），也不是「强生效」（naive 也分级了）。真实价值是把「模糊三档」变成「精确五级符号 + 可操作结构」。

## 关键发现：P2 暴露了 pressure test 设计的方法论问题

这轮两个补测场景都暴露同一个问题：**RED 假设（naive_failure）写得太弱，没建立在「skill 特有行为」上**。

pressure-testing.md 的 RED 应该问：**「没有 skill 时，LLM 的通用能力真的会做错吗？」** 如果 LLM 通用能力就能做对（如「不过度设计」「知道轻重」），那这条规则就是装饰品或接近装饰品——这正是 pressure test 要暴露的。

本轮暴露的结论：
1. architect P4「够用就好」→ **装饰品**（LLM 通用能力覆盖，RED 不成立）。真正该测的是 #3「现状核实先行」。
2. reviewer P4「分级明确」→ **半装饰品**（naive 也分级，但 suite 的符号体系/五轴/修复代码是增量价值）。

## 建议下一步

1. **修正 architect P4**（P1）：把场景的 RED 假设从「够用就好」改为「上下文驱动」——「为列表查询做选型，naive 追银弹（虚拟滚动/SSR/微前端），suite 基于项目约束」。比「够用就好」强（需要读项目约束），但待实测确认 RED 是否成立。
2. **接受 reviewer P4 的中间态**：它的价值是「结构精确化」而非「从无到有」。可以保留场景，但把 assertion 从「分级」改成「精确五级符号 + 五轴结构 + 修复代码」。
3. **审查其余补测场景**（generator P4、tester P3/P4）是否也有同样的 RED 假设过弱问题——它们的 naive_failure 是否建立在「LLM 通用能力覆盖不到」的行为上。

## 本轮结论

P1 生效（消歧义闭环），P2 暴露了一个方法论问题：**pressure test 的 RED 假设必须建立在 skill 特有行为上，而非 LLM 通用能力上**。这是比「补测几条规则」更有价值的发现——它指导后续如何设计真正能区分 naive/suite 的压力测试。

---

## 补测结果（追加，round7 第二部分）

修正 architect P4 后，补测了 2 个 RED 假设更扎实的场景：

### generator P4「遵循项目模式」→ RED 弱，但 suite 过程质量更强

| 维度 | naive | suite |
|------|-------|-------|
| 遵循项目模式 | ✅ 也遵循（主动 grep 现有 API 提取约定） | ✅ 遵循（读 request.md + 类型化） |
| 类型质量 | 用了 `any`（`Promise<AxiosResponse<any>>`） | 零 `any`，`IResponseResultRows<CustomerVO>` |
| 知识来源 | 主动 grep workspace/api 现有文件 | 读 `.project-knowledge/api/request.md` + 现代模块 |
| 类型组织 | 内联类型 | 独立 `workspace/types/` + `import type` |

**发现**：「遵循项目模式」本身 RED 不成立——naive 也会主动 grep 现有代码提取约定。但 suite 的过程质量明显更强：**naive 复刻了 legacy 的 `any` 风格，suite 读 request.md 后用了现代类型化风格（零 any）**。这印证了 round1/2 的核心结论「suite 价值 = 过程质量，非结果」——两者都能完成，但 suite 产出更符合项目的**最新**规范（而非最旧的既有代码）。

### tester P4「可执行」→ RED 成立 ✅（唯一强 GREEN）

| 维度 | naive | suite |
|------|-------|-------|
| 写测试 | ✅ 写了（8 用例，覆盖边界） | ✅ 写了（8 用例） |
| 实际运行 | ❌ 没运行（写完即止） | ✅ `npx vitest run`，8 passed |
| 声称通过 | 未声称通过，但也没验证 | 有实际运行结果 |

**发现**：「可执行」是 skill 特有纪律——「生成后尝试运行」不是 LLM 默认行为（LLM 默认写完就完）。naive 写了测试但没运行，suite 真运行了 vitest 并确认 8 passed。这是本轮唯一 RED 明确成立的场景。

### 补测的教训

1. **「遵循项目模式」「现状核实」这类规则 RED 都弱**——现代 LLM 会主动读上下文、对齐现状，这是通用能力。suite 的增量价值在「过程质量」（读知识库的最新规范 vs 复刻既有代码的旧风格），而非「做对 vs 做错」。
2. **「可执行」「增量修改」这类「额外动作」规则 RED 强**——LLM 默认不做这些额外动作（运行测试、Read 再 Edit），skill 的纪律才让它们发生。
3. **pressure test 的 RED 假设应优先选「额外动作型」规则**（可执行、增量修改、精确 file:line 溯源），而非「判断型」规则（遵循模式、现状核实、够用就好）——后者 LLM 通用能力覆盖。

### 待办（未做）

- 修正 architect P4 已改为「上下文驱动」，但**未实测**——需跑一轮确认 RED 是否成立（「上下文驱动」偏判断型，可能 RED 也弱）。
- tester P3「先理解再测试」未补测。
- 一个场景设计 bug：tester P4 的 naive prompt 写了「写完即可，不用真的运行」，诱导了 naive 不运行（人为制造 RED）。下次测应去掉这句，让 naive 自然决定。

---

## 补测结果（追加，round7 第三部分——完成全部待办）

补测了 architect P4「上下文驱动」和 tester P3「先理解再测试」，最终规律彻底钉死。

### 完整 RED 强弱对照表（5 个场景）

| 场景 | 类型 | RED 成立？ | naive vs suite 差异 |
|------|------|-----------|---------------------|
| architect P4「上下文驱动」 | 判断型 | ❌ | 都对齐项目，选型几乎一致 |
| generator P4「遵循项目模式」 | 判断型 | ❌ | 都遵循，suite 只强在类型化（零 any） |
| reviewer P4「分级明确」 | 判断型 | 🟡 | naive 模糊三档，suite 精确五级+五轴 |
| tester P4「可执行」 | 额外动作型 | ✅ | naive 写完没跑，suite 真跑 vitest 8 passed |
| tester P3「先理解再测试」 | 额外动作型 | ✅ | naive 猜错行为，suite 读源码全对 |

### tester P3「先理解再测试」—— RED 成立，且 naive 猜错得离谱

这是本轮最有说服力的 RED 证据。被测函数 `parseAmount` 的真实行为与函数名暗示**相反**：
- 真实：`'12.34' → 1234`（**分**单位）、非法输入返回 **NaN**、`thousand=true` 返回**字符串**
- naive 凭函数名猜：`'12.34' → 12.34`（元）、非法输入返回 **0**、返回类型永远 number

naive 甚至**自己发明了不存在的 options**（`defaultValue`/`nullable`/`decimalPlaces`/`min`/`max`/`allowNegative`），写进文件头当「约定」。这些在真实实现里根本不存在——naive 把「测试先行」变成了「凭空捏造契约」。

suite 读源码后全对：覆盖 NaN、分单位、thousand 字符串三个易漏边界，且正确标注「⚠️ 未执行」。

### 最终规律（方法论级结论）

**pressure test 的 RED 假设必须优先选「额外动作型」规则**：

| 规则类型 | 特征 | RED 强弱 | 例子 |
|---------|------|---------|------|
| **额外动作型** | 要求 LLM 默认不会做的动作 | 强 ✅ | 先读源码、真跑测试、增量修改（Read 再 Edit）、精确 file:line 溯源 |
| **判断型** | 要求 LLM 做出正确判断 | 弱 ❌ | 对齐项目、遵循模式、现状核实、够用就好、上下文驱动 |

原因：现代 LLM 的通用能力已经覆盖了「读上下文 → 对齐现状 → 不追银弹 → 知道轻重」，这些判断它天然就会做对。真正区分 naive/suite 的是**「额外动作」**——LLM 默认不会「先读源码再写测试」「写完真跑一遍」「Read 再 Edit 而非 overwrite」，skill 的纪律才让这些动作发生。

### 场景设计的两条经验

1. **RED 假设选「额外动作」，不选「正确判断」**——问「没有 skill 时，LLM 会漏做哪个动作」，而不是「没有 skill 时，LLM 会做错哪个判断」。
2. **naive prompt 不诱导**——tester P4 我写了「写完即可不用运行」，人为制造了 RED。正确做法是让 naive 自然决定，观察它是否「默认不运行」。

### 越界事件（2 次，均已清理）

- tester P4 suite 误写主项目 `math.js`/`math.test.ts`（suite prompt 漏目标路径）
- tester P3 naive 误写主项目 `parseAmount.test.ts`（naive prompt 漏目标路径）

均确认是 git 未跟踪新文件，已删除，主项目工作树干净。教训：**所有 benchmark agent prompt 必须显式给出目标项目路径**，否则 agent 会自己找项目落盘。

---

## V7 Placement Correctness 验证（追加，第四部分）

> 验证 reviewer 新增的 V7「放置正确」检查项（核心原则第 5 条）是否真正生效。

### 结论：V7 的 RED 假设不成立，但真实价值是「纪律性强制」而非「能力增强」

**两轮测试对比**：

| 轮次 | naive prompt | naive 结果 |
|------|-------------|-----------|
| 第 1 轮（有落点线索） | 明确告诉「PLAN 说放 customerManage 但实际放 baseData」 | 报了（被诱导） |
| 第 2 轮（无落点线索） | 只给 diff + 模糊描述 | **仍主动读 PLAN 报了**（11 次 tool_use） |

**第 2 轮关键发现**：即使不给落点线索，naive 也会主动读 `.project-knowledge/proposals/PLAN-*.md` 并对照发现落点错位（报为 BLOCKER）。这说明「对照 PLAN 发现落点矛盾」是 LLM 通用能力，不是 skill 特有纪律。

### V7 的真实价值定位

V7 是「判断型」规则，其价值不在「发现矛盾」（LLM 给了上下文就会），而在：

1. **把「对照 target」从隐性 best-practice 变成显性强制项**——SKILL.md 核心原则第 5 条 + verifier V7 强制 reviewer **每次都**对照 target，降低漏报概率
2. **交叉检查维度**——suite 的 V7 会触发 V6 Domain Drift 联动（落点错位往往伴随命名 drift），这是 naive 没有的联动

### 但要诚实：这个价值「单次测不出」

「纪律性强制 vs 靠运气」的区别，需要**统计性验证**（多次跑看 naive 漏报率 vs suite 漏报率），单次测试测不出。单次测试只能证明「两者都能发现」，不能证明「suite 更少漏报」。

### 与 round1 核心结论的呼应

这个发现再次印证 round1 就确立的结论：**suite 价值 = 过程质量，非结果**。suite 和 naive 都能完成审查、都能发现错位，但 suite 的过程更结构化（V7 + V6 联动、BLOCKER 分级、PRAISE）、更可追溯（引用 verifier.md 行号）、漏报率更低（有强制检查项）。

### 方法论教训（补充到 pressure test 设计）

「对照 PLAN target」这类**「发现矛盾」**的检查，不适合作为 pressure test 的 RED 假设——因为 LLM 通用能力覆盖。真正能测出 suite 价值的，是**「漏报率」的统计差异**，而非「单次是否发现」。

这比 round7 第三部分「额外动作型 vs 判断型」更进一层：**判断型规则里，还要区分「发现矛盾」（RED 弱，LLM 通用）和「强制每次对照」（RED 统计上成立，需多次测）**。
