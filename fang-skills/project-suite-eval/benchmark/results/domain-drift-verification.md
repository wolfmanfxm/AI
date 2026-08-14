# Domain Drift 纠正验证（M1 重跑）

> 日期: 2026-08-14 | 项目: afc-newcore-web-code | 分支: benchmark/20260813
> 目的：验证「vocabulary.yaml（domain model）能否纠正 native/suite 都存在的 personInfo drift」

## 背景

M1（"新增个人信息登记页面"）基准实验发现：native 引入 `personInfo`/`personalInfoRegister`，与 customerManage 模块既有的 `customer` 领域术语不一致。当时目标项目缺 `vocabulary.yaml`，Generator V7（Domain 命名一致）空转，drift 未被纠正。

## 实验

1. 生成 `.project-knowledge/domain/vocabulary.yaml`（customer 领域术语，confirmed），核心条目：
   - `customerIndividual = 个人客户`（定义明确"'个人信息登记'应归入此术语"）
   - `person = 个人信息（弃用术语，status: conflicting）`
2. 重跑 M1 suite（带 generator 工作流 + 显式要求 V7 校验）。

## 结果：drift 被成功纠正 ✅

| 维度 | 无 vocabulary.yaml（M1 基准） | 有 vocabulary.yaml（本次重跑） |
|------|------------------------------|-------------------------------|
| 目录名 | `personalInfoRegister/` | **`customerIndividualRegister/`** |
| API 函数 | `personalInfoRegister` | **`individualCustomerInfoRegister`** |
| 领域归属 | customerManage 下但用 personInfo 术语 | customerManage 下，归入 customerIndividual |

### Agent 的决策记录（D1 显式触发 V7）
> "D1(V7 触发修正): 命名采用 vocabulary 确认的 customerIndividual 前缀... 不用 personInfo/personalInfo"

### Agent 的关键发现
> "命名已按 vocabulary 修正：V7 触发，'个人信息登记' 归入 customerIndividual（个人客户），未使用 personalInfo/personInfo"

## 结论

**Domain Model → 下游 drift 纠正的价值链成立**：

```
Analyzer → vocabulary.yaml（customerIndividual=个人客户, confirmed）
  ↓
Generator V7 → 检测 "个人信息" 应归 customerIndividual → 修正命名
  ↓
输出 customerIndividualRegister（而非 personInfo/personalInfo）
```

这补齐了 [domain-model-validation.md](domain-model-validation.md) 里"当前 drift 检测无法触发（缺 vocabulary.yaml）"的缺口——**加了 vocabulary.yaml 后，drift 确实能被 V7 纠正**。

## 附带发现

1. `form-component-standard.md` 示例里 FormInput 直接挂 label/prop 与实际实现不符（FormInput 无 label/prop props，仅透传 $attrs），实际代码用 el-form-item 包裹 FormInput——这是知识库文档与实现的一个小偏差，需修。
2. 目标项目残留了空的 `personalInfoRegister/` 目录（M1 基准的空壳），本次已清理。
