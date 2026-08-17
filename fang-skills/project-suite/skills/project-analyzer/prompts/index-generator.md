# INDEX Generator

> 生成 Zettelkasten 风格 Knowledge Graph。不是目录，是可导航的知识链接图。

## Actions

1. 读取所有 Accepted Candidates
2. 提取每个知识点的标签和引用关系
3. 构建链接图：Architecture → Patterns → Components → API → Glossary
4. 生成 INDEX.md

## Output: INDEX.md

```markdown
# Knowledge Index

> Zettelkasten-style knowledge graph. Follow links to navigate.

## Architecture
- [[modules]] — 模块划分与职责
- [[tech-stack]] — 技术栈选型
- [[layers]] — 分层架构 (view → composable → api → store)
  - → [[composables]] — 组合式函数模式
  - → [[api-patterns]] — API 调用模式

## Patterns
- [[repository]] — Repository Pattern (18 occurrences)
  - ← [[api-patterns]] — Repository 封装了 API 调用
- [[composition]] — Composition Pattern (34 occurrences)
  - → [[conventions.naming]] — useXxx 命名规范
- [[factory]] — Factory Pattern (5 occurrences)
- [[provider]] — Provider/Inject Pattern (8 occurrences)

## Components
- [[catalog]] — 组件目录
  - → [[<表格组件>]] — 核心表格组件
  - → [[<表单容器>]] — 表单容器组件
  - → [[<字典选择>]] — 字典选择器

## API
- [[api-overview]] — API 总览
  - → [[api-conventions]] — API 调用规范
  - → [[request]] — 请求封装

## Conventions
- [[naming]] — 命名规范 (PascalCase/kebab-case/camelCase)
- [[imports]] — Import 顺序规范
- [[directory]] — 目录结构规范
  - ← [[modules]] — 目录结构反映了模块划分

## Glossary
- [[glossary]] — 领域术语表
  - → [[Voucher]] — 凭证
  - → [[Order]] — 订单
  - → [[Approval]] — 审批

## Decisions
- [[decisions]] — 架构决策记录
  - → [[D1-pnpm]] — 为什么用 pnpm
  - → [[D2-workspace]] — 为什么拆 workspace/src
  - → [[D3-strict]] — 为什么 strict:true

## Risks
- [[risks]] — 风险与技术债
  - → [[god-components]] — God Component 清单
  - → [[circular-deps]] — 循环依赖清单

## Anti-Patterns
- [[antipatterns]] — 反模式清单
  - → [[god-objects]] — God Object 清单
  - → [[any-abuse]] — any 滥用清单

---

> Links: `[[page]]` = internal, `→` = depends on, `←` = depended by
> Generated: YYYY-MM-DD | Extractor count: 9 | Candidates accepted: N
```

## Link Syntax

- `[[page]]` — 内部链接（同目录 .md 文件）
- `→` — 当前知识点依赖的目标
- `←` — 依赖当前知识点的来源
