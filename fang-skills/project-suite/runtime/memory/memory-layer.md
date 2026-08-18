# Memory Layer v1.0

> 四级持久记忆。Skill 间传递"是什么"（state.json/knowledge.json）和"为什么"（memory）。

## 四级记忆

| Level | 存活时间 | 存什么 | 存在哪 |
|-------|---------|--------|--------|
| **Session** | 当前会话 | 本次执行的上下文、中间产出、用户反馈 | `.project-runtime/memory/session.json` |
| **Project** | 项目生命周期 | 架构决策、已知约束、团队约定 | `.project-runtime/memory/project.json` |
| **Suite** | 跨项目 | 通用模式、最佳实践、学习到的规则 | `runtime/memory/suite.json` |
| **Decision** | 永久 | 为什么做某个决策（ADR的"为什么"部分） | `.project-runtime/memory/decisions/<id>.json` |

## Session Memory

```json
{
  "session_id": "20260804-153000",
  "skill": "project-planner",
  "context": {
    "goal": "价格调整审批",
    "user_feedback": ["范围确认通过", "增加撤销审批功能"],
    "assumptions": ["假设审批流程为两级", "假设价格T+1生效"]
  },
  "discoveries": ["发现已有 <审批流模块> 可复用"],
  "open_questions": ["审批撤回是否需要通知申请人？"]
}
```

下游 Skill（architect/generator）读取 Session Memory 了解"用户说了什么"和"做了什么假设"——不用重新问。

## Project Memory

```json
{
  "project": "my-web-app",
  "constraints": {
    "framework": "<框架> <版本>",
    "ui_library": "<组件库> <版本>",
    "typescript": "strict mode",
    "package_manager": "pnpm"
  },
  "conventions": {
    "component_style": "<组件范式>",
    "form_pattern": "<统一表单封装> + <表单字段>/<表单字段>",
    "table_pattern": "<统一表格> + <schema表格>",
    "api_pattern": "export function + <响应类型>"
  },
  "known_gotchas": [
    "<api 目录> 按模块组织,不是按类型",
    "分页参数名/类型以项目为准(可能不同平台不同)"
  ],
  "architectural_decisions": ["ADR-001-knowledge-first"],
  "last_updated": "2026-08-04"
}
```

Analyzer 生成后写入，下游 Skill 直接读——不重新分析。

## Suite Memory

```json
{
  "version": "1.0.0",
  "patterns_learned": {
    "crud": {
      "files_needed": ["<列表页>.<ext>", "<详情页>.<ext>", "<api 模块>.<ext>", "<类型>.<ext>"],
      "typical_structure": "<统一表格> + <schema搜索> + <schema表格> + <统一表单封装> dialog"
    },
    "approval_flow": {
      "pages": ["申请列表", "申请表单", "审批列表", "审批详情"],
      "api": ["submit", "approve", "reject", "history"]
    }
  },
  "cross_project_insights": [
    "某项目的 <审批流模块> 可复用到其他审批场景",
    "cms 模式的 json-driven 表单比手写更灵活"
  ]
}
```

跨项目积累——框架学到的通用知识。

## Decision Memory

```json
{
  "id": "D-20260804-001",
  "skill": "project-architect",
  "decision": "新价格调整模块放在 pricingManage/ 而非扩展 approvalManage/",
  "context": "approvalManage 已有 133 文件，排名 top 5；价格调整是独立业务域",
  "alternatives": [
    { "option": "扩展 approvalManage", "rejected_because": "模块过大，耦合增加" },
    { "option": "新建 billingManage", "rejected_because": "太泛，未来可能包含非价格功能" }
  ],
  "chosen": "新建 pricingManage/",
  "consequences": { "new_module": true, "reuse": ["<审批流模块>"], "risk": "审批流集成需确认" },
  "timestamp": "2026-08-04T15:30:00Z",
  "status": "accepted",
  "revisited_at": null
}
```

记录每个架构决策的"为什么"——下次遇到类似场景，不用重新权衡。

## 读取优先级

Skill 启动时按以下顺序加载 Memory：

```
1. Session Memory → 了解当前上下文（最高优先）
2. Project Memory → 了解项目约束（analyzer 已分析）
3. Decision Memory → 了解为什么之前那样决策
4. Suite Memory → 通用最佳实践（最低优先）
```

## 写入时机

| Memory | 谁写 | 何时 |
|--------|------|------|
| Session | 任何 Skill | CHECKPOINT 时写入用户反馈 + 发现 |
| Project | analyzer | 分析完成后写入约束 + conventions |
| Decision | architect | 每个 ADR 决策写入 |
| Suite | (手动/跨项目聚合) | 识别到跨项目通用模式时写入 |

## 与 state.json / knowledge.json 的关系

```
state.json     → "做了什么事"（执行历史）
knowledge.json → "有什么知识"（知识生命周期）
memory/        → "为什么这样做"（上下文+决策）
```
