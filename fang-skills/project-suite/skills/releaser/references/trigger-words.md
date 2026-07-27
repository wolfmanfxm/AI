# Trigger Words — Releaser

## 中文触发词

### 发布
- 发布、上线、发版
- 准备发布、发布前检查
- release、ship

### 版本号
- 版本号、版本升级、bump version
- 下一个版本、版本怎么定

### Changelog
- changelog、更新日志、版本记录
- 生成 changelog、写 changelog

## English Triggers

- release, ship, deploy, publish
- version bump, bump version, what version
- changelog, generate changelog, release notes

## 歧义处理

| 用户说 | 可能意图 | 路由决策 |
|--------|---------|---------|
| "部署到生产" | releaser vs DevOps | 发布检查+版本管理→releaser；CI/CD执行→DevOps/shell |
| "写 changelog" | releaser vs documenter | 关联版本发布的 changelog→releaser；独立文档→documenter |
| "更新版本号" | releaser | 直接路由 |
