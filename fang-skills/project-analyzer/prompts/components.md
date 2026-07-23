# Component Analysis Prompt

使用模板：[templates/ComponentPattern.md](../templates/ComponentPattern.md)

## 执行清单

### 1. 定位组件目录
从项目实际结构中确定：
- 全局组件目录（如 `src/components/`）
- 页面/视图目录（如 `src/views/`）
- 模块内组件目录（页面下 `components/` 子目录）

### 2. 全局组件扫描
对全局组件目录下每个 `.vue/.tsx` 文件：

```bash
# 列出所有组件文件
find <components_dir> -name '*.vue' -o -name '*.tsx' | sort
```

对每个组件：
- **名称、路径**：从文件名和目录
- **Props**：`grep -A 20 "defineProps" <file>` 提取类型定义
- **Emits**：`grep "defineEmits" <file>`
- **引用次数**：`grep -rl "<ComponentName" <project_dir> --include='*.vue' --include='*.tsx' | wc -l`
- **耦合度**：检查是否 import 业务 API 或全局 store

**标准模式**：仅列出引用≥3 的组件详情。引用<3 的合并为一行表格。

### 3. 页面级组件识别
```bash
find <views_dir> -path '*/components/*.vue' | head -50
```

标记候选提升：被 2+ 模块引用、接口清晰、无业务硬编码。

### 4. 第三方封装
识别对 UI 库组件的封装，标注封装目的。

## 输出
填充 ComponentPattern.md 模板，表格 + 每个高复用组件展开详情（含实际使用代码 5-10 行）。
