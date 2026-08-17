# Context Merge Strategy

> ⚙️ **机器读 [merge.yaml](merge.yaml)** · 📖 **人类读这里**（为什么这样设计）

## 三条操作

| 策略 | 行为 |
|------|------|
| **override** | 高优先级覆盖低优先级 |
| **append** | 追加，不去重 |
| **ignore** | 跳过该源 |

## 关键区分：加载顺序 ≠ 冲突裁决

这两个是独立维度，容易混淆：

- **加载顺序** — 从上到下依次读，后读到的补充前序（见 merge.yaml `loading_flow`）
- **冲突裁决** — 两个源对同一字段给出不同值时谁赢（见 merge.yaml `conflict_resolution`）

其中 `claude_md_constraints` 优先级最高——安全/编码强制约束，无人能覆盖。

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
