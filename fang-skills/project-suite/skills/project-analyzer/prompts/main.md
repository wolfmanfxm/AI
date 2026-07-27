# Main Prompt — Analyzer

> 入口 prompt。根据用户意图路由到对应的分析流程。

## 路由规则

| 用户意图 | 路由 | 专用 prompt |
|---------|------|-----------|
| 首次分析、扫描项目 | Analysis Flow → Phase 1 Discover | 见 SKILL.md Discover 阶段 |
| manifest status = interrupted/partial | Phase 2 Resume | 见 SKILL.md Execute 阶段 |
| 开发前检查、写代码前参考知识库 | Development Flow | 见 [../references/development-flow.md](../references/development-flow.md) |

## 维度 Prompts

执行分析时，按 Wave 分组并行 spawn agent，每个 agent 加载对应维度 prompt：

| Wave | 维度 | Prompt | 输出目录 |
|------|------|--------|---------|
| 0 | 架构 | [architecture.md](architecture.md) | architecture/ |
| 1 | 组件 | [components.md](components.md) | components/ |
| 1 | 编码风格 | [coding-style.md](coding-style.md) | patterns/ |
| 1 | API 模式 | [api-pattern.md](api-pattern.md) | api/ |
| 1 | 变更分析(详尽) | [change-analysis.md](change-analysis.md) | reports/ |
| 2 | UI 模式 | [ui-pattern.md](ui-pattern.md) | patterns/ |
| 2 | 通用模式 | [patterns.md](patterns.md) | patterns/ |
| 3 | 观察统计 | [observations.md](observations.md) | observations/ |

## 产出格式

所有输出文件格式见 [output-format.md](output-format.md)，Evidence Header 见 [../../../shared/templates/evidence-header.md](../../../shared/templates/evidence-header.md)。

## 要求

遵循 SKILL.md 中的完整工作流。CHECKPOINT 处必须停顿等待用户确认。
