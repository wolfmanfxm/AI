# round19 产物清单

> 夹具根：`/Users/fangxiangming/.cache/ps-eval/round19`。所有结果均在此 `results/` 下；夹具本身零改动（仅 macOS `.DS_Store`）。

## 一、结论与报告

| 文件 | 内容 |
|---|---|
| `round19-suite.md` | suite 臂 12 次：运行方式、tool_use 审计表、逐臂结果、判定与建议 |
| `round19-naive.md` | naive 臂 12 次：审计表、逐臂结果、A/B 增量表 |
| `MANIFEST.md` | 本文件 |

## 二、原始输出

| 路径 | 内容 |
|---|---|
| `out/*.json` | suite 12 次的 `claude -p --output-format json` 原始结果（含 session_id、usage、subagent_stats） |
| `out-md/*.md` | 从上述 JSON 抽出的最终报告正文 |
| `out-naive/*.md` | naive 12 次子代理的 SubagentHandback 最终报告（从 transcript 原样抽出） |
| `usage.json` | 两臂 token/耗时/成本汇总（suite 12 次 + naive 12 次） |
| `logs/*.err` | suite 各次 stderr |
| `out-void/` | 作废的早期 pilot（真实仓 cwd，未计入 12 次） |

## 三、Prompt

| 路径 | 内容 |
|---|---|
| `prompts/{planner,reviewer-real,reviewer-clean,tester,delivery,routing}.txt` | suite 臂 prompt（与 round18 L2 模板同构，路径换 round19） |
| `prompts/naive-*.txt` | naive 臂 prompt（含「无 skill」禁令与污染自检行） |
| `run-one.sh`、`batch.sh` | suite 臂 runner（显式工具 allowlist，无 `--dangerously-skip-permissions`） |

## 四、审计

| 文件 | 内容 |
|---|---|
| `audit-all.jsonl` | suite 12 次 + 4 个 verifier 子代理的 tool_use 统计 |
| `audit-naive.jsonl` | naive 12 次的 tool_use 统计 |
| `/Users/fangxiangming/.cache/ps-eval/round19/audit/audit-transcript.py` | 原始审计脚本 |

复现审计：

```bash
# suite：顶层会话与 verifier transcript 已在 /tmp/ps-eval-audit19（软链），也可重建
python3 /Users/fangxiangming/.cache/ps-eval/round19/audit/audit-transcript.py /tmp/ps-eval-audit19 <session-or-agent-id>...

# naive：本会话子代理 transcript
cd ~/.claude/projects/-Users-fangxiangming--cache-ps-eval-round19/90619e9d-be44-4701-b57d-86dec4579108/subagents
python3 /Users/fangxiangming/.cache/ps-eval/round19/audit/audit-transcript.py . $(ls agent-*.jsonl | sed 's/^agent-//; s/\.jsonl$//')
```

（`audit-naive.jsonl` 即上述第二条命令的输出。）

## 五、证据

| 路径 | 内容 |
|---|---|
| `evidence/tester-suite/` | suite tester 写在 `/tmp/ps-eval-run19-tester/` 的测试与报告副本（naive 运行前存档） |

## 六、已知假阳性

- `audit-naive.jsonl` 中 `naive-delivery-r1` 的 2 条 `path_hits`：是该代理用 `python3 -c` 写自己报告时文本里含「project-suite」字样，不是读取 skill 文件。12 次 naive 均无 `Read/Bash/Grep` 实际触达 skill 路径。

## 七、交接位置

- 基准仓（给上一轮 session 读）：`~/Work/AI/fang-skills/project-suite-eval/benchmark/results/round19/`
  - `analysis.md`（结论与分析）
  - `run.yaml`（结构化记录）
  - `artifacts/`（本目录的完整副本，含 raw JSON、报告、prompt、audit、usage）
