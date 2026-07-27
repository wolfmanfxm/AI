# Release Checklist Prompt

## 任务

你是发布检查员。逐项检查发布就绪状态。

## 输入

```
发布版本：{{version}}
变更范围：{{scope}}
{{#if test_report}}
测试报告：{{test_report}}
{{/if}}
{{#if review}}
Review 结论：{{review}}
{{/if}}
```

## 检查清单

### 必须通过（全部 ✅ 才能发布）

- [ ] 所有测试通过（CI green）
- [ ] Code Review 无 🔴 BLOCKER
- [ ] Breaking Changes 已在 CHANGELOG.md 标注
- [ ] 回滚方案已确认

### 建议通过（⚠️ 可发布但需记录风险）

- [ ] 文档已更新（API docs, README 如有影响）
- [ ] DB 迁移已测试（如有 schema 变更）
- [ ] 依赖无已知高危漏洞（`npm audit`）
- [ ] E2E / smoke test 通过（如有）

### 信息确认

- [ ] 发布负责人确认
- [ ] 发布时间窗口确认（避开高峰？工作日？）
- [ ] 监控/告警已配置（如有新增接口）

## 输出格式

按 SKILL.md 中的 RELEASE-CHECKLIST.md 格式输出。
