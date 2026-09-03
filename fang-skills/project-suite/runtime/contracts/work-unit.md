# Work Unit Contract

> 同一阶段内，Agent 平级生产结构化 Artifact；跨 Agent 不传自然语言上下文；程序按 `work_unit.id` 确定性汇合。
> 这是「去中心化蜂群」思想的落地点——但**不是 Agent Engine**：无 Coordinator、无 Message Bus、无 Agent Registry。

## 定义

一个 Work Unit 是最小可独立执行、可独立验证、可独立恢复的产出单元：

```yaml
work_unit:
  id: EX-API                        # 全局唯一，程序按它汇合结果
  producer: api-extractor           # 谁产出（skill 或 agent）
  input:
    artifacts: []                   # 上游 typed artifact（对齐 artifact-types.yaml）
    knowledge: []                   # 注入的知识
  output:
    capability: KnowledgeBase       # 产出能力类型（对齐 capabilities.yaml capability_types）
    artifact: candidates/api.yaml   # 物理产出路径
  dependencies: []                  # 依赖的 work_unit id 列表
  status: pending | running | completed | failed
  evidence:                         # 每个 claim 的证据（file:line + 次数）
    - { file: src/api.ts, line: 42, count: 3 }
  confidence: 0-100                 # 产出置信度
```

## 七条规则

1. **Work Unit 独立** — 每个单元边界清晰，不共享可变状态。
2. **有明确 Producer** — 谁产出谁负责，产出物可溯源。
3. **有 Typed Output** — 输出必须是声明过的 Capability / Artifact Type，不输出「自由文本结果」。
4. **跨 Agent 不传自然语言上下文** — 结果只通过结构化 Artifact 传递，避免 Coordinator 再理解、再转述。
5. **无依赖 Work Unit 可并行** — 依赖从 `dependencies`（或 produces/consumes）推导，不由人拍脑袋分波。
6. **Merge 优先程序确定性完成** — 汇合由程序按 `id` 排序 / 去重 / schema 校验完成，不引入语义转述。
7. **只有冲突才调用 Resolver / Reviewer** — 汇合失败或结果矛盾时才升级到 Agent 裁决，正常路径不调 Agent。

## 参考实现：project-analyzer

Analyzer 已是这套模式的工作实现，本契约只是把它命名出来：

| 规则 | Analyzer 对应 |
|------|--------------|
| Work Unit 独立 | 10 个 Extractor，每个只提取一种知识 |
| Typed Output | 每个 Extractor 输出 Evidence Format 的 YAML Candidate |
| 无依赖可并行 | Phase 1 按 category 并行 spawn agent |
| 确定性 Merge | Phase 2-4：verify → cross-validate → knowledge-builder（程序按序汇合） |
| 冲突才升级 | 仅 Cross-Validator 发现矛盾才标注降级，正常路径不调 Agent |

详见 [skills/project-analyzer/prompts/execution.md](../../skills/project-analyzer/prompts/execution.md)。

## 边界（不是什么）

- ❌ 不是 Agent Registry / Swarm Manager / Message Bus。
- ❌ 不是「新增编排层」——Coordinator 只生成 Work Manifest（task 列表），不参与结果语义转述。
- ❌ 不引入新 Skill——Extractor 是 Agent Work Unit，Analyzer 才是 Protocol boundary。
- ✅ 是「已有模式的命名收敛」——把 parallel-extract → verify → merge 固化为可复用契约。

## 与 Runtime 的分工

- **Host / Runtime** 决定是否真的 parallel、是否 checkpoint、是否 block——本契约只定义「单元的边界与汇合方式」。
- **并行关系** 从 `dependencies` / produces-consumes 推导，不在本契约里手工指定 wave（见 ADR-003「并行关系 = 同 wave 内无依赖即并行（推导）」）。
