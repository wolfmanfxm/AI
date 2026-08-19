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
