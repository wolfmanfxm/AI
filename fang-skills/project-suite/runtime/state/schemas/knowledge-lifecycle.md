# Knowledge Lifecycle v2.0

> 核心问题不是"有没有知识"，而是"有没有长期复用价值"。
> **90% 的 Artifact 永远停留在第一层。** 这不是 bug，是筛选机制。

## 状态机

```
Artifact ────────────→ 任务结束即清理（~90%）
    │
    │ 首次出现 + 非一次性 + confidence ≥ 60
    ▼
Candidate ───────────→ 淘汰（6 个月未晋升）
    │
    │ 满足 Promotion Rules（≥3/5）
    ▼
Accepted ────────────→ Generator 优先读取
    │
    │ 不再适用
    ▼
Deprecated ──────────→ 保留历史，不再推荐
```

## 四个状态

| 状态 | 本质 | 占比 | 生命周期 | 谁可以读 |
|------|------|------|---------|---------|
| **Artifact** | 任务产物，不是知识 | ~90% | 单次任务 | 当前任务链 |
| **Candidate** | 候选知识，等待验证 | ~7% | 观察期（≤6月） | Planner、Architect（标注未验证） |
| **Accepted** | 正式知识，已验证 | ~2% | 长期 | 全部 Skill，Generator 优先 |
| **Deprecated** | 停止推荐 | ~1% | 永久（仅标记） | 不读取（仅供追溯） |

## Artifact：任务产物，不是知识

```
Artifact（任务结束即清理）:
  PLAN-*.md               → 执行完即归档
  REVIEW-*.md              → 修复后即过时
  收尾报告                 → 一次性执行摘要（名字由 skill 自定）
  implementation.md        → 任务结束即删除

这些不是知识。它们是执行记录。留在知识库里只会制造噪音。
```

## Candidate：候选知识

只有同时满足以下条件，Artifact 才进入 Candidate：

| 条件 | 说明 |
|------|------|
| 首次出现的模式/方案 | 之前 `.project-knowledge/` 中不存在同类 |
| 非一次性业务逻辑 | 不是硬编码映射、不是绑定特定 API 版本 |
| confidence ≥ 60 | 有基本可信度 |

```
Candidate（进入候选池等待验证）:
  candidate/upload-pattern.md      → 首次出现的上传模式
  candidate/repository-pattern.md  → 首次使用的数据访问方案
  candidate/api-gateway.md         → 跨模块的 API 设计
```

## Accepted：正式知识

Candidate 不是自动升级。必须满足 **≥3/5 条晋升规则**：

→ [promotion-rules.md](promotion-rules.md)

GoF 的思想：一次出现叫代码，两次叫经验，三次才叫模式。

```
项目 A: Upload 组件出现          → Candidate（首次，进入观察）
项目 B: Upload 组件又出现         → 观察中（2次，接近阈值）
项目 C: Upload 组件再次出现       → Accepted（3次，模式确认）
```

单次出现是巧合。多次出现才是可复用的模式。

## Candidate 强制执行规则（v1.2.0）

以下规则由 Runtime 校验，各 Skill 必须遵守：

### 读取规则

| Skill | Candidate 可读？ | 规则 |
|-------|:---:|------|
| Generator | ❌ | 只读 `Accepted`，Candidate 视为不存在 |
| Planner | ⚠️ | 可读但标注"⚠️ 未验证"，不能作为 Reuse Analysis 的推荐项 |
| Architect | ⚠️ | 可读但标注"⚠️ 候选模式"，不能用于技术选型依据 |
| Reviewer | ✅ | 唯一可验证 Candidate 并晋升为 Accepted 的 Skill |
| Tester | ❌ | 不读 Candidate |
| Documenter | ❌ | 不读 Candidate |
| Refactorer | ❌ | 不读 Candidate |
| Releaser | ❌ | 不读 Candidate |

### 晋升执行规则

Reviewer 执行时必须检查 Candidate 知识：

```
for each Candidate in knowledge.json:
  1. 验证 candidate 的 claims 是否与实际代码一致
  2. 评估 promotion_rules 满足几条（≥3/5 → 晋升）
  3. 标注验证 confidence（基于实际代码审查，非推断）
  4. 更新 knowledge.json：
     - 满足 ≥3/5 → status: "Accepted", promoted_at: now
     - 满足 <3/5 → 保持 Candidate，记录验证结果
     - claims 不实 → confidence 降为 0，标注 [REJECTED]
```

