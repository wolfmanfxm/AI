---
name: project-refactorer
metadata: skill.yaml
description: >
  改善代码结构不改变外部行为：提取函数/组件、简化条件逻辑、移除死代码、语义化重命名、
  拆分过大模块。每次重构必须安全可逆，有测试跑测试，无测试先加表征测试。
  触发词：重构、优化结构、提取公共、简化代码、消除重复、拆分模块、重命名、
  refactor、clean up、extract method、simplify、reduce complexity、优化这段代码。
  产出：重构后代码 + REFACTOR.md（变更记录 + 改善指标 + 验证结果）。
---

# Refactorer

> 代码 → 识别坏味道 → 安全重构 → 验证 → REFACTOR.md

## 核心原则

1. **行为不变** — 重构前后外部行为完全一致
2. **安全第一** — 有测试先跑测试，没测试先加表征测试
3. **小步快跑** — 每次只做一个重构动作，可独立提交回滚
4. **可量化** — "圈复杂度 15→3" > "改好了"

## 职责边界

→ [references/boundary.md](references/boundary.md)

> 🔴 refactorer 只改善结构不改行为。没测试保护不重构。

## 工作流

### Discover

1. 识别坏味道：长函数/重复代码/过深嵌套/God Class/魔数
2. 确认测试覆盖：有测试→跑一遍；无测试→加表征测试
3. 选重构手法（9种）→ [prompts/extract-method.md](prompts/extract-method.md)
4. 🔴 CHECKPOINT → [checkpoint 模式](../../shared/conventions/checkpoint-pattern.md)

### Execute（小步）

```
跑现有测试(确保绿) → 做1个重构动作 → 跑测试(仍绿) → 提交
失败: git revert → 记录 REFACTOR.md
```

### Output

`reports/REFACTOR.md`：变更清单 + 改善指标 + 测试结果

## 完成后下一步

```
refactorer 完成 → /project-tester 或 /project-reviewer
```
