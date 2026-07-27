# ADR-001: Knowledge First Architecture

## Status
Accepted (2026-07-28)

## Context
Project Suite 包含 9 个 skill。最简单的组织方式是把它们串成链：分析→规划→设计→生成→测试→审查。但这条链创建了隐性耦合——每个下游 skill 默认知晓上游的产出格式、文件位置和命名约定。

## Decision
所有 skill 之间的数据传递必须经过 Knowledge 层，不得直接消费上游 skill 的产出文件。

```
不是:  planner → architect (architect 读 planner 写的 PLAN.md)
而是:  planner → Knowledge
         ↓
       architect ← Knowledge (architect 知道 "Plan" 这个 Capability 存在，但通过 Knowledge 层读取)
```

### 具体规则

1. **context.json 是标准入口**。所有下游 skill 启动时读 context.json 获取项目上下文（技术栈、别名、约定、模块清单）。不读上游 skill 的产出文件路径。
2. **produces/consumes 限定为 Capability 类型**。skill.yaml 的 produces 和 consumes 字段使用 `capabilities.yaml` 中定义的类型枚举（KnowledgeBase、Plan、Architecture、Code、Test、Review、RefactoredCode、Documentation、Release），不写文件路径。
3. **interface.md 只声明 Capability**。每个 skill 的 interface 只声明 produces 什么类型的 Capability 和 consumes 什么类型的 Capability，不约定实现细节（文件位置、命名格式）。
4. **下游不推断上游状态**。skill 的可用性由 interface 中声明的 Capability 类型是否已满足决定，不由上游 skill 的 manifest.json 状态决定。

## Consequences

### 正向
- **skill 可替换**。只要新 skill 的 interface 声明相同的 produces/consumes，就可以无缝替换，不需要改任何下游 skill。
- **context 可裁剪**。每个 skill 通过 context_contract 只加载自己需要的知识（见 skill.yaml `context_contract` 字段），避免无限膨胀。
- **并行化自然产生**。scheduler 不需要知道 skill 的执行顺序，只需要知道哪些 Capability 类型已就绪。

### 负向
- **多一层抽象**。开发者需要理解 Capability 类型枚举，不能直接硬编码文件路径。
- **context.json 成为单点**。如果 analyzer 没有运行或 context.json 过时，下游 skill 需要降级。context-resolution.md 已定义裁决规则。

## Alternatives Considered
- **Linear chain（当前实现）**：简单直接，但耦合紧密。被拒绝因为无法扩展并行分支。
- **File-based contract**：每个 skill 声明输出路径，下游读路径。比 Knowledge 层更灵活，但格式变更会破坏所有下游。
- **Event bus**：pub/sub 解耦。对当前的 9 个 skill 来说过度设计，耦合问题的实际成本尚低于 pub/sub 的复杂度。

## Related
- [context.md](../../runtime/context/context.md) — Context Protocol 定义
- [context-priority.md](../../runtime/context/context-priority.md) — REQUIRED/IMPORTANT/OPTIONAL 分级
- [orchestration.md](../../runtime/protocols/orchestration.md) — 基于 Capability 的编排规则
- [capabilities.yaml](../../runtime/registry/capabilities.yaml) — Capability 类型定义和 skill 注册
