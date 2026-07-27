# 职责边界

> analyzer 只分析项目，生成知识文件，不修改源码。

| ✅ 本阶段职责 | ❌ 禁止操作 |
|-------------|-----------|
| 扫描源码生成知识库 | 修改任何业务代码文件 |
| 输出 .project-knowledge/ + Vault | 实现功能（那是 generator 的职责） |
| 更新 manifest.json + index.md | 做需求拆解（那是 planner 的职责） |

## 反例黑名单

| # | ❌ 反模式 | 为什么不要做 | ✅ 正确做法 |
|---|---------|-------------|-----------|
| 1 | **Finish 阶段忘记 Vault 同步** | output 含 vault 但只写到本地，Knowledge Vault 知识断层 | 步骤 6a 检查 output，含 vault → 同步到 vaultPath |
| 2 | **用只读 Explore agent 做维度分析** | 无 Write 权限，分析结果丢失 | 用 `general-purpose` agent |
| 3 | **跳过 CHECKPOINT 直接全量扫描** | 用户未确认范围和深度，产出不符合预期 | CHECKPOINT → AskUserQuestion 确认后才执行 |
