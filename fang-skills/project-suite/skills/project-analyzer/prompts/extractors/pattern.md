# Pattern Extractor

> 只提取设计模式和代码模式。不分析架构，不分析规范。

## Actions

1. 扫描代码，识别以下模式的出现：
   - Repository Pattern (src/repositories/)
   - Factory Pattern
   - Strategy Pattern
   - Composition Pattern (composables)
   - Provider Pattern
   - Observer/Watcher Pattern
2. 对每个模式：统计出现次数、找典型示例、记录文件路径
3. 输出为候选知识（Candidate），待 Verifier 确认

## Output

```markdown
# Patterns

## Repository Pattern
- Confidence: 0.91
- Occurrences: 18
- Example: src/repositories/UserRepository.ts:42
- Evidence:
  - src/repositories/UserRepository.ts
  - src/repositories/OrderRepository.ts
  - ... (18 files)

## Composition Pattern (Composables)
- Confidence: 0.95
- Occurrences: 34
- Example: workspace/composables/useTable.ts:15
- Evidence:
  - workspace/composables/useTable.ts
  - workspace/composables/useForm.ts
  - ... (34 files)
```

## Evidence Score

| Claim | Score | Basis |
|-------|-------|-------|
| Repository Pattern | 0.91 | 18 files in src/repositories/ + consistent naming |
| Composition Pattern | 0.95 | 34 composables + consistent `useXxx` naming |
