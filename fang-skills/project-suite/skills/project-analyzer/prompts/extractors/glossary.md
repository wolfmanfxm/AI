# Glossary Extractor

> 只提取领域术语。从代码中识别业务概念及其定义。

## Actions

1. 扫描 views 目录名 → 提取业务模块名（**最可靠的术语源**，每个目录对应一个可交付页面）
2. 扫描类型定义 → types/ **根目录** + 所有子目录的 `*.d.ts` / `*.ts`（类型定义常散落各处，根目录和子目录都要扫）
3. 扫描 API 函数名 → 提取业务动词（submit/approve/reject/settle）
4. 扫描路由名称 → 提取业务模块名（与 views 目录名交叉验证）
5. 扫描枚举值 → 提取状态/类型常量
6. 对每个术语：标注定义（**优先用 types 里的中文 JSDoc 注释**）、出现位置、使用频率
7. **三分提取（entities / actions / artifacts）**——只提实体术语会导致下游 V7/V6 对「订单退款记录」这类动作级页面命名空转。
   - **entities**：从 views **一级目录名** + types 提取领域实体（order / product / user）。
   - **actions**：从 api **函数名动词** + 中文 JSDoc 释义提取领域动作（refund / create / approve / review）。
   - **artifacts**：从 views **二级/三级目录名** + api **verb+entity 命名** + 页面中文标题，提取「实体×动作」的产物（`orderRefundRecord`=订单退款记录、`orderStatement`=订单对账单、`userReview`=用户审核）。每个 artifact 标注 `composed_of: { entity, action, artifact_kind }` 和规范命名前缀 `naming`。

## Output

```markdown
# Glossary

## 核心术语

| 术语 | 英文 | 定义 | 出现位置 | 频率 |
|------|------|------|---------|------|
| 用户 | User | 系统登录用户 | types/user.ts, views/userManage/ | 高 |
| 订单 | Order | 交易订单 | types/order.ts, api/order.ts | 高 |
| 账户 | Account | 资金账户 | types/account.ts | 中 |
| 角色 | Role | 权限角色 | types/role.ts, views/roleManage/ | 中 |
| 商品 | Product | 商品信息 | types/product.ts | 中 |

## 动作（actions）

| 术语 | 英文 | 定义 | 出现位置 |
|------|------|------|---------|
| 退款 | refund | 对订单发起退款 | api/order/refund.ts |
| 审核 | review | 对内容发起审核 | api/review/index.ts |

## 产物（artifacts）

| 术语 | 英文 | 定义 | composed_of | 命名前缀 |
|------|------|------|------------|---------|
| 订单退款记录 | orderRefundRecord | 订单退款的记录页面/API | order + refund + record | orderRefundRecord |
| 用户审核 | userReview | 用户审核流程 | user + review + workflow | userReview |

## 状态术语

| 术语 | 值 | 含义 |
|------|-----|------|
| PENDING | 0 | 待处理 |
| ACTIVE | 1 | 已激活 |
| DISABLED | 2 | 已禁用 |
| DELETED | 3 | 已删除 |

## 术语歧义

| 术语 | 代码含义 | 注意 |
|------|---------|------|
| Session | 会话（不是「会议」） | types/session.ts |
| Batch | 批次（不是「批处理脚本」） | types/batch.ts |
```

## Evidence

每个术语标注源码位置。歧义术语单独标注。
