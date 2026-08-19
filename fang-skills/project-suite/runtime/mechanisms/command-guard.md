# Command Guard — Runtime v1.0

> 统一命令护栏。Tool Call 执行前拦截，把「禁 git」从 LLM 级 Prompt 约束升级为确定性 Runtime 边界。
> 实证：agent 曾试图 `git checkout -- .`（尽管 SKILL.md 写了禁止），被宿主分类器兜底拦截——证明 prompt 约束不可靠，需要 Runtime 级硬护栏。

## 原则

1. **Prompt 是前置，Guard 是兜底**：SKILL.md 的「禁止 git」提醒 agent 别浪费 turn；Command Guard 拦截真正执行，两层保留。
2. **权威黑名单在 Guard 一处**：所有 Skill 不再各自写 git 黑名单，避免漂移。
3. **Guard 可移植**：换到没有宿主分类器的环境（裸 API / 别的 harness），Guard 依然是唯一硬边界。

## 拦截流程

```
Tool Call (Bash command)
   ↓
Command Guard
   ├─ 命中 blocklist → BLOCK（返回错误，提示用 Edit/Write 代替）
   ├─ 命中 allowlist → ALLOW（只读命令）
   └─ 其他 → ALLOW
```

## Git 黑名单（首例，权威定义）

| 类别 | 命令 | 处置 |
|------|------|------|
| 改写工作树 | `git checkout` / `git reset` / `git clean` / `git restore` / `git rm` | 🔴 BLOCK |
| 改写历史/暂存 | `git stash` / `git revert` / `git commit` / `git add` | 🔴 BLOCK |
| 推送 | `git push` | 🔴 BLOCK |
| 只读 | `git status` / `git diff` / `git log` / `git branch` / `git rev-parse` | ✅ ALLOW |

> 注：releaser 读 `git log`（changelog 合成）并在回滚方案里**文档化** `git revert` 命令（供人工执行，非自己执行）的场景，由 profile 或 workflow 显式放行，见 [gates.yaml](../config/gates.yaml)。refactorer 已改用 Edit 反向回滚，不再依赖 git。

## Skill 侧约定

SKILL.md 的职责边界只写一句：`git 由 [Runtime Command Guard](command-guard.md) 管控，改写工作树/历史的命令一律 BLOCK`，不再重复黑名单。

## 执行器

- [shared/scripts/command-guard.sh](../../shared/scripts/command-guard.sh) — 确定性拦截器。`bash command-guard.sh "<cmd>"` → BLOCK/ALLOW；`--exit` 让 BLOCK 时 exit 1（供 pipeline 直接拦）。黑名单与 adapter-registry.yaml 的 `git.guard.blocklist` 同步。

## 拦截钩子（Host 集成点）

> Guard 不是孤立的脚本，而是 Host 在「每次 Bash 工具调用前」的强制前置拦截点。这是把 #4 从「脚本」变成「运行时边界」的最后一环。

```
Skill 声明工具调用（@adapter:* 或直接 Bash）
   ↓
[adapter-protocol](../tool-adapters/adapter-protocol.md) 解析 provider
   ↓
🔒 Command Guard 钩子（本节）
   ├─ 非 git 命令 → 放行
   ├─ git 只读（allowlist）→ 放行
   └─ git 改写（blocklist / 未列明 git）→ BLOCK
        ├─ 返回错误给 Skill（提示用 Edit/Write 代替）
        └─ 记录 guard-event → guard-events.json（审计）
   ↓
provider 执行
```

### 钩子契约

| 项 | 约定 |
|----|------|
| 挂载点 | Host 的 tool-call dispatch 层（scheduler → tool-adapter 之间），每次 Bash 调用前 |
| 判定 | 调 `command-guard.sh "<cmd>" --exit`，exit 1 = BLOCK |
| BLOCK 行为 | 不执行命令，返回错误，追加 `guard-events.json`（`{ts, cmd, verdict}`） |
| 放行名单 | profile/workflow 显式放行（refactorer/releaser 合法用 git）见 [gates.yaml](../config/gates.yaml) |
| 兜底 | 宿主环境无此钩子时，靠宿主分类器兜底 |

## 反例

| ❌ | ✅ |
|----|----|
| 每个 SKILL.md 各自写 git 黑名单 | 一处 Guard + 一句引用 |
| agent 试图 `git checkout -- .` 清理改动 | Guard BLOCK，提示用 Edit 改回 |
