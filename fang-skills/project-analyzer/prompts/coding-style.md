# Coding Style Analysis Prompt

使用模板：[templates/CodingStyle.md](../templates/CodingStyle.md)

## 执行清单

### 1. 组件写法统计
```bash
# script setup vs Options API（Vue 项目）
echo "script setup: $(grep -r '<script setup' <src_dir> --include='*.vue' | wc -l)"
echo "Options API: $(grep -r '<script>' <src_dir> --include='*.vue' | grep -v setup | wc -l)"
```
如果是 React 项目：统计函数组件 vs Class 组件。

### 2. 类型系统
- `grep -r "interface\|type " <src_dir> --include='*.ts' | wc -l` — 类型定义总量
- 抽样 5 个文件观察 interface vs type 偏好
- `grep -rn ": any" <src_dir> --include='*.ts' --include='*.vue' | wc -l` — any 使用量

### 3. API 命名风格
```bash
# 统计命名模式
grep -rn "export const\|export function" <api_dir> --include='*.ts' | head -30
```
分类：Swagger 生成（`verbNounUsingMethod`）vs 手写（`verbNoun`），计算占比。

### 4. Import 组织
抽样 10 个文件，观察 import 排序。从 `tsconfig.json` 或构建配置读取路径别名。

### 5. 错误处理
```bash
echo "try/catch: $(grep -r 'try {' <src_dir> --include='*.ts' --include='*.vue' | wc -l)"
echo "async/await: $(grep -r 'await ' <src_dir> --include='*.ts' --include='*.vue' | wc -l)"
echo ".then(): $(grep -r '\.then(' <src_dir> --include='*.ts' --include='*.vue' | wc -l)"
```
定位 HTTP 拦截器，分析全局错误处理逻辑。

### 6. Hooks/Composables
列出目录，按职责分类（权限、数据请求、UI 状态、工具函数）。

## 输出
每个维度：1 个统计 + 1 个代码示例。标注"代码事实："vs"模式推断："。
