# Orchestration

> 跨 skill 工作流编排规则。定义 skill 之间的数据流、状态传递、链式触发。

## 编排原则

1. **不自动级联** — 上游 skill 完成不自动触发下游，而是建议用户
2. **数据通过文件传递** — skill 之间通过 manifest + 产出文件通信，不依赖内存状态
3. **可跳过任意环节** — 用户可以跳过任意 skill，直接从需求到 generator

## 标准工作流链

### 全流程（绿色field 项目）

```
analyzer → planner → architect → generator → tester → reviewer → documenter → releaser
  │          │           │            │           │          │           │          │
  │          │           │            │           │          │           │          │
 知识库    PLAN.md   ARCH.md       代码       测试报告   REVIEW.md   文档     CHANGELOG
```

### 功能开发流程（已有项目）

```
planner → architect → generator → tester → reviewer
```

### 重构流程

```
analyzer → refactorer → tester → reviewer
```

### 发布流程

```
reviewer → documenter → releaser
```

## 数据契约

### Skill 间传递物

| 上游 → 下游 | 传递内容 | 传递方式 |
|------------|---------|---------|
| analyzer → * | `.project-knowledge/` 路径 + manifest | manifest.projectKnowledgePath |
| planner → architect | PLAN.md（任务列表 + 依赖） | manifest.planPath |
| architect → generator | ARCHITECTURE.md（技术选型 + 模块设计） | manifest.architecturePath |
| generator → tester | 变更文件列表 | manifest.changedFiles |
| tester → reviewer | 测试报告路径 | manifest.testReportPath |
| reviewer → refactorer | REVIEW.md 中的问题列表 | manifest.reviewPath |
| * → documenter | 各环节产出文件列表 | manifest.allOutputs |
| * → releaser | 变更摘要 + 版本信息 | manifest.changeSummary |

### Manifest 扩展字段

每个 skill 的 manifest 在标准字段基础上可扩展：

```json
{
  "extends": {
    "projectKnowledgePath": ".project-knowledge/",
    "planPath": null,
    "architecturePath": null,
    "changedFiles": [],
    "testReportPath": null,
    "reviewPath": null,
    "allOutputs": [],
    "changeSummary": null
  }
}
```

## 编排信号

### 上游完成信号

当上游 skill 写入 `nextSuggestion` 字段后，用户看到：

```
✅ analyzer 完成
   📂 产出：.project-knowledge/
   📋 建议下一步：planner — "帮我拆解需求为开发任务"
```

### 用户跳过

```
用户: "直接写代码，不用规划"
→ 跳过 planner + architect → 直接 generator
→ generator 以默认模式执行（缺少 PLAN.md + ARCHITECTURE.md 时不阻塞）
```

## 并行执行

同一条链上不可并行（存在数据依赖），但不同分支可以：

```
analyzer ─→ planner ─→ architect
                │
                ├─→ generator(feature-A) ─→ tester ─→ reviewer
                │
                └─→ generator(feature-B) ─→ tester ─→ reviewer
                                              │
                                         documenter ─→ releaser
```

各分支独立 manifest，互不冲突。
