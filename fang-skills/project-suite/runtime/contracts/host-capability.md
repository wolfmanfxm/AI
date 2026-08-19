# Host Capability Contract v1.0

> project-suite 是 **Agent-hosted Protocol Framework**：Suite 定义规则/状态/契约/建议；Agent Host 决定如何执行。
> 本契约诚实声明「Suite 提供 Protocol，不同 Host 提供不同程度的执行能力」——不假装 Suite 自己能强制。

## 定位

```
                project-suite
                      │
       ┌──────────────┼──────────────┐
       ↓              ↓              ↓
     Skills       Protocols      Contracts
       │              │              │
       └──────────────┼──────────────┘
                      ↓
                Agent Host
                      │
             ┌────────┼────────┐
             ↓        ↓        ↓
          Execute   Decide   Enforce

Suite 负责「应该发生什么」（Protocol/Contract）
Host  负责「实际怎么发生」（Execute/Decide/Enforce）
```

## 四层边界（跨 Agent 可移植）

> 「Skill 跨 Agent 可移植」。核心是 **Skill/Contract 不绑死某个 Agent Runtime**，通过 Host Adapter 隔离。

```
Skill（做什么）
  ↓ 声明 Contract（skill.yaml / interface）
Contract（需要什么、产出什么）
  ↓ Host Adapter（本 Host 怎么实现这个能力）
Host Adapter（如 Claude Code Hook）
  ↓
Agent Runtime（Claude / Cursor / Gemini CLI / Windsurf / OpenCode / ...）
```

**规则**：
- **Skill 和 Contract 层是 runtime 无关的**——不写「在 Claude Code 里」，只声明「需要 command_guard 能力」。
- **Host Adapter 层是 runtime 专属的**——每个 Agent Runtime 写自己的 adapter，复用同一份 Contract。
- **禁止 Skill → Claude Code API 直接耦合**——Skill 只到 Contract 层，Host Adapter 才接触具体 Runtime。

**当前 adapter**：[claude-code.md](../adapters/claude-code.md)（第一个 reference implementation）。换 Runtime 时，写新的 adapter，Skill/Contract 不改。

## Host Capability 字段

每个 Host 声明它对 Suite 协议的支持程度：

```yaml
host_capabilities:
  stage_progression: advisory | managed   # 阶段推进：建议 / Host 托管
  command_guard: advisory | enforced      # 命令护栏：建议 / 硬拦截
  convergence: advisory | enforced        # 收敛：建议 / 强制停止
  checkpoint: supported | unsupported     # CHECKPOINT：支持 / 不支持
  user_confirmation: supported | unsupported  # 用户确认：支持 / 不支持
```

| capability | advisory | managed / enforced / supported |
|-----------|----------|-------------------------------|
| stage_progression | Suite 建议阶段顺序，Agent 自行判断 | Host 按 stage contract 推进（ENTRY→EXIT） |
| command_guard | Suite 声明禁用什么，Agent 自行遵守 | Host 在 tool-call 层硬拦（如 Claude Code Hook） |
| convergence | Suite 声明「已做够」，Agent 自行决定是否停 | Host 读 next_action 强制停止/继续 |
| checkpoint | Suite 声明 CHECKPOINT 位置，Agent 自行处理 | Host 在 CHECKPOINT 处暂停等用户 |
| user_confirmation | Suite 建议询问用户，Agent 自行判断 | Host 提供 AskUserQuestion 机制 |

## Host 能力声明示例

### Claude Code（当前）

```yaml
host_capabilities:
  stage_progression: advisory
  command_guard: enforced          # 通过 PreToolUse Hook
  convergence: advisory
  checkpoint: supported            # 通过 AskUserQuestion
  user_confirmation: supported
```

### 裸 API / 自定义 Harness（理论）

```yaml
host_capabilities:
  stage_progression: managed       # harness 自己跑 stage 循环
  command_guard: enforced          # harness 拦截工具调用
  convergence: enforced            # harness 读 next_action 强制停
  checkpoint: supported
  user_confirmation: unsupported   # 无交互，全部 auto-approve
```

## 与 Suite 的关系

Suite 的协议**不因 Host 能力弱而失效**——Protocol 是「应该发生什么」，Host 是「实际怎么发生」。

- Host 能力弱（advisory）→ Suite 协议靠 agent 自觉遵守，可能不被执行
- Host 能力强（enforced）→ Suite 协议被硬执行

**关键**：Suite 不在文档里假装有强制能力。强制能力是 Host 的，Suite 只在协议里**声明期望**，由 Host 决定是否 enforce。诚实声明，不虚构 Enforced。

## 相关协议

| 协议 | 依赖的 Host capability |
|------|----------------------|
| [convergence.md](../../shared/primitives/convergence.md) | `convergence`（advisory 或 enforced） |
| [command-guard.md](../mechanisms/command-guard.md) | `command_guard`（advisory 或 enforced） |
| [stage 模板](../../workflow-protocol/references/stage-templates/) | `stage_progression`（advisory 或 managed） |
| [approval-framework.md](../mechanisms/approval-framework.md) | `checkpoint` + `user_confirmation` |
