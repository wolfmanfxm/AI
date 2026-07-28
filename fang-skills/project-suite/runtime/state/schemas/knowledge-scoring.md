# Knowledge Scoring v1.0.0

> Generator 每次使用知识后反向评分。知识不是静态的——它在使用中进化。

## 核心理念

```
不是: Analyzer 生成 → 知识库 → 永远不变
而是: Generator 使用 → 反馈结果 → 分数变化 → 影响未来优先级
```

## 评分模型

每条 Accepted 知识有一个动态 score（0-100）：

```
score = base_confidence × usage_weight

base_confidence: 初始来自 Reviewer 的 confidence
usage_weight:    随时间衰减 + 使用反馈调整
```

## 使用反馈

Generator 每次生成代码后，在 `result.md` 中记录：

```markdown
## Knowledge Used
| 知识 | score_before | 采用程度 | 结果 | score_after |
|------|-------------|---------|------|-------------|
| patterns/upload.md | 92 | 完全采用 | good | 93 |
| patterns/crud.md | 85 | 部分采用 | partial | 82 |
| patterns/table.md | 78 | 未采用 | abandoned | 75 |
```

**采用程度：**
| 级别 | 含义 | 分数影响 |
|------|------|---------|
| **完全采用** | 直接复用了模式，无修改 | +1 |
| **部分采用** | 参考了模式但有调整 | -1 |
| **未采用** | 有相关知识但本次不适用 | 0 |
| **被放弃** | 尝试采用但最终放弃（模式有问题） | -3 |

## 分数衰减

长期未被使用的知识自然衰减：

```
30 天未使用 → -5
90 天未使用 → -10
180 天未使用 → 标记 review_needed
365 天未使用 → 建议 deprecated
```

## 知识进化效果

```
高分知识（> 85）:
  - Generator 优先读取（Reuse Analysis 置顶）
  - 可作为新 Candidate 的参考模板

中分知识（60-85）:
  - 正常读取
  - 使用时有 confidence 警告

低分知识（< 60）:
  - Generator 降级读取（标注"⚠️ 低分知识，建议验证"）
  - Reviewer 建议重新审查

负反馈累积（连续 3 次 abandoned）:
  - 自动建议 deprecated
  - AskUserQuestion 确认
```

## knowledge.json 中的评分数据

```json
{
  "files": {
    "patterns/upload.md": {
      "score": 92,
      "score_history": [
        {"at": "2026-03-15", "score": 85, "event": "created"},
        {"at": "2026-04-20", "score": 88, "event": "used", "result": "good"},
        {"at": "2026-06-10", "score": 92, "event": "used", "result": "good"}
      ],
      "usage_feedback": {
        "times_used": 12,
        "times_good": 10,
        "times_partial": 1,
        "times_abandoned": 1,
        "last_used": "2026-07-20"
      }
    }
  }
}
```
