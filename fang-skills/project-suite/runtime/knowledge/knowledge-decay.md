# Knowledge Decay v0（planned）

> Status: **planned**（暂未实现，不是可用能力）
> Producer: **Knowledge Health Producer（planned / not implemented）**
> Consumer: **none**
>
> ⚠️ 这是「知识**可信度衰减**」生命周期（Stable → Stale → Decaying → Deprecated），
> **区别于**「知识**晋升**」生命周期（Artifact → Candidate → Accepted → Deprecated，
> 见 [../state/schemas/knowledge-lifecycle.md](../state/schemas/knowledge-lifecycle.md)）。
> 两者都叫 lifecycle，但维度不同：**晋升 = 证据/人工确认后的知识采纳**，**衰减 = 随时间或验证缺失而降低信任**。

## 目标

判断知识还值不值得信：`Stable → Stale → Decaying → Deprecated`。

## 为什么暂缓

可靠输入不存在——`last_verified` / `stability` / `decay_score` **没有任何 Producer 写入**。

当前 `.md` frontmatter 只有 `last_scan`（analyzer 的扫描时间），不是「人类最后验证时间」，
**不能作为 decay 依据**。用扫描时间推断知识衰减是「假运行能力」：200 天没扫描 ≠ 知识失效。

## 两个 health 概念（明确分开，不混淆）

| 产物 | 含义 | 输入 | 状态 |
|------|------|------|------|
| `knowledge-health.json` | **质量健康**：broken_link / empty_document / duplicate / evidence | analyzer Phase D 扫描 .md | ✅ 已实现 |
| `.lifecycle/health.json` | **可信度衰减**：last_verified / stability / decay_score | 无 Producer | ⏸️ planned |

**不要把 `knowledge-health.json`（质量）暗示成 decay（可信度）输入——两者来源不同。**

## 未来契约（预留插槽，现在不生成）

```
.project-knowledge/
├── knowledge-index.json        ← Knowledge Compiler 产出（结构索引，不掺 decay 字段）
├── context-package.json        ← Knowledge Resolver 产出
└── .lifecycle/
    └── health.json             ← 未来 Knowledge Health Producer 产出（decay/trust）
```

```json
{
  "version": 1,
  "entries": {
    "decision:foo": {
      "state": "stable",
      "last_verified": "2026-08-20",
      "source": "decisions/foo.md"
    }
  }
}
```

> `state` 取值就是衰减状态机：`stable` / `stale` / `decaying` / `deprecated`。
> `last_verified` 是**输入事实**（时间戳），不是状态；状态由 Producer 依据输入算出。

## Resolver 的消费规则（明确，避免伪能力）

- `health.json` **存在且通过 schema validation** → Resolver 消费，做降级（stale→warning / decaying→非 blocking / deprecated→排除）
- `health.json` **缺失或非法** → 按不存在处理，Resolver 正常行为，**不推断 decay**（损坏的 health.json 不污染 Resolver）

## 职责边界

| 模块 | 职责 | 产物 |
|------|------|------|
| Knowledge Compiler | 编译成可消费索引 | `knowledge-index.json` |
| Knowledge Resolver | 取出当前任务需要的知识 | `context-package.json` |
| Knowledge Health Producer（未来） | 判断知识可信度（decay） | `.lifecycle/health.json` |

> 旧 `check-decay.sh` 已废弃（依赖从未产出的 `knowledge-graph.yaml`）；
> 旧 `runtime/mechanisms/decay.md` 已删除（它描述了一个从未实现的「Decay Engine」，与当前 planned 状态冲突）。
> 本能力待有可靠 Producer 后再落地。
