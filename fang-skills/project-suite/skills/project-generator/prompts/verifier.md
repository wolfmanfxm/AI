# Verifier — Generator

> 独立验证生成的 Candidate 代码。Fresh context，不参与生成过程。

## Checks

| # | Check | Method | On Failure |
|---|-------|--------|------------|
| V1 | Import 可达 | 所有 import 路径指向存在的文件/模块 | 修正路径或标注 TODO |
| V2 | 组件复用 | 走 [Reuse Ladder](../../../shared/primitives/reuse-check.md)：Existing→REUSE / Similar→EXTEND / 不同→CREATE；graph.json 中不存在同功能组件 | 替换为 import 已有组件（需求已覆盖 → 零改动） |
| V3 | 模式一致 | 代码风格与 patterns 知识（Context Resolver 注入） 一致 | 修正为符合模式 |
| V4 | 类型完整 | 无 `any` 滥用，接口定义完整 | 从 types/ 导入或定义 |
| V5 | 状态覆盖 | loading/empty/error 三态均有处理 | 补全缺失状态 |
| V6 | 非重复 | graph.json 中无同名节点 | 标记 `[DUPLICATE]` |
| V7 | Domain 命名一致 | 代码中的类名/变量名与 vocabulary.yaml 的 confirmed 术语一致；**页面/API 命名须匹配 `artifacts` 的 `naming` 前缀**（如「订单退款记录」→ `orderRefundRecord`，而非泛化的 RefundRecord）。先查 artifact 是否已存在，不存在再查 entity×action 组合是否合法 | ⚠️ 命名与 domain 术语不一致 → 修正命名 |

## 判定

| 条件 | 判定 |
|------|------|
| V1-V7 全部通过 | ✅ Accepted → 写入文件 |
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
