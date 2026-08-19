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

## command_guard 的实现（enforced 的例子）

这是 Claude Code 唯一「enforced」的能力，展示「Host 如何把 advisory 协议变成硬拦」：

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

## 相关

- 契约：[host-capability.md](../contracts/host-capability.md)
- 可移植脚本：[command-guard.sh](../../shared/scripts/command-guard.sh)
- Host adapter 脚本：`project-suite-eval/hooks/command-guard-hook.sh`（外部 eval 仓库）
