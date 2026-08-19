# Execution — Architect

> @template: execution

## Actions

### 0. 查询已有决策：`@adapter:knowledge.query --type decision --scope project`（先查再设计）

### 按用户意图路由：

### "选什么技术" → 技术选型

→ [prompts/tech-selection.md](tech-selection.md)

1. 列出候选方案（≥2）
2. 构建对比矩阵（维度 ≥3：性能/生态/团队熟悉度/社区活跃度/许可）
3. 标注推荐方案 + 分差说明
4. 输出 ADR 格式决策记录（问题→候选→选择→理由）

### "模块怎么划分" → 模块设计

→ [prompts/module-design.md](module-design.md)

1. 基于现状核实 + Graph 分析结果
2. 设计模块边界（public API / 内部实现）
3. 定义模块间依赖方向（单向依赖、无循环）
4. 输出模块图（mermaid）+ 边界说明

### "API 怎么设计" → API 契约

→ [prompts/api-design.md](api-design.md)

1. 每个 endpoint：method + path + request（params/body/headers）+ response（status/data/errors）
2. 标注幂等性、速率限制、鉴权要求
3. 标注与 Graph 中已有 API 的兼容关系

### 综合设计 → 1→2→3 顺序

每步 CHECKPOINT — 用户确认当前步骤后再进入下一步。

🔴 CHECKPOINT — 展示 ARCHITECTURE.md 摘要（决策数 + 模块图 + API 概要）

## Decision Record

每个 ADR 输出标准化 Decision Record：

```yaml
decisions:
  - id: D1
    decision: "状态管理: 使用 Pinia"
    selected: "Pinia"
    ignored:
      - { option: "Vuex", reason: "Vue3 官方不再推荐, TS 支持弱" }
      - { option: "raw reactive", reason: "缺少 devtools/持久化/模块化" }
    reason: "Vue3 官方推荐, TypeScript 支持优于 Vuex, 项目已有 11 stores"
    evidence: ["package.json: pinia 2.1", "src/stores/ 含 11 stores"]
    confidence: 0.95
    risk: "无"
    owner: "architect"
```

## Exit

- 所有设计决策已记录（ADR 格式）
- 无未 resolve 的 trade-off
- Reasoning Report 已生成
- 用户已确认

## Failure

| Condition | Action |
|-----------|--------|
| 对比矩阵分差 <10%（无明确最优） | 展示完整对比 + 权衡分析 → AskUserQuestion 让用户选择 |
| PLAN.md `# Decision` 为空（无待 resolve 决策） | 自行识别架构决策点 → 标注 `⚠️ 自行识别决策点` |
