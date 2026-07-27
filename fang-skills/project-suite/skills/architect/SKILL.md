---
name: architect
description: >
  架构决策、技术选型、模块设计、API 契约设计。使用对比矩阵做技术选型，输出 ADR 格式的架构决策记录。
  触发词：架构设计、技术选型、模块设计、系统设计、数据库设计、API 设计、架构评审、
  怎么设计、选什么技术、模块怎么划分、接口怎么定义、design architecture、tech stack、
  system design、API design。
  产出：ARCHITECTURE.md（ADR 决策记录 + 模块图 + 选型理由 + API 契约）。
---

# Architect

> 需求 → 技术选型 → 模块设计 → API 契约 → ARCHITECTURE.md

## 核心原则

1. **决策可追溯** — 每个决策记录：问题 → 候选方案 → 选择 → 理由
2. **上下文驱动** — 没有银弹，选型基于项目约束（团队、时间、规模、生态）
3. **够用就好** — 不过度设计，当前需求 + 可预见扩展，不设计"可能永远不需要"的能力
4. **基于事实** — 有 `.project-knowledge/` 时基于现有架构，不凭空设计

## 前置条件

| 优先级 | 资源 | 作用 | 缺失时 |
|--------|------|------|--------|
| 1 | `.project-knowledge/architecture/` | 了解现有架构，避免重复造轮子 | 标注"未分析现有架构" |
| 2 | `PLAN.md` | 了解任务范围和约束 | 不阻塞 |
| 3 | 用户描述 | 设计需求 | 必须 |

## 工作流

### Discover

1. 确认设计范围：全系统 / 某模块 / 某技术选型 / API 设计
2. 收集约束：现有技术栈、团队经验、性能要求、部署环境、时间压力
3. 🔴 **CHECKPOINT** — 确认范围 + 约束

### Execute

按需执行以下维度（用户可能只需要其中一个）：

#### 1. 技术选型

**流程**：候选方案列出 → 评估维度确定 → 对比矩阵 → 推荐 + 理由

评估维度模板：

| 维度 | 权重 | 说明 |
|------|------|------|
| 团队熟悉度 | 高 | 学习曲线、现有经验 |
| 生态成熟度 | 中 | 社区活跃度、插件、文档 |
| 性能 | 按需 | 是否满足项目性能目标 |
| 维护成本 | 中 | 升级难度、breaking change 频率 |
| 许可合规 | 高 | 商业使用是否有限制 |

输出格式：

```
决策：状态管理方案
| 方案 | 团队熟悉 | 生态 | 性能 | TS支持 | 推荐 |
|------|---------|------|------|--------|------|
| Pinia | ✅ 已有项目用 | ✅ 官方推荐 | ✅ | ✅ | ⭐ 推荐 |
| Vuex 4 | ⚠️ 需学习 | ⚠️ 迁移中 | ✅ | ⚠️ | 不推荐 |
| 自研 | ❌ 成本高 | ❌ | ⚠️ | ⚠️ | 不推荐 |

结论：Pinia，理由：团队已有经验 + Vue 官方推荐 + TS 原生支持
```

#### 2. 模块设计

设计模块划分 + 职责 + 边界 + 通信方式。

输出：模块图（mermaid/ASCII）+ 各模块职责说明。

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   auth      │────→│   order     │←────│   product   │
│  认证+鉴权   │     │  订单管理    │     │  商品管理    │
└─────────────┘     └──────┬──────┘     └─────────────┘
                           │
                    ┌──────┴──────┐
                    │   payment   │
                    │  支付模块    │
                    └─────────────┘
```

| 模块 | 职责 | 对外接口 | 依赖 |
|------|------|---------|------|
| auth | 登录/注册/权限校验 | `getUser()`, `hasPermission()` | - |
| order | CRUD + 状态流转 + 查询 | `createOrder()`, `queryOrderList()` | auth, product |
| payment | 支付发起/回调/退款 | `pay()`, `refund()`, `handleCallback()` | order |

#### 3. API 契约

| 要素 | 说明 |
|------|------|
| 方法 + 路径 | `POST /api/orders` |
| 请求参数 | 类型 + 必填/可选 + 示例值 |
| 响应结构 | 正常 + 错误（含 HTTP 状态码） |
| 鉴权 | 是否需要登录/权限 |
| 幂等性 | 重复调用是否安全 |

```typescript
// POST /api/orders — 创建订单
Request: {
  productId: number   // 必填
  quantity: number    // 必填，1-999
  couponCode?: string // 可选
}
Response 200: { orderId: number, totalPrice: number, status: 'pending' }
Response 401: { error: 'UNAUTHORIZED' }
Response 422: { error: 'VALIDATION_ERROR', details: [...] }
```

### Output

生成 `ARCHITECTURE.md` — 一个或多个 ADR 格式的决策记录。

## Runtime 协议

| 协议 | 路径 |
|------|------|
| 状态机 | [../../runtime/engine/state-machine.md](../../runtime/engine/state-machine.md) |
| 异常恢复 | [../../runtime/engine/error-recovery.md](../../runtime/engine/error-recovery.md) |
| 编排 | [../../runtime/protocols/orchestration.md](../../runtime/protocols/orchestration.md) |

## References

| 资源 | 路径 |
|------|------|
| 技术选型 Prompt | [prompts/tech-selection.md](prompts/tech-selection.md) |
| 模块设计 Prompt | [prompts/module-design.md](prompts/module-design.md) |
| API 设计 Prompt | [prompts/api-design.md](prompts/api-design.md) |
| 决策框架指南 | [references/decision-framework.md](references/decision-framework.md) |
| 触发词 | [references/trigger-words.md](references/trigger-words.md) |
| 能力边界 | [references/capability-matrix.md](references/capability-matrix.md) |
| 反例清单 | [references/anti-patterns.md](references/anti-patterns.md) |
| 设计示例 | [references/examples.md](references/examples.md) |
