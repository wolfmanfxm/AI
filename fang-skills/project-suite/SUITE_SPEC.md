# Suite Spec v1.0.0

> Project Suite 的正式 Framework 规范。定义一个合格的 suite skill 必须满足的目录结构、文件契约、质量门禁。

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
│   └── ...               🟢 OPTIONAL    code-audit / failure-handling / self-check 等
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
| `## 完成后下一步` | 下游 skill 路由建议 |
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

### 3.2 Capability 类型枚举（🔴 REQUIRED，不可自定义）

```
KnowledgeBase | Context | Plan | Architecture | Code | Test | Review |
RefactoredCode | Documentation | Release
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
| 状态机 | `runtime/engine/state-machine.md` | ✅ |
| 断点续传 | `runtime/engine/checkpoint.md` | ✅（manifest.json 读写） |
| DAG 调度 | `runtime/engine/scheduler.md` | ✅（按 capabilities.yaml 优先级） |
| Context Protocol | `runtime/context/context.md` | ✅（下游 skill 读 context.json） |
| 能力注册 | `runtime/registry/capabilities.yaml` | ✅（定义 produces/consumes） |

---

## 6. 质量门禁

### 6.1 门禁检查清单

| # | 检查项 | 级别 | 验证方式 |
|---|--------|------|---------|
| G1 | SKILL.md 存在且 ≤100 行 | 🔴 | `wc -l` |
| G2 | skill.yaml 存在且字段完整 | 🔴 | YAML 解析 + 字段校验 |
| G3 | boundary.md 含 ≥3 条反例 | 🔴 | 搜索 `❌ 反模式` 计数 |
| G4 | 至少 1 个 `🔴 CHECKPOINT` | 🔴 | 搜索 `CHECKPOINT` |
| G5 | 职责边界表 ≥3 行 ✅/❌ | 🔴 | 搜索 `✅ 本阶段职责` |
| G6 | frontmatter 含 description + 触发词 | 🔴 | YAML 解析 |
| G7 | capabilities.yaml 中已注册 | 🟡 | grep skill id |
| G8 | `完成后下一步` 章节存在 | 🟡 | 搜索 |
| G9 | failure-handling.md 存在 | 🟡 | 文件存在检查 |
| G10 | 无 runtime-specific 措辞 | 🟡 | grep `在 Claude Code` |
| G11 | prompts/ 至少 1 个文件 | 🟢 | `ls` |
| G12 | references/ 至少 2 个文件 | 🟢 | `ls` |

### 6.2 模式分级

| 模式 | 门禁要求 |
|------|---------|
| **Governed** | G1-G12 全部 🔴🟡 通过 + 独立 judge 评估 + 实测验证 |
| **Production** | G1-G8 全部 🔴🟡 通过 |
| **Scaffold** | G1-G6 全部 🔴 通过 |

---

## 7. 合规验证

运行时自动验证（analyzer 可触发）：

```
check_spec_compliance(skill_path)
  → 读取 SKILL.md + skill.yaml + references/boundary.md
  → 按 G1-G12 逐项检查
  → 输出 COMPLIANCE.md（通过/警告/阻断 + 修复建议）
```
