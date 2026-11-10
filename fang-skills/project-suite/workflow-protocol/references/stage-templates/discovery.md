# Stage Template: Discovery

> Suite 拥有（Protocol）。Skill 通过 `@template: discovery` 引用，只需提供 Actions/Exit/Failure。

## Task Resolution（Step 0 — 所有 Skill 强制，先于一切文件读取）

> 没有 task_id，就会读到别的任务的 session / context-package / snapshot。
> 权威协议：[task-identity.md](../../../runtime/mechanisms/task-identity.md)

```
1. 显式 task_id（参数或 $PS_TASK_ID）→ 先校验存在且可恢复（completed / abandoned 拒绝）
2. 用户说「继续 X」→ task-registry.sh list 按 goal 匹配
3. 恰好一个 active 任务，且请求目标与它的 goal 一致 → 使用（打印一行确认，不阻塞）
4. 恰好一个 active 任务，但请求目标是另一件事 → AskUserQuestion「继续 <旧 goal> / 新建」
5. 多个 active 任务 → 列出 id + goal + 最后活跃时间 → AskUserQuestion 选择（含「新建」）
6. 无 active 任务 → 记下待创建任务的 goal / slug；由随后的 runtime-run.sh start 创建
7. 用户确认本阶段输入后 → runtime-run.sh start（创建/恢复 Run + 单写者锁 + 运行指针）
   - 恢复旧任务 → `--task-id <id>`；确认新建 → `--new-task --goal <goal>`
   - Runtime **不会**自动复用唯一 active 任务：不给任务身份也不给 `--new-task` 会直接拒绝
```

Step 0 的 1–6 是**只读解析**；第 7 步才是登记（任何项目级写入之前）。

> **单一 active 任务 ≠ 当前用户意图。** 请求目标与任务 goal 不一致时不得自动接管，
> 否则昨天未关闭的任务会把今天的新需求吞掉。

**适用范围**：除 **Dispatcher 类 Skill**（`pipeline-orchestrator`）外的所有 Skill。
Dispatcher 不创建自己的 Run，也不调用 `runtime-run.sh start`；但它必须在 Discovery 里
**绑定一个目标 `task_id`**（选择已有任务，或经用户确认 goal 后 `task-registry.sh create`），
通过 `PS_TASK_ID` 传给后续 Skill。绑定 Task 不等于创建 Run。

此步完成前**禁止**写入任何任务级文件（session / context-package / snapshot / pipeline-state）。
任务级路径一律带 `<task_id>`，项目级（state.json / 知识目录 / analyzer 根产物）不带。

> **唯一入口**：`bash shared/scripts/runtime-run.sh start <project-root> --skill <name> (--task-id <id> | --new-task --goal ...)`
> 一次完成 task 恢复/创建 + 单写者锁 + 运行指针（见 workflow-protocol 的 Terminal Record）。
>
> **时序**：Task Resolution（只读）先于一切文件读取；**运行登记 `start` 在用户确认本阶段输入
> （范围 / 模式 / 目标）之后、任何项目级写入之前**执行。已有任务传 `--task-id`，新任务传
> `--new-task --goal`（必要时 `--slug`）。锁被占用 / stale → 🔴 BLOCKED，不得无锁写项目级知识。
>
> 正常运行由 Skill Discovery 调用；Host Hook **不创建 Task / Run**（它拿不到用户确认后的
> task / goal / 范围）。运行登记仍在 Discovery 内完成，**不能**等到 Delivery——否则中途退出
> 的运行在指标里不存在。

## Standard Contract

| Field | Value |
|-------|-------|
| Entry  | 用户触发 {skill_name} 需求（匹配触发词） |
| Input  | 参见 skill.yaml `interface.inputs` — P0 缺失则 BLOCKED |
| Output | `runtime/tasks/<task_id>/discovery.json` (status=discover) + 阶段确认产物（如任务级 `analysis-config.json` 草稿） |
| Recovery | 读 `runtime/tasks/<task_id>/discovery.json` → 若 status=discover 且产物已存在 → 跳过信息收集，直入 CHECKPOINT |

> ⚠️ Discovery **不写项目级 `manifest.json` / `analysis-config.json`**：
> 前者的 status 反映知识库状态（不是某次运行的阶段），后者是长期用户配置。
> 一次探针/取消不得改写它们；配置草稿在 Delivery 由 `analysis-config-merge.mjs` 合并（带备份）。

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

| Actions  | 1. Task Resolution（只读，确定沿用/新建任务） 2. 探测技术栈、目录结构、Vault 路径 3. AskUserQuestion 确认项目名/深度/范围 4. runtime-run.sh start（用确认后的 goal 登记 + 加锁） 5. 写任务级 discovery.json + analysis-config.json 草稿 |
| Exit     | framework identified, package manager identified, scope confirmed, 任务级配置草稿已写入（根 manifest/analysis-config 未改） |
| Failure  | 无 package.json → AskUserQuestion 手动指定框架; 权限不足 → 🔴 BLOCKED |
```
