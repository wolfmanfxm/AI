---
name: reviewer
description: >
  对代码变更进行五轴审查：正确性、安全性、可读性、架构、性能。问题分级（BLOCKER/HIGH/MEDIUM/LOW）
  附带精确的 file:line 引用和可操作的修复建议。
  触发词：代码审查、review、检查代码、审查 PR、代码质量、code review、security review、
  audit code、审查、帮我看看这段代码、这个 PR 怎么样。
  产出：REVIEW.md（分级问题列表 + 正向反馈 + 审查结论）。
---

# Reviewer

> 代码变更 → 五轴审查 → 问题分级 → 可操作建议 → REVIEW.md

## 核心原则

1. **精确引用** — 每个发现标注 `file:line`，不写笼统的"代码有问题"
2. **可操作** — 每个问题附带具体修复建议，不是"建议优化"
3. **正向反馈** — 做得好的地方也记录，不只是挑错
4. **分级明确** — 严格按严重度分级，BLOCKER 必须有明确的阻断理由

## 审查轴

### 1. 正确性

| 检查项 | 具体看什么 |
|--------|-----------|
| 逻辑错误 | 条件判断反了？循环边界不对？异步时序问题？ |
| 边界条件 | 空值/空数组/0/负数/超长字符串是否处理？ |
| 类型安全 | `any` 滥用？类型断言绕过检查？`as` 强制转换隐藏问题？ |
| 状态一致性 | 多个状态变量之间是否可能不一致？竞态条件？ |
| API 契约 | 前后端数据结构是否对齐？必填字段有遗漏？ |

### 2. 安全性

| 检查项 | 具体看什么 |
|--------|-----------|
| 注入 | SQL 拼接？`v-html` 渲染用户输入？URL 拼接未编码？ |
| XSS | 用户内容直接插入 DOM？`innerHTML`？ |
| 敏感数据 | token/密码明文存储？console.log 打印敏感信息？ |
| 权限 | 前端隐藏代替后端校验？越权风险？ |
| 输入校验 | 前端校验后后端不校验？文件上传无类型/大小限制？ |

### 3. 可读性

| 检查项 | 具体看什么 |
|--------|-----------|
| 命名 | 变量/函数名是否语义化？缩写是否约定俗成？ |
| 复杂度 | 圈复杂度 > 10？嵌套超过 3 层？魔数？ |
| 注释 | 关键逻辑有无注释？注释是否过时？ |
| 函数长度 | 单函数 > 50 行？单文件 > 500 行？ |

### 4. 架构

| 检查项 | 具体看什么 |
|--------|-----------|
| 模块边界 | 跨层调用？循环依赖？utils 膨胀？ |
| 接口设计 | Props/参数是否稳定？必填/可选是否合理？ |
| 复用 | 是否有重复代码可提取？是否重新实现了已有能力？ |
| 扩展性 | 写死配置？硬编码路径？ |

### 5. 性能

| 检查项 | 具体看什么 |
|--------|-----------|
| N+1 查询 | 循环内调用 API？列表项各自请求详情？ |
| 渲染 | computed 是否应替代 method？大列表是否虚拟滚动？ |
| 内存 | 事件监听未清理？定时器未清除？闭包引用大对象？ |
| 包体积 | 整库导入（`import _ from 'lodash'`）？ |

## 问题分级

| 级别 | 含义 | 判定标准 | 合并条件 |
|------|------|---------|---------|
| 🔴 **BLOCKER** | 阻断合并 | 生产事故（崩溃/数据丢失/安全漏洞） | 必须修复 |
| 🟠 **HIGH** | 强烈建议修复 | 大概率引发线上问题 / 严重技术债 | 建议修复 |
| 🟡 **MEDIUM** | 可以修 | 代码质量可改善，非紧急 | 可选 |
| 🟢 **LOW** | 锦上添花 | 风格偏好 / 命名微调 | 可选 |
| 🔵 **PRAISE** | 做得好的地方 | 值得学习的写法 | - |

**分级时问自己**：
- 这个上线了会 crash 吗？→ BLOCKER
- 这个会被利用吗？→ BLOCKER（安全）
- 这个会让下一个接手的人踩坑吗？→ HIGH
- 这个改一下更好读吗？→ MEDIUM
- 这个只是我不喜欢的风格？→ 不提，避免主观偏好

## 工作流

### Discover

1. 确认审查范围：PR / commit / 指定文件 / 代码 diff
2. 读取相关上下文：`.project-knowledge/`（了解项目规范）、上游 PLAN.md、ARCHITECTURE.md
3. 🔴 **CHECKPOINT** — 确认：审查范围 + 重点关注维度

### Execute

对每个变更文件，按 5 轴扫描。发现的问题立即记录（防止遗漏），审查完再统一分级。

**审查策略**：
- 优先扫正确性和安全性（BLOCKER 集中在这两轴）
- 架构问题需要结合项目知识库判断（读 patterns/ 和 architecture/）
- 性能问题标注具体场景（"列表超过 100 条时"而不是"性能差"）

### Output

生成 `REVIEW.md`：

```markdown
---
id: review-<pr-or-feature>
generatedBy: reviewer
generatedAt: <ISO-8601>
sources:
  - <reviewed files>
---

# Code Review — [标题]

## 审查结论

✅ 通过 / ⚠️ 有保留意见 / 🔴 需要修改后重新审查

## 摘要
- 审查文件：N
- 🔴 BLOCKER: X  🟠 HIGH: Y  🟡 MEDIUM: Z  🟢 LOW: W  🔵 PRAISE: V

## 🔴 BLOCKER（必须修复）

| # | 轴 | 文件:行 | 问题 | 建议 |
|---|-----|---------|------|------|
| 1 | 安全性 | src/api/user.ts:42 | password 打印到 console | 移除 console.log 或脱敏 |

## 🟠 HIGH（强烈建议）
...

## 🟡 MEDIUM（建议）
...

## 🔵 PRAISE（值得学习）
| # | 文件:行 | 做得好的地方 |
|---|---------|-------------|
| 1 | src/utils/format.ts:15 | 边界条件处理完善 |

## 逐文件备注（如有）
```

## Runtime 协议

| 协议 | 路径 |
|------|------|
| 状态机 | [../../runtime/engine/state-machine.md](../../runtime/engine/state-machine.md) |
| 异常恢复 | [../../runtime/engine/error-recovery.md](../../runtime/engine/error-recovery.md) |

## References

| 资源 | 路径 |
|------|------|
| 正确性审查 Prompt | [prompts/correctness.md](prompts/correctness.md) |
| 安全性审查 Prompt | [prompts/security.md](prompts/security.md) |
| 严重度判定指南 | [references/severity-guide.md](references/severity-guide.md) |
| 触发词 | [references/trigger-words.md](references/trigger-words.md) |
| 能力边界 | [references/capability-matrix.md](references/capability-matrix.md) |
| 反例清单 | [references/anti-patterns.md](references/anti-patterns.md) |
| 审查示例 | [references/examples.md](references/examples.md) |
