# Knowledge Builder

> 从 Accepted Candidates 组装最终 `.project-knowledge/` 产出。

## Actions

1. 收集 Verifier 输出的所有 Accepted Candidates
2. 按知识类型分组（architecture / patterns / conventions / glossary / decisions / risks / antipatterns）
3. 合并同类型 Candidates 为最终 .md 文件
4. 注入 Evidence Score Section（每个 Claim 的溯源）
5. 生成跨文件交叉引用

## Output Structure

```
.project-knowledge/
├── architecture/
│   ├── overview.md          ← Directory + Architecture Extractor
│   ├── modules.md           ← Architecture Extractor
│   └── tech-stack.md        ← Framework Extractor
├── patterns/
│   ├── repository.md        ← Pattern Extractor
│   ├── composition.md       ← Pattern Extractor
│   └── ...
├── conventions/
│   ├── naming.md            ← Convention Extractor
│   ├── imports.md           ← Convention Extractor
│   └── directory.md         ← Convention Extractor
├── glossary.md              ← Glossary Extractor
├── decisions.md             ← Decision Extractor
├── risks.md                 ← Risk Extractor
├── antipatterns.md          ← AntiPattern Extractor
├── principles.md            ← Principle (from Convention+Pattern)
├── INDEX.md                 ← Index Generator
├── statistics.json
├── context.json
└── graph.json
```

## Evidence Score Section

每个 .md 文件末尾附 Evidence Score 表：

```markdown
## Evidence Score

| Claim | Confidence | Occurrences | Verified | Evidence |
|-------|-----------|-------------|----------|----------|
| Repository Pattern | 0.91 | 18 | ✅ | src/repositories/ (18 files) |
| PascalCase convention | 0.95 | 380 | ✅ | 95% of components |
| ... | | | | |

Overall Confidence: 0.89
```
