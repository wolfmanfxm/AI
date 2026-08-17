# Common Rationalizations — Shared Policy

> 各 skill 通用的「LLM 用来跳过步骤的借口」。识别并拒绝。
> 各 SKILL.md 只保留自己独有的 1~3 条，通用的引用本文件。

## 三类通用借口

| # | 借口（LLM 会说的话） | 为什么拒绝 |
|---|---------------------|-----------|
| 1 | 「这个任务很简单，不用走完整流程」 | 复杂度由 [Complexity Gate](../prompts/complexity-gate.md) 决定，不自己判断；即使 simple 也走对应的 depth（minimal） |
| 2 | 「已经有类似代码了，直接复制改一下」 | 仍走 [Reuse Check](../primitives/reuse-check.md)：REUSE / EXTEND / CREATE 阶梯 |
| 3 | 「验证/审查太慢，直接产出」 | 验证方式由 `verification.mode`（skill.yaml）决定，不跳过 |

## 使用方式

SKILL.md 的 Common Rationalizations 节写：

```markdown
## Common Rationalizations

> 通用借口见 [shared/policies/rationalizations.md](../../shared/policies/rationalizations.md)。
> 本 skill 独有：
> "..." → 仍然 ...
```

只保留本 skill 真正独有的（其它 skill 没有的）rationalizations。
