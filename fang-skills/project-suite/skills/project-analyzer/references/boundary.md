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
| 4 | **重扫时只更新 markdown，跳过 JSON 产物** | manifest 标记 unchanged 就跳过 context.json 生成，下游读到过期数据 | Phase A 强制刷新：statistics + context + graph + search-index 每次必定重新生成 |
| 5 | **只更新统计数字、不创建入口文件** | 规格里若只剩「读 CLAUDE.md 第一行替换数字」——它**预设文件已存在**，文件缺失时静默跳过、永不报错。实测：同一套 skill，一个项目有入口、另一个首扫后 `.claude/` 为空——差一个 agent 入口 | Phase D 步骤 13 三态处理（不存在→创建 / 无 KB 引用→追加 / 已有引用→只刷 `kb-stats` 标记），步骤 17 由 `check-claude-md.sh` **阻断**断言 |

## 失败兜底

| 触发条件 | 一线修复 | 兜底 |
|---------|---------|------|
| `.project-knowledge/` 不存在 | 跳过现有分析，全量扫描 | 标注"⚠️ 首次分析" |
| manifest 状态异常 | 读 manifest，按 checkpoint 协议恢复 | 标注"⚠️ 状态异常，全量重扫" |
| 维度 agent 执行失败 | 标记该维度 `failed`，不阻塞其他 | Finish 阶段汇总失败的维度 |
| `analysis-config.json` 缺失 | 进入 Discover 阶段重新收集 | AskUserQuestion 确认 |
| vaultPath 不可达 | 跳过 Vault 同步 | 标注"⚠️ Vault 路径不可达" |
| agent spawn 超限 | 分批执行，降低并行度 | 标注"⚠️ 分批执行" |

## 常见借口（Common Rationalizations）

| # | LLM 会说的借口 | 为什么拒绝 |
|---|---------------|-----------|
| 1 | 「项目很简单，不需要全量扫描」 | → 仍然全量 |
| 2 | 「这个维度没什么内容，跳过」 | → 仍然提取，标注 [MINIMAL] |
| 3 | 「Verifier 太慢，直接写 knowledge」 | → 必须经过完整验证 |
