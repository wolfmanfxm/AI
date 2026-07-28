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

4. 写入 `analysis-config.json` 时必须包含的字段：

   | 字段 | 来源 | 说明 |
   |------|------|------|
   | `projectName` | 用户选择 | 项目名称 |
   | `mode` | 用户选择 | `quick` / `standard` / `deep` |
   | `scope` | 用户选择 | `["src"]` / `["src", "workspace"]` 等 |
   | `output` | 用户选择 | `["vault", "local"]` / `["local"]` / `["vault"]` |
   | `vaultPath` | 探测结果 | Obsidian Vault 绝对路径（output 含 "vault" 时必填） |
   | `schemaVersion` | 固定 | `"1.0.0"` |
   | `createdAt` | 当前时间 | ISO-8601 格式 |

   > `vaultPath` 需在步骤 1 中探测，通常为 `{用户目录}/Data/Knowledge Vault/`。
   > 若 output 仅含 `"vault"`（不写本地），Phase 2 仍先在本地生成再同步。
