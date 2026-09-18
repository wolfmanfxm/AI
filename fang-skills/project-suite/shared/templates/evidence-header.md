# Evidence Header Template

所有 skill 产出的 `.md` 文件使用以下 Frontmatter 模板：

```yaml
---
id: <unique-id>
generatedBy: <skill-name>
generatedAt: <ISO-8601-timestamp>
last_scan: <ISO-8601-timestamp>
lifecycle: Artifact
confidence: <0-100>
sources:
  - <source-file-path>
---
```

## 字段规范

| 字段 | 含义 | 示例 |
|------|------|------|
| `id` | 文档唯一标识，kebab-case | `architecture-overview` |
| `generatedBy` | 生成 skill 名 | `analyzer` `documenter` |
| `generatedAt` | 首次生成时间 | `2026-07-27T14:00:00Z` |
| `last_scan` | 最后校验时间 | 同上 |
| `lifecycle` | 生命周期（v2.0） | `Artifact` `Candidate` `Accepted` `Deprecated` |
| `confidence` | 置信度 0-100 | 95（统计事实） 75（模式推断） |
| `sources` | 证据源文件 | `src/api/user.ts` |

## `rules/` 与 `decisions/` 的额外必需字段：`constraint`

`rules/` 与 `decisions/` 下的文件，在通用 Frontmatter 之外**必须**写 `constraint:`——一句可执行的硬约束。

**这不是建议，是硬校验**：`knowledge-compiler.sh` 检测到缺失即 `exit 1`，**不生成 `knowledge-index.json`**，
整条知识链（Compiler → Resolver → context-package）随之中断。

```yaml
---
id: rules-form-standard
generatedBy: manual
generatedAt: <ISO-8601-timestamp>
last_scan: <ISO-8601-timestamp>
lifecycle: confirmed
confidence: 95
constraint: "所有表单必须用 FormWrapper 封装"
sources:
  - <source-file-path>
---
```

**为什么**：Compiler 把 `constraint` 作为该条目的**机器可读约束文本**，注入 `context-package` 的
`constraints[]`（`enforcement: blocking`）。没有它，这条规则/决策就无法以「约束」形式被下游消费，
只能退化成一段没人解析的散文。

**适用范围**：仅 `rules/` 与 `decisions/`。`patterns/` `components/` `api/` `architecture/` 不需要
（它们走 `statement`/`constraints`，见 project-analyzer 的 knowledge-builder.md）。

### 派生值标记：`constraint_source`（仅存量补齐时写）

存量知识库可能是在这条要求之前产出的。analyzer 的 Knowledge Builder 在**存量补齐**时，会为缺失字段的文件
从正文派生一个值，并**同时写标记**：

```yaml
constraint: "……"
constraint_source: derived-from-body   # 派生值，未经人工确认；原始产出者见 generatedBy
```

- **有标记** = 这个值是 analyzer 从正文派生的，不是原作者写的 → 人工复核确认后**移除该标记**
- **无标记** = 值来自原作者本人 → 不要再动它

Compiler 检测到派生值时会在输出里打印 `⚠️` 提示条数（不阻塞生成）。完整规则见
project-analyzer 的 [knowledge-builder.md](../../skills/project-analyzer/prompts/knowledge-builder.md)「存量补齐」。

> 权威规则见 [runtime/knowledge/knowledge-compiler.md](../../runtime/knowledge/knowledge-compiler.md) 的「constraint 必需性（按 type 分级）」。
