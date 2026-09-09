# AntiPattern Extractor

> 只提取反模式和坏味道。项目有哪些"不该这样做但还是做了"的地方。

## Actions

1. 扫描 God Object（单文件 >800行 或 单函数 >100行）
2. 扫描 utils/ 膨胀（>500行 的 utils 文件）
3. 扫描 `any` 滥用（>5% 的 TS 文件含 `any`）
4. 扫描 props 直接修改（违反单向数据流）
5. 扫描硬编码（魔数、硬编码 URL、硬编码配置）
6. 扫描注释掉的代码块（>5行 的注释代码）
7. 扫描 `as` 类型断言滥用

## Output

```markdown
# Anti-Patterns

## God Object
| File | Lines | Issue |
|------|-------|-------|
| <示例 utils 文件> | 3200 | Utils 膨胀：混入格式/校验/转换 |
| <示例页面> | 1200 | 页面过大 |

## any 滥用
| File | any Count | % |
|------|----------|-----|
| <示例 API 文件> | 23 | 15% |
| <示例组件> | 18 | 10% |

## 硬编码
| Location | Value | Should Be |
|----------|-------|-----------|
| <示例配置文件>:5 | `<示例内网地址>` | env variable |
| <示例表单>:42 | `<示例魔数>` | config constant |

## Dead Code
| Location | Lines | Description |
|----------|-------|-------------|
| <示例废弃文件> | 200 | 整文件注释掉 |
```

## Evidence

每个反模式标注：实际路径 + 行号 + 度量值 + 建议修复方向。
