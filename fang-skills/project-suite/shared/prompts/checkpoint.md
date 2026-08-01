# Checkpoint Prompt — Shared Library v1.0.0

> 所有 Skill 的统一用户确认模式。18 个 prompt 文件引用。
> 确保关键决策前必须有人类确认，防止 Skill 自主失控。

---

## 使用方式

在 Skill prompt 的关键决策点插入：

```
🔴 CHECKPOINT — <展示什么信息>，用户确认后进入 <下一阶段>
```

## 必须停顿的决策点

| 阶段 | 检查什么 | 示例 |
|------|---------|------|
| **Discover 后** | 范围确认 | "🔴 CHECKPOINT — 展示扫描范围(全量/增量)+预估时间，用户确认后开始分析" |
| **Execute 关键决策前** | 方案确认 | "🔴 CHECKPOINT — 展示改动文件清单+预估行数，用户确认后写入代码" |
| **Output 前** | 结果确认 | "🔴 CHECKPOINT — 展示审查摘要(BLOCKER/HIGH/MEDIUM/LOW/PRAISE计数)，用户确认后生成REVIEW.md" |

## 信息密度要求

每个 CHECKPOINT 必须包含三项：

```
1. 展示内容（具体数据，不是概括）   ← "3个文件, +120/-45行" 而非 "一些改动"
2. 阻止继续的风险（若有）           ← "⚠️ 上游confidence=55, 建议Review后继续"
3. 用户的选择项                    ← 通过 AskUserQuestion 给出选项
```

## 反例

| ❌ 弱 CHECKPOINT | ✅ 强 CHECKPOINT |
|-----------------|----------------|
| "确认后继续" | "🔴 CHECKPOINT — 展示: 新增brandRecipient/index.vue(+220行)+BrandRecipientDialog.vue(+180行)，⚠️ 无ARCHITECTURE.md约束，确认后写入文件" |
| "建议确认一下"（无 🔴 标记） | 🔴 CHECKPOINT 视觉标记是 LLM 扫描时的锚点 |
| AskUserQuestion 无选项 | 给出 2-3 个具体选项 + 推荐项 |

## 工具调用

统一使用 `AskUserQuestion`（引用 `shared/conventions/checkpoint-pattern.md`）：

```
AskUserQuestion({
  questions: [{
    question: "是否继续？",
    header: "确认",
    options: [
      { label: "继续 (推荐)", description: "范围已确认, 无阻塞风险" },
      { label: "修改范围", description: "调整扫描深度或排除目录" },
      { label: "取消" }
    ]
  }]
})
```
