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
| workspace/utils/format.ts | 3200 | Utils 膨胀：混入格式/校验/转换 |
| src/views/accountManage/orderReview/detail.vue | 1200 | 页面过大 |

## any 滥用
| File | any Count | % |
|------|----------|-----|
| workspace/api/legacy.ts | 23 | 15% |
| workspace/views/oldModule/index.vue | 18 | 10% |

## 硬编码
| Location | Value | Should Be |
|----------|-------|-----------|
| workspace/api/config.ts:5 | `http://10.0.0.1:8080` | env variable |
| workspace/views/form.vue:42 | `10000` | config constant |

## Dead Code
| Location | Lines | Description |
|----------|-------|-------------|
| workspace/views/oldModule/deprecated.vue | 200 | 整文件注释掉 |
```

## Evidence

每个反模式标注：实际路径 + 行号 + 度量值 + 建议修复方向。
