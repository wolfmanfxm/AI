# Domain-aware SDLC 链路验证（补齐上游两环）

> 日期: 2026-08-14 | 项目: afc-newcore-web-code
> 目的：验证「Domain Model 成为 SDLC 共同语言」里之前未测的两环——Analyzer 术语提取 + Architect V8 校验。

## 背景

「Domain Model → 全 Suite」链路有 5 环：Analyzer(提取) → Planner(确认) → Architect(校验) → Generator(遵循) → Reviewer(检测)。

之前只验证了**下游两环**（Generator V7 纠正 M1、Reviewer V6 准确率 0.966）。本轮补**上游两环**。

## 一、Analyzer 术语提取验证 ✅

用 Glossary Extractor 逻辑，从真实代码（views/types/api，三个模块）提取领域术语，**不读手写 vocabulary**。

### 结果：完整还原手写术语表 + 发现更多

| 领域 | 手写 confirmed | 提取是否还原 | 额外发现 |
|------|--------------|-------------|---------|
| customer | customerIndividual / customerCompany / groupCustomer / customerTag / customerCheck | ✅ 全部还原 | investigation(信用查询配置)、emailgation(邮箱配置)、management(操作日志)、customerIndividualRegister |
| quota | quota / retailQuota / wholesaleQuota / margin / rebate | ✅ 全部还原 | quotaConfig、myQuota(激活/降额/解冻)、brandRecipient、mailConfig |
| credit | creditApprove / creditReview / creditDistribute / creditExtend / creditLetter / scoreCard | ✅ 全部还原 | creditScoreCard、informationImport(经销商销售信息/拒绝支付/库存违规) |

### 提取器的关键发现（可指导后续改进）

1. **views 目录名是最可靠的术语源**——每个目录名直接对应一个可交付页面。
2. **types 文件的中文 JSDoc 注释是中文释义的最可靠证据**（如 `quotaManage.d.ts` 的「额度配置规则子项」「冻结提交参数」）。
3. **api 函数名贡献业务动词**（activate/freeze/unfreeze/reduce/claim/allocate/audit/renewal/extend），且用 Toe/Tob 后缀区分零售/批发接口。
4. ⚠️ **覆盖 caveat**：`types/customerManage/` 只有 customerTag.ts，其余客户类型散落在 types 根目录（groupCustomer.d.ts、relatedCompany.d.ts）。Glossary Extractor 若只扫子目录会**漏掉**这些术语。这是提取器的一个真实覆盖缺口。

**结论**：Analyzer 能自动提取领域术语，且与手写 vocabulary 一致（还更全）。上游源头成立。

## 二、Architect V8 校验验证 ✅

用 V8 规则（「设计引入的术语必须与 confirmed 术语一致」），对两个设计片段跑校验：

| 设计 | 内容 | V8 判定 |
|------|------|---------|
| A | 个人客户登记模块，目录 `customerIndividualRegister`，复用 `customerIndividual` 结构 | ✅ **Accepted**（术语一致） |
| B | 个人信息登记模块，目录 `personInfoRegister`，用 `PersonInfo` 类型 | ❌ **Rejected**（personInfo 是 conflicting，应归 customerIndividual） |

**结论**：V8 正确拦截 domain 冲突（personInfo → Rejected），正确放行规范术语（customerIndividual → Accepted）。

## 三、Planner Interview 确认 —— 机制同 V8，交互流未单独走

Planner Interview 三步（read → check → write）：
- **read**：提问前查 vocabulary → 已有定义不重问（机械读取）
- **check**：假设与 confirmed 冲突 → ⚠️ 追问（**与 V8 的冲突检测同源**，已在 V8 验证）
- **write**：确认新术语 → 写入 confirmed（机械写入）

**诚实标注**：冲突检测（check）已由 V8 验证覆盖；但「candidate → confirmed」的**交互式 confirm 写回**这一具体步骤没有单独走一遍（它依赖人机交互的 Interview，非自动化测试）。

## 四、链路完整性结论

| 环节 | 状态 |
|------|------|
| Analyzer 提取 candidate | ✅ 验证（自动提取还原术语） |
| Planner 确认 | 🟡 check 逻辑同 V8 已覆盖，confirm 写回未单测 |
| Architect V8 校验 | ✅ 验证（正确拦截/放行） |
| Generator V7 遵循 | ✅ 验证（M1 纠正） |
| Reviewer V6 检测 | ✅ 验证（准确率 0.966） |

**Domain-aware SDLC 五环中，4.5 环已验证，唯一残留是 Planner Interview 的交互式 confirm 写回**（本质是机械写操作 + 人机交互，非检测逻辑风险）。

## Related

- [domain-drift-accuracy.md](domain-drift-accuracy.md) — Reviewer V6 检测准确率
- [domain-drift-verification.md](domain-drift-verification.md) — Generator V7 纠正验证
- [domain-model-validation.md](domain-model-validation.md) — drift 存在的定性验证
