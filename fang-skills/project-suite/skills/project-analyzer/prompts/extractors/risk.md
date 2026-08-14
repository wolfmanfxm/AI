# Risk Extractor

> 只提取风险和技术债。不美化项目。

## Actions

1. 扫描大文件（>500行）→ 标注 God Component/God Class
2. 扫描循环依赖（A imports B, B imports A）
3. 扫描过时依赖（package.json 中 deprecated 的包）
4. 扫描未使用的依赖
5. 扫描重复代码（跨文件 >80% 相似）
6. 扫描缺失的测试覆盖

## Output

```markdown
# Risks & Technical Debt

## Critical
| Risk | Location | Impact | Evidence |
|------|---------|--------|----------|
| God Component | src/views/accountManage/orderReview/detail.vue (1200行) | 维护性 | 单文件 >1000行 |

## High
| Risk | Location | Impact | Evidence |
|------|---------|--------|----------|
| Circular Dep | A → B → A | 架构 | import chain |
| Deprecated Pkg | package.json: moment.js | 安全 | 官方已废弃 |

## Medium
| Risk | Location | Impact |
|------|---------|--------|
| Duplicate API | userApi.ts ≈ accountApi.ts (85%) | 冗余 |
| Missing Tests | workspace/views/clueManage/ 0 tests | 质量 |

## Technical Debt Score
- Files >500行: 12
- 循环依赖: 2
- 废弃依赖: 1
- 重复代码区块: 5
```

## Evidence

每个风险标注实际路径 + 具体行号或度量值。
