---
name: project-analyzer
description: >
  Analyze a software project and generate a reusable project knowledge base.
  Supports Architecture, Components, API, Patterns, Incremental Refresh, and Development Knowledge.
  Outputs to .project-knowledge.
  Full trigger words: references/trigger-words.md.
---

## Quick Start

分析项目 → 说"分析项目"即进入 [Analysis Flow](#analysis-flow)。
写代码前检查 → 说"新增组件/创建页面"即进入 [Development Flow](#development-flow)。
中断后继续 → 说"继续分析"，自动从断点恢复。

首次运行：探测技术栈 → 确认配置 → 8 维度并行分析 → 产出 ~20 个知识文件。
后续运行：增量更新变更部分，人工维护的 rules/ 目录绝不覆盖。

---

## Lifecycle

收到用户请求后，判断意图路由：

```
用户意图
├── "分析/扫描/刷新" → Analysis Flow
└── "新增/创建/实现/开发前检查" → Development Flow
```

---

## Analysis Flow

进入 Analysis Flow 后，先读 `.project-knowledge/analysis-config.json` 判断状态：

```
config 不存在  → Phase 1：发现（首次分析）
config status = completed → 询问：🔁全量刷新 / 📝增量更新 / ❌取消
config status = interrupted / partial / in_progress → Phase 2 Resume：恢复执行
```

### Phase 1：发现

1. 探测技术栈、目录结构、源码目录、Vault 根路径
2. 使用 `AskUserQuestion` 确认配置：

   | Q | 首次 | 非首次 |
   |---|------|--------|
   | 项目名称 | 4选1（package name/目录名/Vault名/其他） | 跳过 |
   | 分析深度 | 🚀快速 / 📊标准 / 🔬详尽 | 同左 |
   | 扫描范围 | 全量 / 增量 | 🔄上次变更(默认) / 全量 / 增量 |
   | 输出位置 | Vault+本地 / 仅本地 / 仅Vault | 跳过 |

   > AskUserQuestion: header 4-6字中文, label 3-8字, 单选

3. 完成 → `status: confirmed` → 立即进入 Phase 2

### Phase 2 Resume：恢复执行

> 入口条件：manifest 状态为 `interrupted` / `partial` / `in_progress`

1. 读 manifest，列出各维度状态（`completed` / `pending` / `partial`）
2. 跳过 `completed` 维度，仅执行 `pending` 和 `partial`
3. 已有文件保留（遵循 [Overwrite Policy](#overwrite-policy)），仅更新变更部分
4. 完成后 manifest `status` → `completed`

### Phase 2：执行

🔴 **CHECKPOINT · 🛑 STOP**：以下维度将产出约 15-25 个文件。展示预计产出清单（维度→文件名→预估行数），用户确认后执行。快速模式跳过 `change-analysis` 维度，标准模式跳过 `change-analysis`，详尽模式全执行。

1. 读 config → 按 scope、mode 并行执行以下维度（各维度独立，无依赖的可并行）：

| 维度 | 指南 | 输出目录 | 预期产出（必选 + 可选） |
|------|------|---------|---------------------|
| 架构 | [prompts/architecture.md](prompts/architecture.md) | architecture/ | `overview.md`（必选），可选 `modules.md` `tech-stack.md` `directory-tree.md` |
| 组件 | [prompts/components.md](prompts/components.md) | components/ | `catalog.md`（必选），可选 高复用组件独立 `.md` |
| 编码 | [prompts/coding-style.md](prompts/coding-style.md) | patterns/ | 按需: `vue.md` `typescript.md` `naming.md` `folder.md` |
| UI | [prompts/ui-pattern.md](prompts/ui-pattern.md) | patterns/ | 按需: `table.md` `form.md` `dialog.md` `layout.md` `upload.md` |
| API | [prompts/api-pattern.md](prompts/api-pattern.md) | api/ | `overview.md` `request.md`（必选），可选 `modules.md` `auth.md` |
| 模式 | [prompts/patterns.md](prompts/patterns.md) | patterns/ | 按需: `crud.md` `approval.md` `import-export.md` |
| 观察 | [prompts/observations.md](prompts/observations.md) | observations/ | `statistics.md`（必选），可选 `dead-code.md` |
| 变更 | [prompts/change-analysis.md](prompts/change-analysis.md) | reports/ | `change-log.md`（详尽模式必选） |

2. 固定产出：`manifest.json`、`statistics.json`、`graph.json`、`search-index.json`、`index.md`
3. 目录初次运行时全部创建：`architecture/` `components/` `api/` `patterns/` `observations/` `proposals/` `reports/` `rules/` `experience/` `playbooks/` `decisions/`
4. 根据分析发现填充各目录，有内容才建文件。详见 [prompts/output-format.md](prompts/output-format.md)
5. 聚合 `graph.json`：所有维度分析完成后，从各目录汇总节点和关系
6. 每个 `.md` 文件包含 Evidence Header，详见 [prompts/output-format.md](prompts/output-format.md)
7. 非首次运行：已有文档不被覆盖，对比标记 `[NEW]/[CHANGED]/[REMOVED]/[CONFIRMED]`；`rules/` 中已确认规则不再重复提议
8. 检查/创建 `.claude/CLAUDE.md`
9. 报告摘要 → config `status` → `completed`

---

## Development Flow

**保障**：`.claude/CLAUDE.md` 自动加载（主） + skill 触发（辅）。

**流程**：
1. 查 `.project-knowledge/index.md`，若无则查 `{Vault}/Projects/{project}/`
2. 按任务选读 1-2 份文档（写组件→components/+patterns/、写页面→architecture/+patterns/、写API→api/+patterns/、不确定→patterns/）
3. 提取关键约定 → 用项目实际模式生成代码
4. 🛑 若知识文档不存在 → `AskUserQuestion`：🔍运行分析 / 📝通用规范 / 📂手动路径

---

## Prompt References

各维度指南（由 Analysis Flow Phase 2 调度）：

[prompts/architecture.md](prompts/architecture.md) ·
[prompts/components.md](prompts/components.md) ·
[prompts/coding-style.md](prompts/coding-style.md) ·
[prompts/ui-pattern.md](prompts/ui-pattern.md) ·
[prompts/api-pattern.md](prompts/api-pattern.md) ·
[prompts/patterns.md](prompts/patterns.md) ·
[prompts/observations.md](prompts/observations.md) ·
[prompts/change-analysis.md](prompts/change-analysis.md)

## Template References

[templates/](templates/) · [examples/](examples/)

---

## Runtime Specification

### Operating Mode

Production · Deterministic · Incremental OK · Dev OK

### Capability Contract

#### 保证能力

✓ 架构分析
✓ 组件编目
✓ API 发现
✓ 模式提取
✓ 编码风格分析
✓ 知识索引生成
✓ 增量刷新
✓ 开发前检查

#### 不做

✗ 业务需求分析
✗ 运行时分析
✗ 安全审计
✗ 性能基准测试
✗ 部署验证
✗ 代码重构
✗ 测试生成

> 触发词命中了但意图落在"不做"区域 → 不调用本 skill，直接告知用户边界。

### Output Contract

#### 固定产出

每次分析必定产出，无条件覆盖：

| 文件 | 说明 |
|------|------|
| `manifest.json` | 元数据：版本、维度、文件清单、状态 |
| `statistics.json` | 仪表盘数据：组件/API/模式/质量指标 |
| `search-index.json` | 关键词→文件检索索引 |
| `graph.json` | 结构化关系图谱（节点+边） |
| `index.md` | 人类导航入口 |

#### 按需产出

按实际代码检测结果动态产出，有内容才建文件：

| 目录 | 产出文件 | 触发条件 |
|------|---------|----------|
| `architecture/` | `overview.md`（必选），可选 `modules.md` `tech-stack.md` | 有源码目录 |
| `components/` | `catalog.md`（必选），可选 高复用组件独立 `.md` | 有组件目录 |
| `api/` | `overview.md` `request.md`（必选），可选 `modules.md` | 有 API 目录 |
| `patterns/` | `vue.md` `typescript.md` `naming.md` `folder.md` `table.md` `form.md` `dialog.md` `layout.md` `upload.md` `crud.md` `approval.md` `import-export.md` | 按实际模式数量 |
| `observations/` | `statistics.md`（必选），可选 `dead-code.md` | 有扫描数据 |
| `reports/` | `change-log.md`（详尽模式） | 增量/详尽模式 |

#### 人工维护

分析模式**仅首次创建占位 `index.md`**，后续运行**绝不覆盖**：

| 目录 | 维护者 | 说明 |
|------|--------|------|
| `rules/` | 人工 | 团队编码规则 |
| `experience/` | 人工 | 项目经验教训 |
| `playbooks/` | 人工 | 操作手册 |
| `decisions/` | 人工 | 架构决策记录 |

### Overwrite Policy

非首次运行时，已有文档遵循以下覆盖策略：

**自动覆盖** — 每次分析无条件覆盖（机器生成内容，不应人工编辑）：

```
architecture/   components/   api/
patterns/       observations/ reports/
manifest.json   statistics.json   graph.json
search-index.json   index.md
```

**永不覆盖** — 即使文件已存在也绝不覆盖（人工维护内容）：

```
rules/     experience/     playbooks/     decisions/
```

对比标记：非首次运行时，自动覆盖区域的文件对比后标注 `[NEW]` / `[CHANGED]` / `[REMOVED]` / `[CONFIRMED]`；永不覆盖区域跳过不处理。

### Resource Boundaries

#### 行为原则

以下原则不受 context 大小变化影响，始终适用：

| 原则 | 说明 |
|------|------|
| 优先并行分析 | 无依赖的维度并行执行（架构/组件/API/编码可并行） |
| manifest 存在时避免全量扫描 | 非首次运行优先增量，仅变更维度全量重扫 |
| 优先增量更新 | 增量模式回退全量前先尝试 git diff 范围 |
| 跳过大型二进制文件 | PDF/图片/视频等不参与文本分析 |
| 不扫描构建产物 | 跳过 `node_modules/` `dist/` `.git/` 等 |
| 遵循 ignore 文件 | 遵循 `.gitignore` 排除规则 |
| 非必要不读取 vendor 依赖 | `node_modules/` 中的代码不分析 |

#### 项目规模自适应策略

根据项目规模自动选择执行策略，不硬编码数字阈值：

```
小型项目               中型项目               大型项目
(少量文件)             (中等规模)             (海量文件)
    │                      │                      │
    ▼                      ▼                      ▼
 单次扫描               并行                  增量
 主 agent 直接扫描      维度 agent 并行       优先增量 + 变更维度
 不 spawn 子 agent      按需 spawn            仅变更模块全量重扫
```

#### 降级策略

见 [Failure Contract](#failure-contract)「若某维度 agent 失败」。

### Failure Contract

#### 若架构无法推断

→ 输出部分知识，推断章节标注 `confidence: <50`。
  manifest 标记 `status: partial`，列出缺失维度。

#### 若分析中途 token 耗尽

→ 立即持久化所有已完成章节文件。
  manifest 更新各维度状态（`completed` / `pending` / `partial`）。
  下次运行读 manifest → 从第一个 `pending` 维度恢复。

#### 若分析被中断

→ manifest 状态更新为 `interrupted`。
  恢复时：读 manifest，跳过 `completed` 维度，重新执行 `pending`。
  已写入文件保留（遵循 [Overwrite Policy](#overwrite-policy)）。

#### 若某维度 agent 失败

→ 主 agent 从部分数据合成产出，标记 `⚠️ 子agent超时，数据由主agent补充`。
  不阻塞其他维度。

### Governed Package

| 字段 | 值 | 来源 |
|------|-----|------|
| owner | skill author | Production 模式要求 |
| review cadence | 每次大版本后 | Appendix 关键约束 §6 |
| input_files | `package.json` + 源码目录 + Vault 路径 | file-backed fixture（文件锚点） |
| output contract | 见 [Output Contract](#output-contract) | 固定产出 + 按需产出 + 人工维护 |
| rollback boundary | 删除 `.project-knowledge/` 即可回滚 | [Overwrite Policy](#overwrite-policy) |
| trust report | missing evidence（缺失证据） | 待产出 |
| quality scorecard | missing evidence（缺失证据） | 待 `reports/output_quality_scorecard.md` |

---

## Appendix

### A. 关键约束

1. **只读业务代码** — 不修改项目源码目录中的任何业务代码，仅写入 `.project-knowledge/` 和 Obsidian Vault（agent 应主动写文件，不是只读模式；源码目录从探测结果动态确定，不预设名称）
2. **自动适配** — 不预设技术栈，一切从实际代码检测
3. **证据优先** — 每个结论标注 `file:line`
4. **区分事实与推断** — 标注模式来源
5. **中文输出** — 主体中文，代码原文
6. **定期刷新** — 建议每周或大版本后运行 (§6)

### B. 异常处理

| 步骤 | 触发条件 | 一线修复 | 仍失败兜底 |
|------|---------|---------|-----------|
| 读 `package.json` | 不存在/解析失败 | 检查是否在根目录 | AskUserQuestion：输入框架名/跳过/自定义目录 |
| 探测目录结构 | find 空/权限拒绝 | 排除 node_modules/dist | AskUserQuestion：输入目录/降级ls/取消 |
| 统计命令 | 零匹配 | 扩大搜索范围 | 标注⚠️，不编造数据 |
| 读 Vault | 路径不可达 | 尝试本地 `.project-knowledge/` | AskUserQuestion：重输路径/仅本地/取消 |
| 组件引用计数 | 无结果 | 尝试 PascalCase + kebab-case | 标注"引用计数=0" |
| 增量扫描 | 本地副本为空 | 回退全量扫描 | 新建目录 + 全量 |

### C. 反例清单

| # | ❌ 不要做 | ✅ 正确做法 |
|---|----------|-----------|
| 1 | 修改任何业务代码文件 | 仅写 `.project-knowledge/` 和 Obsidian Vault |
| 2 | 用框架通用模式代替项目实际模式 | 从实际代码提取，引用 `file:line` |
| 3 | 编造不存在的 API、组件、目录 | 实时验证后再写 |
| 4 | 跳过确认直接扫描大型项目 | 先确认项目名、范围、路径 |
| 5 | 开发前检查中重新扫描源码 | 只读已有文档 |
| 6 | 输出无 `file:line` 的笼统建议 | 每个结论标注源文件位置 |
| 7 | 对不存在的目录静默跳过 | 标注"⚠️ 路径不存在" |
