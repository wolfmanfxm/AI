# Principle Extractor

> 从代码模式中提取 Always / Never / Prefer / Avoid 原则。

## Actions

1. 扫描 Convention Extractor 的输出 → 提取 Always/Prefer 规则
2. 扫描 AntiPattern Extractor 的输出 → 提取 Never/Avoid 规则
3. 扫描 tsconfig / eslint 配置 → 提取强制的规则
4. 对每条原则标注：来源（配置/代码/约定）+ 执行率

## Output

```markdown
# Principles

## Always
| Principle | Source | Compliance |
|-----------|--------|------------|
| 使用 Composition API (script setup) | 95% of .vue files | 95% |
| 使用 defineProps<T>() 泛型 | 75% of components | 75% |
| API 使用 export function 风格 | workspace/api/ 全部 | 100% |

## Never
| Principle | Source | Violations |
|-----------|--------|------------|
| 不直接修改 props | Vue eslint rule | 3 files |
| 不提交注释掉的代码块 | .eslintrc | 12 blocks |
| 不在 composable 外使用 useState | convention | 0 |

## Prefer
| Principle | Reason | Adoption |
|-----------|--------|----------|
| readonly 优先 | tsconfig strict | 60% |
| reactive() 用于表单, ref() 用于单值 | 项目约定 | 85% |
| PageTable + SchemaTable 而非手写 el-table | workspace 模式 | 90% |

## Avoid
| Principle | Reason | Current State |
|-----------|--------|---------------|
| any 类型 | 类型安全 | 3% of TS files |
| 直接操作 DOM | Vue 响应式 | 2 files |
| 硬编码 API URL | 环境切换 | 5 files |
```

## Evidence

每条原则标注：来源文件 + 遵守率/违反数 + 典型示例。
