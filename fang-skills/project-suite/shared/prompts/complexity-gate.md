# Complexity Gate Prompt — Shared Library v1.0.0

> 任务复杂度门。Pipeline 入口（orchestrator Discovery）用它决定走哪条路径。
> 目的：让简单任务不背 suite 全流程成本——简单任务固定开销占比最高，而「需求已覆盖」时复用判定可反杀省 token。

## 核心：先查复用，再定复杂度

```
Intent
  ↓
① Reuse Fast Path（先问：需求是否已被现有组件/模式完全覆盖？）
     → 是 → 直接 Reuse Check → 零改动（或 import 已有）→ 结束，不跑 pipeline。
     ↓ 否
② Complexity 分类（3 档，rubric 判）—— 同时决定 pipeline 和 Skill 深度
     ├─ trivial/simple → Quick Path：generator → verify（无 planner）—— 深度 minimal
     ├─ medium → Standard Path：planner → generator → reviewer —— 深度 standard
     └─ complex/long → Full Path：analyzer → planner → architect → generator → tester → reviewer —— 深度 full
                          ↑ 先判知识缺口（②b）：知识库已覆盖 → 跳过 analyzer → Knowledge Resolver → planner
```

## ① Reuse Fast Path（最优先，最省）

进入任何 pipeline 前，先做一次便宜的 [Reuse Check](../primitives/reuse-check.md)：
- 需求已被 `catalog.md` / `graph.json` 里现有组件**完整覆盖** → 直接 REUSE，零改动。
- 已有组件完整覆盖需求时，直接 REUSE 零改动，不新建冗余组件。

## ② Complexity 分类 rubric（便宜，几百 token）

| 档 | 信号（关键词/特征） | 例子 |
|----|--------------------|------|
| trivial/simple | 单文件小改、样式调整、加一个搜索项/筛选、删 import | 改按钮颜色、加状态筛选 |
| medium | 新增页面/组件、加一个功能、单模块内改动 | 新增登记页、加导出 |
| complex/long | 新模块、架构变更、重构、从零搭建、跨多模块、迁移 | 权限模块、全链路重构 |

**默认规则**：不确定 → 判 medium（宁可不省，也不误路由到过轻的路径）。
**升级规则**：
- simple 但涉及 domain 命名 / 新 API 契约 → 升 medium（需要 planner 的 Context Package）。
- medium 但含 ≥2 个独立子功能 / 新 API 契约 / 从零搭建 → 升 complex（Full Path，需 Analyzer + Architect）。

> ⚠️ `complexity-gate.sh` 是**零 token 关键词粗筛**，对「多子功能」「语义复杂度」有天然盲区（如「新增审批流配置页面」脚本判 medium，实际是 complex）。**脚本结果以 LLM 按 rubric 复核为准**——脚本省 token，LLM 保准确。

## ②b 知识缺口判定（Analyzer 只在缺知识时跑）

> Analyzer 是**知识缺口入口**，不是默认入口。Full Path 里在跑 Analyzer 前先判：

| 知识状态 | 判定 | 动作 |
|---------|------|------|
| `.project-knowledge/` 不存在 | 缺口 | 跑 Analyzer（首次分析） |
| 存在但**未覆盖当前领域**（graph.json 无对应模块） | 缺口 | 跑 Analyzer |
| 存在且覆盖，但 `last_scan` 过期 | 缺口（陈旧） | 跑 Analyzer 增量刷新 |
| 存在且覆盖、新鲜 | 无缺口 | **跳过 Analyzer** → Knowledge Resolver → Reuse → Planner/Generator |

典型场景：「已有 .project-knowledge，任务只是新增一个已有模式的页面」→ 知识够用，直接 Knowledge Resolver → Reuse → Planner/Generator，不重跑 10 个 Extractor。

## ③ 路由表（pipeline + 深度）

| 路径 | Pipeline | 深度 | 适用 |
|------|---------|------|------|
| Reuse Fast Path | reuse-check → 零改动 | — | 需求已覆盖 |
| Quick Path | generator → verify | **minimal** | trivial/simple |
| Standard Path | planner → generator → reviewer | **standard** | medium |
| Full Path | analyzer → planner → architect → generator → tester → reviewer | **full** | complex/long |

> 深度统一为 **minimal / standard / full** 三档。每个 skill 在 skill.yaml 声明 `depth_profiles`（simple→minimal, medium→standard, complex→full），并在 prompts 里定义该深度对本 skill 的具体含义（如 planner 的 minimal=只产 Goal/Scope/Tasks/AC、generator 的 minimal=跳过 Validation、reviewer 的 minimal=只审正确性+安全）。原则是**复杂度越低，深度越浅**——降 token 只靠少做事。

## 输出

```markdown
Complexity Gate 判定:
  复用判定: [REUSE | 未覆盖]
  复杂度: [trivial | simple | medium | complex | long]
  路由: [Reuse Fast Path | Quick | Standard | Full]
  深度: [无 | minimal | standard | full]
  理由: <一句话，基于信号>
```

## 执行器

- [shared/scripts/complexity-gate.sh](../scripts/complexity-gate.sh) — 确定性分类器。`bash complexity-gate.sh "<需求>"` → 复杂度 + 路由（零 token，关键词启发式 + 默认 medium）。

## 反例

| ❌ 反模式 | ✅ 正确做法 |
|-----------|-----------|
| 简单任务也走 full-sdlc | Quick Path：generator → verify |
| 不确定复杂度就拍 simple | 不确定 → medium |
| 需求已覆盖还跑 generator | Reuse Fast Path 零改动 |
