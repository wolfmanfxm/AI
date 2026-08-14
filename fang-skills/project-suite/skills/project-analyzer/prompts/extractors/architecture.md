# Architecture Extractor

> 只提取架构模式：分层、模块边界、依赖方向。

## Actions

1. 识别分层结构（view → composable → api → store 的数据流）
2. 识别模块边界（每个 workspace/views/<module> 的职责）
3. 识别依赖方向（单向/循环/跨层）
4. 识别路由结构

## Output

```markdown
# Architecture

## Layers
view → composable → api → store → types

## Modules
| Module | 职责 | 文件数 | 依赖 |
|--------|------|--------|------|
| accountManage | 账户管理 | 80 | api, stores, components |
| orderManage | 订单管理 | 60 | api, stores |

## Cross-cutting
- src/components/ ← 全局组件，被所有模块依赖
- src/api/ ← 框架层 API，被所有模块依赖
```

## Evidence

每个模块标注实际路径，每个依赖标注 import 来源。
