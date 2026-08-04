# Evidence Format v1.0

> 每个 Extractor 产出的 Candidate 使用此格式。YAML + 结构化证据，机器可读。

## Candidate YAML 格式

```yaml
# candidates/<extractor-id>.yaml
candidate:
  id: repository-pattern
  category: behavioral.pattern
  extracted_by: pattern-extractor
  extracted_at: "2026-08-04T16:30:00Z"

claim:
  statement: "项目使用 Repository Pattern 封装数据访问"
  confidence: 0.93

evidence:
  - path: src/repositories/UserRepository.ts
    type: file
    lines: 45
    pattern: "class.*Repository"
  - path: src/repositories/OrderRepository.ts
    type: file
    lines: 62
    pattern: "class.*Repository"

verification:
  occurrences: 17
  occurrence_paths:
    - src/repositories/UserRepository.ts
    - src/repositories/OrderRepository.ts
    # ... 15 more
  first_seen: "src/repositories/UserRepository.ts:1"
  consistency: 1.0  # 17/17 files match pattern
  counter_examples: []
  predictive_power: "Can answer: 'Where to add data access for new entity?' → 'Add file in src/repositories/'"
  obviousness: "non-obvious"  # non-obvious | somewhat-obvious | obvious

verdict: accepted  # accepted | adjusted | rejected
adjusted_confidence: 0.93  # post-verification
```

## 证据类型

| type | 含义 | 示例 |
|------|------|------|
| file | 文件路径 | src/repositories/UserRepository.ts |
| pattern | 代码模式 | class.*Repository |
| config | 配置项 | tsconfig.json:strict=true |
| count | 计数 | 17 files |
| ratio | 比例 | 95% of components |

## 存储路径

```
.project-knowledge/candidates/
├── accepted/                    ← Verifier 通过的 Candidate
│   ├── directory.yaml
│   ├── framework.yaml
│   ├── architecture.yaml
│   ├── patterns.yaml
│   ├── conventions.yaml
│   ├── glossary.yaml
│   ├── decisions.yaml
│   ├── principles.yaml
│   ├── risks.yaml
│   └── antipatterns.yaml
├── rejected/                    ← Verifier 拒绝的 Candidate
│   └── <id>.yaml                ← 保留原文件 + rejection-reason
└── adjusted/                    ← Verifier 调整 confidence 的 Candidate
    └── <id>.yaml                ← 保留原 confidence + 调整原因
```
