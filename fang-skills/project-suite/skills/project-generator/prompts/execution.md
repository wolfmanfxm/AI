# Execution — Generator

> @engine: execution

## Actions

```
读知识库 → Graph 查询 → 找参考实现 → 提取模式 → 套用模式生成 → 自检
```

### 1. 读知识库
- 优先读 `context-package.json`（Planner 产出，唯一知识入口）
- 遍历 `context.knowledge[]` → 注入 pattern + constraints
- 遍历 `context.components[]` → reuse=true 直接 import
- 遍历 `context.api[]` → 按 conventions 生成 API 调用
- 降级：`context-package.json` 缺失 → `knowledge-list.json`（v1 兼容）

### 2-3. Graph 查询 + 参考实现
→ [Graph Query Protocol](../../../runtime/contracts/graph-query.md)
- `findNode("component")` → 已存在 → 标记 `[REUSE]`，输出 import 路径
- `findNode("api")` → 已存在 → 直接 import
- `findProducers(<当前模块>)` → 了解已有上游，复用

### 4. 套用模式生成
- 遵循 `.project-knowledge/patterns/` 中的编码规范
- 使用 `components/catalog.md` 中的现有组件
- 匹配项目约定：缩进/引号/命名/import 顺序

### 5. 自检
→ [references/self-check.md](../references/self-check.md)：
- Import 路径存在性
- 组件未重复生成
- TS 类型完整（无 `any` 滥用）
- loading/empty/error 状态覆盖

🔴 CHECKPOINT — 展示代码摘要（文件清单+关键片段），用户确认后写入

## Exit

- 所有代码文件写入成功
- 自检清单全部通过
- confidence 已计算

## Failure

| Condition | Action |
|-----------|--------|
| 目标文件已存在 | `Read` → diff 理解现状 → `Edit` 增量修改，标注 `[已存在]` |
| 需新增依赖（package.json 未安装） | 使用已有依赖的替代方案 → 标注 `TODO: 安装 {package}` |
| 无类似实现可参考（全新模式） | 使用 `context.json` 项目约定生成 → 标注 `⚠️ 全新模式，建议人工审核` |
| `context-package.json` 缺失且 PLAN.md 缺失 | 🔴 BLOCKER — 提示先执行 planner |

## Confidence Gate

→ [confidence.yaml](../../../runtime/engine/confidence.yaml)：<70 🟠 GATE 必须Review，≥95 🟢 直通
