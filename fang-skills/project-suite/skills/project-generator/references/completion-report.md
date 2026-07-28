# 完成报告

代码写入后输出 plan vs actual 对比 + Knowledge 使用反馈。

## Plan vs Actual

若 PLAN.md 存在，逐任务对比：

```markdown
| PLAN 任务 | 预估 | 实际 | 偏差说明 |
|-----------|------|------|---------|
| T0 路由+API | 1.5d | 已存在 | 前序迭代已完成 |
| T1 列表页 | 2d | 1d | PageTable 直接复用 |
```

## Knowledge Used（知识评分反馈）

记录本次使用了哪些 Accepted 知识，以及采用效果：

```markdown
## Knowledge Used
| 知识 | 来源 | 采用程度 | 结果 | 说明 |
|------|------|---------|------|------|
| patterns/upload.md | .project-knowledge/ | 完全采用 | good | 直接复用分片上传模式 |
| patterns/crud.md | .project-knowledge/ | 部分采用 | partial | 参考了分页逻辑，搜索条件自定义 |
| patterns/table.md | .project-knowledge/ | 未采用 | skipped | 本次是卡片布局，不适用 |
```

→ 评分规则详见 [Knowledge Scoring](../../../runtime/state/schemas/knowledge-scoring.md)

## Candidate 发现

若本次生成了此前项目中不存在的模式，标注为 Candidate：

```markdown
## Candidate Discovery
| 候选模式 | 首次出现 | 建议路径 | one_off |
|---------|---------|---------|---------|
| 多级审批流组件 | 本次任务 | candidate/approval-flow.md | false |
```

- `one_off: true` → 纯业务逻辑，不会晋升为 Accepted
- `one_off: false` → 有复用潜力，进入 Candidate 观察
