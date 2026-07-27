# Workflow: feature

> 新功能开发。从需求到代码审查的完整流程。

## 触发
- 用户说"实现 XX 功能""开发 XX""新增 XX 页面"
- 有 PRD/需求文档

## 流程

```
analyzer ──→ planner ──→ architect ──→ generator ──→ tester ──→ reviewer
  │            │            │              │            │           │
  │ produces:  │ produces:  │ produces:    │ produces:  │ produces: │ produces:
  │ KB+Context │ Plan       │ Architecture │ Code       │ Test      │ Review
  ↓            ↓            ↓              ↓            ↓           ↓
  Knowledge    Knowledge    Knowledge      Knowledge    Knowledge   Knowledge
      ↓            ↓            ↓              ↓            ↓
      └────────────┴────────────┴──────────────┴────────────┘
                        所有下游只依赖 Knowledge，不直接依赖上游 Skill
```

## 各步详情

| Step | Skill | 输入 | 输出 | CHECKPOINT |
|------|-------|------|------|------------|
| 1 | analyzer | 源码目录 | KnowledgeBase + Context | 确认分析范围 |
| 2 | planner | KnowledgeBase + Context + 需求 | Plan（任务+依赖+估时+风险） | 确认需求理解 |
| 3 | architect | KnowledgeBase + Plan | Architecture（ADR + 模块图） | 确认设计范围 |
| 4 | generator | KnowledgeBase + Plan + Architecture + Context | Code | 确认生成范围 |
| 5 | tester | Code | Test + TEST-REPORT | — |
| 6 | reviewer | Code + Plan | Review（五轴审查） | 确认审查范围 |

## 可跳过

| 跳过 | 条件 | 影响 |
|------|------|------|
| architect | 无架构决策需求（简单 CRUD） | generator 无 Architecture 输入，按默认模式 |
| tester | 手动测试可接受 | 无测试覆盖 |
| analyzer | 已有 `.project-knowledge/` | 使用已有知识库 |

## 并行机会

```
analyzer → planner → architect → generator
                                      ↓
                              ┌───────┴───────┐
                              ↓               ↓
                           tester         documenter
                              ↓               │
                           reviewer ←─────────┘
```
