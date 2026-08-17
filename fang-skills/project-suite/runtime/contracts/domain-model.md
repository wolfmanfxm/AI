# Domain Model v2.0

> 活的项目领域模型。Analyzer 提取 Candidate，Interview 确认，成为项目共同语言。
> 与 Glossary 的区别：Glossary 是"术语表"（发现），Domain Model 是"实体+关系"（持续维护）。

> 状态：**frozen**。v2 三分模型（entities / actions / artifacts）为**命名权威源**，不再增加 kind 复杂度；只在真实案例暴露缺字段时增量扩展，不做推测性设计。

## 目录

```
.project-knowledge/domain/
├── vocabulary.yaml    ← 术语 + 定义 + 关系（核心）
├── entities.yaml      ← 领域实体（可选，术语多了才拆）
└── workflows.yaml     ← 领域流程（可选）
```

## vocabulary.yaml 结构（v2：三分模型）

> **v2 变更**：从 `terms[]` 单表 + `kind` 枚举，改为 `entities` / `actions` / `artifacts` 三个顶层分区。
> 原因：实体级术语（如「订单/商品」）约束不住「订单退款记录」这类**动作级页面命名**——生成端容易产出泛化的 `RefundRecord`，而非规范的 `orderRefundRecord`，因为 vocabulary 里没有这个 artifact 可对照。**修模型，不修检测。**

```yaml
# 三分模型：实体（entity）→ 动作（action）→ 产物（artifact）

entities:            # 领域实体（名词）
  - id: order
    name: "订单"
    definition: "交易订单"
    kind: entity      # entity | value_object | role（实体子类型）
    relationships:
      - { to: product, relation: "refers_to" }
    status: confirmed
    confidence: 0.9

actions:             # 领域动作（动词）
  - id: refund
    name: "退款"
    definition: "对订单发起退款的动作"
    status: confirmed
    confidence: 0.85

artifacts:           # 领域产物（实体×动作 → 页面/API 命名）
  - id: orderRefundRecord
    name: "订单退款记录"
    definition: "订单退款的记录页面/API"
    composed_of:
      entity: order
      action: refund
      artifact_kind: record   # record | statement | report | config | workflow | approval
    naming: "orderRefundRecord"   # 页面/API 命名的规范前缀
    status: confirmed
    confidence: 0.85
```

### 三分语义

| 分区 | 是什么 | 例子 |
|------|--------|------|
| entities | 领域实体（名词） | order / product / user |
| actions | 领域动作（动词） | refund / create / approve / review |
| artifacts | 领域产物（实体×动作，约束「页面/API 命名」） | orderRefundRecord / orderStatement / userReview |

> ⚠️ 上表的 order / product / refund / orderRefundRecord 等是**机制示例**（example: true），仅用于说明 entities/actions/artifacts 三分结构，**不代表任何项目领域**。真实领域术语由 Analyzer 从项目提取，写入 `.project-knowledge/domain/vocabulary.yaml`。

### 命名规则（Domain Action → Domain Artifact → UI/API Naming）

```
entity (order) + action (refund) + artifact_kind (record)
   ↓
artifact (orderRefundRecord)          ← vocabulary 里确认的规范命名
   ↓
页面/API 命名必须用 artifact 前缀      ← V7/V6/V8 对照 artifact，而非对照 entity
```

- 「订单退款记录」页面 → 必须叫 `orderRefundRecord`，不能叫泛化的 `RefundRecord`。
- 「用户审核」流程 → `userReview`（artifact，composed_of: user + review + workflow）。
- artifact 的 `composed_of` 显式绑定 entity + action；V7/V8 校验时先查 artifact 是否已存在，不存在再查 entity×action 组合是否合法。

## 状态机

```
candidate（Analyzer 提取，未验证）
    ↓ Interview 确认
confirmed（项目共同语言，下游 Skill 必须遵守）
    ↓ 发现冲突
conflicting（需重新澄清）
    ↓ 澄清后
confirmed 或 deprecated
```

## 谁读写（Domain-aware SDLC）

Domain Model 是**整个 Suite 的共同语言约束**，不是 Planner 辅助文件：

| 角色 | 动作 | Verify 检查项 |
|------|------|--------------|
| Analyzer | 提取 candidate 术语（entities / actions / artifacts 三分） | — |
| Planner Interview | 读 + 确认新术语（candidate→confirmed）+ 标记冲突 | — |
| Architect | 设计引用的术语必须与 confirmed 一致 | V8: Domain 一致（冲突则阻断） |
| Generator | 代码命名必须与 confirmed 一致 | V7: Domain 命名一致 |
| Reviewer | 检测术语混用（User/UserInfo/Client） | V6: Domain Terminology Drift |

## 核心价值：Domain Conflict

当 Skill 的假设与已确认定义冲突时，**停止并追问**，而不是静默用新定义：

```
假设 "User = 任意登录者"
  vs
已确认 "User = 系统注册用户"
  → ⚠️ Domain conflict → 追问澄清
```

## 与 Glossary Extractor 的关系

Glossary Extractor 提取术语 → 写入 vocabulary.yaml（status: candidate）。
Interview 确认 → 提升为 confirmed。
两者不是重复，是"发现"和"确认"的分工。
