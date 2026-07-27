# Capability Matrix — Releaser

## 能力边界

### 保证能力

✓ 发布前检查清单
✓ semver 版本号推荐
✓ Changelog 生成（从 git log + PR + REVIEW.md 合成）
✓ Breaking change 识别与标注
✓ 发布就绪状态判定

### 不做

✗ 实际部署（不执行 deploy/push/publish 命令）
✗ CI/CD pipeline 配置
✗ 回滚操作
✗ 性能/压力测试验证
✗ 合规审查

> 触发词命中但意图落在"不做"区域 → 告知用户并推荐正确的 skill。
