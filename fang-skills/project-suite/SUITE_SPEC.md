# Suite Spec v1.1.0

> Project Suite 的正式 Framework 规范。v1.1 新增：Stage Template Injection、interface 统一、Governed 就绪。
> v1.0 → v1.1 关键变化：
> - G1 行数限制宽松至 130（为 workflow-engine 留空间）
> - 新增 G13-G16：stage prompts、@engine 声明、skill-policy.yaml rollback、Skill Atlas
> - 新增第 8 节：Governed Package Boundary
> - 反例计数规则更新：SKILL.md 内嵌表计入 G3

---

## 0. 权威层级（单一 Source of Truth）

避免多头权威。每个事实只有一个手工维护的源：

| 层级 | 文件 | 定位 | 维护方式 |
|------|------|------|---------|
| **单一权威** | `skills/*/skill.yaml` | Skill Contract（intrinsic：description/capabilities/produces/consumes/boundary/interface…） | 手工，唯一源 |
| **编排权威** | `runtime/config/scheduler.yaml` | skill_order.decision_order / priority（路由 + 调度顺序） | 手工 |
| **编排权威** | `runtime/registry/workflow-library.yaml` | workflow 编排（pipeline 定义） | 手工 |
| **编排权威** | `runtime/config/profiles.yaml` | profile（任务复杂度 → skill 激活范围 + auto_advance） | 手工 |
| **门禁权威** | `runtime/config/rules.yaml` | gate（conf pass/review/block 阈值）+ 执行前置条件 | 手工 |
| **门禁权威** | `runtime/config/gates.yaml` | 维度门禁（knowledge auto_accept / coverage / safety / release） | 手工 |
| **执行策略** | `runtime/config/skill-policy.yaml` | rollback / recovery / reliability / stage_config | 手工 |
| **派生（勿手改）** | `runtime/registry/*.yaml`（4 份：skills.generated / skill-catalog / capabilities / capability-routing） | 从 skill.yaml 生成 | `generate-registry.mjs` |

**规则**：
- `description/capabilities/produces/consumes/boundary/interface…` 以 `skill.yaml` 为准。
- `gate`（conf 阈值）以 `runtime/config/rules.yaml` 为准；`rollback/recovery/reliability/stage_config` 以 `runtime/config/skill-policy.yaml` 为准。
- `priority/decision_order` 以 `scheduler.yaml` 为准。
- 并行关系由 produces/consumes 推导的 **Capability DAG** 决定（能力依赖，非强制执行顺序），不再是 skill 固定字段。
- 派生文件与 skill.yaml 不一致 → `generate-registry.mjs --check` 报漂移（exit 1）。

---

## 1. 目录结构契约

每个 skill 必须包含以下目录和文件：

```
skills/<skill-name>/
├── SKILL.md              🔴 REQUIRED    skill 主文件（路由 + 工作流 + 引用索引）
├── skill.yaml            🔴 REQUIRED    统一元数据（id/version/produces/consumes/depends/boundary）
├── prompts/              🔴 REQUIRED    维度/步骤 Prompt（至少 1 个）
│   └── main.md           🟡 IMPORTANT  默认 Prompt（若只有一个则为它）
├── references/           🔴 REQUIRED    详细指引（至少 2 个）
│   ├── boundary.md       🔴 REQUIRED    职责边界 + 反例黑名单（≥3 条）
│   ├── trigger-words.md  🟡 IMPORTANT  触发词列表
│   └── ...               🟢 OPTIONAL    code-audit / self-check 等
└── (无其他目录)           🔴 REQUIRED   禁止 scripts/ assets/ 等非标准目录
```

### 目录检查

```
🔴 缺失 → BLOCK，skill 不可发布
🟡 缺失 → WARN，skill 降级为 Scaffold
🟢 缺失 → INFO，不影响发布
```

---

## 2. SKILL.md 契约

### 2.1 Frontmatter（🔴 REQUIRED）

```yaml
---
name: <kebab-case>          # 必须与目录名一致
metadata: skill.yaml        # 引用统一元数据
description: >              # 做什么 + 何时用 + 触发词 + 产出，≤1024 字符
  触发词: ... 产出: ...
---
```

### 2.2 内容结构（🔴 REQUIRED，顺序可调但必须包含）

| 章节 | 要求 |
|------|------|
| `# 标题` | 一行摘要，格式 `> 输入 → 过程 → 输出` |
| `## 核心原则` | 3-4 条，每条一句 |
| `## 职责边界` | 引用 `[references/boundary.md]` + 一行 🔴 警示 |
| `## 前置条件` | 优先级表：0=context.json, 1..N=其他 |
| `## 工作流` | Discover → Execute → Output 三段式 |
| `> 完成后：` | 下游 skill 路由建议 |
| `## 引用索引` | 表格：资源名 + 路径 |

