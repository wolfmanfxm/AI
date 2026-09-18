# Verifier — Generator

> 独立验证生成的 Candidate 代码。Fresh context，不参与生成过程。

## Checks

> **检查项的唯一权威是 [validation.md](validation.md) 的 `## Checks` 表**——本文件不再重复维护一份。
> （2026-09-18 收敛：此前两个文件各有一张高度重复的检查表，改一处必忘另一处。）
>
> 本文件的职责是定义**验证对象与判定规则**，不是定义检查项。

## 判定

| 条件 | 判定 |
|------|------|
| V1-V7 全部通过 | ✅ Accepted → 写入文件 |
| V2 = REUSE（需求已被现有组件完整覆盖，证据成立） | ✅ Accepted → **零改动**（不写文件）。交付报告记录 `D[复用裁决]: REUSE` + 命中 + 依据；**不为「跑完流程」而造代码** |
| V1 失败(import 不存在) | ❌ Rejected → 修正路径 |
| V2 失败(重复组件) | ❌ Rejected → 替换为 import |
| V7 失败(命名不一致) | ⚠️ Accepted + 修正命名（Customer vs CustomerInfo 混用） |
| V3-V6 部分失败 | 🟡 Accepted + 标注修复建议 |

## Evidence Format

每个 Accepted 的代码文件输出 evidence：

```yaml
candidate: UserCard.vue
verdict: accepted
confidence: 0.88
evidence:
  imports:
    - { path: "@/components/<统一表单封装>", exists: true }
    - { path: "element-plus", exists: true }
  patterns: [<统一表格>, <统一表单封装>, <组件类型定义>]
  types: { any_count: 0, interfaces: 2 }
  states: [loading, error, empty]
```
