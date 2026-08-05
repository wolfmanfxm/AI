# Discovery — Generator

> @engine: discovery

## Actions

0. **Context Resolver** → [Context Resolver](../../../runtime/contracts/context-resolver.md)：从用户需求提取 tags → 查询 `knowledge-graph.yaml` → 注入相关 patterns/components/conventions
1. 读项目知识库：`context.json` → `context-package.json`（Planner 产出）→ `components/catalog.md`
2. **Graph 查询**（不搜索代码库）：
   - `findNode("component", <目标>)` → 已存在 → `[REUSE]`，不生成
   - `findNode("api", <目标>)` → 已存在 → 直接 import，不复创建
   - 仅 graph.json 中不存在的 → 进入生成流程
3. 代码存在性检查 → [references/code-audit.md](../references/code-audit.md)
4. 找类似实现：grep 同模块其他页面的 import/组件使用方式，确认技术栈和模式
5. CHECKPOINT — 展示过滤后改动范围（新建/修改文件清单 + 每文件预估行数 + REUSE 标注）

## Exit

- 用户确认改动范围（文件清单 + 预估行数 + REUSE 标注）
- `manifest.json` status = confirmed

## Failure

| Condition | Action |
|-----------|--------|
| `context.json` 缺失 | 从 `.project-knowledge/` 手工提取（读 index.md + architecture/） |
| Graph 不可用（graph.json 缺失） | grep import 手动分析依赖 → 标注 `⚠️ 无 Graph` |

## CHECKPOINT

🔴 CHECKPOINT — 展示改动范围，用户确认后进入 Execution
→ [checkpoint-pattern](../../../shared/conventions/checkpoint-pattern.md)
