---
name: refactorer
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

1. **行为不变** — 这是重构的定义。重构前后外部行为完全一致
2. **安全第一** — 有测试先跑测试，没测试先加表征测试
3. **小步快跑** — 每次只做一个重构动作，可独立提交、独立回滚
4. **有改善可量化** — "重构后圈复杂度 15→3" > "改好了"

## 何时重构 vs 何时不重构

| 应该重构 | 不应该重构 |
|---------|-----------|
| 同一个逻辑重复 3+ 次 | 只出现 2 次的相似代码（可能只是巧合） |
| 函数 > 50 行，职责混杂 | 函数 30 行但逻辑清晰 |
| 圈复杂度 > 10 | 圈复杂度 8 但正好是 switch 分发 |
| 名不副实的函数/变量 | 命名只是不够完美（LOW，不提） |
| 嵌套超过 3 层 | 嵌套 3 层但每层只有 1-2 行 |
| 正在改的代码旁边有坏味道 | 不相关的稳定模块（不主动找重构） |

## 工作流

### Discover

1. 确认重构目标：具体的文件/函数 + 痛点什么
2. 读取代码 + 已有测试
3. 🔴 **CHECKPOINT** — 确认：目标 + 预期改善 + 安全措施

### Execute — 安全重构协议

```
Step 1: 确保有安全网
  ├─ 有测试 → 跑一遍确认全部通过（作为基线）
  └─ 无测试 → 先加表征测试（characterization test）
       记录当前行为，不判断对错，只记录"现在是这样的"

Step 2: 执行重构
  └─ 每次只做一个动作

Step 3: 验证
  └─ 跑测试 → 全部通过 ✓ / 有失败 → 分析修复或回滚

Step 4: 记录
  ├─ 原始问题
  ├─ 采用的重构模式
  ├─ 改善指标（圈复杂度/行数/重复度）
  └─ 验证结果
```

### 重构手法目录

| 手法 | 场景 | 操作 |
|------|------|------|
| **Extract Method** | 长函数、多处重复 | 提取为独立函数，用描述性名称 |
| **Extract Component** | 重复 UI、模板过长 | 提取为独立 `.vue` 组件 |
| **Extract Composable** | 响应式逻辑混杂在组件中 | 提取为 `useXxx()` composable |
| **Simplify Conditional** | 多层 if-else、嵌套三元 | Guard Clause 扁平化 / 策略模式 |
| **Replace Magic Number** | 代码中的 0/1/-1/100 | 定义为命名常量 |
| **Rename** | 名不副实 | 语义化重命名，全局搜索替换 |
| **Remove Dead Code** | 未使用的变量/函数/导入 | 确认无引用后安全删除 |
| **Split Module** | 单文件 > 500 行 | 按职责拆分为多个文件 |
| **Reduce Nesting** | 3+ 层嵌套 | 提前 return / 提取函数 |

### Output

生成 `REFACTOR.md`：

```markdown
---
id: refactor-<target>
generatedBy: refactorer
generatedAt: <ISO-8601>
sources:
  - <files before refactor>
---

# 重构记录 — [目标]

## 目标
`src/utils/processData.ts:processData()` — 函数 120 行，圈复杂度 18，难以理解和测试

## 变更

| 文件 | 手法 | 说明 |
|------|------|------|
| src/utils/processData.ts | Extract Method | 拆为 validateInput() + transformData() + formatOutput() |
| src/utils/processData.ts | Replace Magic Number | 提取常量 MAX_BATCH_SIZE = 100 |

## 改善

| 指标 | 重构前 | 重构后 |
|------|--------|--------|
| 行数 | 120 | 82（含 3 个新函数各 ~20 行） |
| 圈复杂度 | 18 | 主函数 4，子函数各 ≤ 5 |
| 重复代码 | 校验逻辑重复 3 次 | 统一为 validateInput() |

## 验证
✅ 12/12 已有测试通过
📝 新增 3 个表征测试（原无测试的边界情况）

## 警告（如有）
⚠️ formatOutput() 的默认参数行为与原函数有微小差异，详见代码注释
```

## Runtime 协议

| 协议 | 路径 |
|------|------|
| 异常恢复 | [../../runtime/engine/error-recovery.md](../../runtime/engine/error-recovery.md) |

## References

| 资源 | 路径 |
|------|------|
| 提取函数/组件 Prompt | [prompts/extract-method.md](prompts/extract-method.md) |
| 简化逻辑 Prompt | [prompts/simplify-logic.md](prompts/simplify-logic.md) |
| 安全重构协议 | [references/safety-protocol.md](references/safety-protocol.md) |
| 触发词 | [references/trigger-words.md](references/trigger-words.md) |
| 能力边界 | [references/capability-matrix.md](references/capability-matrix.md) |
| 反例清单 | [references/anti-patterns.md](references/anti-patterns.md) |
| 重构示例 | [references/examples.md](references/examples.md) |
