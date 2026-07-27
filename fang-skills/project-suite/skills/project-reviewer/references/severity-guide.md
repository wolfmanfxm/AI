# Severity Guide — Reviewer

> 问题分级决策指南。给定一个发现，如何确定它属于哪一级。

## 决策树

```
发现一个问题 ↓

会导致生产事故（crash / 数据丢失 / 安全漏洞）？
  YES → 🔴 BLOCKER
  NO  ↓

大概率引发线上问题 / 造成严重技术债 / 使后续开发踩坑？
  YES → 🟠 HIGH
  NO  ↓

改善了会更好，但不改也不会出问题？
  YES → 🟡 MEDIUM
  NO  ↓

风格偏好 / 命名微调 / 不影响理解和运行？
  YES → 🟢 LOW（但如果不是明显改进，不提也行）
```

## 各轴严重度速查

| 发现类型 | 默认级别 | 升级条件 |
|---------|---------|---------|
| 未捕获的异步异常 | HIGH | 会导致数据丢失 → BLOCKER |
| `v-html` 渲染用户输入 | BLOCKER | - |
| console.log 打印 token | BLOCKER | - |
| 缺少 loading 状态 | MEDIUM | 会导致重复提交 → HIGH |
| 缺少空状态处理 | MEDIUM | - |
| 圈复杂度 > 15 | MEDIUM | > 25 → HIGH |
| 函数名 `data` / `list` 不够语义化 | LOW | 导致理解错误 → MEDIUM |
| 循环依赖 | HIGH | 导致构建失败 → BLOCKER |
| 重复代码 > 20 行 | MEDIUM | 3 处以上重复 → HIGH |
| N+1 查询 | HIGH | 列表 > 100 条 → BLOCKER |
| `import _ from 'lodash'` | MEDIUM | 包体积增加 > 100KB → HIGH |
| 事件监听未在 onUnmounted 清理 | MEDIUM | SPA 频繁进入离开 → HIGH |
| `as` 强制类型转换无校验 | MEDIUM | 会导致运行时错误 → HIGH |

## 判定原则

1. **上下文加权**：同样的发现，在核心支付模块 vs 管理后台配置页，严重度可以差一级
2. **不问偏好**：if-else vs switch、`ref` vs `reactive`、`function` vs `=>` — 这些是风格偏好，不提
3. **不虚假报警**：标注 `[不确定]` 比错误分级好
4. **同类合并**：同一文件同一模式的多次出现合并为一条，标注多处 file:line
