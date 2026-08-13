# ADR-002: 委托 Symbol 级代码智能给外部 Provider

> 状态: Accepted | 日期: 2026-08-13

## 背景

project-suite 需要回答两类图查询：
- 模块级：模块怎么依赖？有没有循环依赖？（已由 graph.json 提供）
- 符号级：`UserService.update()` 被谁调用？修改它影响哪些代码？（当前缺失）

曾经考虑两种方案：
1. project-suite 自己实现 symbol 级静态分析（tree-sitter + type resolution + call graph）
2. 委托给外部 Code Intelligence provider（如 CodeGraph）

## 决策

**采用方案 2：委托。** project-suite 不实现 symbol 级静态分析。

### 边界划分

| 层 | 谁提供 | 内容 |
|----|--------|------|
| Module Graph | project-analyzer | 模块依赖、循环依赖、跨层依赖（graph.json） |
| Symbol Graph | 外部 provider（CodeGraph） | symbols / calls / references / impact |

### 实现

1. `graph.schema.json` 加 `capabilities` 数组（仅元数据，不存储 symbol 数据）
2. `graph-query.md` 升级为"图能力协议"——预留 symbol.*/call.*/impact.* 查询
3. `graph.json` 是 Module Graph 的 portable artifact，**不是** CodeGraph 数据库

## 理由

自己做 symbol 级静态分析 = 长期维护一个 compiler/tooling 项目（AST、type resolution、reference analysis、incremental indexing），这不是几百行代码的事。

project-suite 的核心竞争力是：
- Context Resolution
- Knowledge Promotion
- Workflow Orchestration
- Project Knowledge

而不是"再实现一个 TypeScript language server"。

## 后果

### 正面
- 避免造轮子，专注差异化能力
- graph.json 保持轻量，不与 symbol 数据耦合
- 未来可替换 provider（TypeScript→CodeGraph, Python→Pyright, Go→gopls），Skill 不用改

### 负面
- 依赖外部 provider 的可用性
- symbol 级查询能力不在 project-suite 控制范围内
- 需要 provider 与 Graph Query Protocol 对齐

### 未来触发重新考虑的条件
- 外部 provider 不可用且 symbol 级查询成为硬需求
- 出现轻量、易维护的 symbol 索引方案（非完整 compiler）
