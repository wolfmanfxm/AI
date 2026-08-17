# Discovery — Generator

> @engine: discovery

## Actions

0. **Context Resolver** → [Context Resolver](../../../runtime/contracts/context-resolver.md)：从用户需求提取 tags → 查询 `graph.json` → 注入相关 patterns/components/conventions
1. 结构化查询知识（不读 .md）：`@adapter:knowledge.query --type component,pattern,api --scope project`
2. **Reuse Check**（不搜索代码库，先查结构化知识）→ [Reuse Ladder](../../../shared/primitives/reuse-check.md)：
   - `findNode("component", <目标>)` → **完全覆盖 → `[REUSE]` 零改动**（已有组件已覆盖，不新建冗余组件）
   - 相近 → **`[EXTEND]`** 加 prop/slot/config，不复制粘贴
   - `findNode("api", <目标>)` → 已存在 → 直接 import，不复创建
   - 仅「语义确实不同」才进入生成流程（`[CREATE]`，复用已有子件）
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
