# {{project}} · 项目知识库

> 最后更新：{{date}} · 版本：{{version}}

## 快速导航

| 我要做什么 | 读这份 |
|-----------|--------|
| 了解项目整体架构 | [架构概述](architecture/overview.md) |
| 找可复用的组件 | [组件目录](components/catalog.md) |
| 写符合规范的代码 | [编码规范](patterns/coding.md) · [UI 指南](patterns/ui.md) · [API 规范](patterns/api.md) |
| 查看最近变化 | [变更记录](reports/migration.md) · [分析报告](reports/analysis-{{date}}.md) |

## 目录

```
.project-knowledge/
├── manifest.json              ← 工具可读元数据
├── index.md                   ← 你在这里
├── architecture/              ← 架构（机器产出）
│   └── overview.md
├── components/                ← 组件（机器产出）
│   └── catalog.md
├── patterns/                  ← 规范（机器产出）
│   ├── coding.md
│   ├── ui.md
│   └── api.md
├── reports/                   ← 报告（机器产出）
│   ├── migration.md
│   └── analysis-YYYY-MM-DD.md
├── experience/                ← 经验（人工沉淀）
└── playbooks/                 ← 操作手册（人工沉淀）
```

## 使用方式

- **写代码前**：先读 `patterns/` 下对应的规范文件
- **选组件时**：查 `components/catalog.md`，优先用已有的
- **了解架构时**：读 `architecture/overview.md`
- **贡献经验时**：写入 `experience/` 或 `playbooks/`
