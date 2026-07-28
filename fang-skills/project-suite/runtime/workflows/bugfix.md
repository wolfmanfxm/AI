# Workflow: bugfix

> ⚠️ **v0.7.0: 此 .md 工作流已废弃。** 保留为历史参考。
> 当前工作流模板：`runtime/workflows/quick-change.yaml`（YAML 格式，User-as-Dispatcher）
> 编排协议：`runtime/protocols/orchestration.md`

## 历史（v0.4.0 自动流水线，已废弃）

> Bug 修复。最小化流程，跳过规划和架构。

## 触发

- 用户说"修复 XX bug""这个报错了""XX 不工作"
- Issue / 错误日志

## 流程

```
generator -> tester -> reviewer
  |            |           |
  | produces:  | produces: | produces:
  | Code       | Test      | Review
  v            v           v
  Knowledge    Knowledge   Knowledge
```

## 为什么跳过 planner + architect

Bug 修复通常不需要需求拆解和技术选型。直接定位、修、测、审。

## 各步详情

| Step | Skill | 输入 | 输出 |
|------|-------|------|------|
| 1 | generator | Code(报错文件) + Context | Code(修复) |
| 2 | tester | Code(修复) | Test(回归) |
| 3 | reviewer | Code(diff) | Review |

## 变体: 有 review 建议的修复

```
reviewer -> generator -> tester -> reviewer
  |           |          |          |
  | produces: |          |          |
  | Review    |          |          |
  |(含建议)    |          |          |
  +---------->|          |          |
              | consumes:|          |
              | Review   |          |
```
