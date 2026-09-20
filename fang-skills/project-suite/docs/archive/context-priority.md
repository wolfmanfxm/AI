> ⚠️ **已归档（2026-09-20）—— Context Engine 规格，零消费者。不得再作为 Runtime Contract。**
>
> 归档原因：本文件描述的不是「一个产物长什么样」，而是**「机器如何加载/校验/合并上下文」**——
> 即一个 **Context Engine 的执行规格**（sources 优先级栈 + fields 三级 + 程序化 `gate` 决策树 + merge_rules）。
> 而全仓**零机器消费者**：无脚本读取、无提示词提及、无 skill 引用（引用者只有它自己的 .md/.yaml 孪生
> 与 ADR-001 的 Related 列表）。
>
> 它与 `context_contract` 是**同一条错误路线，且更重**：后者只是一个字段块，前者是整套引擎规格。
> 其 .yaml 自称「从 .md 提取的**可执行**版本」「Skill 可以 YAML.parse() 后直接执行」，
> 但**没有任何 Host 实现它**——这正是 SUITE_SPEC §0.1 逆命题要挡的形态。
>
> **为什么不给它补 Consumer**：那意味着造一个 Host Context Loader，把 Suite 从 **Protocol 变成 Context Engine**。
> 正确处置是让它退出 active Runtime，而不是补消费者或再造半残契约。
>
> **活的 Context Protocol 仍在** [runtime/context/](../../runtime/context/)：
> `context.md`（定义 `context.json` 这一产物 + 生产者/消费者）+ `context-resolution.md`（context.json 与代码不一致时的裁决规则）。
> 二者的区别是：那两份描述**产物及其 LLM 处置规则**（Protocol），本文件描述**机器要执行的操作**（Engine）。
>
> 保留原因：记录了设计历史（为什么当初考虑优先级栈与 gate 决策树）。

# Context Priority

> ⛔ **以下正文是 2026-09 当时的设计描述，全部为历史语态，不代表任何当前 Runtime 行为。**
> 本文中出现的 `BLOCK` / `DEGRADE` / `SKIP` / 优先级栈 / 字段三级，**没有任何执行者**——
> 不是为了让人照着实现，只是记录当初怎么想的。当前 Context 规则见
> [context.md](../../runtime/context/context.md) 与 [context-resolution.md](../../runtime/context/context-resolution.md)。

> 两个维度：**Source Priority**（哪个来源更权威）+ **Field Priority**（哪些字段必须传）。
>
> （2026-09-20：原先此处还写「⚙️ 机器读 `context-priority.yaml`（执行规则）」——
>   那份可执行规格已随本次清理**删除**，不再有机器可读版本。归档的只有本文这份设计史。）

## Source Priority（跨源优先级栈）

（历史上认为）所有 Skill 应统一按此栈加载上下文，不再各自决定先读谁：

```
优先级 高 ↑
  1. User Prompt            ← 用户显式指令，最高优先级
  2. .project-knowledge/runtime/       ← 项目当前状态 + 上游产出
  3. .project-knowledge/     ← 项目结构化知识（组件/模式/API）
  4. CLAUDE.md               ← 项目强制约束（安全/编码规范）
  5. Knowledge Vault         ← 跨项目经验参考
  6. Skill References        ← Skill 内置默认值，兜底
优先级 低 ↓
```

**合并规则** → [merge.md](merge.md)：override / append / ignore

---

## Field Priority（context.json 字段分级）

> 哪些 context 字段必须传、哪些可降级、哪些可忽略。

## 三级分类

| 级别 | 含义 | 当时规定的下游行为 |
|------|------|--------------|
| 🔴 **REQUIRED** | 缺失则无法正确工作 | **BLOCK** — 拒绝执行，提示运行 analyzer |
| 🟡 **IMPORTANT** | 缺失则质量下降 | **DEGRADE** — 降级模式，标注 `⚠️ 缺少 context` |
| 🟢 **OPTIONAL** | 有则更好，没有无妨 | **SKIP** — 静默跳过 |

---

## 🔴 REQUIRED（4 字段）

（当时规定）缺失任一项 → 下游 skill BLOCK，拒绝执行。**当前不存在此行为。**

| 字段 | 为什么必须 | 影响的 skill |
|------|----------|-------------|
| `techStack.framework` | 决定了用什么语法、组件模式 | generator, refactorer |
| `techStack.language` | 决定 TS/JS 语法、类型定义方式 | generator, reviewer |
| `paths.sourceRoots` | 决定代码在哪、从哪读 | 全部 |
| `paths.aliases` | 决定 import 路径怎么写 | generator |

**当时的 BLOCK 提示模板（历史，无执行者）**：

```
🔴 缺少 context.json 或缺少 REQUIRED 字段: techStack.framework
→ 无法确定项目框架，拒绝生成代码
→ 请先运行 /project-analyzer 生成 context.json
```

---

## 🟡 IMPORTANT（8 字段）

（当时规定）缺失时降级为通用模式，输出可能不完全匹配项目约定。**当前不存在此行为。**

| 字段 | 缺失时降级为 | 影响 |
|------|------------|------|
| `techStack.uiLibrary` | 组件库默认 | 组件名可能不匹配 |
| `techStack.buildTool` | 构建工具默认 | 构建语法可能不兼容 |
| `conventions.componentStyle` | `<script setup lang="ts">` | 生成代码风格可能不匹配 |
| `conventions.apiClient` | `fetch` | API 调用方式错误 |
| `conventions.apiParams.pagination` | `page:1, size:10` | 分页参数名错误 |
| `conventions.errorDisplay` | `console.error` | 用户看不到错误提示 |
| `modules.views` | 空数组 | 无法确认功能属于哪个模块 |
| `modules.components.global` | 空数组 | 不会复用已有组件 |

**当时的降级提示模板（历史，无执行者）**：

```
🟡 context.json 缺少 IMPORTANT 字段: conventions.apiClient
→ 降级为通用模式（使用 fetch），可能与项目约定不一致
→ 建议运行 /project-analyzer 补充 context.json
```

---

## 🟢 OPTIONAL（其余所有字段）

（当时认为）有则使用，无则跳过。不影响核心功能。

| 字段 | 用途 |
|------|------|
| `techStack.microFrontend` | 微前端场景特殊处理 |
| `modules.stores` | 引用已有 store 而非新建 |
| `modules.apis` | 了解 API 规模，不用于生成 |
| `quality.*` | 审查时参考，不做硬约束 |
| `techStack.cssPreprocessor` | 样式语法提示 |
| `conventions.formPattern` | 表单生成参考 |

---

## 优先级决策树（当时设计的 gate 流程）

> ⛔ 这一段是**当初设想的机器决策流程**，从未有任何实现；它的可执行版本 `context-priority.yaml`
> 已删除。**当前 Context 缺失/不一致时的真实规则见 [context-resolution.md](../../runtime/context/context-resolution.md)。**

```
context.json 存在?
  ├─ 是 → 检查 REQUIRED 字段
  │        ├─ 全部存在 → 正常加载，检查 IMPORTANT 降级
  │        └─ 有缺失   → BLOCK + 提示运行 analyzer
  └─ 否 → 尝试从 .project-knowledge/ 提取
           ├─ 提取成功 → 降级加载，标注 `⚠️ 从知识库推断`
           └─ 提取失败 → BLOCK（generator）/ DEGRADE（其他）
```
