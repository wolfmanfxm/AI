# Round 2 综合分析报告

> 8 个全新任务 × (native Claude Code vs project-suite) 对比实验。
> 目标项目：afc-newcore-web-code（Vue 3.4 + Element Plus 2.13 + TS）
> 日期：2026-08-14 ~ 08-17
> 与第一轮（20 任务）的区别：全部落在第一轮未触碰的模块，且目标项目已含 `.project-knowledge/domain/vocabulary.yaml`（domain 检测可真正生效）。

## 一、执行概要

| 维度 | 数值 |
|------|------|
| 任务总数 | 8（simple 2 + medium 3 + complex 2 + long 1） |
| 每任务跑法 | native → 记录 → 清理 → suite → 记录 → 清理（严格隔离，工作树全程干净） |
| 有效对比 | 8/8 完成 |
| 本轮焦点 | 验证 suite 的「过程质量」价值在陌生任务上是否依然成立 |

**核心结论一句话**：第一轮结论（suite 收益 = 过程质量，非 token/复用率）在 8 个全新、未见过的模块上**完整复现**——Decision Record 8/8 一致、边界纪律（反 gold-plate）出现本轮最强案例 N2-M3、domain 归属更准（N2-L1）。token 仍是 suite 平均 +23.5%，但出现 2 个 suite 反而更省的负例（N2-S2 / N2-M3）。

## 二、Token 对比（8 任务逐条）

| 任务 | native | suite | Δ | 说明 |
|------|--------|-------|-----|------|
| N2-S1 | 40.3k | 71.2k | **+76%** | 简单任务，suite 的 workflow+知识注入开销最高 |
| N2-S2 | 147.0k | 103.8k | **-29%** | suite 靠知识库定位 PageTable 契约，native 53 次 grep 探索 |
| N2-M1 | 89.7k | 121.1k | +35% | |
| N2-M2 | 98.3k | 123.2k | +25% | |
| N2-M3 | 83.1k | 78.5k | **-5%** | suite 零代码复用判定，native 写 496 行冗余组件 |
| N2-C1 | 84.2k | 114.7k | +36% | |
| N2-C2 | 112.4k | 161.2k | +44% | |
| N2-L1 | 102.3k | 161.3k | +58% | 长任务 suite 开销最大 |

- **suite 平均 116.9k vs native 94.7k，+23.5%**（第一轮 +12.8%，本轮略高，因长任务 suite 查了大量黄金模式参照）。
- **2 个负例（suite 更省）**：N2-S2（-29%，知识加速定位）、N2-M3（-5%，复用判定零代码）。与第一轮 M2/S2 负例同构，印证「目标模糊/需求已满足时 suite 可能更省」的结论。

## 三、过程质量发现（本轮焦点，逐项）

### 1. Decision Record：8/8 一致，native 0/8
suite 每个任务都产出 D1-Dn（N2-M3 的 D1-D3 复用裁决、N2-L1 的 D1-D8 含 3 个「复用哪个黄金模式」显式裁决）。native 8 个任务零决策记录，做完即散。与第一轮 20/20 一致。

### 2. 边界纪律（反 gold-plate）—— 本轮最强案例 N2-M3
- **N2-M3**：native 新建 496 行 `BatchImportDialog`（ImportDialog 的近重复组件）；suite 查 catalog.md 判定「需求已被 ImportDialog 完整覆盖」→ **零改动**。D3 显式拒绝清理 ImportDialog 既有 console.log 瑕疵。这是第一轮 M2 结论（「suite 识别需求已满足，native 加料」）在陌生任务上的最强复现。
- **N2-M1**：native 新造 PAYMENT_STATUS 枚举，suite 复用 HANDLE_STATUS（D3）。
- **N2-S2**：两者都做了失败分支 return 的防御性改动，但 suite 的 D6 显式「不清理 console.log」，native 无此纪律。

### 3. Domain 归属与命名一致性
- **N2-L1**（最明显）：native 的 API 用 `getLoginTypePrefix`（对齐 marginStatement 模块），suite 的 D1 明确指出应复用 rebateManage 自己的 dealer/internal 双端机制（`rebateTobService`/`rebateToeService`）——**suite 的模块归属更准**。
- **N2-M1**：两者都未严格用 margin 前缀命名页面（native `PaymentRecord` / suite `DepositRecord`），但 suite 至少查了 vocabulary 并写 D7 为「deposit=存保证金动作」辩护；native 无 domain 意识。这暴露 vocabulary 的 `margin` 术语与「缴纳记录页面」命名的映射仍有缝隙（margin 是账户/额度实体，不是「缴纳记录」这个动作）。

### 4. 证据密度
suite 引量化依据（ImportDialog 27 处引用、PageTable 99.7% 共现、0 处 .ts import .vue），native 多为定性描述。与第一轮一致。

