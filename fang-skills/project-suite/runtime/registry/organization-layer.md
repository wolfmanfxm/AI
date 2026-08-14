# Organization Layer v1.0

> Task → Project → Organization → Personal 四层知识模型。
> v1.0 新增 Organization 层：企业内多项目共享的知识资产。

## 四层模型

| Layer | Scope | 示例 | Sync |
|-------|-------|------|------|
| **Task** | 单次任务 | PLAN, REVIEW, CHANGELOG | ❌ 仅归档 |
| **Project** | 单项目 | architecture, components, patterns, conventions | → Vault/Projects/{project}/ |
| **Organization** | 企业内多项目 | UI Design System, Security Policy, DDD Convention, Code Style, CI/CD Pipeline | → Vault/Organization/ |
| **Personal** | 跨企业/个人 | Playbooks, Instincts (Always/Prefer/Avoid/Never) | → Vault/Knowledge/ |

## Organization Layer 特征

- 多个 Project 共享
- 由 Organization 的 Tech Lead/Architect 维护
- 比 Personal 更权威（企业级标准 > 个人偏好）
- 新项目 Analyzer 启动时自动加载

## Organization 示例

```yaml
# Vault/Organization/acme-org/graph.json
organization: "acme"
projects: [acme-web, acme-mobile, acme-admin]

shared_knowledge:
  - id: org.ui-design-system
    type: convention
    scope: organization
    statement: "所有项目统一使用 Element Plus 2.x + el-mp 命名空间"
    projects: [acme-web, acme-mobile, acme-admin]

  - id: org.security-policy
    type: rule
    scope: organization
    statement: "所有 API 请求必须使用国密 SM2/SM4 加密"
    projects: [acme-web, acme-mobile, acme-admin]

  - id: org.code-style
    type: convention
    scope: organization
    statement: "统一使用 script setup + TypeScript strict + ESLint"
    projects: [acme-web, acme-mobile, acme-admin]
```

## Promotion 路径

```
Task → (analyzer) → Project Knowledge
Project → (classifier) → Organization Candidate
Organization Candidate → (Reviewer) → Organization Knowledge
Organization Knowledge → (multi-project verified) → Personal Instinct
```
