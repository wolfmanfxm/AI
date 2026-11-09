# Discovery — Generator

> @template: discovery

## Actions

0. **Task Resolution** — 解析 task_id（[task-identity.md](../../../runtime/mechanisms/task-identity.md)）。
   - 用户指定了 PLAN / 任务 → 匹配对应 task
   - 无法匹配且无 active 任务 → `task-registry.sh create --slug "generator-<timestamp>"`，收尾报告标注 `⚠️ 无上游任务，已自动建任务`
   - **task_id 未确定前不读 context-package、不写任何文件**

1. **Context Resolver** → [Context Resolver](../../../runtime/contracts/context-resolver.md)：读 `runtime/tasks/<task_id>/context-package.json` → 拿 rules[]/knowledge[]/guidance[]/recommendations[]
   - 🔴 包内 `taskId` 必须等于当前 task_id；不一致 → 拒绝消费（别的任务的知识包）
   - **Fallback（Knowledge Context unavailable）**：若本任务包缺失 → 兜底直读 `.project-knowledge/rules/`、`decisions/`（project-scope，非 `ARCHITECTURE-*`）、`experience/`、`playbooks/` 全部文件，逐条记录为本次生成的硬约束。**禁止**读根级 legacy `context-package.json`。

2. **Load blocking rules** — context-package.json 的 rules[]（type=rule + project-scope decision）→ 生成时必须遵守，违反即错。

3. **Load applicable patterns/components/API** — context-package.json 的 knowledge[] → 套用模式。

4. **Load recommendations** — context-package.json 的 recommendations[]（type=recommendation）→ 应然建议（新代码改进方向），**非 blocking**。现状 facts 见 knowledge[]/rules[]；两者冲突时，**新代码遵循「建议」，理解存量代码看「现状」**。

5. **Reuse Check**（不搜索代码库，先查结构化知识）→ [Reuse Ladder](../../../shared/primitives/reuse-check.md)：
   - `findNode("component", <目标>)` → **完全覆盖 → `[REUSE]` 零改动**（已有组件已覆盖，不新建冗余组件）
   - 相近 → **`[EXTEND]`** 加 prop/slot/config，不复制粘贴
   - `findNode("api", <目标>)` → 已存在 → 直接 import，不复创建
   - 仅「语义确实不同」才进入生成流程（`[CREATE]`，复用已有子件）

6. 代码存在性检查 → [references/code-audit.md](../references/code-audit.md)

7. 找类似实现：grep 同模块其他页面的 import/组件使用方式，确认技术栈和模式

8. CHECKPOINT — 展示过滤后改动范围（新建/修改文件清单 + 每文件预估行数 + REUSE 标注）

## Exit

- 用户确认改动范围（文件清单 + 预估行数 + REUSE 标注）
- `runtime/tasks/<task_id>/manifest-project-generator.json` status = confirmed

## Failure

| Condition | Action |
|-----------|--------|
| `context.json` 缺失 | 从 `.project-knowledge/` 手工提取（读 index.md + architecture/） |
| Graph 不可用（graph.json 缺失） | grep import 手动分析依赖 → 标注 `⚠️ 无 Graph` |

## CHECKPOINT

🔴 CHECKPOINT — 展示改动范围，用户确认后进入 Execution
→ [checkpoint-pattern](../../../shared/conventions/checkpoint-pattern.md)
