# Context Merge Strategy

> 跨源知识冲突时的合并规则。所有 Skill 遵循同一策略，不再各自决定。

## 三层合并操作

| 策略 | 行为 | 适用场景 |
|------|------|---------|
| **override** | 高优先级完全覆盖低优先级 | 用户指令 > 项目配置；代码事实 > context.json |
| **append** | 高优先级追加到低优先级之后（不去重） | 用户补充需求 + PLAN.md tasks；多个参考实现 |
| **ignore** | 跳过该源，不参与合并 | 知识库缺失时跳过；Vault 不可达时跳过 |

## 逐源的合并策略

```
源 1: User Prompt        → 起始层，无合并
源 2: .project-runtime/   → append（状态叠加到需求上）
源 3: .project-knowledge/ → override 约束部分 / append 参考部分
源 4: CLAUDE.md           → override（项目约定覆盖通用默认）
源 5: Knowledge Vault     → append（跨项目经验追加）
源 6: Skill References    → ignore（除非上层全部缺失，作为兜底）
```

## 冲突裁决示例

```
场景: Generator 生成一个组件

User Prompt:    "用卡片布局显示客户列表"
.project-knowledge/patterns/table.md: "列表页使用 PageTable + SchemaTable"
CLAUDE.md:     "Element Plus 使用 el-mp 前缀"

合并结果:
  布局: User Prompt override → 卡片布局（不是表格）
  组件: patterns/table.md override → PageTable + SchemaTable（用户没说用什么组件）
  前缀: CLAUDE.md override → el-mp 前缀（强制约束）
```

## 冲突裁决规则

> 加载顺序（读）≠ 冲突裁决（谁赢）。两个独立维度：

**加载顺序**（从上到下依次读取，后读到的可以补充前序）：
```
1. User Prompt → 2. .project-runtime/ → 3. .project-knowledge/ → 4. CLAUDE.md → 5. Knowledge Vault → 6. Skill References
```

**冲突裁决**（当两个源对同一字段给出不同值时，谁赢）：
```
1. CLAUDE.md 安全/强制约束    → 最高，不可被 override
2. 用户显式指令（User Prompt） → 可 override 除安全外的所有
3. 代码事实（grep/read 确认）  → override context.json
4. 项目知识（.project-knowledge/）→ override 通用默认
5. 跨项目经验（Knowledge Vault）→ append 不覆盖
6. Skill 内置默认              → 兜底
```

## 所有 Skill 的统一 Context 加载流程

```
1. 读 User Prompt → 种子上下文
2. 读 .project-runtime/state.json → append（当前状态 + 上游产出）
3. 读 .project-knowledge/ + context.json:
   - 约束类字段（conventions/rules）→ override
   - 参考类字段（patterns/components）→ append
4. 读 CLAUDE.md → override（项目强制约束）
5. 读 Knowledge Vault（可选）→ append（跨项目经验）
6. Skill References → ignore（仅上层全部缺失时兜底）
```