### 2.3 CHECKPOINT（🔴 REQUIRED）

- 至少 **1 个** `🔴 CHECKPOINT` 标记
- 每个 CHECKPOINT 使用 `AskUserQuestion`（引用 `shared/conventions/checkpoint-pattern.md`）
- CHECKPOINT 位置：Discover 完成后（确认范围）、Execute 关键决策前（确认方案）

---

## 3. skill.yaml 契约

### 3.1 字段（🔴 REQUIRED）

```yaml
id: <kebab-case>            # 与目录名一致
version: "<semver>"         # 遵循 semver
mode: Production            # Scaffold | Production | Library | Governed
owner: project-suite        # 固定
priority: <1-9>             # DAG 调度优先级
produces: [<Capability>+]   # 产出的能力类型
consumes: [<Capability>*]   # 消费的能力类型
depends_on: [<skill-id>*]   # 硬依赖
parallel_with: [<skill-id>*]# 同 Wave 并行伙伴
requires: [<resource>*]     # 运行前提（agent 类型/外部依赖）
context_contract:           # 🔴 Context 裁剪（减少 context 膨胀）
  must_read: [<path>*]      #  必须加载，缺失则 DEGRADED
  should_read: [<path>*]    #  有则加载，无则跳过
  neednt_read: [<path>*]    #  明确不需要加载
boundary: <string>          # 一行职责边界
```

### 3.2 版本兼容声明（🟡 IMPORTANT）

```yaml
compatibility:
  context_schema: ">=1.0.0"   # 所需 context.json schema 最低版本
  state_schema: ">=1.0.0"     # 所需 state.json schema 最低版本
  suite: ">=0.7.0"            # 所需 suite 最低版本
```

Skill 独立迭代版本号时，必须声明对上游 schema 的最低版本要求。
上游 schema 变更（如 context.json 新增 REQUIRED 字段）→ 下游 skill 的 `context_schema` 版本跟进。

### 3.3 Capability 类型枚举（🔴 REQUIRED，不可自定义）

> 单一源：`runtime/registry/capabilities.yaml` 的 `capability_types`（generate-registry.mjs 生成）。此处为同步快照，以 capabilities.yaml 为准。

```
KnowledgeBase | KnowledgeIndex | Context | State | Graph | Plan | Architecture | Code | Test | Review |
RefactoredCode | Documentation | Release | PipelineExecution
```

---

## 4. boundary.md 契约

### 4.1 职责表（🔴 REQUIRED）

```markdown
| ✅ 本阶段职责 | ❌ 禁止操作 |
|-------------|-----------|
| ≥3 行        | ≥3 行      |
```

### 4.2 反例黑名单（🔴 REQUIRED）

```markdown
## 反例黑名单

| # | ❌ 反模式 | 为什么不要做 | ✅ 正确做法 |
|---|---------|-------------|-----------|
| 1 | ...     | ...         | ...        |
| 2 | ...     | ...         | ...        |
| 3 | ...     | ...         | ...        |
```

≥3 条反例，每条对应真实踩坑记录。禁止泛泛而谈的"不要写得不好"。

---

## 5. Suite 级别契约

### 5.1 全局 Shared 资源

| 资源 | 路径 | 用途 |
|------|------|------|
| CHECKPOINT 模式 | `shared/conventions/checkpoint-pattern.md` | 统一 AskUserQuestion 调用格式 |
| Vault 同步协议 | `shared/conventions/vault-sync.md` | analyzer + documenter 引用 |
| Evidence Header | `shared/templates/evidence-header.md` | .md 产出文件的 Frontmatter 模板 |

### 5.2 Runtime 协议

| 协议 | 路径 | 所有 skill 必须遵循 |
|------|------|-------------------|
| Project State | `runtime/state/state.md` | ✅（读写 .project-runtime/state.json） |
| Knowledge Lifecycle | `runtime/state/schemas/knowledge-lifecycle.md` | ✅（Generator 只读 accepted；Reviewer 验证 Candidate） |
| Knowledge Index | `runtime/state/schemas/knowledge-index.md` | ✅（analyzer 生成，下游按 capability 查询） |
| Confidence Gate | `runtime/engine/confidence-gate.md` | ✅（confidence → Gate 行为：PASS/REVIEW/GATE/BLOCK） |
| Timeline | `runtime/metrics/timeline.md` | ✅（所有 Skill 追加执行指标到 timeline.json） |
| Knowledge Health | `runtime/metrics/knowledge-health.md` | ✅（analyzer 增量模式自动检测知识库质量） |
| Unified I/O | `runtime/contracts/skill-io.md` | 🟡（建议遵循，非强制） |
| 状态机 | `runtime/engine/state-machine.md` | ✅ |
| 断点续传 | `runtime/engine/checkpoint.md` | ✅（manifest.json 读写） |
| DAG 调度 | `runtime/engine/scheduler.md` | ✅（按 capabilities.yaml 优先级） |
| Context Protocol | `runtime/context/context.md` | ✅（下游 skill 读 context.json） |
| 能力注册 | `runtime/registry/capabilities.yaml` | ✅（定义 produces/consumes） |
| Workflow 模板 | `runtime/registry/workflow-library.yaml` | 🟢（Pipeline 模式，用户是 Dispatcher） |

