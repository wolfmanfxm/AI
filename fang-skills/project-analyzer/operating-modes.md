# Operating Modes

本 skill 工作在 `Production` 模式。

## Mode: Production

| 属性 | 值 |
|------|-----|
| 目标用户 | 团队开发者 |
| 复用频率 | 高（每次迭代/新成员入职/代码审查前） |
| 输出稳定性 | 稳定（固定产出 schema：manifest.json + index.md + 维度文档） |
| 证据门槛 | 每个结论需 `file:line` 引用 |
| 回滚边界 | 不修改业务代码，仅写 `.project-knowledge/` 和 Obsidian Vault |
| 质量门 | 所有维度分析完成后需通过 `index.md` 一致性检查 |

## 模式选择依据

- 非 `Scaffold`：有明确的固定产出 schema，不是探索性工具
- 非 `Library`：不对外暴露 API，不供其他 skill 调用
- 非 `Governed`：不需要 release-critical 级别的审批流程
- 选 `Production`：团队内稳定复用，有明确输入→输出契约
