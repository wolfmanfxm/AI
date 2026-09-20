> ⚠️ **已归档（2026-09-20）—— Context Merge 规格，零消费者。不得再作为 Runtime Contract。**
>
> 归档原因：与 context-priority 同一个缺陷——它描述的是
> **机器在跨源冲突时如何合并**（`operations` / `conflict_resolution`），并自称
> 「Machine Readable Spec」「Skill 加载时: `YAML.parse()` → 按 sources 顺序加载 → 按 conflict_resolution 裁决冲突」。
> 但全仓**零机器消费者**：无脚本读取、无提示词提及、无 skill 引用（唯一引用者是同目录的 .md 孪生）。
>
> 它是同一套「Context Engine」设想的另一半（优先级栈负责"取哪些"，本文件负责"冲突了怎么办"）。
> 两者一并退出 active Runtime，避免留下「半残契约」。
> 与之配对的机器规格 `merge.yaml` 已**删除**（同 context-priority.yaml）；此处只保留设计史。
>
> 保留原因：记录了设计历史。

# Context Merge Strategy

> ⛔ **以下正文是 2026-09 当时的设计描述，全部为历史语态，不代表任何当前 Runtime 行为。**
> 本文的 `override` / `append` / `ignore` 与加载顺序/冲突裁决规则**没有任何执行者**——
> 机器可读版本 `merge.yaml` 已删除。当前 Context 规则见
> [context.md](../../runtime/context/context.md) 与 [context-resolution.md](../../runtime/context/context-resolution.md)。

## 三条操作（当时设计）

| 策略 | 行为 |
|------|------|
| **override** | 高优先级覆盖低优先级 |
| **append** | 追加，不去重 |
| **ignore** | 跳过该源 |

## 关键区分：加载顺序 ≠ 冲突裁决

（当时认为）这两个是独立维度，容易混淆：

- **加载顺序** — 从上到下依次读，后读到的补充前序（原 `merge.yaml` 的 `loading_flow`）
- **冲突裁决** — 两个源对同一字段给出不同值时谁赢（原 `merge.yaml` 的 `conflict_resolution`）

（当时规定）`claude_md_constraints` 优先级最高——安全/编码强制约束，无人能覆盖。**当前不存在此规则。**

## 裁决示例

```
Generator 生成一个组件:

User Prompt:     "用卡片布局显示用户列表"
patterns/table.md: "列表页使用 <统一表格> + <schema表格>"
CLAUDE.md:       "Element Plus 使用 <组件库前缀> 前缀"

合并结果:
  布局: User Prompt override → 卡片布局（不是表格）
  组件: project_knowledge override → <统一表格> + <schema表格>（用户没说用什么组件）
  前缀: claude_md override → <组件库前缀> 前缀（强制约束）
```
