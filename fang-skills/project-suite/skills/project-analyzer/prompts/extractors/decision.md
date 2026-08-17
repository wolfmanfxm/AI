# Decision Extractor

> 只提取架构决策。从代码/配置/注释中推断"为什么"。

## Actions

1. 扫描配置文件 → 从选择推断决策
   - package.json 选择 → 为什么用 pnpm 而不是 npm
   - tsconfig strict:true → 为什么开启严格模式
   - vite.config → 为什么用 Vite 而不是 Webpack
2. 扫描 ADR 文档（若存在 `.project-knowledge/decisions/`）
3. 扫描代码注释中的 "WHY" / "HACK" / "FIXME" / "NOTE"
4. 扫描 monorepo 结构 → 为什么拆包

## Output

```markdown
# Architecture Decisions

## D1: 为什么选择 pnpm
- Evidence: package.json 含 pnpm-lock.yaml, workspace 配置
- Inferred: monorepo workspace 支持 + 磁盘效率
- Confidence: 0.90

## D2: 为什么拆 workspace/ 和 src/
- Evidence: tsconfig paths: { "@": "src", "<业务层别名>": "workspace" }
- Inferred: 框架层(src/)稳定 + 业务层(workspace/)高频变更
- Confidence: 0.85

## D3: 为什么 strict:true
- Evidence: tsconfig.json compilerOptions.strict = true
- Inferred: 类型安全优先，企业项目标准
- Confidence: 0.95
```

## Evidence

每个决策标注：证据来源 + 推断依据 + 置信度。没有证据的标注 `[推断]`。
