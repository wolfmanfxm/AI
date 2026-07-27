# Safety Protocol — Refactorer

> 重构安全协议。确保每次重构可验证、可逆、不引入 bug。

## 安全层 0：基线确认

在改任何代码之前：

1. **确认测试基线**
   ```
   有测试 → npm test → 确认全部通过 → 记录"✅ 基线：N/N 通过"
   无测试 → 跳到安全层 1
   ```

2. **确认 git 状态**
   ```
   git status → 工作区干净？有未提交代码？
   建议：先 commit 当前状态，以便随时 git checkout 回滚
   ```

## 安全层 1：表征测试

当被测代码没有测试时，先加 characterization test：

> 表征测试：记录代码"当前的行为"，不判断正确与否。目的：重构后能验证行为没变。

```typescript
// 表征测试示例
describe('processOrder (characterization)', () => {
  it('当前：传入空 items 时抛出 "empty" 错误', () => {
    expect(() => processOrder({ items: [] }))
      .toThrow('empty')
  })

  it('当前：正常订单返回含 total 的对象', () => {
    const result = processOrder({ items: [{ price: 100 }] })
    expect(result).toHaveProperty('total')
  })
})
```

**关键**：表征测试只记录"现在怎样"，不判断"应该怎样"。如果行为看起来不对（例如错误信息不友好），记录但不修复 — 那是 bug fix，不是重构。

## 安全层 2：单步操作

每次只做一个重构动作：

```
✅ Extract Method → 测试 → commit
✅ Rename → 测试 → commit
❌ Extract Method + Rename + Simplify 一起做 → 失败后不知道哪个出问题
```

## 安全层 3：验证后提交

```
重构 → npm test → 通过 → git commit -m "refactor: extract validateOrder"
                 → 失败 → 分析 diff，修复或 git checkout .
```

## 安全层 4：回滚

如果重构后发现逻辑变了（测试失败且修复成本高于还原）：

```
git checkout <target-file>  → 回到重构前状态
```

这就是为什么小步提交重要 — 只回滚失败的那一步。

## 不适合重构的信号

| 信号 | 行动 |
|------|------|
| 没测试 + 函数 200 行 + 无类型 | 建议先加类型 + 表征测试，再重构 |
| 代码依赖即将被替换的 API | 不重构，等技术迁移完再说 |
| 代码正在被多人活跃修改 | 不重构（冲突风险高），等稳定后 |
| 你无法确定重构后行为是否一致 | 不加类型/加测试前不动手 |
