# Execution — Generator

> @template: execution
> Session Snapshot: 每个文件生成后写入 `.project-knowledge/.sessions/project-generator/state.json` → 跨 session resume

## Actions

### Phase 1: Candidate Generation

```
`@adapter:knowledge.query type=pattern,component --scope project` → `@adapter:filesystem.search "similar implementation" workspace/` → 提取模式 → 套用模式生成 → `@adapter:filesystem.write <file>` → Candidate 代码
```

### Phase 2: Verification

→ [prompts/verifier.md](verifier.md)

对每个 Candidate 代码文件执行 Verify：
- V1 Import 可达 → 所有 import 路径指向存在的文件
- V2 组件复用 → graph.json 中无同功能组件
- V3 模式一致 → 风格与 `patterns/` 一致
- V4 类型完整 → 无 any 滥用
- V5 状态覆盖 → loading/error/empty 三态
- V6 非重复 → graph.json 中无同名节点

判定：全部通过 → Accepted → 写入文件。V1/V2 失败 → Rejected → 修正。V3-V6 部分失败 → Accepted + 标注修复建议。

⚡ 每个文件写入后 snapshot: `files_generated: [<ComponentName>.<ext>, ...]` → 中断后跳过已完成文件。

### 1. 结构化知识查询

不读 .md 文件。通过 [Knowledge Query API](../../../runtime/contracts/knowledge-query.md) 查询 `graph.json`：

```bash
# 查询可复用组件
@knowledge:type=component scope=project
# 查询目标模块的 pattern
@knowledge:type=pattern tags=<target_module>
# 查询命名/import 等 convention
@knowledge:type=convention scope=project
# 查询已有 API（避免重复生成）
@knowledge:type=api scope=project
```

降级：`graph.json` 缺失 → 读 `context-package.json` → `context.json`。

### 2-3. Graph 查询 + 参考实现
→ [Graph Query Protocol](../../../runtime/contracts/graph-query.md)
- `findNode("component")` → 已存在 → 标记 `[REUSE]`，输出 import 路径
- `findNode("api")` → 已存在 → 直接 import
- `findProducers(<当前模块>)` → 了解已有上游，复用

### 4. 套用模式生成
- 遵循 patterns 知识（Context Resolver 注入） 中的编码规范
- `@adapter:knowledge.query --type component --scope project` → 使用已有组件
- 匹配项目约定：缩进/引号/命名/import 顺序

### 5. 自检
→ [references/self-check.md](../references/self-check.md)：
- Import 路径存在性
- 组件未重复生成
- TS 类型完整（无 `any` 滥用）
- loading/empty/error 状态覆盖

🔴 CHECKPOINT — 展示代码摘要（文件清单+关键片段），用户确认后写入

## Decision Record

```yaml
decisions:
  - id: D1
    decision: "表单组件: 使用 <统一表单封装>"
    selected: "<统一表单封装>"
    ignored:
      - { option: "原生表单组件", reason: "不符合项目规范, Reviewer 会标记为 antipattern" }
    reason: "项目 convention, 331 files use it"
    evidence: ["conventions: <统一表单封装> is standard"]
    confidence: 0.96
    risk: "无"
    owner: "generator"
```

## Exit

- 所有代码文件写入成功
- 自检清单全部通过
- confidence 已计算
- Reasoning Report 已生成

## Failure

| Condition | Action |
|-----------|--------|
| 目标文件已存在 | `Read` → diff 理解现状 → `Edit` 增量修改，标注 `[已存在]` |
| 需新增依赖（package.json 未安装） | 使用已有依赖的替代方案 → 标注 `TODO: 安装 {package}` |
| 无类似实现可参考（全新模式） | 使用 `context.json` 项目约定生成 → 标注 `⚠️ 全新模式，建议人工审核` |
| `context-package.json` 缺失且 PLAN.md 缺失 | 🔴 BLOCKER — 提示先执行 planner |

## Confidence Gate

→ [confidence.yaml](../../../runtime/mechanisms/confidence.yaml)：<70 🟠 GATE 必须Review，≥95 🟢 直通
