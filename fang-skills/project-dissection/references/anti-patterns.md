# 反例清单

## 通用反例

| # | ❌ 不要做 | ✅ 正确做法 |
|---|----------|-----------|
| 1 | 修改任何业务代码文件 | 仅写 `.project-knowledge/` 和 Obsidian Vault |
| 2 | 用框架通用模式代替项目实际模式 | 从实际代码提取，引用 `file:line` |
| 3 | 编造不存在的 API、组件、目录 | 实时验证后再写 |
| 4 | 跳过确认直接扫描大型项目 | 先确认项目名、范围、路径 |
| 5 | 开发前检查中重新扫描源码 | 只读已有文档 |
| 6 | 输出无 `file:line` 的笼统建议 | 每个结论标注源文件位置 |
| 7 | 对不存在的目录静默跳过 | 标注"⚠️ 路径不存在" |

## 操作反例黑名单

> 以下为执行本 skill 时的禁止操作，每条对应真实踩坑记录。

| # | 反模式 | 为什么不要做 | 正确做法 |
|---|--------|-------------|---------|
| 1 | **使用只读 agent 做维度分析** | Explore agent 无法写文件，分析结果丢失，主 agent 需二次处理 | 用 `general-purpose` 或带 Write 权限的 agent 类型 |
| 2 | **跳过 CHECKPOINT 直接执行** | 用户未确认分析范围和深度，产出不符合预期 | 必须在 🔴 CHECKPOINT 处停顿，等用户确认 |
| 3 | **单 agent 顺序执行所有维度** | 7 个维度串行耗时 10+ 分钟，且可能 token 超限 | 并行 spawn 7 个独立 agent |
| 4 | **不读 manifest 就全量重扫** | 已有分析结果被浪费，重复劳动且知识版本号断裂 | 先检查 manifest 状态，决定增量/恢复/全量 |
| 5 | **覆盖人工维护目录** | `rules/` `experience/` `playbooks/` `decisions/` 中有人工内容被覆盖 | 仅首次建占位 index.md，后续绝不写入 |
| 6 | **不创建 CLAUDE.md** | 后续会话无法自动加载项目知识，skill 触发链路断裂 | Finalize 阶段必须检查/创建 |
| 7 | **Finish 阶段忘记 Vault 同步** | analysis-config 中 output 含 "vault" 但只写到本地，Knowledge Vault 知识断层 | 检查 output 配置，若含 "vault" 则执行 phase-2-finish.md 步骤 6a |
| 8 | **Agent 内 spawn 子 agent 后提前返回** | 维度 agent 内并行分析多个子任务（如 TS/composables/API）时，主 agent 先于子 agent 结束，产出文件未写入 | 必须等待全部子 agent 完成后统一写入；Finish 阶段逐文件验证，缺失的由主 agent 补写 |
| 9 | **manifest.json 被外部进程覆盖** | 执行期间 manifest 可能被 linter/IDE/git hook 等外部进程 revert，导致 mode/scope 与本次执行不一致 | Finish 步骤 6.5 强制校验 mode/scope/dimensions/files/executionLog，以本次执行参数覆盖 |
| 10 | **主 agent 逐文件拼装 prompt** | 每次执行时手动从 prompts/ + 项目上下文 + 失败处理三处组合 prompt，质量不稳定 | 使用 Prompt 组合模板（4 部分：任务+上下文+产出+失败处理），确保每个维度 prompt 完整一致 |