### 过期淘汰规则

| 状态 | 条件 | 动作 |
|------|------|------|
| Candidate | 6 个月内未被晋升 | 标记 Deprecated，reason: "expired" |
| Candidate | confidence < 40 且已验证 | 标记 Deprecated，reason: "low_confidence" |
| Candidate | 被 Reviewer 明确 REJECTED | 标记 Deprecated，reason: "rejected_by_reviewer" |

### knowledge-index.json 与 Candidate

`knowledge-index.json` 中只列出 `status: Accepted` 的 capability。
Candidate 知识不进入 index → Generator 通过 index 加载时自动过滤 Candidate。

## Deprecated：停止推荐

```
不再适用的场景:
  - Element UI 升级为 Ant Design → 旧组件模式标记 deprecated
  - 项目不再使用某技术栈          → 相关模式标记 deprecated
  - 被更好的模式替代              → 旧模式标记 deprecated

不删除。保留历史。Generator 不再读取，Reviewer 不再推荐。
```

## ADR 准入标准

不是所有决策都值得记录。五个月后还会有人问的才进入 ADR：

| 准入（满足任一） | 不记录 |
|-----------------|--------|
| 第一次出现的新架构 | 按钮位置、颜色选择 |
| 团队争论过（有 ≥2 Alternatives） | 单文件命名 |
| 未来可能重复决策 | 临时 workaround |
| 影响 ≥2 个模块 | 单组件 prop 设计 |
| 影响超过一个版本 | 当前 sprint 内的方案 |
| 修改成本高（>3 天回滚） | 可一键重构的代码 |

不存在 Alternatives 的决策 → 不是决策，是约束，记录在 Context 而非 ADR。

## knowledge.json 条目格式

```json
{
  "files": {
    "patterns/upload.md": {
      "status": "accepted",
      "occurrences": 3,
      "projects": ["acme-web", "crm-web", "vendor-portal"],
      "first_seen": "2026-03-15",
      "promoted_at": "2026-06-20",
      "promotion_rules_met": ["r1", "r2", "r3"],
      "score": 92,
      "usage_feedback": {
        "times_used": 12,
        "times_good": 11,
        "times_abandoned": 1
      }
    },
    "candidate/upload-pattern.md": {
      "status": "candidate",
      "occurrences": 1,
      "projects": ["acme-web"],
      "first_seen": "2026-07-20",
      "score": 65
    }
  }
}
```

## GC 策略（Deprecated → Purge）

Deprecated 条目何时可被物理删除的规则：

1. **Purge 条件**（全部满足才可删除）:
   - status = deprecated 超过 90 天
   - 最近 90 天内没有任何 Skill 查询过该条目
   - 不被任何 Accepted 条目的 `related_to` 引用

2. **Purge 流程**:
   ```
   Deprecated ──(90天+无引用+无查询)──→ Purge（物理删除）
   ```

3. **安全机制**:
   - Purge 前在 knowledge.json 的 `purge_log` 数组记录: file path + deprecated_at + purged_at + reason
   - 对应的 .md 文件移动到 `.project-knowledge/.archive/`（不立即删除，保留 30 天）
   - archive 超过 30 天 → 物理删除

4. **Candidate 淘汰**:
   - 补充已有的"6 个月未晋升"规则：Candidate 超过 180 天未满足 promotion rules → status 变为 expired → 从 knowledge.json 移除（不归档，因为从未被验证过）

5. **GC 触发时机**:
   - analyzer 全量执行时自动检查
   - 不设定时触发（避免依赖外部调度）

## 这套机制的本质

不是"生成知识库"。是建立一套**知识筛选与演化机制**。

```
输入: 每次 Skill 执行产生的所有 Artifact
过滤: 90% 任务结束即清理
候选: ~7% 进入 Candidate 观察
晋升: ~2% 通过 3/5 规则成为 Accepted
淘汰: ~1% 过时标记 Deprecated

输出: 始终保持精炼、高信噪比的 .project-knowledge/
```
