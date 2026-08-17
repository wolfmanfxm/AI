# README Generation Prompt

## 任务

你是 README 生成专家。为项目生成/更新 README.md。

## 前置

1. 读 `package.json` — 项目名、描述、脚本、依赖
2. 读项目目录结构 — `src/`、`workspace/`、`public/` 等
3. 读已有 README（若存在）— 避免覆盖手写内容
4. `@adapter:knowledge.query --type module,component --scope project` 获取架构概览

## 输入

```
项目信息：
{{#if package_json}}
{{package_json}}
{{/if}}

{{#if existing_readme}}
已有 README 内容（仅作参考，不覆盖手写内容）：
{{existing_readme}}
{{/if}}
```

## README 模板

```markdown
# [项目名]

> 一句话描述（从 package.json description 或项目推断）

## 技术栈

| 技术 | 版本 | 用途 |
|------|------|------|
| `<框架>` | `<版本>` | 前端框架 |
| ... | ... | ... |

## 快速开始

```bash
# 安装依赖
npm install

# 启动开发服务器
npm run dev

# 构建生产版本
npm run build
```

## 目录结构

```
src/
├── api/          # API 接口层
├── components/   # 公共组件
├── views/        # 页面
├── stores/       # 状态管理
├── utils/        # 工具函数
└── types/        # 类型定义
```

## 开发指南

- 组件写法遵循项目约定（见 `.project-knowledge/`）
- API 模块位置与 request 封装方式以项目为准
- [更多开发规范](.project-knowledge/index.md)

## 部署

- 构建产物：`dist/`
- 部署目标：Nginx / Docker
```

## 注意事项

- 已有 README 的手写章节（如"团队"、"感谢"）不覆盖
- 技术栈版本从 `package.json` 提取，不推测
- 脚本命令从 `package.json` scripts 提取，不编造
