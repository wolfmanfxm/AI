# Workflow: refactor

> ⚠️ **v0.7.0: 此 .md 工作流已废弃。** 保留为历史参考。
> 当前编排协议：`runtime/protocols/orchestration.md`（User-as-Dispatcher）

## 历史（v0.4.0 自动流水线，已废弃）

> 代码重构。改善结构不改变行为。

## 触发

- 用户说"重构 XX""优化 XX 结构""提取公共""简化这段代码"

## 流程

```
reviewer -> refactorer -> tester -> reviewer
  |            |            |           |
  | produces:  | produces:  | produces: | produces:
  | Review     | RefCode    | Test      | Review
  |(baseline)  |            |           |(verify)
  v            v            v           v
  Knowledge    Knowledge    Knowledge   Knowledge
```

## 为什么先 review

重构前审查建立基线，确认:
- 当前代码的坏味道位置
- 哪些地方需要重构
- 避免重构不该动的地方

## 各步详情

| Step | Skill | 输入 | 输出 | CHECKPOINT |
|------|-------|------|------|------------|
| 1 | review | Code(原始) | Review(baseline) | - |
| 2 | refactor | Code + Review + Test(原始) | RefactoredCode | 确认重构范围 |
| 3 | tester | RefactoredCode | Test(回归) | - |
| 4 | reviewer | Code(diff) | Review(verify) | 行为不变验证 |

## 前置条件

- 重构前必须跑通现有测试
- 无测试 → refactorer 先加表征测试
- 每步独立 commit，可独立回滚
