---
name: project-generator
metadata: skill.yaml
description: >
  根据需求和项目规范生成生产级代码：Vue 3 组件、页面、API 模块、工具函数、类型定义。
  必须遵循项目现有模式，从 .project-knowledge/ 提取规范而非凭记忆。
  触发词：写一个、实现、创建组件、新增页面、开发这个功能、生成代码、帮我写、implement、
  create component、build feature、generate code、write a、开发、编写、添加。
  产出：代码文件（.vue / .ts / .js 等）+ 少量注释说明。
---

# Generator

> 需求 + 项目知识 → 生产级代码

## 核心原则

1. **遵循项目模式** — 从 `.project-knowledge/` 提取写法
2. **使用项目组件** — 查 `components/catalog.md`
3. **完整性** — loading、empty、error 全状态
4. **一致性** — 缩进、引号、命名、import 与项目一致

## 职责边界

→ [references/boundary.md](references/boundary.md)

> 🔴 generator 只写代码。缺少 PLAN.md/ARCHITECTURE.md → 提示先执行上游。

## 前置条件

| 优先级 | 资源 | 缺失时 |
|--------|------|--------|
| 0 | **`context.json`**（[Context Protocol](../../runtime/context/context.md)）| 🔴 BLOCK 若缺 REQUIRED 字段 → [priority](../../runtime/context/context-priority.md)；不存在则从 `.project-knowledge/` 提取 |
| 1 | `.project-knowledge/index.md` | 降级通用模式 |
| 2 | `PLAN.md`，**若存在必读** | 标注"⚠️ 无规划" |
| 3 | `ARCHITECTURE.md`，**若存在必读** | 标注"⚠️ 无架构约束" |

> `context.json` 来自 analyzer 的 Finish 阶段，包含技术栈/路径别名/编码约定/模块清单。加载后不再需逐个读 `.project-knowledge/` 文件。

## 项目知识读取（context.json 覆盖后按需补充）

| 生成类型 | context.json 已覆盖 | 按需补充 |
|---------|-------------------|---------|
| 组件 | 技术栈、别名、组件风格、已有组件列表 | `components/catalog.md`（组件详情） |
| 页面 | 路径别名、分页参数、路由模块 | `architecture/overview.md`（路由架构） |
| API 模块 | API 前缀、封装函数名、响应类型 | `api/request.md`（拦截器细节） |
| 工具函数 | 语言版本、import 规范 | `patterns/typescript.md` |
| 类型定义 | 语言版本、路径别名 | `patterns/typescript.md` |

## 工作流

### Discover

1. 读项目知识库 + PLAN.md/ARCHITECTURE.md
2. 🔴 代码存在性检查 → [references/code-audit.md](references/code-audit.md)
3. 找类似实现，确认技术栈
4. 🔴 CHECKPOINT → 展示过滤后的范围 → [checkpoint 模式](../../shared/conventions/checkpoint-pattern.md)

### Execute

```
读知识库 → 找参考实现 → 提取模式 → 套用模式生成 → 自检
```

自检清单 → [references/self-check.md](references/self-check.md)

🔴 CHECKPOINT → 展示代码摘要

### 完成报告

→ [references/completion-report.md](references/completion-report.md)

## 边界处理

| 场景 | 做法 |
|------|------|
| 知识库不存在 | 降级通用模式，标注 `⚠️ 未找到项目知识库` |
| 组件不在目录中 | 搜索后降级 Element Plus 原生 |
| 与 PLAN.md 冲突 | 以代码为准，标注 `⚠️ 偏差` |
| 需新增依赖 | 标注 `TODO: 安装依赖`，不修改 package.json |

## 完成后下一步

```
generator 完成 → /project-reviewer 或 /project-tester 或 /project-documenter
```
