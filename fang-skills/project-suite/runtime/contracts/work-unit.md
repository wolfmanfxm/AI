# Work Unit Contract

> 去中心化协作的最小抽象（蜂群思想）。
> 同一阶段内：Agent 平级生产结构化 Artifact；跨 Agent 不传递自然语言上下文；程序按 Work Unit ID 确定性汇合；只有冲突才升级到 Resolver。
> 不是 Agent Engine——没有 Coordinator / Message Bus / Agent Registry。

## Work Unit 结构

```yaml
work_unit:
  id: <unique>
  producer: <skill-or-agent>
  input:
    artifacts: []
    knowledge: []
  output:
    capability: <Capability>
    artifact: <path>
  dependencies: []
  status: pending | running | completed | failed
  evidence: []
  confidence: 0-100
```

## 七条规则

1. Work Unit 独立
2. 有明确 Producer
3. 有 Typed Output
4. 不通过自然语言向另一个 Agent 传递结果
5. 无依赖 Work Unit 可并行
6. Merge 优先程序确定性完成
7. 只有冲突才调用 Resolver / Reviewer

## 参考实现：Analyzer 的 Extractor

Analyzer 的 10 个 Extractor 已经是 Work Unit 模式（见 `skills/project-analyzer/prompts/execution.md`）：

```
registry 驱动 → 按 category 并行 spawn → 输出 Evidence Format YAML Candidate
       ↓
Candidate → Verify（5-Verify）→ Cross-Validate → Knowledge Build
       ↓
确定性 Merge（程序按 id 汇合，无自然语言转述）
```

## 未来 Work Unit：Conflict Resolver（规则 7 的落地，尚未实现）

> 当前 Cross-Validator（`prompts/cross-validator.md`）的处理是「标注 + confidence 降级 + 严重标人工审核」，够用。本条为未来「中等冲突需自动决策」预留。

当 Cross-Validator 发现冲突时，on-demand spawn 一个 Resolver Work Unit：

```
Conflict (A: pattern X  vs  B: pattern Y)
        ↓
Resolver Agent（仅冲突时 spawn，平级，非协调器）
        ↓
Decision（Typed）: pick A / pick B / merge / escalate + rationale + evidence
```

三条约束（否则就退化成 Orchestrator）：

1. **on-demand** —— 只在冲突时 spawn，无冲突不出现，不是常驻协调器。
2. **Typed Decision** —— 输出 `{decision: pick|merge|escalate, winner, rationale, evidence}`，程序可确定性消化，不用自然语言向别的 Agent 转述。
3. **分层升级** —— 清晰冲突 resolver 定；真正两可 / 高风险的仍 escalate 给用户（Dispatcher），不替代人。

**落地时机**：出现「中等冲突被降级后，模糊知识导致下游出错」的真实场景时，再实现为 `skills/project-analyzer/prompts/conflict-resolver.md` + Phase 3.5。
