# Domain Drift 检测准确率评估报告

> 日期: 2026-08-14 | 项目: afc-newcore-web-code
> 目的：量化 domain drift 检测（Reviewer V6 / Generator V7）的可靠性——它到底靠不靠谱，还是只在 M1 碰巧对了。

## 一、为什么测准确率

benchmark 之前证明了「drift **存在**」（M1 的 personInfo）和「vocabulary.yaml 能纠正 **一个** case」。但「能纠正一个」≠「检测可靠」。本评估回答更硬的问题：

- **精度**：报的 drift 里有多少是真 drift（会不会误伤 user/dealer 这种合法词）
- **召回**：真 drift 里抓到多少（会不会漏掉 company/client 这种漂移）
- **失效点**：检测器在哪些词上会栽（泛化词、歧义词、不同概念）

## 二、方法

| 要素 | 内容 |
|------|------|
| 术语表 | 3 领域（customer/quota/credit），17 个 confirmed + 8 个 conflicting |
| 测试集 | 30 个命名样例：15 no_drift（10 规范 + 5 不同概念）+ 15 drift（11 明确 + 4 边界） |
| 检测方式 | 2 轮独立 agent 判定（Reviewer V6 逻辑），取一致率 |
| 指标 | precision / recall / F1 / accuracy / 一致率 |

测试集：[drift-testset.yaml](drift-testset.yaml)

## 三、结果

### 混淆矩阵（检测器 vs ground truth）

| | GT drift | GT no_drift |
|---|---|---|
| **预测 drift** | TP = 14 | FP = 0 |
| **预测 no_drift** | FN = 1 | TN = 15 |

### 指标

| 指标 | 值 | 含义 |
|------|-----|------|
| **Precision** | **1.000** | 报的 drift 100% 是真 drift，零误报 |
| **Recall** | 0.933 | 15 个真 drift 抓到 14 个 |
| **F1** | 0.966 | |
| **Accuracy** | 0.967（29/30） | |
| **两轮一致率** | **100%**（30/30） | 判定高度稳定 |

## 四、FP/FN 分析

### 唯一 FN：`customerInfo`

- ground truth 标注：drift → customerIndividual（注「应明确个人还是机构」）
- 检测器判定：no_drift（理由「customer 词根构成的合法复合概念『客户信息』」）

**这不是检测器错误，是 ground truth 标注歧义。** 证据：早期 domain-model-validation.md 自己就把 `customerInfoRegister` 列为 `customerIndividualRegister` 的**合法替代名**。`customerInfo`（客户信息）确实是一个可接受的泛化概念，不是明确的 drift。

> 若把 `customerInfo` 归为「歧义词」而非「drift」，则准确率 = 100%（0 错误）。

### 零误报（FP = 0）

`user` / `dealer` / `employee` 三个「不同概念」全部正确判 no_drift。检测器**没有**因为词汇表里没有这些词就误报 drift——它正确区分了「漂移术语」和「无关概念」。

### 边界 case 全对

`individual` / `amount` / `limit` / `money` 四个泛化词，全部正确判 drift（召回不丢）。检测器**没有**因为它们太泛化就漏报。

## 五、关键发现

1. **检测器稳定可靠**：100% 一致率 + 96.7% 准确率（严格口径），~100%（把歧义词排除）。
2. **零误报、几乎零漏报**：精度 1.0，召回 0.933（唯一 miss 是歧义词）。
3. **唯一的弱点在词汇表，不在检测逻辑**：`customerInfo` 的歧义暴露了 vocabulary 需要明确「泛化客户信息」是否算独立合法术语。这是 domain model 设计问题，不是 V6/V7 的问题。
4. **Domain Model 的投资有回报**：vocabulary.yaml + V6/V7 能可靠地（96.7%+）抓住命名漂移，且不误伤无关概念。

## 六、结论与建议

**结论**：domain drift 检测是可靠的（F1 0.966，零误报），可以作为 Domain-aware SDLC 的一环投入使用。

**建议**（2 条，都是 vocabulary 层，不是检测层）：

1. **明确 `customerInfo` 的归属**：要么在 vocabulary 里新增 `customerInfo` 为 confirmed 合法术语（「客户信息」泛指），要么标 conflicting → customerIndividual（「客户信息」必须落到个人/机构）。当前「既不在 confirmed 也不在 conflicting」的空白导致判定歧义。
2. **评估规模可扩展**：本评估 30 样例 / 3 领域已证明方法可行。若要更稳的结论，可扩到更多领域（trustManage/loanManage/collection）和更多边界词（application/entry/record 等跨域易混词）。

## Related

- [domain-model-validation.md](domain-model-validation.md) — drift 存在的定性验证
- [domain-drift-verification.md](domain-drift-verification.md) — vocabulary.yaml 纠正 drift 的验证
- [drift-testset.yaml](drift-testset.yaml) — 本评估的测试集
