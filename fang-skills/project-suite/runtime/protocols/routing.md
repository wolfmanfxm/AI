# Intent Routing v0.8.0

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

## 路由规则（优先级从高到低）

1. **显式命名** — 用户输入 `/project-X` 或明确说"用 project-X" → 直接路由，跳过所有判断
2. **精确触发词匹配** — 用户消息包含 `skill.yaml` 的 `triggers_cn`/`triggers_en`
3. **上下文续执行** — 存在 manifest 且 status != completed → 续执行当前 skill
4. **语义路由** — 用户意图与 skill description 最匹配（LLM 判断）
5. **回退链** — 以上均未命中 → 进入回退流程（见下方）

## 多命中优先级

当多个 skill 同时匹配用户意图时，按以下规则消歧：

| 优先级 | 规则 | 示例 |
|--------|------|------|
| P0 | 用户显式指定 `/project-X` | `/project-reviewer` → 无条件 reviewer |
| P1 | 精确触发词 > 上下文续执行 > 语义匹配 | "代码审查" 精确命中 reviewer，即使上下文在 generator |
| P2 | 同为精确匹配时，上游 DAG 优先 | analyzer > planner > architect > generator > tester > reviewer > refactorer > documenter > releaser |
| P3 | 同一 DAG 层级时，触发词匹配数量多的优先 | "分析项目代码" 命中 analyzer 2 词 vs reviewer 0 词 |

## 歧义意图消歧表

用户表达模糊时，按下表默认路由并检查修正条件：

| 模糊意图 | 候选 skill | 默认路由 | 修正条件 |
|----------|-----------|----------|----------|
| "帮我改一下代码" | generator / refactorer / reviewer | generator | 含"优化/简化/整理" → refactorer；含"检查/审查/看看" → reviewer |
| "这个功能有问题" | tester / reviewer | reviewer | 含"测试/跑一下/验证" → tester |
| "帮我看看这个项目" | analyzer / reviewer | analyzer | 含"代码质量/安全/审查" → reviewer |
| "我要上线" | releaser / tester | releaser | 含"先测一下/回归" → tester |
| "帮我整理一下" | refactorer / documenter | refactorer | 含"文档/说明/注释" → documenter |
| "我要开始做了" | planner / generator | planner | 已有 PLAN.md → generator |
| "架构需要调整" | architect / refactorer | architect | 含"重构/抽取/合并" → refactorer |

## 上下文感知路由

读取 `.project-runtime/state.json`，根据上一个 skill 的执行状态推荐下一步：

| 上一个 skill | 状态 | 推荐下一步 | 理由 |
|-------------|------|-----------|------|
| analyzer | completed | planner 或 architect | 分析完成，进入规划或设计阶段 |
| planner | completed | architect 或 generator | 计划就绪，可设计架构或直接开发 |
| architect | completed | generator | 架构确定，开始实现 |
| generator | completed | tester 或 reviewer | 代码写完，需要测试或审查 |
| tester | completed | reviewer 或 refactorer | 测试通过后审查或优化 |
| reviewer | completed | refactorer 或 releaser | 审查通过后可优化或发布 |
| 任意 skill | partial / interrupted | 同一 skill（续执行） | 未完成任务优先恢复 |

> 推荐不等于自动触发。提示用户"上次 X 已完成，建议接下来 Y"，由用户决定。

## 路由示例

### 示例 1：精确触发
- **输入**: "帮我分析一下这个项目的代码结构"
- **路由**: project-analyzer
- **理由**: "分析项目" + "代码" 精确命中 analyzer 触发词

### 示例 2：上下文续执行
- **输入**: "继续"
- **state.json**: `{ "last_skill": "project-generator", "status": "partial" }`
- **路由**: project-generator（续执行）
- **理由**: 存在未完成任务，上下文续执行优先级高于语义匹配

### 示例 3：歧义消解
- **输入**: "这段代码写得不太好，帮我优化一下"
- **候选**: generator / refactorer / reviewer
- **路由**: project-refactorer
- **理由**: "优化" 触发消歧表修正条件，从默认 generator 修正为 refactorer

### 示例 4：多命中 DAG 排序
- **输入**: "帮我看看这个模块，需要重新设计一下"
- **候选**: analyzer（"看看"）/ architect（"设计"）
- **路由**: project-analyzer
- **理由**: 同为精确匹配，analyzer 在 DAG 中位于 architect 上游

### 示例 5：显式指定绕过路由
- **输入**: "/project-tester 帮我检查代码"
- **路由**: project-tester
- **理由**: 用户显式命名，虽然"检查代码"语义更接近 reviewer，但 P0 规则直接路由

## 回退链

当所有路由规则均未命中时（无触发词匹配、无上下文、语义置信度低）：

1. **候选排序** — 基于用户输入的语义相似度，选出 Top-3 候选 skill
2. **询问用户** — 通过 `AskUserQuestion` 展示候选列表，格式如下：
   ```
   无法确定最佳匹配，以下 skill 可能相关：
   1. project-generator — 生成/实现代码
   2. project-refactorer — 重构/优化现有代码
   3. project-reviewer — 审查代码质量
   请选择编号，或描述你想做什么。
   ```
3. **学习反馈** — 用户选择后，将"用户原始输入 → 最终 skill"记录到 `state.json` 的 `routing_history`，供后续语义路由参考

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
