# Semver Guide — Releaser

> Semantic Versioning 2.0.0 快速参考 + 实践指南。

## 版本号结构

```
MAJOR.MINOR.PATCH[-PRERELEASE][+BUILD]

  1  .  2  .  0   -beta.1  +20260727
  │     │     │       │          │
  │     │     │       │          └─ 构建元数据（可选）
  │     │     │       └─ 预发布标识（可选）
  │     │     └─ PATCH：向后兼容的 bug 修复
  │     └─ MINOR：向后兼容的新功能
  └─ MAJOR：不兼容的 API 变更
```

## Bump 决策表

| 变更内容 | Bump | 示例 |
|---------|------|------|
| 新增函数/接口，旧代码仍可用 | MINOR | 新增 `exportOrders()` |
| 修复 bug，行为修正 | PATCH | 空数组返回 `[]` 而非 `null` |
| 删除函数、改函数签名、改返回类型 | MAJOR | `login(token)` → `login(email, password)` |
| 只改内部实现，API 不变 | PATCH | 用 Map 替代 Object |
| 新增可选参数 | MINOR | `fn(x, opts?)` 新增第三个参数 |

## 常见歧义

| 场景 | 判定 | 理由 |
|------|------|------|
| 修改了错误消息文本 | PATCH | Bug fix，不影响 API |
| 修改了 HTTP 状态码 | MAJOR | 调用方可能依赖状态码 |
| 新增了必填参数 | MAJOR | 旧调用方编译/运行失败 |
| 废弃了一个函数（加 `@deprecated`） | MINOR | 还没删，向后兼容 |
| 删除了 `@deprecated` 函数 | MAJOR | 删了就是 Breaking |

## Pre-release 版本

| 阶段 | 版本 | 受众 | 稳定预期 |
|------|------|------|---------|
| alpha | `1.3.0-alpha.1` | 内部开发者 | 不稳定 |
| beta | `1.3.0-beta.1` | 早期 adopters | 基本稳定 |
| rc | `1.3.0-rc.1` | 所有人（测试） | 候选发布 |

## 实践建议

- **0.x 版本**：API 不稳定，MINOR bump 可以包含 Breaking Change
- **1.0.0+**：严格遵守 semver，Breaking Change 必须 MAJOR bump
- **不 bump 的情况**：纯 docs/comment/内部重构（行为 0 变化）
