# Session Snapshot v1.0

> 跨 Session 恢复。Claude 重启 ≠ 重来。借鉴 GSD Checkpoint 思想。

## 核心假设

LLM 一定会忘。不要让 LLM 一直记，让 Runtime 帮它记。

## Snapshot 格式

`.project-knowledge/.sessions/<skill>/state.json`：

```json
{
  "skill": "project-analyzer",
  "session_id": "20260807-093000",
  "status": "paused",
  "current_phase": 3,
  "phases": {
    "1_extraction": { "status": "completed", "completed_at": "..." },
    "2_verification": { "status": "completed", "completed_at": "..." },
    "3_cross_validation": { "status": "in_progress", "started_at": "..." },
    "4_knowledge_builder": { "status": "pending" },
    "5_index": { "status": "pending" },
    "6_classifier": { "status": "pending" },
    "7_instinct": { "status": "pending" },
    "8_promotion": { "status": "pending" }
  },
  "knowledge_extracted": {
    "architecture": true,
    "components": true,
    "patterns": true,
    "conventions": false,
    "glossary": false
  },
  "git_commit": "abc1234",
  "last_checkpoint": "2026-08-07T10:30:00Z"
}
```

## 写入时机

每个 Phase 完成后立即写入 snapshot：
```
Phase N 完成 → 更新 phases[N].status = completed
           → 更新 current_phase = N+1
           → 更新 knowledge_extracted
           → 写入 .project-knowledge/.sessions/<skill>/state.json
```

## Resume 流程

Skill 启动时第一步：

```
1. 检查 .project-knowledge/.sessions/<skill>/state.json 是否存在
2. 存在 + status = paused:
   a. 对比 git_commit: 代码是否变化？
      - 不变 → 从 current_phase 继续
      - 变了 → 警告用户，询问：重新开始 / 从当前 phase 继续
   b. 展示已完成 phases + extracted knowledge
   c. 用户确认 → 从 current_phase resume
3. 不存在或 status = completed → 正常启动
```

## Resume 指令

在 Skill 的 Discovery 阶段第一步执行：

```
🔍 检测到未完成的 Session:
   Skill: project-analyzer
   已完成: Phase 1-2 (extraction + verification)
   当前: Phase 3 (cross-validation)
   Knowledge: architecture ✅ components ✅ patterns ✅
   上次: 2026-08-07 10:30

   选项:
   ✅ 继续（从 Phase 3 开始）
   🔄 重新开始
   📋 查看详情
```

## 过期检测

- git_commit 不同 → ⚠️ 代码已变更，自动提取的 knowledge 可能过期
- last_checkpoint > 24h → ⚠️ Session 较旧，建议重新开始
- last_checkpoint > 7d → 🔴 Session 过期，建议重新开始

---

## Compaction Invariant（长 Skill 内对话被压缩）

Suite 是 **cross-skill stateless**：Skill 之间只靠 state/artifact/文件传递，不依赖对话历史。
但**单个长 Skill**（如 analyzer 扫数千文件）一次运行中，对话上下文会被 compaction 压缩。
规则只保证一件事——**「压缩不掉关键事实」**：

```
任何影响后续执行的关键事实，必须已持久化到下列存储之一；
不得仅存在于当前对话上下文（否则 compaction 即丢失）。
```

| 存储 | 存什么 | 载体 |
|------|--------|------|
| 执行位置 | phase 进度、subtask 状态 | snapshot / `manifest.json`（checkpoint） |
| 事实 / 为什么 | goal、assumptions、discoveries、反馈 | `runtime/memory/session.json` |
| 产出 | 已生成的 artifact 路径 | `.project-knowledge/` 产出文件 |

最小 survival set（**落盘才算数**）：

- current goal / completed / remaining work
- important discoveries / assumptions / open questions
- changed files 或产出路径
- 需复用的确切 command / path（含 exact errors，若后续执行要重试）

淘汰优先级（对话上下文内可安全丢弃）：

- stale tool output / 已确认的探索过程
- 重复 grep / read / 已被 artifact 取代的原始输出
- narration / chatter

**一句判据**：对话上下文可被 compaction；持久化事实不可丢失。recover 的信息载体是
state/artifact/session memory，不是「上次对话里我说过什么」。

> 不引入任何删除/压缩算法（不学 fast-jev 的淘汰逻辑、不建 Pi 式 compaction engine）。
> 本 invariant 只是「关键事实必须落盘」的纪律——与 memory-layer「让 Runtime 记，不让 LLM 记」一致。
