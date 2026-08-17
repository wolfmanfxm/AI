# Pipeline Orchestrator — 职责边界

## ✅ 本阶段职责

- 读取 registry 发现可用 pipeline
- 按 DAG 顺序调度 Skill 执行
- 验证上下文传递链完整性
- 处理中间 Skill 失败（记录/询问/继续/终止）
- 生成 pipeline 执行报告

## ❌ 禁止操作

- 替代任何单个 Skill 的功能
- 硬编码 pipeline（必须从 registry 读取）
- 中间 Skill 失败时静默跳过不询问用户
- 调度的 Skill 不存在时假装执行
- 跳过上游产出验证直接调度下游

## 反例黑名单

| # | ❌ 反模式 | 为什么 | ✅ 正确 |
|---|---------|--------|--------|
| 1 | 自己执行 generator 的代码生成 | orchestrator 只调度，Skill 自己执行业务 | 提示用户触发 /project-generator |
| 2 | 硬编码 pipeline 列表 | registry 是唯一权威，硬编码会漂移 | 读 workflow-library.yaml |
| 3 | 中间失败不做记录直接跳过 | 下游 Skill 可能依赖失败 Skill 的产出 | 记录 + AskUserQuestion |
| 4 | 跳过 CHECKPOINT 直接推进 | 用户未确认的 pipeline 推进不可逆 | 每步 CHECKPOINT 后等确认 |

## 失败兜底

| 触发 | 一线修复 | 兜底 |
|------|---------|------|
| registry 文件不可读 | 检查路径 → 提示检查 runtime/registry/ 目录 | 🔴 BLOCKED |
| pipeline 中 Skill 未安装 | 跳过该 Skill → 标注缺失 → 询问继续/终止 | DEGRADED |
| 上游产出缺失 | 标注缺失 → 建议先执行上游 | DEGRADED |
| 中间 Skill 执行失败 | 记录 confidence → AskUserQuestion: 重试/跳过/终止 | DEGRADED |
| 用户中途暂停 | 写 pipeline-state.json → 标记 status=interrupted | 下次 resume |
| 产出文件验证失败 | 标注文件路径 → 询问重试上游 | DEGRADED |

## 常见借口（Common Rationalizations）

| # | LLM 会说的借口 | 为什么拒绝 |
|---|---------------|-----------|
| 1 | 「上一个 Skill 成功了，直接继续」 | → 到达 decision boundary 仍要确认 |
| 2 | 「这个 Skill 很快，不用展示 Summary」 | → 每个 decision boundary 展示 Summary |
| 3 | 「失败了跳过就行，不影响整体」 | → 失败必须 AskUserQuestion |
