# Discovery — Analyzer

> @engine: discovery

## Actions

0. **Context Resolver** → [Context Resolver](../../../runtime/contracts/context-resolver.md)：从项目路径提取 tags → 查询 `knowledge-graph.yaml` → 注入已有的 architecture/patterns/glossary
1. 探测技术栈：`@adapter:filesystem.read package.json`（dependencies/devDependencies/scripts）、`@adapter:filesystem.read tsconfig.json`（paths/baseUrl）、`@adapter:filesystem.read vite.config.*`（alias/resolve）
2. 探测目录结构：`@adapter:filesystem.list src/` + `@adapter:filesystem.find "*.vue" workspace/`（若有）
3. 探测 Knowledge Vault 路径：`@adapter:filesystem.list "$HOME/Data/Knowledge Vault"` → `@adapter:filesystem.list "./Knowledge Vault"` → `@adapter:filesystem.list "$HOME/Documents/Knowledge Vault"`，取第一个可达路径
4. `AskUserQuestion` 确认：
   - 项目名（默认 package.json name）
   - 分析深度：`quick`（仅架构+组件）/ `standard`（7维度）/ `deep`（7维度+交叉验证+QA）
   - 分析范围：全项目 / 指定模块（逗号分隔）
   - 输出位置：默认 `.project-knowledge/`
5. 写入 `analysis-config.json`（含 `vaultPath`）+ `manifest.json`（status=discover）

## Exit

- `framework` identified（从 package.json + 配置文件推断）
- `package_manager` identified（npm/yarn/pnpm）
- `scope` confirmed（用户已回答）
- `analysis-config.json` 已写入
- `manifest.json` status = discover

## Failure

| Condition | Action |
|-----------|--------|
| 无 `package.json` | `AskUserQuestion` 手动指定框架和包管理器 |
| 权限不足（无法读项目文件） | 🔴 BLOCKED — 提示用户检查权限 |
| Vault 路径全部不可达 | 🟡 DEGRADED — 跳过 Vault 同步，标注 `⚠️ Vault 不可达` |
| 用户取消 | 删除 `analysis-config.json` + `manifest.json`，结束 |

## CHECKPOINT

🔴 CHECKPOINT — 用户确认范围后进入 Execution
→ [checkpoint-pattern](../../../shared/conventions/checkpoint-pattern.md)
