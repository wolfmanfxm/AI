# Prompt Quality Checklist v1.0

> 每个 Stage Prompt 的自评清单。在 Review Studio 审查时使用。
> yao-meta-skill prompt-quality 要求。

## 评估维度

| Dimension | Weight | Question |
|-----------|--------|----------|
| **Clarity** | 25% | 指令是否无歧义？一个没看过代码的人能否理解要做什么？ |
| **Completeness** | 25% | 是否覆盖了所有该 stage 需要做的事？有遗漏步骤吗？ |
| **Actionability** | 20% | 每一步是否有明确的产出？"分析"太模糊，"读 package.json 提取 framework 字段"才可操作 |
| **Error Handling** | 15% | Failure 表是否覆盖了该 stage 的主要失败场景？ |
| **Conciseness** | 15% | 是否有冗余描述？是否每条指令都有存在理由？ |

## 评分

| Score | 标准 |
|-------|------|
| 90-100 | 可直接交给新 agent 执行，无需额外解释 |
| 70-89 | 可用但有 1-2 处需要 human clarification |
| 40-69 | 有歧义或遗漏，需要修改后才能可靠执行 |
| <40 | 重写 |

## 自评模板

每个 `prompts/<stage>.md` 末尾可加（可选）：

```markdown
## Prompt Quality Self-Assessment

| Dimension | Score | Notes |
|-----------|-------|-------|
| Clarity | /25 | |
| Completeness | /25 | |
| Actionability | /20 | |
| Error Handling | /15 | |
| Conciseness | /15 | |
| **Total** | /100 | |
```

## 审查时检查

Review Studio 审查时抽查至少 1 个 stage prompt 的质量：读 prompt → 能否仅凭 prompt 完成该 stage？标记模糊/遗漏/冗余处。
