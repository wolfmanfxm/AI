# Evidence Prompt — Shared Library v1.0.0

> 所有 Skill 的通用证据引用规范。被 analyzer/documenter/reviewer/generator 引用。
> 使用方式：在 Skill 的 prompts/ 文件中 `[引用](../../shared/prompts/evidence.md)` 即可。

---

## 核心规则

1. **源码引用格式**：`file:line`，如 `workspace/api/quotaManage.ts:65`
2. **不编造**：所有代码示例从源文件复制，不凭记忆写
3. **不确定标标注**：无法确认的内容标 `[待补充]` 或 `[推断]`

## 证据等级

| 等级 | 标记 | 含义 | 示例 |
|------|------|------|------|
| ✅ CONFIRMED | `sources: [file:line]` | 从源码直接提取 | `defineProps<T>()` in `workspace/views/*.vue` |
| ⚠️ INFERRED | `[推断]` | 从类型/命名推断，未直接看到源码 | "参数类型推断为 QuotaQueryParams" |
| ❓ UNCONFIRMED | `[待补充]` | 假设或外部信息，需人工确认 | "假设后端 API 已就绪" |

## Evidence Header 模板

每个产出 `.md` 文件头部：

```yaml
---
id: <kebab-case>
generatedBy: <skill-name>
generatedAt: <ISO-8601>
last_scan: <ISO-8601>
lifecycle: draft
confidence: <0-100>
sources:
  - <file:line>
  - <file:line>
---
```

## 反例

| ❌ 不要 | ✅ 要 |
|--------|------|
| "项目使用 XX 模式"（无证据） | "项目使用 PageTable+SchemaTable 模式，见 `workspace/views/quotaManage/mailConfig/index.vue:4-10`" |
| 凭框架知识写代码 | 读 2+ 个现有文件提取实际模式 |
| 编造 API 参数名 | 从 `workspace/api/<module>.ts` 源码复制参数名 |
