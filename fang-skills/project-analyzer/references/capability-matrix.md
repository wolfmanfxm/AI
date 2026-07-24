# Prompt Capability Matrix

| Prompt | 输入 | 输出目录 | 依赖 |
|--------|------|---------|------|
| [prompts/architecture.md](../prompts/architecture.md) | `package.json` + 目录结构 | `architecture/` | 无 |
| [prompts/components.md](../prompts/components.md) | `src/components/` `workspace/components/` | `components/` | architecture（组件目录位置） |
| [prompts/coding-style.md](../prompts/coding-style.md) | `.vue` `.ts` 文件抽样 | `patterns/` | architecture（技术栈确认） |
| [prompts/api-pattern.md](../prompts/api-pattern.md) | `src/api/` `workspace/api/` | `api/` | architecture（API 目录位置） |
| [prompts/ui-pattern.md](../prompts/ui-pattern.md) | 视图模板代码抽样 | `patterns/` | components（已知可用组件） |
| [prompts/patterns.md](../prompts/patterns.md) | architecture/ + components/ + api/ | `patterns/` | architecture + components + api |
| [prompts/observations.md](../prompts/observations.md) | 全部已有产出 | `observations/` | 所有前序维度 |
| [prompts/change-analysis.md](../prompts/change-analysis.md) | git diff + 已有产出 | `reports/` | architecture（模块结构） |

## 并行策略

```
Wave 0（无依赖，可立即并行）
  architecture

Wave 1（依赖 architecture，4 个可并行）
  components  coding-style  api-pattern  change-analysis

Wave 2（依赖 Wave 1，2 个可并行）
  ui-pattern（需 components）  patterns（需 architecture + components + api）

Wave 3（依赖全部前序）
  observations
```
