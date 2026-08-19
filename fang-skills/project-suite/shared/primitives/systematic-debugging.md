# Systematic Debugging — Suite Primitive v1.0.0

> Suite 一级「系统化定位问题」原语。当代码行为异常（测试失败 / 报错 / 输出不对）时，按统一循环定位根因，而非「改一点试试看」的随机试错。
> 借鉴 Superpowers 的 Systematic Debugging 思想。不新增 debugger Skill——本原语让 generator / tester / reviewer / refactorer 复用同一套定位流程。

## 定位：生产者 / 消费者

| 角色 | Skill | 职责 |
|------|-------|------|
| **Consumer** | generator / tester / reviewer / refactorer | 遇到「行为不符合预期」时，走本循环而非随机改 |

> 使用方式：在 skill 的 execution 阶段遇到 bug 时 `[引用](../../shared/primitives/systematic-debugging.md)`。

## Debugging Loop（六步，缺一不可）

```
Reproduce → Isolate → Hypothesis → Minimal Fix → Re-run → Regression
```

| 步 | 动作 | 产出 | 跳过条件 |
|----|------|------|---------|
| 1. **Reproduce** | 用最小输入稳定复现问题 | 一个可复现的失败用例 | 无法复现 → 不要改，先补复现手段 |
| 2. **Isolate** | 二分定位：是哪一层/哪个函数/哪一行导致 | 定位到最小可疑单元 | — |
| 3. **Hypothesis** | 写下一个「根因假设」，说明为什么它会这样 | 一个明确假设（可被推翻） | 无假设 → 不盲目改 |
| 4. **Minimal Fix** | 只改修复根因所需的最小代码 | 最小 diff | 禁止顺手重构 |
| 5. **Re-run** | 重跑第 1 步的失败用例，确认转绿 | pass/fail | — |
| 6. **Regression** | 跑相关测试，确认没引入新问题 | 回归结果 | 无测试 → 先补表征测试 |

## 关键纪律

1. **先复现再改**——无法复现的问题，改就是赌博。先花时间把失败稳定复现出来。
2. **一次一个假设**——不要同时改多处「说不定哪处管用」，那样无法归因是哪个改动修好的。
3. **Minimal Fix 优先**——修复根因的最小 diff，不顺手重构、不扩大范围。
4. **回归兜底**——修复后必跑回归，防止「修了 A 坏了 B」。

## 与 Tester 的关系

- **tester 的「生成/执行测试」** = 产出测试用例（验证「该不该这样」）
- **systematic-debugging** = 定位已有问题（回答「为什么不对」）

两者互补，不是重复。tester 发现测试失败后，走本原语定位根因，而不是直接改源码让测试「碰巧通过」。

## 反例

| ❌ 反模式 | ✅ 正确做法 |
|-----------|-----------|
| 无法复现就凭猜改代码 | 先 Reproduce，稳定复现再动手 |
| 同时改 3 处「试试哪个管用」 | 一次一个 Hypothesis + Minimal Fix |
| 修复时顺手重构无关代码 | Minimal Fix，只改根因所需 |
| 改完不跑回归 | Re-run + Regression 兜底 |
| 测试失败直接改源码让它过 | 先定位根因（可能源码真有 bug），再修 |

## 输出格式

每次 Debugging 循环产出一条记录：

```markdown
Debug[定位记录]: <问题一句话>
  Reproduce: <最小复现用例>
  Isolate:   <定位到的最小单元>
  Hypothesis: <根因假设>
  Minimal Fix: <最小 diff>
  Re-run:    <pass/fail>
  Regression: <相关测试结果>
```
