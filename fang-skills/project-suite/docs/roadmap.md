# Roadmap

> project-suite 演进路线图。

## 版本策略

- **主版本号**：破坏性变更（schema 不兼容、skill 移除）
- **次版本号**：新 skill 正式发布、skill 大功能新增
- **修订号**：skill 优化、bug 修复、prompt 改进

---

## v0.1.0 — 骨架 ✅ 已完成

- [x] 目录结构确定
- [x] runtime/ 核心协议完成（state-machine, checkpoint, scheduler, error-recovery, routing, orchestration）
- [x] shared/ 基础设施完成（schemas, templates, conventions, examples）
- [x] docs/ 完成（architecture, roadmap, migration）
- [x] SUITE.md 入口完成
- [x] analyzer 迁移完成（从独立 skill → suite skills/analyzer/，protocol 提升到 runtime/）
- [x] 8 个新 skill 骨架创建（SKILL.md + prompts/main.md + references/capability-matrix.md）

---

## v0.2.0 — 核心闭环 ✅ 已完成

四 skill 形成最小可用链路：

```
analyzer → planner → generator → reviewer
```

- [x] **planner 正式版** 
  - 5 种需求输入策略（模糊想法/PRD/Issue/多模块/重构）
  - 3 种依赖标注（硬/软/外部）+ 工作量评估 + 风险矩阵
  - 2 个专用 prompt（task-breakdown, estimation）+ 触发词 + 反例 + 示例
- [x] **generator 正式版**
  - 按生成类型分策略（组件/页面/API/工具函数/类型）
  - 项目知识读取策略 + 代码自检清单 + 边界处理
  - 3 个专用 prompt（component-gen, api-gen, page-gen）+ 触发词 + 反例（含安全反例）+ 示例
- [x] **reviewer 正式版**
  - 五轴审查（正确性/安全性/可读性/架构/性能）+ 每轴详细检查清单
  - 4 级严重度（BLOCKER/HIGH/MEDIUM/LOW）+ PRAISE 正向反馈
  - 2 个专用 prompt（correctness, security）+ 严重度指南 + 触发词 + 反例 + 示例

---

## v0.3.0 — 扩展覆盖 ✅ 已完成

```
analyzer → planner → architect → generator → tester → reviewer
                                            ↘ refactorer ↗
```

- [x] **architect 正式版**（10 files）
  - 技术选型对比框架：候选×维度矩阵 + 加权评分（[tech-selection.md](../skills/architect/prompts/tech-selection.md)）
  - 模块设计模板：DDD 限界上下文 / 分层架构（[module-design.md](../skills/architect/prompts/module-design.md)）
  - API 契约设计：RESTful 接口规范 + 检查清单（[api-design.md](../skills/architect/prompts/api-design.md)）
  - ADR 格式 + 决策时机 + 陷阱警告（[decision-framework.md](../skills/architect/references/decision-framework.md)）
- [x] **tester 正式版**（10 files）
  - 按测试类型分策略：单元/组件/集成 + 测试策略规划（[main.md](../skills/tester/prompts/main.md)）
  - Given-When-Then 覆盖矩阵：正常→边界→异常→状态转换→并发（[unit-test.md](../skills/tester/prompts/unit-test.md) + [component-test.md](../skills/tester/prompts/component-test.md)）
  - 6 项环境自动检测：框架/目录/命名/命令/断言/mock（SKILL.md 前置检测）
  - Mock 策略：可 mock/不可 mock/stub 选择（[mock-strategy.md](../skills/tester/references/mock-strategy.md)）
- [x] **refactorer 正式版**（9 files）
  - 9 种重构手法目录：Extract Method/Component/Composable、Guard Clause、对象映射、可选链等
  - 4 层安全重构协议：基线确认→表征测试→单步操作→验证提交→回滚（[safety-protocol.md](../skills/refactorer/references/safety-protocol.md)）
  - 过度重构警告：出现2次不提取、抽象代码>重复代码不提取、case<4不用对象映射

---

## v0.4.0 — 完整闭环 ✅ 已完成

```
analyzer → planner → architect → generator → tester → reviewer → refactorer → documenter → releaser
```

- [x] **documenter 正式版**（8 files）
  - 4 种文档类型生成：API/README/组件/ADR（[main.md](../skills/documenter/prompts/main.md)）
  - 风格匹配框架：6 特征检测 + 4 跟随规则（[doc-style-guide.md](../skills/documenter/references/doc-style-guide.md)）
  - JSDoc→Markdown 提取 + 代码事实优先（[api-doc.md](../skills/documenter/prompts/api-doc.md)）
  - 文档新鲜度检查：`[OUTDATED]` `[MATCH]` `[NEW]` 对比
- [x] **releaser 正式版**（9 files）
  - semver 自动推荐：conventional commits→bump 决策表 + 多 commit 最高 bump 原则（[version-bump.md](../skills/releaser/prompts/version-bump.md)）
  - Changelog 合成：git log + PR + REVIEW.md → 7 类分组（[changelog-gen.md](../skills/releaser/prompts/changelog-gen.md)）
  - 发布检查清单：6 项必检 + 发布后验证步骤（[release-checklist.md](../skills/releaser/prompts/release-checklist.md)）
  - Semver 2.0.0 实践指南：歧义场景判定 + pre-release 策略（[semver-guide.md](../skills/releaser/references/semver-guide.md)）
- [ ] **跨 skill 工作流端到端测试** ← 移到 v1.0.0

---

## v1.0.0 — 稳定版

- [ ] 全部 9 个 skill 经过实际项目验证
- [ ] 每个 skill 有完整的 evals（至少 5 个测试用例 + benchmark）
- [ ] 有至少 3 个真实项目的使用案例
- [ ] SUITE.md + all skill SKILL.md 文档完整
- [ ] runtime/ 协议经过多 skill 协作验证
- [ ] shared/ schemas 兼容性经过验证
- [ ] 至少 1 个外部用户成功上手

---

## 未来探索

| 方向 | 描述 | 触发条件 |
|------|------|---------|
| **project-observer** | 新增 skill，git hook 触发，自动检测变更并增量更新知识库 | analyzer 增量模式有用户反馈不便 |
| **skill 市场** | 允许社区贡献和安装 skill，类似 VS Code 插件 | 有外部贡献者出现 |
| **可视化编排** | 拖拽式 skill 工作流编辑 + 实时状态面板 | 用户反馈命令式编排不够直观 |
| **CI/CD 集成** | skill 作为 CI pipeline 的一环（如 reviewer 在 PR 自动触发） | 有团队 CI 集成需求 |
| **多语言 project-knowledge** | 支持 Java/Python/Go 项目的 analyzer 分析 | 有非 JS/TS 项目使用需求 |
| **Skill 间实时协作** | 多个 skill 在同一 session 中交替工作，而非严格串行 | generator 和 reviewer 频繁交替的场景 |
