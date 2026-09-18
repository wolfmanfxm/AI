# Round 13 分析 — 存量补齐（contract backfill）验证

> 验证 knowledge-builder 新增的 Action 6「存量补齐」。**suite-only**，单项 A1 + 连带 C1。
> 与 round12 **逐字相同的 prompt、相同项目、相同基线**——唯一变量是 skill 文档。
> 目标项目 `afc-newcore-web-code`，分支 `benchmark/20260813`，全程零 git 操作。

## 结果总览

| 判定项 | 结果 |
|--------|------|
| **A1：存量补齐是否发生** | ✅ **生效**——27 个既有文件被补上契约字段 |
| **「只补不覆盖」是否守住** | ✅ **零违规**——既有 frontmatter 键丢失/被改 = **0** |
| **标记是否写上** | ✅ 28 个文件带 `*_source: derived-from-body`（27 补写 + 1 新建误标，见下） |
| **新建文件回归** | ✅ 4/4 合规（与 round12 一致） |
| **C1：编译器能否产出 index** | ✅ **首次成功**——该知识库第一次生成 `knowledge-index.json`（4,953 字节，8 个能力桶） |
| **⚠️ 连带发现** | 🔴 **编译器前 15 行硬窗口 bug**——见下，这是本轮最有价值的发现 |

## A1：补齐确实发生，且未越界

**判定方式：用跑前备份逐文件对比，不采信 agent 自报。**

| 目录 | 补写字段 | 文件数 |
|------|---------|--------|
| `patterns/` | `statement` | 14 |
| `decisions/` | `constraint` | 4 |
| `rules/` | `constraint` | 4 |
| `components/` | `statement` | 2 |
| `api/` | `statement` | 3 |
| **合计** | | **27** |

**关键规则验证（`只补缺失，绝不覆盖`）**：

| 检查 | 结果 |
|------|------|
| 既有 frontmatter 键丢失或被改 | **0** |
| 正文被改动 | 3 个（`index.md` / `observations/risks.md` / `observations/antipatterns.md`）——**属本次分析的正常内容追加，非补齐动作**，与 agent 自报一致 |

**补写值有实质**（不是为过检编的空壳）——抽查：

```yaml
# rules/frontend-convention.md（generatedBy: manual，原有键一字未动）
constraint: "静态 import 仅写在模块顶层，禁止写在函数或条件分支内；类型导入必须用 import type；
             对外 HTML 属性必须 kebab-case 对应内部 camelCase prop；props 禁止 any；事件名必须 kebab-case"
constraint_source: derived-from-body
```

**agent 的边界判断也对**：主动跳过 `decisions/index.md` 与 `rules/index.md`——二者是人工维护的导航存根
（无 frontmatter，文件头写「分析工具不会覆盖」），非知识对象。

**一处误标**：本次**新建**的 `decisions/ARCHITECTURE-quota-manage-implementation.md` 也带了 `derived-from-body`。
新文件没有「原作者」，字段就是本次产出的，标记是噪音。已在 knowledge-builder 规则 2 补一句澄清
（**只对既有文件补写时标记**）。

## 🔴 C1 的连带发现：编译器「前 15 行」硬窗口（本轮最有价值）

补齐后首次跑编译器，**仍然失败**：

```
❌ 缺少 constraint: decisions/ARCHITECTURE-quota-mail-config.md
❌ 缺少 constraint: decisions/ARCHITECTURE-quota-wholesale-gap.md
❌ 缺少 constraint: decisions/architecture-decisions.md
```

但**独立对比证明这 3 个文件确实补上了 `constraint:`**。矛盾点在于：

| 文件 | `constraint:` 所在行 | 编译器检查范围 |
|------|---------------------|---------------|
| `decisions/architecture-decisions.md` | 第 **17** 行 | `sed -n '1,15p'` |
| `decisions/ARCHITECTURE-quota-mail-config.md` | 第 **19** 行 | 同上 |
| `decisions/ARCHITECTURE-quota-wholesale-gap.md` | 第 **24** 行 | 同上 |

这些文件 frontmatter 很长（`sources:` 列了多条），补齐的字段落在第 15 行之后 → **写了但读不到**。
后果：**「补齐成功」与「编译器仍拒绝生成 index」同时成立**——链路依旧断着，而两边的日志看起来都正常。

**而且没有任何文档说过「字段必须在 15 行内」**——这是个隐式的位置约束，`evidence-header.md` 与
`output-format.md` 都只讲字段、不讲位置。即 **契约声称的要求（写字段）与实现的真实要求（写在 15 行内）不一致**。

**修复**：`knowledge-compiler.sh` 增加 `fm_field()`，按 frontmatter 块解析（首个 `---` 到闭合 `---`），
替换两处 `sed -n '1,15p'` 硬窗口（另一处是 `detect_scope` 读 `scope:`，同一个 bug）。

**修复后**：编译器**首次**在该项目产出 index：

```
✅ 契约硬校验字段齐全（rules:constraint decisions:constraint）
⚠️ 9 个文件的契约字段是 analyzer 从正文**派生**的（未经人工确认，见 *_source: derived-from-body）
Generated: .project-knowledge/knowledge-index.json
  capabilities: rules decisions patterns components api architecture experience playbooks recommendations
  rules:4  decisions:5  patterns:15  components:3  api:4  architecture:4  experience:1
```

## 为什么这个 bug 只有端到端实跑才能发现

- **静态检查全绿**：`check-knowledge-pipeline.sh` 的 fixture 里 frontmatter 很短，字段都在前 15 行内 → 测试通过。
- **补齐本身"成功"**：字段确实写进文件了，diff 能验证。
- **只有把两者连起来跑**（补齐 → 编译）才暴露：**生产者写对了，消费者读不到**。

这与 round11 发现的 `constraint` 断链是**同一类问题的两个层次**：前者是「没人写」，后者是「写了但读不到」。

## 判定

- **A1：✅ 生效**——存量补齐按文档执行，27/27 补齐、零覆盖违规、标记齐全、值有实质。
- **C1：✅ 生效**（修掉 15 行窗口后）——编译器首次产出 index。
- **新写进文档的规则本身未验证**：规则 3「派生不出就不写」本轮**没有被触发**（27 个文件全部派生成功），
  因此「宁缺勿造」这条只写了、没验。标记「只对既有文件」的澄清同理（正是本轮误标后才补的）。
