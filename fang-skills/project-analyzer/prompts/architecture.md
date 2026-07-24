# Architecture Analysis

## Goal
理解项目的整体架构：技术栈、目录结构、模块划分、状态管理、路由设计。

## Context
本项目为通用前端项目分析，无特定框架预设。从 package.json 和目录结构推理。

## Evidence
- `package.json` — 技术栈和依赖
- 顶层目录结构 — 层级关系
- 视图/页面目录 — 模块划分
- Store 目录 — 状态管理方案
- 路由配置 — 页面路由和权限

## Analysis
1. 从 package.json 提取框架、构建工具、UI库、状态管理、HTTP客户端
2. 识别源码目录层级，标注每层用途，若有多层架构注明关系
3. 扫描视图目录的一级子目录，统计代码规模，标注前5大模块
4. 列出所有 store，标注名称、路径、职责
5. 提取路由树、守卫、懒加载模式
6. 搜索循环依赖、标注超大模块、标注未使用的 store

## Output
`architecture/overview.md`（必选）
按需：`modules.md`、`tech-stack.md`、`dependencies.md`、`directory-tree.md`
