# Round 15 分析 — VR2 干净重跑（suite 臂 vs native 臂）

> 目的：round14 的 VR2 因主试方在 agent 运行中还原而被判**受污染**，本轮重跑取干净证据，
> 并补上 round14 缺的 **native 臂**以闭合四象限。
> 目标项目 `afc-newcore-web-code`，分支 `benchmark/20260813`（本轮**未中途改动工作区**）。
> 备份 `/tmp/r15-backup`；还原在**两个 agent 都回报之后**执行，并做了二次验证。

## 结果：**本轮没跑出 suite 臂 —— 两臂都没有调用任何 skill**

| | Arm A（"suite"） | Arm B（native） |
|---|---|---|
| 是否使用 skill | **否** | **否**（被明确要求不用，已确认） |
| 产出 | 597 行 / 33,403 字节 | 377 行 / 29,303 字节 |
| `file:line` 引用（总/唯一） | 213 / 186 | 199 / 154 |
| 推断标注 | 15 处 | 7 处 |
| 自建校验脚本 | 有（Python，191/191 通过） | 有（bash，170/170 通过） |

（上表为**独立核验**所得，非采信自报。）

**Arm A 的原话**：

> **没有使用任何 skill。** 全程未调用 Skill 工具。可用列表里有 `project-documenter`（描述正是"补 API 文档"），我没用它，直接按任务要求手动读源码写的。

## 这个结果比原问题更靠前

`project-documenter` 的 description 字面写着「生成文档、写文档、补文档、**API 文档**、README…」，
而任务就是「给 `src/api/OrgUserRelationManagement` 补一份 **API 文档**」——**字面完全命中**。
agent 明确说它在可用列表里**看到了**这个 skill，**选择不用**。

**含义**：本轮（以及 round14）投入的 Verification Contract，治理的是「skill 被加载**之后**发生什么」
（验证子流程从哪个 stage 加载、`verification.mode` 怎么决定加载点、检查项唯一权威是谁）。
而这里 **skill 根本没被加载** → 那套契约**根本没有机会生效**。

> **瓶颈在入口，不在内部验证。** 一个从未被进入的 skill，其内部的验证契约再严密也等于零。
> 这与 SUITE_SPEC §0.1 的原则同构，但方向相反：§0.1 管的是「声明了但执行路径上没有入口」，
> 这里管的是「**有入口但没人走**」。

## 归因必须留白（n=1，且不是路由场景）

**不能**据此断言「路由坏了」——本轮不是路由场景：我给的是一份完整任务描述，
没有让 agent「判断该用谁」。它的选择空间是「用 skill 还是直接做」，而不是「用哪个 skill」。

一个可供下一轮检验的**假设**（n=1，勿当结论）：

> **任务描述越完整具体，agent 越倾向跳过 skill 直接做。**
> 旁证：round14 的 R8 给的是**短且模糊**的诉求（「这段代码写得不太好，帮我看看该怎么改」），
> agent 主动加载了 `project-reviewer`；本轮给的是**完整任务描述**，两臂都不加载。

## 意外收获：一份可复用的 native baseline

两个 native 样本独立产出、质量可比，且**都独立发现了同一批真实源码问题**：

- `src/api/OrgUserRelationManagement/index.ts:201` 的 `params?: an`（未定义标识符，`strict:true` 下应为类型错误）
- `secure: true` / `format: 'json'` 在 `src/utils/service/` 全目录**零消费**（历史字段）
- `showUserApiPurviewUsingGet` / `showApiUserPurviewUsingGet` **URL 完全相同**

可作为后续 round 的 native 基线参照。

## 两臂都自建了校验脚本，且都抓出了自己的行号错误

- Arm A：肉眼数 `sed` 输出 → **约 15 处行号错**（普遍差 1–3 行），自建 Python 脚本后全部修正
- Arm B：自建 bash 脚本，**第一版写错产生 125 条假失败**（`case` 漏 `esac`、zsh 不做词分割），用 bash 重跑后才 0 bad

> 佐证与本会话主题同构的一条：**「看起来能溯源」不等于「溯源正确」**。
> 两份文档在自建校验之前，肉眼都无法发现行号偏移；而**校验脚本本身也会写错**（Arm B 的 125 条假失败）。

## 判定

| 项 | 判定 |
|----|------|
| VR2（direct-verify 路径验证子流程） | **仍未判定**——本轮没进入 skill，契约无从生效 |
| 「任务越具体越跳过 skill」假设 | 待检验（n=1，round14 R8 为旁证） |
| native baseline（文档任务） | 已有 2 个干净样本，可复用 |
| Verification Contract 整体 | `untested`（入口未触发，内部机制未被触及） |

**本轮净结果**：没有推进 Verification Contract 的判定，但**发现了一个更上游的问题**——
需要先回答「skill 在什么条件下才会被加载」，否则内部机制的验证没有意义。

## 还原

```
分支 feature/develop_930 ｜ HEAD 3229f1d7a（与备份一致）｜ 未提交 0
.project-knowledge 逐字节一致 ｜ 残留 knowledge-index.* 0 ｜ docs/ 内容恢复原状
还原后二次验证（立即 + 20s 后复查）均通过
```
