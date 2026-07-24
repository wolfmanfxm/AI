# Change Analysis

## Goal
对比本次和上次扫描结果，生成变更记录。

## Context
依赖 Obsidian Vault 中上轮输出的知识文档，需要先完成所有维度的分析再进行对比。

## Evidence
- Obsidian Vault 中上轮输出的知识文档
- 本次新生成的分析结果

## Analysis
逐文件对比以下维度：
- **架构**：模块增删改、Store 变化、路由调整
- **组件**：新增高复用组件、接口变化、废弃组件
- **编码**：新模式出现、旧模式淘汰
- **UI**：新 UI 模式、替代方案
- **API**：目录变化、新模块、约定变更

首次执行全部标记 `[NEW]`，非首次逐项标记。

## Output
`reports/latest.md`（必选）+ `reports/migration.md`（按需）
🆕 NEW / 🔄 CHANGED / ❌ REMOVED / ✅ CONFIRMED
先列变化项，再列确认项。确认项可合并。
