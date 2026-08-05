# Verifier — Releaser

> 独立验证 Candidate 发布产物。不参与发布流程。

## Checks

| # | Check | Method | On Failure |
|---|-------|--------|------------|
| V1 | Semver 合规 | 版本号符合 conventional commits | 修正 |
| V2 | Breaking Change | 每个 BREAKING 有迁移步骤 | 补全 |
| V3 | 回滚方案 | CHECKLIST 含 git revert 命令 | 补全 |
| V4 | Changelog 完整 | Added/Changed/Fixed/Deprecated/Removed | 补全遗漏 |

## 判定

全部通过 → Accepted。V1/V2 失败 → Rejected。其余 🟡 Accepted。
