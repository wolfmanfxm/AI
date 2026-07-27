# Project Suite

> 软件项目全生命周期 skill 套件 — 9 个 skill，从分析到发布，覆盖完整 SDLC。
> 每个 skill 可独立触发，也可编排为工作流链。

## 当前版本：0.4.0

全部 9 个 skill 已达正式版。详见 [docs/roadmap.md](docs/roadmap.md)。

## Skill 矩阵

| # | Skill | 职责 | 文件 | 亮点 |
|---|-------|------|------|------|
| 1 | **analyzer** | 7 维度代码分析 → `.project-knowledge/` | 14 | 并行 agent、增量刷新、开发前检查 |
| 2 | **planner** | 需求 → 任务拆解 → 依赖分析 → 风险矩阵 | 8 | 3 种依赖标注、t-shirt size 估算、里程碑规划 |
| 3 | **architect** | 技术选型 + 模块设计 + API 契约 | 10 | 候选×维度矩阵、ADR 格式、决策陷阱警告 |
| 4 | **generator** | 需求 + 项目知识 → 生产级代码 | 9 | 9 项自检清单、按生成类型分策略、安全反例 |
| 5 | **tester** | 测试生成 + 环境检测 + 覆盖率报告 | 10 | 6 项环境自动检测、Mock 策略、覆盖矩阵 |
| 6 | **reviewer** | 五轴代码审查 + 分级 + 修复建议 | 9 | 严重度决策树、correctness/security 专项审查 |
| 7 | **refactorer** | 安全重构：9 种手法 + 4 层安全协议 | 9 | 表征测试、单步操作、过度重构警告 |
| 8 | **documenter** | 代码 → 结构化文档（API/README/组件） | 10 | 风格匹配框架、JSDoc→Markdown 提取、新鲜度检查 |
| 9 | **releaser** | 版本 bump + Changelog + 发布检查 | 10 | Conventional Commits 解析、7 类 Changelog 分组 |

## 架构

```
project-suite/
├── SUITE.md                  ← 你在这里
│
├── skills/                   ← 9 个 skill（各自 SKILL.md + prompts/ + references/）
│   ├── analyzer/   14 files  ✅ 完整版
│   ├── planner/     8 files  ✅ 正式版
│   ├── architect/  10 files  ✅ 正式版
│   ├── generator/   9 files  ✅ 正式版
│   ├── tester/     10 files  ✅ 正式版
│   ├── reviewer/    9 files  ✅ 正式版
│   ├── refactorer/  9 files  ✅ 正式版
│   ├── documenter/ 10 files  ✅ 正式版
│   └── releaser/   10 files  ✅ 正式版
│
├── runtime/                  ← 共享运行时协议（所有 skill 共用）
│   ├── engine/               ← 单 skill 执行层
│   │   ├── state-machine.md     通用生命周期：idle→discover→execute→finish
│   │   ├── checkpoint.md        断点续传 + manifest 格式
│   │   ├── scheduler.md         调度：继续/暂停/优先级/token 管理
│   │   └── error-recovery.md    异常分级(WARNING/DEGRADED/BLOCKED/FATAL)
│   └── protocols/            ← 多 skill 协作层
│       ├── routing.md           9 skill 意图→路由表 + 歧义处理规则
│       └── orchestration.md     编排链 + skill 间数据契约(manifest.extends)
│
├── shared/                   ← 静态制品（skill 间共享的数据契约）
│   ├── schemas/               manifest / analysis-config / graph JSON Schema
│   ├── templates/             Evidence Header 模板
│   ├── conventions/           命名、格式、引用约定
│   └── examples/              跨 skill 输出示例
│
└── docs/                     ← suite 自身文档
    ├── architecture.md        架构设计决策
    ├── roadmap.md             版本演进路线
    └── migration.md           从旧 analyzer 迁移指南
```

## 典型工作流

### 全流程（绿field 项目）

```
analyzer → planner → architect → generator → tester → reviewer → refactorer → documenter → releaser
 知识库    PLAN.md   ARCH.md      代码      测试报告   REVIEW.md    REFACTOR.md   文档     CHANGELOG
```

### 日常功能开发

```
planner → architect → generator → tester → reviewer
```

### 轻量改动

```
generator → reviewer
```

### 重构

```
analyzer → refactorer → tester → reviewer
```

### 发布

```
documenter → releaser
```

## 如何使用

### 触发单个 skill

直接说需求，`runtime/protocols/routing.md` 定义意图→skill 路由：

```
"分析这个项目的代码结构"          → analyzer
"这个需求拆成哪些任务"            → planner
"选什么状态管理库比较好"          → architect
"帮我实现这个搜索功能"            → generator
"给 formatPrice 写单元测试"       → tester
"帮我 review 这个 PR"            → reviewer
"这个函数太长了帮我重构"          → refactorer
"给 user 模块生成 API 文档"       → documenter
"准备发布，帮我生成 changelog"    → releaser
```

### 歧义处理

路由表对每个 skill 定义了 `歧义处理` 规则（如 "设计系统" → architect vs planner），不确定时 `AskUserQuestion` 确认。

### 安装使用

将 `skills/` 下需要的 skill 目录复制或软链接到 Claude Code 的 skills 目录。每个 skill 独立可工作，缺失上游产物时降级为默认模式。

## 参与

- [docs/architecture.md](docs/architecture.md) — suite 设计决策
- [docs/roadmap.md](docs/roadmap.md) — 版本路线
- [docs/migration.md](docs/migration.md) — 从独立 analyzer 迁移
