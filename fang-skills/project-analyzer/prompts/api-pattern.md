# API Pattern Analysis

## Goal
分析项目的 API 层组织方式和请求规范。

## Context
API 层位置和 HTTP 客户端实现因项目而异，先通过架构分析确定目录位置。

## Evidence
- API 目录（如 `src/api/`, `services/`）
- HTTP 客户端封装文件（如 `request.ts`, `http.ts`）
- API 调用点（页面/组件中的 import 和使用）

## Analysis
1. 检查模块组织方式（模块文件夹 / 扁平 / 按资源类型）
2. 抽样5-10个文件，分类命名风格，统计占比，提取典型签名模板
3. 读取 HTTP 客户端封装，记录拦截器逻辑（token、加密、签名、解包、错误处理）
4. 搜索 API 调用点，提取数据解包路径和错误处理模式
5. 从实际函数提取分页参数字段名、响应列表路径
6. 搜索 FormData/upload，记录上传模式

## Output
`api/` 下按需创建：`overview.md`、`request.md`、`auth.md`、`modules.md`
区分"约定俗成"（多数遵循）vs"少数写法"
