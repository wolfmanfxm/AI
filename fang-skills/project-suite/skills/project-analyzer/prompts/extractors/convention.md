# Convention Extractor

> 只提取编码规范。命名、目录、import、commit 等约定的实际执行情况。

## Actions

1. 扫描命名规范（组件 PascalCase / 文件 kebab-case / 变量 camelCase）
2. 扫描目录规范（views/<module>/<page>/index.vue 模式）
3. 扫描 import 规范（顺序：Vue → 第三方 → 项目 → 相对路径）
4. 扫描 commit 规范（conventional commits 使用率）

## Output

```markdown
# Conventions

## Naming
| 类型 | 规范 | 证据 |
|------|------|------|
| 组件 | PascalCase | 95% of .vue files |
| 文件 | kebab-case | 90% of files |
| 函数 | camelCase | 98% |
| 常量 | UPPER_SNAKE | 85% |

## Import Order
1. Vue (vue, vue-router, pinia)
2. Element Plus (element-plus)
3. 项目别名 (@/, @workspace/)
4. 相对路径 (./)

## Directory
views/<module>/<page>/
├── index.vue
├── detail.vue (可选)
└── components/ (可选)
```

## Evidence

每个规范标注：遵守率 + 反例数量 + 典型示例路径。
