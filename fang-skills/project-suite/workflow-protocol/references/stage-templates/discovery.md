# Stage Template: Discovery

> Suite 拥有（Protocol）。Skill 通过 `@template: discovery` 引用，只需提供 Actions/Exit/Failure。

## Task Resolution（Step 0 — 所有 Skill 强制，先于一切文件读取）

> 没有 task_id，就会读到别的任务的 session / context-package / snapshot。
> 权威协议：[task-identity.md](../../../runtime/mechanisms/task-identity.md)

```
1. 显式 task_id（参数或 $PS_TASK_ID）→ 使用
2. 用户说「继续 X」→ task-registry.sh list 按 goal 匹配
3. 恰好一个 active 任务 → 使用（打印一行确认，不阻塞）
4. 多个 active 任务 → 列出 id + goal + 最后活跃时间 → AskUserQuestion 选择
5. 无 active 任务 → task-registry.sh create（非 planner 类 Skill 见 task-identity.md 的回退规则）
```

此步完成前**禁止**写入任何任务级文件（session / context-package / snapshot / pipeline-state）。
任务级路径一律带 `<task_id>`，项目级（state.json / 知识目录 / analyzer 根产物）不带。

## Standard Contract

| Field | Value |
|-------|-------|
| Entry  | 用户触发 {skill_name} 需求（匹配触发词） |
| Input  | 参见 skill.yaml `interface.inputs` — P0 缺失则 BLOCKED |
| Output | manifest-<skill>.json (status=discover) + 阶段确认产物（如 analysis-config.json） |
| Recovery | 读 `runtime/tasks/<task_id>/manifest-<skill>.json` → 若 status=discover 且产物已存在 → 跳过信息收集，直入 CHECKPOINT |

## Custom Fields (Skill Must Provide)

| Field | Description |
|-------|-------------|
| **Actions** | 本 Skill 在 Discovery 阶段的具体步骤（编号列表） |
| **Exit**    | 本阶段退出条件（可验证的断言，如 `framework identified, scope confirmed`） |
| **Failure** | 本阶段失败场景 + 处理策略（用 `→` 连接条件与动作） |

## CHECKPOINT

Discovery 完成后必须 CHECKPOINT → [checkpoint-pattern](../../../shared/conventions/checkpoint-pattern.md)

用户的确认是本阶段的 Gate：未确认 → 不可进入下一阶段。

## 示例：Analyzer 的 Discovery

```markdown
### Stage: Discovery
@template: discovery

| Actions  | 1. 探测技术栈、目录结构、Vault 路径 2. AskUserQuestion 确认项目名/深度/范围 3. 写入 analysis-config.json + manifest.json |
| Exit     | framework identified, package manager identified, scope confirmed, config written |
| Failure  | 无 package.json → AskUserQuestion 手动指定框架; 权限不足 → 🔴 BLOCKED |
```
