# Benchmarks v1.0

> 每个 Skill 的"好产出"标准。不测语义质量，测结构契约。
> yao-meta-skill Governed 模式要求。

## 基准维度

| 维度 | 测什么 | 不测什么 |
|------|--------|---------|
| **Structural** | 产出文件数量、类型、最小 size | 内容质量 |
| **Section** | 必需章节存在且非空 | 章节内容正确性 |
| **Confidence** | 置信度在预期范围内 | 置信度是否"准确" |
| **Contract** | `produces` 声称的产出全部存在 | 产出的下游可用性 |
| **Fixture** | file-backed fixture 输入下产出稳定 | 不同输入下的行为 |

## 基准场景定义

### analyzer benchmark

```yaml
input:
  fixture: [package.json, tsconfig.json, src/]  # 任何前端项目
expected:
  files:
    - architecture/overview.md       # min: 500 bytes
    - architecture/modules.md        # min: 300 bytes
    - architecture/tech-stack.md     # min: 200 bytes
    - components/catalog.md          # min: 300 bytes
    - api/overview.md               # min: 200 bytes
    - patterns/crud.md              # min: 200 bytes
    - statistics.json               # valid JSON
    - context.json                  # valid JSON, required fields present
    - graph.json                    # valid JSON, nodes > 0
  confidence: 70-95
  stages_completed: [discovery, execution, delivery, validation]
```

### generator benchmark

```yaml
input:
  fixture: [context-package.json, PLAN.md]
expected:
  files:                           # 至少 1 个 .vue/.ts 文件
    - "*.vue"                      # min: 100 bytes, valid Vue SFC
    - "*.ts"                       # min: 50 bytes, no `any` without comment
  confidence: 65-95
  stages_completed: [discovery, execution, validation]
  no_duplicate_components: true    # 未重复生成已有组件
```

### planner benchmark

```yaml
input:
  fixture: [context.json, knowledge-index.json]
expected:
  files:
    - proposals/PLAN-*.md          # 9 个 section 全部非空
    - context-package.json         # valid JSON, capabilities 非空
  sections: [Goal, Scope, Context, Reuse Analysis, Decision, Task Breakdown, Dependency Graph, Risk Assessment, Acceptance Criteria]
  confidence: 70-95
```

### architect benchmark

```yaml
input:
  fixture: [context.json, PLAN.md]
expected:
  files:
    - decisions/ARCHITECTURE-*.md  # ADR 四段完整
  sections: [问题, 候选方案, 选择, 理由]  # 至少 1 个决策记录
  matrix_dimensions: 3             # 对比矩阵至少 3 个维度
  confidence: 70-90
```

### reviewer benchmark

```yaml
input:
  fixture: [变更代码 diff, PLAN.md]
expected:
  files:
    - reports/REVIEW-*.md          # 五轴各有记录
  sections: [正确性, 安全性, 可读性, 架构, 性能]
  findings_per_axis: 1             # 每轴至少 1 条
  file_line_citations: true        # 每条发现含 file:line
  confidence: 70-90
```

### tester benchmark

```yaml
input:
  fixture: [被测代码, PLAN.md AC]
expected:
  files:
    - "*.test.ts" or "*.spec.ts"   # 可解析的测试文件
    - reports/TEST-REPORT.md
  ac_coverage: 1.0                 # 每条 AC 至少 1 个测试
  boundary_cases: 3                # null/undefined/empty 至少 3 种
  executable: true                 # 无语法错误
  confidence: 65-90
```

### documenter benchmark

```yaml
input:
  fixture: [源码文件]
expected:
  files:
    - "api/*.md" or "components/*.md" or "README.md"
  file_line_citations: true        # 每个关键信息含溯源
  style_consistent: true           # 与已有文档风格一致
  vault_synced: true               # API/组件文档已同步
  confidence: 70-90
```

### refactorer benchmark

```yaml
input:
  fixture: [待重构代码, 现有测试]
expected:
  behavior_unchanged: true         # 重构前后测试全绿
  metric_improved: true            # 至少一项指标改善 >10%
  files_changed: 1-5               # 单次重构范围
  atomic_commits: true             # 每个重构动作独立 commit
  confidence: 70-90
```

### releaser benchmark

```yaml
input:
  fixture: [git log, state.json]
expected:
  files:
    - CHANGELOG.md                 # Added/Changed/Fixed/Deprecated/Removed 分类
    - RELEASE-CHECKLIST.md         # 含回滚方案
  semver_compliant: true           # 版本号符合 conventional commits
  breaking_change_migration: true  # 每个 BREAKING 有迁移步骤
  full_chain_confidence: "≥70"     # 全链路检查
  confidence: 80-95
```

## 基准执行器

`shared/scripts/run-benchmark.sh` — 对指定 Skill 运行基准检查，输出 PASS/FAIL/结构差异。
