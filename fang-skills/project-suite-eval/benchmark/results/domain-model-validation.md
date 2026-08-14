# Domain Model 验证报告

> 日期: 2026-08-13 | 项目: afc-newcore-web-code | 分支: benchmark/20260813（未 push）

## 发现的真实 Domain Drift

### 术语混用：personInfo vs customer

`customerManage` 模块的既有命名规范：

```
customerCheck / customerCompany / customerIndividual / customerTag / groupCustomer
```

全部使用 `customer` 作为"客户"的领域术语。

**native agent 引入了新术语 `personInfo`**：

```
workspace/views/customerManage/personInfoRegister/    ← native 新生成，用 personInfo
workspace/types/customerManage/personInfo.ts          ← suite 补齐，沿用 personInfo
workspace/api/customerManage/personInfo.ts            ← suite 补齐，沿用 personInfo
```

"个人信息登记"在 customerManage 模块下，语义上是"个人客户的登记"，应该叫 `customerIndividualRegister` 或 `customerInfoRegister`，而非 `personInfo`。

### 三个"人"术语并存（需区分是否真混用）

| 术语 | 位置 | 语义 | 判断 |
|------|------|------|------|
| **Customer** | customerManage 模块 | 客户（贷款人） | ✅ 业务领域对象 |
| **Person** | personInfoRegister（新引入） | 个人信息 | ⚠️ 可能是 customer 的同义词 drift |
| **User** | taskManage/myTodo/UserInfo.vue | 系统登录用户 | ✅ 不同概念（内部员工） |

其中 **Person vs Customer 是真实 drift**——同一模块（customerManage）内，"客户信息"用了 Customer，新页面却用了 Person。

## 验证结论

### Domain drift 是真实存在的 ✅

native 在"无 domain model 约束"的情况下，凭语义直觉引入了 personInfo，与项目既有的 customer 规范不一致。

### 当前 drift 检测无法触发 ❌

原因：项目没有 `.project-knowledge/domain/vocabulary.yaml`（Analyzer 未跑过），所以：
- Generator 的 V7（Domain 命名一致）无 vocabulary 可对照
- Reviewer 的 V6（Domain Terminology Drift）无 confirmed 术语可检测

### 这正好证明 Domain Model → 全 Suite 的价值

```
如果先跑 Analyzer → 生成 vocabulary.yaml（customer = 已完成实名认证的用户，status=confirmed）
  ↓
Generator 生成时 → V7 检测到 personInfo ≠ customer → 修正命名
  ↓
Reviewer 审查时 → V6 检测到 Customer/CustomerInfo/PersonInfo 混用 → 报 Domain Terminology Drift
```

当前缺口：**Domain Model 必须由 Analyzer 先建立，下游才能约束**。没有 vocabulary.yaml，V6/V7/V8 都是空转。

## Benchmark 建议

后续跑完整 benchmark 前，先对目标项目跑一次 Analyzer 生成 .project-knowledge/ + domain/vocabulary.yaml，这样 suite 的 domain 约束才能真正生效，native vs suite 的 domain drift 差异才能被度量。