---

## 6. 质量门禁

### 6.1 门禁检查清单

| # | 检查项 | 级别 | 验证方式 |
|---|--------|------|---------|
| G1 | SKILL.md 存在且 ≤130 行 | 🔴 | `wc -l` |
| G2 | skill.yaml 存在且字段完整（含 `interface:` 块） | 🔴 | YAML 解析 + 字段校验 |
| G3 | boundary.md **或** SKILL.md 内嵌反例 ≥3 条 | 🔴 | 搜索 `❌` 计数（两处之和） |
| G4 | 至少 1 个 `CHECKPOINT`（SKILL.md 或 prompts/） | 🔴 | 搜索 `CHECKPOINT` |
| G5 | 职责边界表 ≥3 行 ✅/❌ | 🔴 | 搜索 `✅ 本阶段职责` |
| G6 | frontmatter 含 `description` + 触发词 + 产出 | 🔴 | YAML 解析 |
| G7 | capabilities.yaml 中已注册 | 🟡 | grep skill id |
| G8 | `完成后` next-step hint 存在 | 🟡 | 搜索 |
| G9 | boundary.md 含失败兜底 | 🟡 | 搜索 |
| G10 | 无 runtime-specific 措辞 | 🟡 | grep `在 Claude Code` |
| G11 | prompts/ 至少 1 个文件 | 🟢 | `ls` |
| G12 | references/ 至少 2 个文件 | 🟢 | `ls` |
| **G13** | **每个 `stages:` 声明有对应 `prompts/<stage>.md`** | 🔴 | 对比 skill.yaml stages 与 prompts/ 文件 |
| **G14** | **每个 stage prompt 含 `@engine:` 声明** | 🔴 | 搜索 `@engine:` |
| **G15** | **`skill-policy.yaml` 含 rollback** | 🔴 | grep `rollback:` skill-policy.yaml |
| **G16** | **Skill Atlas 条目完整** | 🟡 | 检查 `docs/skill-atlas.md` 含该 Skill |
| **G17** | **last_reviewed 在 review_cadence_days 内** | 🟡 | 对比当前日期与 skill.yaml `last_reviewed` |

### 6.2 模式分级

| 模式 | 门禁要求 |
|------|---------|
| **Governed** | G1-G17 全部 🔴🟡 通过 + trust report + quality scorecard + 独立 judge + 实测验证 |
| **Production** | G1-G16 全部 🔴🟡 通过 |
| **Scaffold** | G1-G6 全部 🔴 通过 |

---

## 7. 合规验证

自动验证（`shared/scripts/check-conformance.sh`）：

```
check_suite_compliance()
  → 读取所有 skill 的 SKILL.md + skill.yaml + boundary.md + prompts/
  → 按 G1-G16 逐项检查
  → 输出 PASS/WARN/FAIL + 修复建议
```

触发词评测（`shared/scripts/trigger-eval.mjs`）：

```
trigger_eval()
  → 读取所有 skill.yaml 的 triggers_cn / triggers_en
  → 检测重叠（>1 skill 共享同一触发词）
  → 检测缺失（无触发词的 skill）
  → 输出 trigger-eval-report.md
```

---

## 8. Governed Package Boundary (v1.1)

> yao-meta-skill Governed 模式要求。所有 Production 模式 Skill 建议满足，Governed 模式 Skill 必须满足。

### 8.1 要求清单

| Requirement | 对应文件 |
|-------------|---------|
| `owner` | skill.yaml `owner:` 字段 |
| `review cadence` | 每个 SUITE_SPEC 版本 bump 时审查 |
| `input_files` (file-backed fixture) | skill.yaml `interface.inputs` |
| `output contract` | skill.yaml `interface.outputs` |
| `rollback boundary` | `runtime/config/skill-policy.yaml` 的 rollback |
| `trust report` | `reports/trust-report.md` |
| `output_quality_scorecard` | `reports/output-quality-scorecard.md` |

### 8.2 Missing Evidence

以下项当前不可获取，标记为 `missing evidence`（不伪造）：

- **telemetry**: Skills 运行在 Claude Code 会话中，无集中式指标采集
- **approvals**: User-as-Dispatcher 模式，人在 CHECKPOINT 处审批
- **metrics**: 无自动化质量指标流水线
- **benchmarks**: 无标准化 skill 产出质量基准测试套件
- **drift detection**: 无自动检测 skill 偏离其契约的机制
```
