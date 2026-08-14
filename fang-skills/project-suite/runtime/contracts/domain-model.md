# Domain Model v1.0

> 活的项目领域模型。Analyzer 提取 Candidate，Interview 确认，成为项目共同语言。
> 与 Glossary 的区别：Glossary 是"术语表"（发现），Domain Model 是"实体+关系"（持续维护）。

## 目录

```
.project-knowledge/domain/
├── vocabulary.yaml    ← 术语 + 定义 + 关系（核心）
├── entities.yaml      ← 领域实体（可选，术语多了才拆）
└── workflows.yaml     ← 领域流程（可选）
```

## vocabulary.yaml 结构

```yaml
terms:
  - id: user
    name: "用户"
    definition: "系统注册用户"
    kind: entity              # entity | value_object | workflow | role
    relationships:
      - { to: account, relation: "is_a_kind_of" }
    status: confirmed         # candidate | confirmed | conflicting
    source: interview         # analyzer | interview
    confidence: 0.9
```

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
| Analyzer | 提取 candidate 术语 | — |
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
