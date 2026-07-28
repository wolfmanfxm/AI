# Context Priority

> 两个维度：**Source Priority**（哪个来源更权威）+ **Field Priority**（哪些字段必须传）。

## Source Priority（跨源优先级栈）

所有 Skill 统一按此栈加载上下文，不再各自决定先读谁：

```
优先级 高 ↑
  1. User Prompt            ← 用户显式指令，最高优先级
  2. .project-runtime/       ← 项目当前状态 + 上游产出
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

| 级别 | 含义 | 缺失时下游行为 |
|------|------|--------------|
| 🔴 **REQUIRED** | 缺失则无法正确工作 | **BLOCK** — 拒绝执行，提示运行 analyzer |
| 🟡 **IMPORTANT** | 缺失则质量下降 | **DEGRADE** — 降级模式，标注 `⚠️ 缺少 context` |
| 🟢 **OPTIONAL** | 有则更好，没有无妨 | **SKIP** — 静默跳过 |

---

## 🔴 REQUIRED（4 字段）

缺失任一项 → 下游 skill BLOCK，拒绝执行。

| 字段 | 为什么必须 | 影响的 skill |
|------|----------|-------------|
| `techStack.framework` | 决定了用什么语法、组件模式 | generator, refactorer |
| `techStack.language` | 决定 TS/JS 语法、类型定义方式 | generator, reviewer |
| `paths.sourceRoots` | 决定代码在哪、从哪读 | 全部 |
| `paths.aliases` | 决定 import 路径怎么写 | generator |

**BLOCK 时的提示模板**：

```
🔴 缺少 context.json 或缺少 REQUIRED 字段: techStack.framework
→ 无法确定项目框架，拒绝生成代码
→ 请先运行 /project-analyzer 生成 context.json
```

---

## 🟡 IMPORTANT（8 字段）

缺失时降级为通用模式，输出可能不完全匹配项目约定。

| 字段 | 缺失时降级为 | 影响 |
|------|------------|------|
| `techStack.uiLibrary` | Element Plus 默认 | 组件名可能不匹配 |
| `techStack.buildTool` | Vite 默认 | import.meta 语法可能不兼容 |
| `conventions.componentStyle` | `<script setup lang="ts">` | 生成代码风格可能不匹配 |
| `conventions.apiClient` | `fetch` | API 调用方式错误 |
| `conventions.apiParams.pagination` | `page:1, size:10` | 分页参数名错误 |
| `conventions.errorDisplay` | `console.error` | 用户看不到错误提示 |
| `modules.views` | 空数组 | 无法确认功能属于哪个模块 |
| `modules.components.global` | 空数组 | 不会复用已有组件 |

**降级提示模板**：

```
🟡 context.json 缺少 IMPORTANT 字段: conventions.apiClient
→ 降级为通用模式（使用 fetch），可能与项目约定不一致
→ 建议运行 /project-analyzer 补充 context.json
```

---

## 🟢 OPTIONAL（其余所有字段）

有则使用，无则跳过。不影响核心功能。

| 字段 | 用途 |
|------|------|
| `techStack.microFrontend` | 微前端场景特殊处理 |
| `modules.stores` | 引用已有 store 而非新建 |
| `modules.apis` | 了解 API 规模，不用于生成 |
| `quality.*` | 审查时参考，不做硬约束 |
| `techStack.cssPreprocessor` | 样式语法提示 |
| `conventions.formPattern` | 表单生成参考 |

---

## 优先级决策树

```
context.json 存在?
  ├─ 是 → 检查 REQUIRED 字段
  │        ├─ 全部存在 → 正常加载，检查 IMPORTANT 降级
  │        └─ 有缺失   → BLOCK + 提示运行 analyzer
  └─ 否 → 尝试从 .project-knowledge/ 提取
           ├─ 提取成功 → 降级加载，标注 `⚠️ 从知识库推断`
           └─ 提取失败 → BLOCK（generator）/ DEGRADE（其他）
```
