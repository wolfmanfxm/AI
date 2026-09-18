# Round 12 监测方案

> 验证 2026-09-17 第二批改动（`constraint` / `statement` 的 **Producer 侧修复** + Knowledge Directory Contract）。
> 性质：**suite-only 轻量验证**，最小集 2 项。核心问题只有一个：
> **Producer 侧改了之后，analyzer 真的会写出契约要求的字段吗？**

## 本轮改动清单

| # | 改动 | 类型 | 验证点 |
|---|------|------|--------|
| 1 | `constraint` Producer 修复：`evidence-header.md` 模板 + analyzer `output-format.md` 字段表 | 行为（Producer） | analyzer 写 `decisions/` 时是否真的带上 `constraint:` |
| 2 | `statement` Producer 修复：`output-format.md` 字段表补字段 + `knowledge-builder.md` Coverage Gate 加「frontmatter 契约」门 | 行为（Producer） | analyzer 写 `patterns/components/api` 时是否真的带上 `statement:` |
| 3 | **新增** `verifier.md` Verify 6：契约字段齐备（产不出 → Reject） | 行为（Producer 拦截点） | Verifier 阶段是否执行了 Verify 6 |
| 4 | Knowledge Directory Contract（`knowledge-directories.yaml` + 生成器 + I1–I4） | 声明 + 运行时 | 编译器 I1（扫描列表 == 契约）在真实项目上是否成立 |
| 5 | check-yaml 门禁（L0） | 静态 | 静态（44/44） |

> round11 已实测：这三处修复**之前**的合规率是 `statement` **0/12**、`constraint` 缺失（8 个文件）。

## 最小验证集

| 任务 | 用途 | 关键信号 | 执行方式 |
|------|------|---------|---------|
| **A1** | #1 #2 #3 —— **Producer 真的写契约字段了吗** | 新产出的 `patterns/` `components/` `api/` 文件含 `statement:`；`decisions/` 文件含 `constraint:`；Verifier 执行了 Verify 6 | suite agent（增量分析 quotaManage 模块） |
| **C1** | #4 —— 契约驱动的编译器在真实项目上是否成立 | I1（扫描列表 == 契约）通过；硬校验按 `KD_ENFORCED` 报缺字段 | bash 直跑（脚本行为） |

### 设计要点：A1 的 prompt **不提 `statement` / `constraint`**

若 prompt 里提到这两个字段，agent 可能因为被点名而写上——那就测不出「skill 自身的 prompt 是否足以让 agent 写出契约字段」。
因此 A1 的 prompt 只给任务（增量分析某模块 + 写入知识库 + 按 analyzer 流程），字段是否出现完全由 skill 文档决定。
**判定靠我事后直接读产物文件，不采信 agent 自报。**

## 前置约束（沿用 round1–11）

1. 目标项目 `/Users/fangxiangming/Work/Ly/东风汽金/code/afc-newcore-web-code`，分支 `benchmark/20260813`，**全程禁 commit**。
2. suite agent prompt 含「绝对禁止运行任何 git 命令」+「只在目标项目目录内读写」。
3. `.project-knowledge/` 跑前备份（`/tmp/r12-backup/pk-orig`），跑完**逐字节还原**。
4. 代码产物跑完即清。

## 跑前基线（2026-09-17）

| 项 | 值 |
|---|---|
| `patterns/*.md` 含 `statement:` | **0 / 14** |
| `rules/` + `decisions/` 缺 `constraint:` | **8 个文件** |
| 编译器能否生成 index | ❌ 否（被上一条挡住，`exit 1`） |

## 判定口径

- **A1 生效** = 新产出的 `patterns/components/api` 文件中，含 `statement:` 的占比显著 > 0（基线 0/14）；新建的 `decisions/` 文件含 `constraint:`。
- **A1 部分生效** = 字段出现但覆盖率低，或只在 agent 被额外提示时才出现。
- **A1 未生效** = 新产出文件仍无这两个字段——说明补文档不足以改变 Producer 行为，需要更强的机制。
- **C1 生效** = I1 通过（扫描列表与契约一致）且硬校验只按 `KD_ENFORCED` 报缺失。
- ⚠️ **预期内的非目标**：历史遗留的 8 个缺 `constraint` 文件**不会被本轮修复**——Producer 修复只对**新产出**生效，
  存量知识库需要迁移。若 C1 因此仍 `exit 1`，记为「存量缺口」，不计为本轮改动失败。
