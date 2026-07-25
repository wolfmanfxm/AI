# Phase 1: 发现

1. 探测技术栈、目录结构、源码目录、Vault 根路径
2. 使用 `AskUserQuestion` 确认配置：

   | Q | 首次 | 非首次 |
   |---|------|--------|
   | 项目名称 | 4选1（package name/目录名/Vault名/其他） | 跳过 |
   | 分析深度 | 🚀快速 / 📊标准 / 🔬详尽 | 同左 |
   | 扫描范围 | 全量 / 增量 | 🔄上次变更(默认) / 全量 / 增量 |
   | 输出位置 | Vault+本地 / 仅本地 / 仅Vault | 跳过 |

   > AskUserQuestion: header 4-6字中文, label 3-8字, 单选

3. 完成 → 写入 `analysis-config.json`（用户选择，此后只读）和 `manifest.json`（status: confirmed，维度清单）→ 立即进入 Phase 2

> `analysis-config.json` 存放用户选择（mode/scope/vault），一旦创建不再修改。
> `manifest.json` 存放执行状态（status/dimensions/files），由分析流程持续更新。
