# Stage Contract

> 每个 Stage 的结构化契约格式。**此规范的权威实现是 [stage-templates/](stage-templates/)。**
> Skill 不直接写 7 字段，而是通过 `@template: <stage>` 引用模板，只写 Actions/Exit/Failure。

## 7 字段 Contract

每个 Stage 必须包含以下 7 个字段：

| Field | 含义 | 必须 | 示例 |
|-------|------|------|------|
| **Entry** | 进入条件：什么触发这个阶段 | ✅ | 用户触发 / 上游阶段 Exit 满足 |
| **Input** | 消费的数据/文件 | ✅ | analysis-config.json / PLAN.md / 项目源码 |
| **Actions** | 执行动作（编号列表） | ✅ | 1. 探测技术栈 2. spawn agent 3. 写入文件 |
| **Output** | 产出的数据/文件 | ✅ | .md 文件 / manifest 更新 / context.json |
| **Exit** | 退出条件：必须满足才能进入下一阶段 | ✅ | framework identified, scope confirmed |
| **Failure** | 失败模式 + 处理策略 | ✅ | agent timeout → retry once; 权限不足 → BLOCKED |
| **Recovery** | 中断后恢复策略 | ✅ | 读 manifest → 跳过 completed → 执行 pending |

## 示例

### 示例 1：Analyzer 的 Discovery Stage

```markdown
### Stage: Discovery

| Contract | Detail |
|----------|--------|
| Entry    | 用户触发分析需求（"分析项目"/"扫描项目"等触发词） |
| Input    | Project Root（工作目录） |
| Actions  | 1. 探测技术栈（package.json/tsconfig/vite.config） 2. 探测目录结构 3. 探测 Knowledge Vault 路径 4. AskUserQuestion 确认项目名/深度/范围/输出位置 5. 写入 analysis-config.json + manifest.json |
| Output   | analysis-config.json, manifest.json (status=discover) |
| Exit     | framework identified, package manager identified, scope confirmed, config written |
| Failure  | 无 package.json → AskUserQuestion 手动指定框架; 权限不足 → 🔴 BLOCKED |
| Recovery | 读 manifest.json → 若 status=discover 且 config 已存在 → 跳过探测，直接进入 CHECKPOINT |
```

### 示例 2：Generator 的 Execution Stage

```markdown
### Stage: Execution

| Contract | Detail |
|----------|--------|
| Entry    | Discover 完成，改动范围已确认 |
| Input    | context-package.json, PLAN.md, ARCHITECTURE.md（若存在）, graph.json |
| Actions  | 1. 读知识库 → 提取 patterns/constraints/components 2. Graph 查询 → 确认可复用组件/API 3. 找类似实现 → 提取代码模式 4. 套用模式生成代码 5. 自检（import 正确性/组件复用/TS 类型/linting） |
| Output   | 代码文件（扩展名按项目技术栈）+ completion-report.md |
| Exit     | 所有文件写入成功，自检清单全部通过 |
| Failure  | 目标文件已存在 → diff 后增量修改; 需新增依赖 → 使用已有替代; 无类似实现 → 标注"⚠️ 全新模式" |
| Recovery | manifest.subtasks 标记每个文件的生成状态，resume 时跳过已生成文件 |
```

### 示例 3：Planner 的 Validation Stage

```markdown
### Stage: Validation

| Contract | Detail |
|----------|--------|
| Entry    | Execution 完成，9 模块 PLAN.md 已生成 |
| Input    | PLAN.md（完整内容）, context.json |
| Actions  | 1. 检查 9 模块完整性（无缺失 section） 2. 检查依赖无循环 3. 检查 AC 可验证（每条 AC 有明确的 pass/fail 条件） 4. 检查 Decision↔Task 绑定完整 5. QA Agent: spawn 独立 agent 检查逻辑一致性 |
| Output   | validation-report.md |
| Exit     | 无 CRITICAL 发现，或所有 CRITICAL 已修复 |
| Failure  | 模块缺失 → 返回 Execution 补全; AC 不可验证 → 标注并降级为 MEDIUM; 依赖循环 → 🔴 BLOCK |
| Recovery | 读 validation-report.md → 仅重新检查之前 FAIL 的项 |
```

## 反模式

| # | ❌ 反模式 | ✅ 正确做法 |
|---|---------|-----------|
| 1 | Exit 写成 "Done" 或 "完成" | 写具体的、可验证的条件：`framework identified, scope confirmed` |
| 2 | Failure 写 "失败则重试" | 写具体的失败场景 + 对应处理：`agent timeout → retry once; 返回空 → 标注 FAILED` |
| 3 | Recovery 写 "重新开始" | 写具体的恢复路径：`读 manifest → 跳过 completed → 从 CHECKPOINT 恢复` |
| 4 | Actions 写成一段散文 | 用编号列表，每步一个动作 |
| 5 | 省略 Input/Output | 每个 Stage 必须有明确的输入和输出，这是阶段间数据流的契约 |
