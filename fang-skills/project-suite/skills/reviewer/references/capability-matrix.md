# Capability Matrix — Reviewer

## 能力边界

### 保证能力

✓ 五轴审查（正确性、安全性、可读性、架构、性能）
✓ 问题分级（BLOCKER / HIGH / MEDIUM / LOW）
✓ 修复建议（file:line 级精确标注）
✓ 正向反馈（做得好的地方）

### 不做

✗ 自动修复代码（→ refactorer 或手动修复）
✗ 性能基准测试（可识别 N+1 等模式但不跑 benchmark）
✗ 正式安全审计报告
✗ 测试（→ tester）
✗ CI 集成

> 触发词命中但意图落在"不做"区域 → 告知用户并推荐正确的 skill。
