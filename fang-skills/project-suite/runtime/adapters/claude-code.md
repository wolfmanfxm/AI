# Claude Code Host Adapter（Reference Implementation）

> 第一个 reference host implementation。展示 Claude Code 如何通过自身机制落实 [host-capability.md](../contracts/host-capability.md) 声明的能力。
> 这是**参考实现**，不是唯一实现。其他 Host（裸 API / 自定义 harness）可写自己的 adapter，复用同一份 host-capability 契约。

## 能力实现对照

| capability | Claude Code 声明 | 实现机制 |
|-----------|-----------------|---------|
| `stage_progression` | advisory | 无强制——Skill 的 SKILL.md/prompts 建议阶段顺序，Agent 自行判断推进 |
| `command_guard` | **enforced** | PreToolUse Hook（`command-guard-hook.sh`）拦截 git checkout/reset/commit 等，tool-call 层硬拦 |
| `convergence` | advisory | 无强制——Agent 读 convergence 字段自行决定是否 handoff，Claude Code 不拦 |
| `checkpoint` | supported | `AskUserQuestion` 工具实现 CHECKPOINT 暂停等用户 |
| `user_confirmation` | supported | `AskUserQuestion` 原生支持 |
| `run_lifecycle` | **supported（推荐启用）** | `claude-code-lifecycle-hook.sh`：**Start 由 Skill Discovery 执行**；SessionEnd 只对本 session 且身份已知的指针执行 `finish --auto-finalized`；PreToolUse(Write) 校验锁归属 |

## command_guard 的实现（enforced 的例子）

这是 Claude Code 第一个「enforced」的能力，展示「Host 如何把 advisory 协议变成硬拦」：

```
Claude Code Bash 调用
  → PreToolUse Hook（command-guard-hook.sh）
  → 读事件 JSON → 提取 command
  → 调 command-guard.sh（可移植脚本）判断
  → block → 返回 {"decision":"block"}，Claude Code 不执行该 Bash
  → allow → 放行
```

**分层**：
- `command-guard.sh`（project-suite 本体 `shared/scripts/`）— 可移植，声明「拦什么」
- `command-guard-hook.sh`（Host adapter）— Claude Code 专属，把脚本接进 PreToolUse 机制
- 换到裸 API / 别的 harness，写另一个 adapter，复用同一个 command-guard.sh

## 其他 capability 为什么是 advisory

Claude Code 对 stage_progression / convergence / checkpoint 都是 advisory（建议），不是 enforced。原因：

1. **这些是「决策」不是「危险操作」**——推进阶段、handoff 下游、暂停确认，本质是「该不该继续」的判断，Agent 自行判断通常无害。
2. **command_guard 是「危险操作」**——git checkout/reset 会破坏工作树，必须硬拦。
3. **区分原则**：危险操作（破坏性命令）→ enforced；决策（推进/暂停）→ advisory。

## 挂载方式（参考）

```json
// .claude/settings.local.json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "bash /path/to/command-guard-hook.sh" }
        ]
      }
    ]
  }
}
```

> 只在 benchmark 上下文挂载，不全局挂——否则会拦掉用户自己的 git 操作。

## run_lifecycle 的实现（Host 兜底例子）

协议要求「每条退出路径恰好一行终态记录」，但纯 prose 约束在换模型 / 上下文压缩后会静默失效
（实测：一次 monitor-only 运行在 Discovery 结束，timeline 里 0 行）。Host 兜底：

> **单一入口**：`runtime-run.sh start` 的正常调用者只有 **Skill Discovery**。
> Hook 不创建 Task / Run——它拿不到用户最终确认的 task / goal / 范围，抢先登记会落
> `Run <skill>` 脏任务并与 Task Resolution 竞争。Hook 只负责**异常收尾**与写入边界检查。

```json
// <project>/.claude/settings.local.json —— 项目级挂载，不要写进全局 settings
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Write|Edit|MultiEdit",
        "hooks": [{ "type": "command",
                    "command": "bash <suite>/shared/scripts/claude-code-lifecycle-hook.sh" }] }
    ],
    "SessionEnd": [
      { "hooks": [{ "type": "command", "timeout": 10,
                    "command": "bash <suite>/shared/scripts/claude-code-lifecycle-hook.sh" }] }
    ]
  }
}
```

| 事件 | 行为 | 失败时 |
|------|------|--------|
| `SessionEnd` | **本 session 且指针有 `sessionId`** → `finish --session-id <id> --auto-finalized`（记 `degraded` + `context.autoFinalized`）；session 缺失或指针无 sessionId → 不代收，保留给人工恢复 | 静默忽略 |
| `PreToolUse(Write/Edit)` | 写项目级真相文件（graph/manifest/statistics/…）且：指针 session 未知、指针属于别的 session，或指针在、锁丢了 → `permissionDecision: deny` | 无指针时一律放行 |
| `UserPromptExpansion` / `PreToolUse(Skill)` | **不登记运行**（no-op）。可以挂载做日志或上下文注入，但不得创建 Task / Run | 静默放行 |

> ⚠️ **不要用 `Stop` 做收尾**：`Stop` 在每一轮助手回复结束时都会触发，不是会话结束。
> 长任务在两轮之间会被误判为已结束、释放单写者锁。Claude Code 的会话级收尾是 `SessionEnd`
> （默认 1.5s 预算，脚本头部示例里给了 `"timeout": 10`）。
>
> 拒绝格式用现行的 `hookSpecificOutput.permissionDecision = "deny"`；顶层的
> `{"decision":"block"}` 对 `PreToolUse` 已弃用（仍被接受，但在 transcript 里显示成 hook error）。

**边界**：
- **Start 不由 Hook 创建**：Task / Run 的登记只发生在 Skill Discovery；Hook 只做异常收尾和写入边界检查
- 只在本项目挂载；全局挂载会替用户自己的编辑做判断
- 没有 `.project-knowledge/` → no-op
- 任务级 / `runtime/` / `reports/` / `proposals/` 写入永不拦截
- **不是绝对的写入互斥**：只覆盖 `Write/Edit/MultiEdit`，拦不住 Bash / PowerShell / 脚本写入。
  真正的单写者协议仍依赖 Skill 在写前 `runtime-run.sh renew`；Hook 是 Host 层辅助检查
- 锁被 break 后的 deny 是**可恢复**的：`runtime-run.sh finish` 或重新 `acquire`，不是死锁
- 并发 session：运行指针记录 `sessionId`；`SessionEnd` 只收本 session 的 run，
  写项目级知识时若锁属于另一个 session（或 session 未知）也会 deny——单写者不能靠「两个 session 都自觉」

## 相关

- 契约：[host-capability.md](../contracts/host-capability.md)
- 可移植脚本：[command-guard.sh](../../shared/scripts/command-guard.sh)
- Host adapter 脚本：`command-guard-hook.sh`（外部 eval 仓库，见 [eval-contract.md](../../docs/eval-contract.md)）
