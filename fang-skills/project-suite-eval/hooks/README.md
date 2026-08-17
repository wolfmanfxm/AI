# Command Guard 接线（Claude Code Adapter）

> 这是 project-suite 的 Command Guard 在 **Claude Code** 上的「接线」，**不属于 project-suite 本体**。
> 可移植的规范/脚本在 [project-suite/runtime/engine/command-guard.md](../../project-suite/runtime/engine/command-guard.md) + [command-guard.sh](../../project-suite/shared/scripts/command-guard.sh)。

## 为什么放这里，而不是 project-suite 里

`command-guard.sh`（脚本）+ `command-guard.md`（规范）+ `adapter-registry.yaml`（声明）是**可移植的**——它们定义了「拦什么、怎么拦」，跟哪个宿主无关。

而本目录的 `command-guard-hook.sh` 是 **Claude Code 的 PreToolUse Hook**，它负责「在 Claude Code 每次 Bash 调用前，调 command-guard.sh」。这是**环境接线**：

```
                        ┌── project-suite 本体（可移植）
                        │   command-guard.md（规范）
                        │   command-guard.sh（脚本）
                        │   adapter-registry.yaml（blocklist/allowlist 声明）
                        │
Claude Code Bash 调用 ──┤
                        │   ┌── 环境 adapter（本目录，Claude Code 专属）
                        │   │   command-guard-hook.sh（PreToolUse Hook）
                        │   │   settings.example.json（挂载示例）
                        │   └── guard-events.json（BLOCK 审计）
                        │
                        └── provider 真正执行
```

换到裸 API / 别的 harness，写另一个 adapter（复用同一个 command-guard.sh），本目录不改。

## 三件产物

| 文件 | 作用 |
|------|------|
| `command-guard-hook.sh` | PreToolUse Hook 脚本：读 Claude Code 事件 JSON → 抽 command → 跑 command-guard.sh → 输出 block/allow 决策 |
| `settings.example.json` | 挂载示例（照抄进 settings.json，但**别全局挂**，见下） |
| `README.md` | 本契约文档 |

## 怎么接线（当你要真上时）

1. 把 `settings.example.json` 里的 `hooks.PreToolUse` 段复制进你的 `settings.json`（或 `.claude/settings.local.json`）。
2. **不要全局挂载**——它会拦掉你自己的 `git checkout` 清理、refactorer 的 commit、releaser 的 `git log`。要么只在 benchmark 上下文挂，要么给 allowlist 放行（见 command-guard.sh 的 ALLOWLIST）。
3. 挂好后，任何 `git checkout / reset / clean / stash / commit / push / merge ...` 都会被 hook 拦（输出 `{"decision":"block"}`），只读的 `git status / diff / log` 放行。

## Demo 验证（本会话已跑）

```
输入: {"tool_name":"Bash","tool_input":{"command":"git checkout -- ."}}
输出: {"decision":"block","reason":"BLOCK (改写工作树/历史): git checkout -- . ..."}
```

证明「能拦」。真上生产时，拦截动作由 Claude Code 执行（hook 返回 block → Claude Code 不执行该 Bash），并写 `guard-events.json` 审计。

## 边界（诚实标注）

- 本 hook 是**规范层的接线**，验证「能拦」。它没有接入一个「真正的 Runtime Engine」——`runtime/` 目前是 Protocol/Spec，不是 Engine。真正运行时拦截，靠 Claude Code 的 Hook 机制 + 宿主分类器兜底。
- 与 Complexity Gate 的关系：Gate 是「Skill 内决策协议」（orchestrator Discovery 强制跑），Command Guard 是「Tool-call 边界硬拦」。两者都在「执行边界」，但一个是软路由、一个是硬拦截。