### 5. 长任务护栏（与第一轮 L2 的对比）
- **本轮 N2-L1 无护栏违规**：native 和 suite 都遵守了禁 git / 禁跨界。第一轮 L2 native 的跨界软链 node_modules 事故**未在本轮复现**。
- **N2-S2 suite 首跑**试图执行 `git checkout -- .`（违反禁 git 约束）被安全分类器拦截，重跑才完成。这是本轮唯一一次「护栏接近被破」的观察（suite 侧），但被环境拦截，未造成实际跨界。
- **环境性中断**：N2-L1 native 连续 3 次被电脑休眠打断（agent 探索 ~20min 后机器 idle 休眠），第 4 次才完成。这暴露长任务在「idle 休眠」环境下的脆弱性，属环境问题而非护栏差异。

## 四、domain drift 观察

| 术语 | native 用 | suite 用 | vocabulary 期望 | 判断 |
|------|----------|---------|----------------|------|
| 缴纳记录页名 | PaymentRecord | DepositRecord | margin 前缀 | 两者都未严格用 margin；suite 有 D7 决策，native 无 |
| 返利 API 端别 | getLoginTypePrefix | dealer/internal 双端 | rebateManage 同模块一致 | suite 更准 |

**结论**：domain drift 检测在本轮「被部分触发」——suite 查了 vocabulary（N2-M1/L1 都 grep 了），但 vocabulary 的 term 粒度（实体级 margin/quota/customer）与「动作级页面命名」（缴纳记录/对账报表）不完全对齐，导致 V7 在这些动作命名上约束力不足。这是 vocabulary 设计层面的新发现，不是检测逻辑问题。

## 五、与第一轮结论的对照

| 结论 | 第一轮（20 任务） | 本轮（8 新任务） | 一致性 |
|------|-----------------|----------------|--------|
| suite 收益=过程质量，非 token | ✅ | ✅ 复现 | 一致 |
| Decision Record 可追溯 | 20/20 vs 0 | 8/8 vs 0 | 一致 |
| 边界纪律/反 gold-plate | M2/C2/L4 | N2-M3（最强）+ M1 + S2 | 一致且更强 |
| token 平均 +13% | +12.8% | +23.5% | 一致（量级同） |
| 目标模糊任务 suite 可能更省 | M2/S2 | N2-S2/N2-M3 | 一致 |
| 长任务护栏 | L2 native 事故 | 无事故（环境休眠干扰） | 本轮护栏未触发 |
| domain drift | native 引入 personInfo | 命名动作级缝隙 | 部分复现 |

## 六、本轮新增发现（第一轮没有的）

1. **N2-M3 是「需求已满足识别」的最强案例**：native 造了 496 行冗余组件，suite 零改动。价值可直接量化（省 496 行代码 + 省 token）。
2. **N2-S2 suite 反而省 29% token**：比第一轮 M2（-38%）略弱但同构，进一步夯实「知识加速定位」结论。
3. **vocabulary 的动作级命名缝隙**：实体术语（margin/quota/customer）约束不住「缴纳记录/对账报表」这类动作级页面命名，是 domain model 的粒度缺口。
4. **suite 也偶发护栏接近违规**（N2-S2 首跑试 git checkout）：说明护栏不是 suite 的绝对免死金牌，但环境拦截兜了底。
5. **长任务对 idle 休眠的脆弱性**：agent 探索超 20min 会撞机器休眠，是长任务 benchmark 的实操约束。

## 七、结论与建议

### 得到进一步证据支持的能力（可继续投入）
1. **Decision Record 机制** → 8/8 复现，价值稳定。
2. **边界纪律/反 gold-plate** → N2-M3 是最直接的可量化案例（避免 496 行冗余）。
3. **组件复用查重（catalog.md + V2 门槛）** → N2-M3 的零改动判定正是靠 catalog.md 结构化登记。
4. **领域归属（Context Resolver / module 一致）** → N2-L1 的 D1 证明 suite 能选对同模块机制。

### 需要修的能力缺口（本轮暴露）
1. **vocabulary 动作级术语缺失**：补「缴纳记录=marginDeposit / 对账=rebateStatement」这类动作级 term，否则 V7/V8 对动作级命名空转。
2. **suite 的护栏仍需兜底**：N2-S2 首跑试 git 说明 skill 的「禁 git」约束可被 agent 越过，需在 workflow 里更硬地阻断（或依赖环境分类器兜底）。

### 下一步建议
1. 补 vocabulary 动作级术语，重跑 N2-M1 验证 V7 能否把 PaymentRecord/DepositRecord 统一到 margin 前缀。
2. 把 N2-M3（复用判定零改动）作为 suite 价值的**标杆 case**，纳入宣传/文档。
3. 长任务 benchmark 需配合 `caffeinate` 或明确告知用户关闭休眠，否则探索超时的 agent 会被环境打断。
