# API Pattern Analysis Prompt

使用模板：[templates/APIGuide.md](../templates/documents/APIGuide.md)

## 前置

确定 API 层位置（`src/api/`、`services/` 等）和 HTTP 客户端封装位置（`utils/`、`lib/` 中的 request/http 文件）。

## 执行清单

### 1. 目录结构
```bash
find <api_dir> -type f -name '*.ts' | head -40
```
标注组织方式（模块文件夹 / 扁平 / 按资源类型）。

### 2. 函数签名
抽样 5-10 个文件：
```bash
grep -rn "export const\|export function" <api_dir> --include='*.ts' | head -20
```
分类命名风格，统计占比。提取典型函数签名模板。

### 3. 请求配置
读取 HTTP 客户端封装文件（如 `request.ts`、`http.ts`），记录：
- 基础 URL、timeout、默认 headers
- 请求拦截器逻辑（token、加密、签名）
- 响应拦截器逻辑（解包、错误处理、token 刷新）
- 特殊配置项（加密标记、格式转换等）

### 4. 响应处理
搜索 API 调用点：
```bash
grep -rn "await.*api\|\.then.*api" <src_dir> --include='*.vue' --include='*.tsx' | head -20
```
提取：数据解包路径、错误处理方式、loading 管理模式。

### 5. 分页约定
从实际 API 函数提取分页参数字段名、响应中列表数据路径。

### 6. 文件上传
搜索 `FormData\|upload`，记录上传模式。

## 输出
- 每个模式：来源 `file:line` + 实际代码示例
- 区分"约定俗成"（多数遵循）vs"少数写法"
