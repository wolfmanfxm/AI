# 失败处理

| 触发条件 | 一线修复 | 兜底 |
|---------|---------|------|
| `.project-knowledge/` 不存在 | 跳过现有分析，全量扫描 | 标注"⚠️ 首次分析" |
| manifest 状态异常 | 读 manifest，按 checkpoint 协议恢复 | 标注"⚠️ 状态异常，全量重扫" |
| 维度 agent 执行失败 | 标记该维度 `failed`，不阻塞其他 | Finish 阶段汇总失败的维度 |
| `analysis-config.json` 缺失 | 进入 Discover 阶段重新收集 | AskUserQuestion 确认 |
| vaultPath 不可达 | 跳过 Vault 同步 | 标注"⚠️ Vault 路径不可达" |
| agent spawn 超限 | 分批执行，降低并行度 | 标注"⚠️ 分批执行" |
