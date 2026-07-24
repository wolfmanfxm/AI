---
name: project-analyzer
description: >
  双模式技能 — 分析模式：扫描项目生成结构化知识文档；开发前检查模式：写代码前读取知识文档，
  确保生成代码符合项目实际规范而非框架通用最佳实践。
  分析触发（Phase 1 Discover）：用户提到"分析项目"、"代码分析"、"项目审计"、
  "发现模式"、"梳理组件"、"更新项目知识"、"项目规范"、"编码规范"、"代码风格"、
  "刷新项目知识"、"project refresh"、"scan project"、"generate architecture"、
  "analyze codebase"、"项目文档生成"。
  恢复触发（Phase 2 Resume）：用户说"继续分析"、"resume"、"analyze now"、
  "开始分析"、"确认配置"、"start analysis"。
  检查触发：用户提出编码需求时（"新增组件"、"创建页面"、"写一个 XX"、"实现 XX 功能"、
  "开发前检查"、"pre-dev check"、"before coding"），应先读取项目知识文档再编码。
  仅做只读分析，不修改任何业务代码。
---

# Project Analyzer Skill

## 模式路由

收到用户请求后，判断意图并路由到对应模式：

```
用户意图
├── "分析/扫描/刷新" → 分析模式（Phase 1 Discover → Phase 2 Resume）
└── "新增/创建/实现/开发前检查" → 开发前检查模式
```

---

## 开发前检查模式

**保障**：`.claude/CLAUDE.md` 自动加载（主） + skill 触发（辅）。

**流程**：
1. 查 `.project-knowledge/index.md`，若无则查 `{Vault}/Projects/{project}/`
2. 按任务选读 1-2 份文档（写组件→components/+patterns/、写页面→architecture/+patterns/、写API→api/+patterns/、不确定→patterns/）
3. 提取关键约定 → 用项目实际模式生成代码
4. 🛑 若知识文档不存在 → `AskUserQuestion`：🔍运行分析 / 📝通用规范 / 📂手动路径

---

## 分析模式

### Phase 1：Discover

1. 检测 `.project-knowledge/analysis-config.json` 是否存在，判断首次/非首次
2. 探测技术栈、目录结构、源码目录、Vault 根路径
3. 使用 `AskUserQuestion` 确认配置：

   | Q | 首次 | 非首次 |
   |---|------|--------|
   | 项目名称 | 4选1（package name/目录名/Vault名/其他） | 跳过 |
   | 分析深度 | 🚀快速 / 📊标准 / 🔬详尽 | 同左 |
   | 扫描范围 | 全量 / 增量 | 🔄上次变更(默认) / 全量 / 增量 |
   | 输出位置 | Vault+本地 / 仅本地 / 仅Vault | 跳过 |

   > AskUserQuestion: header 4-6字中文, label 3-8字, 单选

4. 完成 → `status: confirmed` → 立即进入 Phase 2

### Phase 2：Resume

1. 读 config → 按 scope、mode 依次执行以下维度：

| 维度 | 指南 | 输出目录 |
|------|------|---------|
| 架构 | [prompts/architecture.md](prompts/architecture.md) | architecture/ |
| 组件 | [prompts/components.md](prompts/components.md) | components/ |
| 编码 | [prompts/coding-style.md](prompts/coding-style.md) | patterns/ |
| UI | [prompts/ui-pattern.md](prompts/ui-pattern.md) | patterns/ |
| API | [prompts/api-pattern.md](prompts/api-pattern.md) | api/ |
| 模式 | [prompts/patterns.md](prompts/patterns.md) | patterns/ |
| 观察 | [prompts/observations.md](prompts/observations.md) | observations/ |
| 变更 | [prompts/change-analysis.md](prompts/change-analysis.md) | reports/ |

2. 固定产出：`manifest.json`、`statistics.json`、`graph.json`、`search-index.json`、`index.md`
3. 目录初次运行时全部创建：`architecture/` `components/` `api/` `patterns/` `observations/` `proposals/` `reports/` `rules/` `experience/` `playbooks/` `decisions/`
4. 根据分析发现填充各目录，有内容才建文件。详见 [prompts/output-format.md](prompts/output-format.md)
5. 聚合 `graph.json`：所有维度分析完成后，从各目录汇总节点和关系
6. 每个 `.md` 文件包含 Evidence Header，详见 [prompts/output-format.md](prompts/output-format.md)
7. 非首次运行：已有文档不被覆盖，对比标记 `[NEW]/[CHANGED]/[REMOVED]/[CONFIRMED]`；`rules/` 中已确认规则不再重复提议
8. 检查/创建 `.claude/CLAUDE.md`
9. 报告摘要 → config `status` → `completed`

---

## 关键约束

1. **只读** — 仅写 Obsidian Vault 和 `.project-knowledge/`
2. **自动适配** — 不预设技术栈，一切从实际代码检测
3. **证据优先** — 每个结论标注 `file:line`
4. **区分事实与推断** — 标注模式来源
5. **中文输出** — 主体中文，代码原文
6. **定期刷新** — 建议每周或大版本后运行

## 异常处理

| 步骤 | 触发条件 | 一线修复 | 仍失败兜底 |
|------|---------|---------|-----------|
| 读 `package.json` | 不存在/解析失败 | 检查是否在根目录 | AskUserQuestion：输入框架名/跳过/自定义目录 |
| 探测目录结构 | find 空/权限拒绝 | 排除 node_modules/dist | AskUserQuestion：输入目录/降级ls/取消 |
| 统计命令 | 零匹配 | 扩大搜索范围 | 标注⚠️，不编造数据 |
| 读 Vault | 路径不可达 | 尝试本地 `.project-knowledge/` | AskUserQuestion：重输路径/仅本地/取消 |
| 组件引用计数 | 无结果 | 尝试 PascalCase + kebab-case | 标注"引用计数=0" |
| 增量扫描 | 本地副本为空 | 回退全量扫描 | 新建目录 + 全量 |

## 反例清单

| # | ❌ 不要做 | ✅ 正确做法 |
|---|----------|-----------|
| 1 | 修改任何业务代码文件 | 仅写 `.project-knowledge/` 和 Obsidian Vault |
| 2 | 用框架通用模式代替项目实际模式 | 从实际代码提取，引用 `file:line` |
| 3 | 编造不存在的 API、组件、目录 | 实时验证后再写 |
| 4 | 跳过确认直接扫描大型项目 | 先确认项目名、范围、路径 |
| 5 | 开发前检查中重新扫描源码 | 只读已有文档 |
| 6 | 输出无 `file:line` 的笼统建议 | 每个结论标注源文件位置 |
| 7 | 对不存在的目录静默跳过 | 标注"⚠️ 路径不存在" |
