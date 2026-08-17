# Examples — Analyzer

> 真实分析场景示例。更多产出示例见 [../../../shared/examples/analyzer-output.md](../../../shared/examples/analyzer-output.md)。

> ⚠️ **Reference example only**：本文件的组件名/API 名/参数名来自参考项目，仅作示例，**不代表项目默认**。实际名称从 `.project-knowledge/`（catalog.md / context.json）解析。

---

## 示例 1：首次分析 — Vue3+TS 项目

### 输入

> "分析这个项目"

### 交互

```
Phase 1 Discover:
  Q: 项目名称？
  A: my-web-app（package.json name）
  Q: 分析深度？
  A: 📊 标准
  Q: 扫描范围？
  A: 全量
  Q: 输出位置？
  A: Vault + 本地

→ analysis-config.json 写入
→ manifest.json status: confirmed
→ 🔴 CHECKPOINT: 展示 8 个维度预计产出 → 用户确认

Phase 2 Execute:
  Wave 0: architecture ✅
  Wave 1: components ✅, coding-style ✅, api-pattern ✅
  Wave 2: ui-pattern ✅, patterns ✅
  Wave 3: observations ✅

Phase 2 Finish:
  manifest.json → status: completed
  产出: .project-knowledge/ (12 files) + Knowledge Vault
```

---

## 示例 2：增量刷新

### 输入

> "刷新项目知识"

### 交互

```
检测到 manifest.json (status: completed)
  → AskUserQuestion: 🔁全量刷新 / 📝增量更新 / ❌取消
  → 用户选 📝增量更新

→ git diff --stat 获取变更文件列表
→ 仅重新分析变更涉及的维度
→ 已有文件标注 [CHANGED] / [CONFIRMED]
→ manifest knowledgeVersion 不变（增量非全量）
```

---

## 示例 3：开发前检查

### 输入

> "我要写一个用户列表页"

### 流程

1. 查 .project-knowledge/index.md → 存在
2. 按任务类型选读：patterns/table.md + components/catalog.md
3. 提取关键约定：MpTable 组件、pageindex/pagesize 字符串类型、request 封装路径
4. 提示用户："项目使用 MpTable 封装，分页参数 pageindex/pagesize(字符串)，API 从 @/api/ 导入。是否按此模式生成？"
