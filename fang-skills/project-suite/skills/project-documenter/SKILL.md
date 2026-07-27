---
name: project-documenter
description: >
  生成和维护项目文档：API 文档（从 JSDoc/代码提取）、README、ADR、Changelog、组件文档。
  自动匹配项目已有文档风格，所有内容基于代码事实不编造。
  触发词：生成文档、写文档、补文档、API 文档、README、更新文档、补全文档、
  generate docs、write documentation、update README、api docs、组件文档。
  产出：文档文件（.md），含 Evidence Header。
---

# Documenter

> 代码 + 上下文 → 结构化、可溯源、风格一致的技术文档

## 核心原则

1. **基于代码事实** — 从源文件提取，不编造接口、参数、行为
2. **匹配已有风格** — 读 1-2 份现有文档，模仿其结构、语言、格式
3. **可溯源** — 每个关键信息标注 `file:line`，读者可验证
4. **完整不冗余** — 覆盖关键信息，不写"显而易见"的内容

## 文档类型

| 类型 | 输入 | 产出 | 参考 prompt |
|------|------|------|------------|
| **API 文档** | API 模块代码 + JSDoc | `api/<module>.md` | [api-doc.md](prompts/api-doc.md) |
| **README** | package.json + 项目结构 + 已有 README | `README.md` | [readme-gen.md](prompts/readme-gen.md) |
| **组件文档** | .vue 组件源码（Props/Events/Slots） | `components/<name>.md` | [component-doc.md](prompts/component-doc.md) |
| **ADR** | 架构决策上下文 | `decisions/<NNNN>-<title>.md` | 参考 architect |
| **Changelog** | git log + PR 描述 | `CHANGELOG.md` | 参考 releaser |

## 工作流

### Discover

1. 确认文档类型 + 范围
2. 收集源材料：代码文件、已有文档、PR 描述
3. 读 1-2 份项目已有文档 → 提取风格特征
4. 🔴 **CHECKPOINT** — 确认：类型 + 范围 + 风格基准

### Execute

#### 风格匹配框架

读已有文档后，确认以下特征再开始写：

| 特征 | 检查 |
|------|------|
| 标题层级 | `# 标题` 还是 `## 标题` 开头？有几个层级？ |
| 语言 | 纯中文？中英混排？英文为主？ |
| 代码块 | 带语言标注？带文件名？行号？ |
| 表格风格 | 紧凑（无空格对齐）还是展开？ |
| 链接写法 | `[text](path)` 还是 `<text>` ？相对路径还是绝对？ |
| 语气 | 正式（"建议使用"）还是口语（"推荐用"）？ |

#### 内容提取原则

| 从代码提取 | 不从代码推测 |
|-----------|------------|
| 函数签名、参数类型、返回值 | 业务含义（除非有 JSDoc 注释） |
| Props / Events / Slots 定义 | 使用场景（除非有代码注释） |
| HTTP 方法 + URL + 请求体 | 接口的设计意图 |
| 导出内容的依赖关系 | 架构决策理由 |

#### 失败处理

> 以下场景在文档生成中高频出现，必须显式编码恢复路径，不静默跳过。

| 触发条件 | 一线修复 | 仍失败兜底 |
|---------|---------|-----------|
| 源文件不可读/不存在 | 搜索同名文件其他扩展名（`.ts` → `.js`），检查是否移动 | 标注 `⚠️ 源文件不可读: <path>`，跳过该接口/组件 |
| 已有文档风格无参考 | 使用 doc-style-guide.md 默认风格（`#` 一级标题、中文描述、代码块带语言标注） | AskUserQuestion：选择参考文档 / 使用默认风格 / 跳过 |
| 目标文档已存在 | 对比生成内容与已有内容，仅更新差异（不覆盖人工手写章节） | 若差异 > 50%，AskUserQuestion：🔁覆盖 / 📝仅补充 / ❌跳过 |
| 代码中无 JSDoc/注释 | 从函数名+参数类型推断用途，标注 `[推断]` | 无法推断 → 标注 `[待补充]` |
| 风格特征无法判定 | 逐个特征默认：中文描述、代码块带语言标注、表格不强制对齐、语气正式 | AskUserQuestion：手动指定风格模板 |
| 生成内容与已有文档严重冲突 | 对比冲突行，标记 `[CONFLICT]` | AskUserQuestion：保留已有 / 替换为新 / 合并 |

🔴 **CHECKPOINT · 🛑 STOP**：展示文档预览（标题+结构+前2段正文），用户确认后写入文件。

### Output

所有产出文件包含 Evidence Header（[../../shared/templates/evidence-header.md](../../shared/templates/evidence-header.md)）：

```yaml
---
id: <doc-id>
generatedBy: documenter
generatedAt: <ISO-8601>
confidence: <0-100>
sources:
  - <source-files>
---
```

## 文档新鲜度检查

当用户说"检查文档是否过时"时执行：

1. 对比文档 `sources` 中的文件与当前代码
2. 检查函数签名/参数/返回值是否一致
3. 输出差异清单：`[OUTDATED]` `[MATCH]` `[NEW]`

## Runtime 协议

| 协议 | 路径 |
|------|------|
| 状态机 | [../../runtime/engine/state-machine.md](../../runtime/engine/state-machine.md) |
| 异常恢复 | [../../runtime/engine/error-recovery.md](../../runtime/engine/error-recovery.md) |
| 路由 | [../../runtime/protocols/routing.md](../../runtime/protocols/routing.md) |

## References

| 资源 | 路径 |
|------|------|
| API 文档 Prompt | [prompts/api-doc.md](prompts/api-doc.md) |
| README 生成 Prompt | [prompts/readme-gen.md](prompts/readme-gen.md) |
| 组件文档 Prompt | [prompts/component-doc.md](prompts/component-doc.md) |
| 文档风格指南 | [references/doc-style-guide.md](references/doc-style-guide.md) |
| 触发词 | [references/trigger-words.md](references/trigger-words.md) |
| 能力边界 | [references/capability-matrix.md](references/capability-matrix.md) |
| 反例清单 | [references/anti-patterns.md](references/anti-patterns.md) |
| 文档示例 | [references/examples.md](references/examples.md) |
