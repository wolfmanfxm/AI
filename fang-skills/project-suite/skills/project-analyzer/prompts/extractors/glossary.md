# Glossary Extractor

> 只提取领域术语。从代码中识别业务概念及其定义。

## Actions

1. 扫描类型定义（types/ *.d.ts）→ 提取 interface/type 名称
2. 扫描 API 函数名 → 提取业务动词（submit/approve/reject/settle）
3. 扫描路由名称 → 提取业务模块名
4. 扫描枚举值 → 提取状态/类型常量
5. 对每个术语：标注定义、出现位置、使用频率

## Output

```markdown
# Glossary

## 核心术语

| 术语 | 英文 | 定义 | 出现位置 | 频率 |
|------|------|------|---------|------|
| 借据 | LoanNote | 贷款凭证 | types/loan.ts, api/loan.ts | 高 |
| 额度 | Quota | 授信额度 | types/quota.ts, views/quotaManage/ | 高 |
| 批复 | Approval | 审批决策 | api/approval.ts, views/*/review/ | 高 |
| 放款 | Disbursement | 贷款发放 | types/disburse.ts | 中 |
| 还款方式 | RepaymentMethod | 等额本息/等额本金等 | types/loan.ts:42 | 中 |

## 状态术语

| 术语 | 值 | 含义 |
|------|-----|------|
| PENDING | 0 | 待审批 |
| APPROVED | 1 | 已通过 |
| REJECTED | 2 | 已驳回 |
| SETTLED | 3 | 已结清 |

## 术语歧义

| 术语 | 代码含义 | 注意 |
|------|---------|------|
| Policy | 保险单 (不是系统策略) | types/insurance.ts |
| Settlement | 结算 (不是支付) | api/settlement.ts |
```

## Evidence

每个术语标注源码位置。歧义术语单独标注。
