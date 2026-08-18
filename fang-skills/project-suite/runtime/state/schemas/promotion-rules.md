# Knowledge Promotion Protocol v1.0.0

> Candidate → Accepted 不是自动的。必须满足晋升规则。
> 一次出现叫代码，两次叫经验，三次才叫模式。

## 5 条晋升规则

Candidate 必须满足 **≥3/5** 才能晋升为 Accepted：

| # | 规则 | 判定方式 | 阈值 |
|---|------|---------|------|
| R1 | 重复出现 | 同一模式在 ≥2 个独立上下文中被使用 | ≥2 次 |
| R2 | 跨模块影响 | 模式被 ≥2 个不同模块引用/使用 | ≥2 模块 |
| R3 | Reviewer 确认 | Reviewer confidence > 阈值 | > 85 |
| R4 | 非一次性 | 不是纯业务逻辑、不是硬编码映射、不绑定特定 API 版本 | 人工判定 |
| R5 | 未来可复用 | 模式的抽象层级足够、无项目特定耦合、有清晰的使用边界 | 人工判定 |

## 逐条详解

### R1: 重复出现

```
不是"同一个文件被复制了 2 次"。
而是"同一个抽象模式在 2 个独立上下文中被采用"。

✅ 场景 A 用 upload pattern，场景 B 也用了 → R1 满足
❌ 同一个 upload 组件被 import 了 2 次 → 不算
```

判定来源：`knowledge.json` 中的 `occurrences` 字段。

### R2: 跨模块影响

```
✅ upload pattern 被 approvalManage 和 userManage 两个模块使用 → R2 满足
❌ upload pattern 只被 approvalManage 一个模块使用 → 不满足
```

判定来源：`graph.json` 中的 `findConsumers(nodeId)` 查询结果。

### R3: Reviewer 确认

```
Reviewer 对 Candidate 知识进行审查：
  - 模式是否正确描述了实现？
  - 有没有遗漏的边界条件？
  - 代码示例是否可运行？

Confidence > 85 → R3 满足
```

判定来源：Reviewer 的收尾报告（`REVIEW-<topic>.md`）中的 confidence。

### R4: 非一次性

```
❌ 非一次性:
  - "用户列表按首字母分组" → 纯业务逻辑
  - "调用 /api/v1/legacy/upload" → 绑定特定 API
  - "if status === 3 then show red" → 硬编码映射

✅ 可复用:
  - "文件上传：分片 + 进度 + 断点续传"
  - "列表页：搜索 + 分页 + 批量操作"
  - "表单提交：校验 + loading + 错误恢复"
```

判定：Generator 在 candidate 创建时标注 `one_off: true/false`。

### R5: 未来可复用

```
抽象层级足够高，不绑定特定项目：

✅ "Repository 模式：数据访问抽象层" → 任何项目可用
✅ "API 请求拦截器：token 刷新 + 错误统一处理"
❌ "某企业特定审批流" → 绑定特定业务
❌ "某数据库连接配置" → 绑定特定项目
```

判定：Architect 在 candidate review 时标注 `reusable: true/false`。

## 晋升流程

```
1. Generator 发现新模式 → 创建 candidate/{name}.md
   - 标注 one_off (R4)、occurrences (R1)
   
2. Reviewer 审查 candidate → 更新 confidence (R3)
   - 同时检查 graph.json 确认跨模块影响 (R2)
   
3. Architect 评估可复用性 (R5)

4. 满足 ≥3/5 → 自动标记为 accepted
   - 从 candidate/ 移动到 patterns/ 或 architecture/
   
5. 不满足 → 保留在 candidate/
   - 下次出现时重新评估
   - 超过 6 个月未晋升 → 标记为 deprecated
```

## 闭环工作流（Generator → Reviewer → Knowledge）

```
Generator:
  1. 完成代码生成
  2. 完成报告 → Candidate Discovery:
     - 标注首次出现的新模式
     - 标注 one_off / reusable
     - 写入 candidate/{name}.md
     - 更新 knowledge.json（status: Candidate, occurrences: 1）

Reviewer:
  3. 审查代码 + Candidate 知识:
     - 验证 Candidate 是否准确描述实现
     - 标注 confidence（满足 R3 需要 > 85）
     - 验证 graph.json 中的跨模块引用（R2）
  4. 更新 knowledge.json（confidence, verified）

Architect（可选，下次出现时触发）:
  5. 第二次出现 → 评估 R5（可复用性）
  6. 第三次出现 → 检查是否满足 ≥3/5 → 晋升 Accepted
     从 candidate/ → patterns/ 或 architecture/
```

## 知识库演化

```
初始: .project-knowledge/ 只有 analyzer 生成的基础知识
  ↓
每次 Generator → Reviewer 循环:
  - 新 Candidate 进入候选池
  - 已有 Candidate 获得第二次/第三次验证 → 晋升 Accepted
  - 低分 Accepted 被自然淘汰 → Deprecated
  ↓
结果: 知识库越来越精，不会越来越大
```

## ADR 准入标准

| 准入条件（满足任一） | 反例（不记录） |
|---------------------|--------------|
| 第一次出现的新架构模式 | 按钮位置调整 |
| 团队争论过（有 ≥2 个 Alternatives） | 单文件命名 |
| 未来可能重复决策 | 临时的 workaround |
| 影响 ≥2 个模块 | 单个组件的 prop 设计 |
| 影响超过一个版本 | 当前 sprint 内的临时方案 |
| 修改成本高（> 3 天回滚） | 可一键重构的代码 |
