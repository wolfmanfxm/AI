# Pipeline Orchestrator — 失败处理

| 触发 | 一线修复 | 兜底 |
|------|---------|------|
| registry 文件不可读 | 检查路径 → 提示检查 runtime/registry/ 目录 | 🔴 BLOCKED |
| pipeline 中 Skill 未安装 | 跳过该 Skill → 标注缺失 → 询问继续/终止 | DEGRADED |
| 上游产出缺失 | 标注缺失 → 建议先执行上游 | DEGRADED |
| 中间 Skill 执行失败 | 记录 confidence → AskUserQuestion: 重试/跳过/终止 | DEGRADED |
| 用户中途暂停 | 写 pipeline-state.json → 标记 status=interrupted | 下次 resume |
| 产出文件验证失败 | 标注文件路径 → 询问重试上游 | DEGRADED |
