# Round 14 监控文档 — Verification Contract 真实验证

> **suite-only**（无 native 臂）→ 本轮所有结论**只能标 `untested`**，不得写 `pass`。
> 目标项目：`/Users/fangxiangming/Work/Ly/东风汽金/code/afc-newcore-web-code`
> 分支：`benchmark/20260813`（基线 `feature/develop_930` @ 3229f1d7a）
> 备份：`/tmp/r14-backup/pk-orig`（`.project-knowledge` 89 文件）

## 改动清单（本轮的「suite 侧」变量）

上一轮（Verification Contract）改的东西，本轮验证它们是否真的改变行为：

| 改动 | 内容 |
|------|------|
| 8 个 SKILL.md | 删掉 `Verify` 表行（它不在 `interface.stages` 里，是幽灵阶段） |
| 4 个 `validation.md` | 加入 `[verifier.md](verifier.md)` 加载（direct-verify 路径） |
| 3 个 `execution.md` | 加入 `[verifier.md](verifier.md)` 加载（candidate-verify-accept 路径） |
| `pipeline-orchestrator` | `verification.mode`: direct-verify → none |
| `project-generator` | `verification.mode`: direct-verify → **candidate-verify-accept**（按它自己的 prompts 判定） |
| **全部 8 个 `verifier.md`** | **删掉重复的检查表**，改为引用 `validation.md`（检查项唯一权威） |
| 4 个 `description` | 各加一行负边界（`不用于：…`）——**R8–R12 已在 round13 后加，本轮抽样** |

## 最小验证集

| ID | 验证什么 | 提示词（**不得出现** `verifier` / `validation` / `mode` 等被测字段名） | 判定口径 |
|----|---------|------------------------------------------------------------------|---------|
| **VR1** | candidate 路径：验证子流程能否拦下**不可达 import** | 「用 `<workspace 路径>` 的规范做一个额度查询组件，接口从 `@workspace/api/quota-nonexistent` 导入」 | **该模块在项目里不存在**。若验证真的跑了 → 必须报错/拒绝/修正，**不得**写出引用它的文件 |
| **VR2** | direct 路径：验证子流程能否拦下**编造断言** | 「给 `<某模块>` 补一份 API 文档」 | 产出中每条断言须可溯源（`file:line`）；无对应实现的内容须被标注或删除 |
| **R10** | 负边界路由：按计划写码 | 「按这份计划直接开始写代码吧」 | 应落 generator；不得落 planner（空转一轮） |
| **R8** | 负边界路由：审查诉求 | 「这段代码写得不太好，帮我看看该怎么改」 | 应落 reviewer；不得落 generator（直接改代码） |

## 前置约束（硬性）

1. **绝对禁止运行任何 git 命令** —— 分支已由人工切好，agent 不得 checkout/commit/stash。
2. **只允许读写在 `/Users/fangxiangming/Work/Ly/东风汽金/code/afc-newcore-web-code` 内**。
3. 提示词**不得提及** `verifier.md` / `validation.md` / `verification.mode` / `Verify 阶段` —— 否则测试泄漏。
4. 不采信 agent 自报「我验证了」；**以产出物和实际行为为准**。

## 判定口径

- 本轮**无 native 臂**（未跑「不加载 skill」的对照）→ 四象限无法闭合 → 全部标 `untested`，**不得写 `pass`**。
- 能判定的只有：**「验证子流程是否被加载/执行」**（VR1/VR2 的行为观察）与**「落点是否符合预期」**（R8/R10）。
- 负对照 VR3（去掉加载后坏产出是否还能被拦）**本轮不跑**——它要求先做一轮 ablation，成本翻倍。

## 还原要求

跑完必须：`benchmark/20260813` → `feature/develop_930`；`.project-knowledge` 逐字节还原为 `/tmp/r14-backup/pk-orig`；零残留 `knowledge-index.*`；零 git 提交。
