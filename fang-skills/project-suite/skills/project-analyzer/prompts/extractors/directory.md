# Directory Extractor

> 只提取目录结构。不分析代码内容，不找模式。

## Actions

1. 扫描 `src/` `packages/` `apps/` `libs/` 等一级目录
2. 识别每个目录的职责（views/utils/api/components/stores/types）
3. 输出目录树 + 职责标注

## Output

```markdown
# Directory Structure

## Top-level
| Dir | 职责 | 文件数 |
|-----|------|--------|
| src/ | 框架层 | 120 |
| workspace/ | 业务层 | 800 |

## src/
| Dir | 职责 |
|-----|------|
| components/ | 全局组件 |
| api/ | 框架层 API |
| stores/ | 状态管理 |

## workspace/views/
| Dir | 职责 |
|-----|------|
| accountManage/ | 账户管理 |
| orderManage/ | 订单管理 |
```

## Evidence

每个目录标注：实际路径 + 文件计数。不编造目录。
