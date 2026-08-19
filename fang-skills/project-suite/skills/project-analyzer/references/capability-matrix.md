# Capability Matrix

## 能力边界

### 保证能力

✓ 架构分析
✓ 组件编目
✓ API 发现
✓ 模式提取
✓ 编码风格分析
✓ 知识索引生成
✓ 增量刷新
✓ 开发前检查

### 不做

✗ 业务需求分析
✗ 运行时分析
✗ 安全审计
✗ 性能基准测试
✗ 部署验证
✗ 代码重构
✗ 测试生成

> 触发词命中了但意图落在"不做"区域 → 不调用本 skill，直接告知用户边界。

## 产出契约

**固定产出** — 每次必定生成：`manifest.json`（含 `knowledgeVersion` + `schemaVersion`）、`statistics.json`、`search-index.json`、`graph.json`、`index.md`。字段定义见 [../../../runtime/mechanisms/checkpoint.md](../../../runtime/mechanisms/checkpoint.md)。

**按需产出** — 由 8 个维度并行 agent 按实际代码检测结果动态生成，有内容才建文件。

**人工维护** — 以下目录分析仅首次创建占位 `index.md`，后续绝不覆盖：

| 目录 | 维护者 | 说明 |
|------|--------|------|
| `rules/` | 人工 | 团队编码规则 |
| `experience/` | 人工 | 项目经验教训 |
| `playbooks/` | 人工 | 操作手册 |
| `decisions/` | 人工 | 架构决策记录 |

## 覆盖策略

非首次运行时，已有文档遵循以下覆盖策略：

**自动覆盖** — 每次分析无条件覆盖（机器生成内容，不应人工编辑）：

```
architecture/   components/   api/
patterns/       observations/ reports/
manifest.json   statistics.json   graph.json
search-index.json   index.md
```

**永不覆盖** — 即使文件已存在也绝不覆盖（人工维护内容）：

```
rules/     experience/     playbooks/     decisions/
```

对比标记：非首次运行时，自动覆盖区域的文件对比后标注 `[NEW]` / `[CHANGED]` / `[REMOVED]` / `[CONFIRMED]`；永不覆盖区域跳过不处理。

---

## Prompt Capability Matrix

| Prompt | 输入 | 输出目录 | 依赖 |
|--------|------|---------|------|
|--------|------|---------|------|
| [prompts/architecture.md](../prompts/architecture.md) | `package.json` + 目录结构 | `architecture/` | 无 |
| [prompts/components.md](../prompts/components.md) | `src/components/` `workspace/components/` | `components/` | architecture（组件目录位置） |
| [prompts/coding-style.md](../prompts/coding-style.md) | `.vue` `.ts` 文件抽样 | `patterns/` | architecture（技术栈确认） |
| [prompts/api-pattern.md](../prompts/api-pattern.md) | `src/api/` `workspace/api/` | `api/` | architecture（API 目录位置） |
| [prompts/ui-pattern.md](../prompts/ui-pattern.md) | 视图模板代码抽样 | `patterns/` | components（已知可用组件） |
| [prompts/patterns.md](../prompts/patterns.md) | architecture/ + components/ + api/ | `patterns/` | architecture + components + api |
| [prompts/observations.md](../prompts/observations.md) | 全部已有产出 | `observations/` | 所有前序维度 |
| [prompts/change-analysis.md](../prompts/change-analysis.md) | git diff + 已有产出 | `reports/` | architecture（模块结构） |

## 并行策略

```
Wave 0（无依赖，可立即并行）
  architecture

Wave 1（依赖 architecture，4 个可并行）
  components  coding-style  api-pattern  change-analysis

Wave 2（依赖 Wave 1，2 个可并行）
  ui-pattern（需 components）  patterns（需 architecture + components + api）

Wave 3（依赖全部前序）
  observations
```
