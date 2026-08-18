# Knowledge Index v1.0.0

> Capability-based knowledge lookup。将"按文件路径读知识"升级为"按能力标签查询知识"。
> Skill 不需要知道 `.project-knowledge/` 的目录结构——只需要声明需要什么能力。
>
> 📖 **人类读这里** · ⚙️ **Schema: [knowledge-index.schema.json](knowledge-index.schema.json)** · 📍 **输出: `.project-runtime/knowledge-index.json`**

## 设计目标

```
Before（Knowledge as Files）:
  Generator: "我需要 patterns/vue.md + patterns/form.md + components/catalog.md"
  → 硬编码文件路径，目录结构变更则全部 Skill 失效

After（Knowledge as Capability）:
  Generator: "我需要 VueConvention + FormPattern"
  → knowledge-index.json 解析到具体文件，目录结构变更只改 index
```

**核心收益：**
- Context 减半 — 声明 2 个 capability 而非列举 5+ 个文件
- 解耦 — Skill 不知道文件路径，analyzer 重组目录不影响下游
- 可发现 — "有哪些 capability 可用？" → 直接看 index keys

## Schema

文件位置：`.project-runtime/knowledge-index.json`

```json
{
  "schemaVersion": "1.0.0",
  "generatedBy": "project-analyzer",
  "generatedAt": "2026-07-30T14:00:00Z",

  "capabilities": {
    "VueConvention": {
      "description": "Vue 3 组件写法约定：<script setup>、defineProps<T>()、reactive/ref 选择",
      "files": ["patterns/vue.md", "patterns/typescript.md"],
      "keywords": ["组件", "component", "setup", "props", "emit"],
      "confidence": 90
    },
    "TablePattern": {
      "description": "项目表格组件使用模式：<表格组件> 选择与配置",
      "files": ["patterns/table.md", "components/catalog.md"],
      "keywords": ["表格", "table", "分页", "pagination", "列配置"],
      "confidence": 92
    },
    "FormPattern": {
      "description": "项目表单模式：reactive() + defineExpose + <schema搜索> + 校验",
      "files": ["patterns/form.md", "patterns/dialog.md"],
      "keywords": ["表单", "form", "校验", "validate", "弹窗"],
      "confidence": 88
    },
    "ApiPattern": {
      "description": "API 请求封装模式：request() 签名、错误处理、分页参数格式",
      "files": ["api/overview.md", "api/request.md"],
      "keywords": ["API", "接口", "request", "service", "http"],
      "confidence": 90
    },
    "CrudPattern": {
      "description": "标准 CRUD 页面模式：搜索→表格→弹窗(新增/编辑)→删除",
      "files": ["patterns/crud.md"],
      "keywords": ["CRUD", "增删改查", "列表", "管理"],
      "confidence": 91
    },
    "Architecture": {
      "description": "项目架构全景：分层结构、模块边界、依赖方向",
      "files": ["overview.md", "modules.md", "tech-stack.md"],
      "keywords": ["架构", "architecture", "模块", "分层"],
      "confidence": 90
    },
    "CodingStyle": {
      "description": "编码风格约定：命名、缩进、import 顺序、注释规范",
      "files": ["patterns/vue.md", "patterns/typescript.md", "patterns/naming.md"],
      "keywords": ["编码", "风格", "命名", "naming", "规范"],
      "confidence": 85
    }
  },

  "aliases": {
    "表格": "TablePattern",
    "表单": "FormPattern",
    "CRUD": "CrudPattern",
    "API": "ApiPattern",
    "架构": "Architecture"
  }
}
```

## 使用方式

### Generator — 按 capability 精确加载

```
1. 读 knowledge-index.json
2. 根据 PLAN.md # Reuse Analysis 确定需要的 capability → e.g. ["VueConvention", "TablePattern", "FormPattern", "ApiPattern"]
3. lookup capabilities → 得到文件列表 → 只加载这些文件
4. 不再读整个 patterns/ 目录
```

**对比：**

| | 旧方式（knowledge-list.json，已废弃） | 新方式（knowledge-index.json → context-package.json） |
|---|---|---|
| Planner 产出 | `files: ["patterns/vue.md", "patterns/form.md", ...]` | `capabilities: ["VueConvention", "FormPattern"]` → Resolver 预消化 |
| Generator 加载 | 遍历 files 列表读文件 | Resolver 遍历 knowledge[] 直接注入 pattern/constraints |
| 文件路径变更 | Planner + Generator 都要改 | 只改 index |
| Context 大小 | N 个文件路径 | 预消化知识包，无需 Generator 解析 |

### Planner — 按 capability 推荐

```
1. 读 knowledge-index.json → 了解有哪些 capability 可用
2. 分析需求 → 推导需要的 capability → e.g. "新增审批页面" → [TablePattern, FormPattern, ApiPattern]
3. 产出 context-package.json（Resolver 预消化，Generator 直接注入）
```

### Reviewer — 按 capability 加载审查规则

```
1. 读 knowledge-index.json
2. 根据变更文件类型 → 确定需要的 capability → e.g. 改 API 文件 → [ApiPattern, CodingStyle]
3. 加载对应审查规则 → 对照检查
```

### 用户/Dispatcher — 发现可用能力

```
"这个项目有哪些 capability？"
→ 读 knowledge-index.json → 展示 capability 列表 + description
→ 决定需要执行哪些 skill
```

## 生成规则

**生产者：project-analyzer**（Finish 阶段，在 context.json 之后生成）

生成逻辑：
```
1. 扫描 .project-knowledge/ 所有 .md 文件
2. 按内容聚类 → 识别 capability（VueConvention / TablePattern / FormPattern / ...）
3. 为每个 capability 生成：
   - description：一句话说明
   - files：关联的知识文件列表
   - keywords：中英文搜索关键词（用于未来自动 Resolver）
   - confidence：基于文件数量和 occurrence 的置信度
4. 生成 aliases：中文常用简称 → capability 名
5. 写入 .project-runtime/knowledge-index.json
```

**更新规则：**
- analyzer 增量模式 → 只更新变更的 capability
- analyzer 全量模式 → 重新生成整个 index
- 其他 skill 只读不写

## 与 context-package.json 的关系

```
knowledge-index.json   — 全局映射（analyzer 产出，所有 skill 可用）
context-package.json    — 任务级知识包（Resolver 产出，generator 消费）
                           ↑ 预消化 pattern + constraints + components

⚠️ Legacy: knowledge-list.json（v1 文件路径清单）已废弃，不再作为正式输入。
```