- 机制台账已更新：`~/Work/AI/fang-skills/project-suite-eval/mechanism-verification-ledger.md`
  （round19 章节 + planner/reviewer/tester/routing/delivery 各行状态）

## 八、附：reviewer-clean-v2 补测

15:09 由外部在本轮目录创建 `reviewer-clean-v2/`（白名单修复）+ `prompts/*-v2.txt` + `run-ro.sh`；其中 suite 尝试因 `--allowedTools` 未含 `Skill` 而未跑成（0 字节输出）。本轮用同一夹具补跑：

- `out-v2-addendum/reviewer-clean-v2-r1.json`（suite，Skill=1、Agent=1、BLOCKER=0、one-way 触发 QA）
- `out-naive/naive-reviewer-clean-v2-r1.md`（naive，Skill=0，同报 F1 HIGH，无 QA）
- 详见 `round19-suite.md` 附录与 `round19-naive.md` 附录。该补测**不计入** 12+12 主结果。
- ⚠️ 15:17 起另有 4 个 headless `claude -p` 进程在跑并覆写 `results/out/`（非本轮启动）。v2 结果已从 `out-void/reviewer-clean-v2-r1.raw.jsonl` 恢复到 `out-v2-addendum/`，不再依赖可能被覆写的 `out/`。

## 九、交接要点（给上一轮 session）

1. **planner 决策边界**：suite 2/2 停 CHECKPOINT（confidence 63–65%，D-001 A/B）；naive 2/2 自行决定「不做短信验证」并继续实现。→ 稳定增量。
2. **reviewer 独立 QA**：suite 4/4 用 `Agent` 派生 verifier（clean-r2 派 2 个），round18 的 2/6 派生率已修复；real-r1 的 verifier 撞 25-turn 上限，需 `SendMessage` resume，属执行摩擦。
3. **`reviewer-clean` v1 不是 0-BLOCKER 负对照**：8/8 运行（4 suite + 4 naive）都拒绝；suite 判 BLOCKER，naive 判 HIGH。原因：只去 query 信任、未加来源白名单，跨菜单详情页 403。**v2 白名单夹具补测（各 1 次）**：suite BLOCKER=0 + one-way 命中 + Agent 派生，恢复 round18 的决定性样本；但 v2 白名单漏 `contractAudit`，仍有 1 个 HIGH，干净负对照还需补齐白名单。
4. **`shared/scripts/complexity-gate.sh:96` 在 macOS bash 3.2 必崩**（`$is_simple` 后全角逗号 + `set -u`），routing 2/2 复现；属工具缺陷。
5. **tester / routing 维持装饰品判定；delivery 增量收窄**（naive 也会列「待补测」，但未把未证明项排除在 PASS 之外）。

## 五、v2 补测（2026-11-27 晚）

| 路径 | 内容 |
|---|---|
| `out-v2-retest/` | reviewer-clean-v2 的 2 suite + 2 naive（bare）原始 JSON；pre-fix 与非 bare 版本保留对照 |
| `out-v2-retest/changes.diff` | v2 白名单修复的 diff 快照 |
| `audit-v2-retest.jsonl` | 4 次运行的 tool_use 审计（suite：Skill=1 Agent=1；naive：Skill=0 Agent=0 零路径触达） |

结论：v2 夹具 4/4 运行 0 BLOCKER；suite 2/2 在 BLOCKER=0 时由 one-way 触发独立 QA，并 2/2 派生 verifier。

## 六、Routing L2 — R6（2026-11-27 晚）

| 路径 | 内容 |
|---|---|
| `out-r6/` | 自然语言「从分析到发布」的 2 次 headless 原始结果（session_id / cost） |
| `audit-r6.jsonl` | tool_use 审计：Skill=1、执行 complexity-gate、无 runtime-run.sh start、无额外 Skill 调用 |

结论：2/2 通过 symlink 真实加载 `pipeline-orchestrator`；Gate/Reuse/Decision Boundary 正确；未自建 Run、未自动级联。
