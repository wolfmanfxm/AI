# Intent Routing v0.7.0

> 用户意图 → skill 路由。路由表从 `skills/*/skill.yaml` + `runtime/registry/capabilities.yaml` 自动生成。
> **用户始终是 Dispatcher。路由只是建议，不自动级联。**
> Artifact 类型详见 `runtime/artifacts/artifact-types.yaml`，Interface 详见各 Skill 的 `interface.md`。

## 路由来源

| 字段 | 来源 | 说明 |
|------|------|------|
| triggers_cn / triggers_en | `skill.yaml` | 触发词 |
| produces / consumes | `capabilities.yaml` | 能力注册 |
| depends_on / parallel_with | `skill.yaml` | 依赖和并行关系 |

> 手动维护此文件时，需与 `skill.yaml` + `capabilities.yaml` 保持一致。不一致时以 `skill.yaml` 为准。

## 路由规则

1. **精确触发词匹配** — 用户消息包含 `skill.yaml` 的 `triggers_cn`/`triggers_en`
2. **上下文路由** — 存在 manifest 且 status ≠ completed → 续执行
3. **语义路由** — 用户意图与 skill description 最匹配（LLM 判断）

## 路由表（从 capabilities.yaml 编译）

| Skill | 触发词（中文） | 触发词（English） |
|-------|-------------|-----------------|
| project-analyzer | 分析项目、代码分析、项目审计、扫描项目、更新项目知识 | analyze codebase, scan project, project refresh |
| project-planner | 任务拆解、开发计划、需求分析、排期、估算工作量 | break down tasks, plan sprint, estimate effort |
| project-architect | 架构设计、技术选型、模块设计、系统设计、API 设计 | design architecture, tech stack, system design |
| project-generator | 写一个、实现、创建组件、开发、生成代码 | implement, create, build, generate code |
| project-tester | 写测试、测试用例、单元测试、集成测试、测试覆盖 | write tests, test cases, unit test |
| project-reviewer | 代码审查、review、检查代码、审查 PR、代码质量 | code review, security review, audit code |
| project-refactorer | 重构、优化结构、提取公共、简化代码、消除重复 | refactor, clean up, extract method, simplify |
| project-documenter | 生成文档、API 文档、组件文档、写文档、补文档 | generate docs, api docs, write documentation |
| project-releaser | 发布、上线、发版、release、changelog、版本号 | release, ship, deploy, version bump |

## 模糊意图处理

多 skill 命中时 → 按 `capabilities.yaml` 的 DAG 顺序推荐上游优先。不自动级联触发。
