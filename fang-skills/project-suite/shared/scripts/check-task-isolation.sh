#!/bin/bash
# Task Isolation Check v1.0
#
# 串行回归：任务 A → 任务 B → 回到 A。
# 这是最高频、可确定性复现的失败路径（不需要真并发）。
#
# 断言：
#   1. task-registry 创建/解析/歧义处理
#   2. Session Memory 按 task_id 隔离（B 写入不污染 A）
#   3. Context Package 按 task_id 隔离（resolver --task）
#   4. Session Snapshot 按 task_id × skill 隔离
#   5. state.json history 可同时保留两个 task_id
#   6. writer-lock 单写者：占用 / 拒绝 / owner 校验 / stale / break
#
# Usage: bash shared/scripts/check-task-isolation.sh
# Exit:  0 = 通过；1 = 有断言失败
set -euo pipefail

# 测试必须自己控制 session 身份：Claude Code 会把真实 session id 注入子进程，
# 不清掉会让「不传 --session-id」的用例意外带上宿主的 session。
unset CLAUDE_CODE_SESSION_ID CLAUDE_SESSION_ID

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SUITE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
REG="$SCRIPT_DIR/task-registry.sh"
LOCK="$SCRIPT_DIR/writer-lock.sh"
COMPILER="$SCRIPT_DIR/knowledge-compiler.sh"
RESOLVER="$SCRIPT_DIR/knowledge-resolver.sh"
APPEND="$SCRIPT_DIR/timeline-append.sh"
STATS="$SCRIPT_DIR/timeline-stats.mjs"

red()   { echo -e "\033[31m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }
PASS=0; FAIL=0
pass() { green "  ✅ $1"; PASS=$((PASS+1)); }
fail() { red   "  ❌ $1"; FAIL=$((FAIL+1)); }
assert_eq() { if [ "$2" = "$3" ]; then pass "$1"; else fail "$1 (expected '$3', got '$2')"; fi; }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/task-isolation.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
KD="$TMP/.project-knowledge"

# ---------------------------------------------------------------------------
echo "=== 1. task registry：创建 / 解析 / 歧义 ==="
TASK_A="$(bash "$REG" create "开发用户审批功能" --slug user-approval --skill project-planner --dir "$KD")"
TASK_B="$(bash "$REG" create "开发订单管理功能" --slug order-management --skill project-planner --dir "$KD")"
[ -f "$KD/runtime/tasks/$TASK_A/meta.json" ] && pass "任务 A 目录已创建 ($TASK_A)" || fail "任务 A 目录缺失"
[ -f "$KD/runtime/tasks/$TASK_B/meta.json" ] && pass "任务 B 目录已创建 ($TASK_B)" || fail "任务 B 目录缺失"
[ "$TASK_A" != "$TASK_B" ] && pass "两个任务 task_id 不同" || fail "task_id 冲突：$TASK_A"

set +e
bash "$REG" resolve --dir "$KD" >/dev/null 2>&1; R=$?
set -e
assert_eq "多 active 任务时 resolve 返回 2（禁止猜）" "$R" "2"
assert_eq "显式 resolve A" "$(bash "$REG" resolve "$TASK_A" --dir "$KD")" "$TASK_A"
assert_eq "PS_TASK_ID 覆盖" "$(PS_TASK_ID="$TASK_B" bash "$REG" resolve --dir "$KD")" "$TASK_B"

# ---------------------------------------------------------------------------
echo "=== 2. Session Memory 按 task_id 隔离 ==="
mkdir -p "$KD/runtime/tasks/$TASK_A" "$KD/runtime/tasks/$TASK_B"
cat > "$KD/runtime/tasks/$TASK_A/session.json" <<'EOF'
{"session_id":"s-a","task_id":"TASK_A_ID","skill":"project-planner",
 "context":{"goal":"开发用户审批功能","user_feedback":["两级审批"],"assumptions":["假设审批为两级"]},
 "discoveries":[],"open_questions":[]}
EOF
cat > "$KD/runtime/tasks/$TASK_B/session.json" <<'EOF'
{"session_id":"s-b","task_id":"TASK_B_ID","skill":"project-planner",
 "context":{"goal":"开发订单管理功能","user_feedback":[],"assumptions":["假设订单支持批量操作"]},
 "discoveries":[],"open_questions":[]}
EOF
A_GOAL="$(node -e 'console.log(require(process.argv[1]).context.goal)' "$KD/runtime/tasks/$TASK_A/session.json")"
B_GOAL="$(node -e 'console.log(require(process.argv[1]).context.goal)' "$KD/runtime/tasks/$TASK_B/session.json")"
assert_eq "A 的 goal 未被 B 覆盖" "$A_GOAL" "开发用户审批功能"
assert_eq "B 的 goal 独立" "$B_GOAL" "开发订单管理功能"

# ---------------------------------------------------------------------------
echo "=== 3. Context Package 按 task_id 隔离 ==="
cat > "$KD/knowledge-index.json" <<'EOF'
{"schemaVersion":"2.0.0","generatedBy":"fixture","generatedAt":"2026-11-09T00:00:00Z",
 "capabilities":{"patterns":{"files":[
   {"source":"patterns/table.md","type":"pattern","priority":1,"confidence":92,"summary":"DataTable + schema 表格","tags":["table"]}
 ]}}}
EOF
mkdir -p "$KD/patterns"
cat > "$KD/patterns/table.md" <<'EOF'
---
summary: DataTable + schema 表格
confidence: 92
---
# 表格模式
EOF
bash "$RESOLVER" "$KD" "" --task "$TASK_A" >/dev/null
bash "$RESOLVER" "$KD" "" --task "$TASK_B" >/dev/null
[ -f "$KD/runtime/tasks/$TASK_A/context-package.json" ] && pass "A 的知识包落在任务目录" || fail "A 知识包缺失"
[ -f "$KD/runtime/tasks/$TASK_B/context-package.json" ] && pass "B 的知识包落在任务目录" || fail "B 知识包缺失"
[ ! -f "$KD/context-package.json" ] && pass "未再写根级 context-package.json" || fail "仍写根级 context-package.json（污染源）"
A_HASH="$(md5 -q "$KD/runtime/tasks/$TASK_A/context-package.json" 2>/dev/null || md5sum "$KD/runtime/tasks/$TASK_A/context-package.json" | cut -d' ' -f1)"
# 重新生成 A 之前先把 A 内容改成可辨识，确认 B 的生成不影响 A
node -e 'const fs=require("fs");const p=process.argv[1];const j=JSON.parse(fs.readFileSync(p));j.marker="A";fs.writeFileSync(p,JSON.stringify(j))' "$KD/runtime/tasks/$TASK_A/context-package.json"
bash "$RESOLVER" "$KD" "" --task "$TASK_B" >/dev/null
A_MARK="$(node -e 'console.log(require(process.argv[1]).marker||"")' "$KD/runtime/tasks/$TASK_A/context-package.json")"
assert_eq "B 重新生成后 A 的知识包未被覆盖" "$A_MARK" "A"

bash "$RESOLVER" "$KD" "" >/dev/null
[ -f "$KD/context-package.json" ] && pass "无 task 时保留 legacy 根路径（向后兼容）" || fail "legacy 回退丢失"

# ---------------------------------------------------------------------------
echo "=== 4. Session Snapshot 按 task_id × skill 隔离 ==="
mkdir -p "$KD/.sessions/$TASK_A/project-planner" "$KD/.sessions/$TASK_B/project-planner"
printf '{"skill":"project-planner","task_id":"%s","status":"paused","current_phase":3}\n' "$TASK_A" \
  > "$KD/.sessions/$TASK_A/project-planner/state.json"
printf '{"skill":"project-planner","task_id":"%s","status":"paused","current_phase":1}\n' "$TASK_B" \
  > "$KD/.sessions/$TASK_B/project-planner/state.json"
A_PHASE="$(node -e 'console.log(require(process.argv[1]).current_phase)' "$KD/.sessions/$TASK_A/project-planner/state.json")"
B_PHASE="$(node -e 'console.log(require(process.argv[1]).current_phase)' "$KD/.sessions/$TASK_B/project-planner/state.json")"
assert_eq "A 恢复到 Phase 3" "$A_PHASE" "3"
assert_eq "B 恢复到 Phase 1" "$B_PHASE" "1"

# ---------------------------------------------------------------------------
echo "=== 5. state.json history 保留两个 task_id ==="
cat > "$KD/runtime/state.json" <<EOF
{"phase":"planning","status":"in_progress",
 "active_tasks":{"$TASK_A":{"skill":"project-planner","status":"in_progress"},
                 "$TASK_B":{"skill":"project-planner","status":"in_progress"}},
 "history":[{"task_id":"$TASK_A","skill":"project-planner","status":"completed","at":"2026-11-09T10:00:00Z"},
            {"task_id":"$TASK_B","skill":"project-planner","status":"completed","at":"2026-11-09T10:05:00Z"}],
 "blockers":[]}
EOF
HIST="$(node -e 'const s=require(process.argv[1]);console.log(s.history.map(h=>h.task_id).join(","))' "$KD/runtime/state.json")"
assert_eq "history 两条都在且各带 task_id" "$HIST" "$TASK_A,$TASK_B"
ACTIVE="$(node -e 'console.log(Object.keys(require(process.argv[1]).active_tasks).length)' "$KD/runtime/state.json")"
assert_eq "active_tasks 能表达多个并行任务" "$ACTIVE" "2"

# ---------------------------------------------------------------------------
echo "=== 6. writer-lock 单写者约束 ==="
set +e
bash "$LOCK" "$KD" analyzer acquire --owner-id A >/dev/null 2>&1; R1=$?
bash "$LOCK" "$KD" analyzer acquire --owner-id B >/dev/null 2>&1; R2=$?
set -e
assert_eq "A 获取 analyzer 锁" "$R1" "0"
assert_eq "B 被拒绝（occupied）" "$R2" "1"
set +e
bash "$LOCK" "$KD" analyzer release --owner-id B >/dev/null 2>&1; R3=$?
set -e
assert_eq "B 不能释放 A 的锁" "$R3" "3"
bash "$LOCK" "$KD" analyzer release --owner-id A >/dev/null
set +e
bash "$LOCK" "$KD" analyzer status >/dev/null 2>&1; R4=$?
set -e
assert_eq "释放后状态为 unlocked" "$R4" "4"

# stale：TTL 过期（锁持有者是 Skill 会话，不是短命 shell 进程，不能用 pid 判活）
mkdir -p "$KD/.locks/analyzer.lock"
printf 'owner_id=dead\npid=999999\nhostname=%s\nstarted_at=x\nstarted_epoch=%s\nttl_seconds=3600\n' \
  "$(hostname)" "$(( $(date +%s) - 7200 ))" > "$KD/.locks/analyzer.lock/owner.env"
set +e
bash "$LOCK" "$KD" analyzer acquire --owner-id C >/dev/null 2>&1; R5=$?
set -e
assert_eq "TTL 过期 → stale（需显式 break）" "$R5" "2"
bash "$LOCK" "$KD" analyzer break --force >/dev/null 2>&1
set +e
bash "$LOCK" "$KD" analyzer acquire --owner-id C >/dev/null 2>&1; R6=$?
set -e
assert_eq "break 后可接管" "$R6" "0"
bash "$LOCK" "$KD" analyzer release --owner-id C >/dev/null

# ---------------------------------------------------------------------------
echo "=== 7. timeline.jsonl：append-only（并发不丢行 / 坏记录不落盘） ==="
TL="$KD/runtime/metrics/timeline.jsonl"
rm -f "$TL"
mkdir -p "$KD/runtime/metrics"

append_one() { # <task_id> <skill> <startedAt>
  local rec
  rec=$(printf '{"taskId":"%s","skill":"%s","status":"completed","timing":{"startedAt":"%s","finishedAt":"2026-11-09T10:01:00Z","durationMs":60000},"quality":{"confidence":80}}' "$1" "$2" "$3")
  printf '%s' "$rec" | bash "$APPEND" "$TMP" - >/dev/null
}

# 20 次追加交错跑（两个任务各 10 次），每次是独立进程 + 独立 O_APPEND 打开
i=0
while [ "$i" -lt 10 ]; do
  append_one "$TASK_A" project-planner "2026-11-09T10:00:$((10 + i))Z" &
  append_one "$TASK_B" project-generator "2026-11-09T10:00:$((30 + i))Z" &
  i=$((i + 1))
done
wait

assert_eq "并发追加 20 行无丢失" "$(wc -l < "$TL" | tr -d ' ')" "20"
assert_eq "20 行全部是完整 JSON" \
  "$(node -e 'const fs=require("fs");let ok=0;for(const l of fs.readFileSync(process.argv[1],"utf8").split("\n")){if(!l.trim())continue;try{JSON.parse(l);ok++}catch{}}console.log(ok)' "$TL")" "20"
assert_eq "taskId 归属正确（A=10, B=10）" \
  "$(node -e 'const fs=require("fs");const c={};for(const l of fs.readFileSync(process.argv[1],"utf8").split("\n")){if(!l.trim())continue;const r=JSON.parse(l);c[r.taskId]=(c[r.taskId]||0)+1}console.log(c[process.argv[2]]+","+c[process.argv[3]])' "$TL" "$TASK_A" "$TASK_B")" "10,10"
assert_eq "runId 每次运行唯一（不能只用 taskId）" \
  "$(node -e 'const fs=require("fs");const s=new Set();for(const l of fs.readFileSync(process.argv[1],"utf8").split("\n")){if(l.trim())s.add(JSON.parse(l).runId)}console.log(s.size)' "$TL")" "20"

# 坏记录：status 非法 → exit 2，且不写半条
set +e
printf '%s' '{"taskId":"'"$TASK_A"'","skill":"project-planner","status":"ok","timing":{"startedAt":"2026-11-09T10:00:00Z","finishedAt":"2026-11-09T10:01:00Z"},"quality":{"confidence":80}}' | bash "$APPEND" "$TMP" - >/dev/null 2>&1; BAD1=$?
set -e
assert_eq "非法 status 被拒绝（exit 2）" "$BAD1" "2"
assert_eq "坏记录未落盘（仍 20 行）" "$(wc -l < "$TL" | tr -d ' ')" "20"

# 缺 taskId 且无 PS_TASK_ID → exit 2（禁止把无主 run 写进项目账本）
set +e
printf '%s' '{"skill":"project-planner","status":"completed","timing":{"startedAt":"2026-11-09T10:00:00Z","finishedAt":"2026-11-09T10:01:00Z"},"quality":{"confidence":80}}' | env -u PS_TASK_ID bash "$APPEND" "$TMP" - >/dev/null 2>&1; BAD2=$?
set -e
assert_eq "缺 taskId 被拒绝（exit 2）" "$BAD2" "2"

# 未知顶层字段必须在写盘前被拒绝：schema 是 additionalProperties:false，
# 旧 writer 放行 reason/notes 等自造字段 → 行能落盘却过不了 schema（探针实测）。
set +e
printf '%s' '{"taskId":"'"$TASK_A"'","skill":"project-planner","status":"completed","timing":{"startedAt":"2026-11-09T10:00:00Z","finishedAt":"2026-11-09T10:01:00Z"},"quality":{"confidence":80},"reason":"self-invented field"}' | bash "$APPEND" "$TMP" - >/dev/null 2>&1; BAD3=$?
set -e
assert_eq "未知顶层字段被拒绝（exit 2）" "$BAD3" "2"
assert_eq "未知字段未落盘（仍 20 行）" "$(wc -l < "$TL" | tr -d ' ')" "20"

# skipped 是合法状态：运行在产出前结束（monitor-only / 用户取消），不代表失败。
SKIP_ROOT="$TMP/skip-proj"
mkdir -p "$SKIP_ROOT/.project-knowledge"
set +e
printf '%s' '{"taskId":"task-20261109-skip-probe","skill":"project-analyzer","status":"skipped","timing":{"startedAt":"2026-11-09T10:00:00Z","finishedAt":"2026-11-09T10:01:00Z"},"quality":{"confidence":0}}' | bash "$APPEND" "$SKIP_ROOT" - >/dev/null 2>&1; SKIP_RC=$?
set -e
assert_eq "status=skipped 被接受（exit 0）" "$SKIP_RC" "0"
assert_eq "skipped 记录落盘（1 行）" \
  "$(wc -l < "$SKIP_ROOT/.project-knowledge/runtime/metrics/timeline.jsonl" | tr -d ' ')" "1"

# 聚合在读取时计算（不依赖落盘 aggregates）
STATS_OUT="$(node "$STATS" "$TL")"
assert_eq "timeline-stats 总数 = 20" "$(echo "$STATS_OUT" | awk '{print $1}')" "20"
assert_eq "timeline-stats 平均时长 = 60s" "$(echo "$STATS_OUT" | awk '{print $4}')" "60"

# v1 兼容：{runs:[]} 旧形态仍能被读取
LEGACY="$TMP/legacy-timeline.json"
printf '%s' '{"schemaVersion":"1.0.0","project":"p","runs":[{"runId":"r1","skill":"project-planner","status":"completed","timing":{"startedAt":"2026-11-09T10:00:00Z","finishedAt":"2026-11-09T10:02:00Z","durationMs":120000},"quality":{"confidence":80}}]}' > "$LEGACY"
assert_eq "legacy {runs:[]} 可被读取" "$(node "$STATS" "$LEGACY" | awk '{print $1}')" "1"

# --shell：供 collect-metrics 读取完整聚合（执行数/状态/confidence/skills）
SHELL_OUT="$(node "$STATS" "$TL" --shell)"
assert_eq "--shell TOTAL_RUNS = 20" "$(printf '%s\n' "$SHELL_OUT" | sed -n 's/^TOTAL_RUNS=//p')" "20"
assert_eq "--shell COMPLETED = 20" "$(printf '%s\n' "$SHELL_OUT" | sed -n 's/^COMPLETED=//p')" "20"
assert_eq "--shell AVG_CONFIDENCE = 80" "$(printf '%s\n' "$SHELL_OUT" | sed -n 's/^AVG_CONFIDENCE=//p')" "80"
assert_eq "--shell SKILLS 去重排序" "$(printf '%s\n' "$SHELL_OUT" | sed -n 's/^SKILLS=//p')" "project-generator,project-planner"

# confidence 聚合口径：skipped/degraded 的 0 是「未评估」哨兵，不能计入质量平均。
# 报表用 COMPLETED_AVG_CONFIDENCE；旧 AVG_CONFIDENCE 保留旧语义（全部有值的运行）。
MIXED_TL="$TMP/mixed-timeline.jsonl"
cat > "$MIXED_TL" <<'EOF'
{"skill":"project-analyzer","status":"completed","timing":{"durationMs":60000},"quality":{"confidence":90}}
{"skill":"project-analyzer","status":"degraded","timing":{"durationMs":30000},"quality":{"confidence":0}}
{"skill":"project-analyzer","status":"skipped","timing":{"durationMs":10000},"quality":{"confidence":0}}
EOF
MIXED_OUT="$(node "$STATS" "$MIXED_TL" --shell)"
assert_eq "--shell SKIPPED 单独计数 = 1" "$(printf '%s\n' "$MIXED_OUT" | sed -n 's/^SKIPPED=//p')" "1"
assert_eq "--shell AVG_CONFIDENCE 保留全部样本（30）" "$(printf '%s\n' "$MIXED_OUT" | sed -n 's/^AVG_CONFIDENCE=//p')" "30"
assert_eq "--shell COMPLETED_AVG_CONFIDENCE 只统计 completed（90）" "$(printf '%s\n' "$MIXED_OUT" | sed -n 's/^COMPLETED_AVG_CONFIDENCE=//p')" "90"
assert_eq "--shell COMPLETED_CONFIDENCE_SAMPLES = 1" "$(printf '%s\n' "$MIXED_OUT" | sed -n 's/^COMPLETED_CONFIDENCE_SAMPLES=//p')" "1"

# collect-metrics：timeline 是执行事实的唯一 append-only 来源。
# 本 fixture 同时有 state.json（4 条 "skill"）和 timeline（20 行）→ 必须报 20 且 source=timeline。
# 修复前的缺陷：执行数只读 state.json → 报 4，与同一报告的 timeline 20 自相矛盾。
bash "$SCRIPT_DIR/collect-metrics.sh" "$TMP" >/dev/null
METRICS_REPORT="$KD/reports/telemetry-report.md"
assert_eq "collect-metrics 报告落在项目知识库（不写 suite 包）" \
  "$([ -f "$METRICS_REPORT" ] && echo yes || echo no)" "yes"
assert_eq "collect-metrics 执行数与 timeline 同源（20，而非 state 的 4）" \
  "$(sed -n 's/^| Total executions | \(.*\) |$/\1/p' "$METRICS_REPORT")" "20"
assert_eq "collect-metrics 标注 source=timeline" \
  "$(sed -n 's/^| Execution metrics source | \(.*\) |$/\1/p' "$METRICS_REPORT")" "timeline"
assert_eq "collect-metrics 取 timeline 的 confidence（80）" \
  "$(sed -n 's/^| Avg confidence | \(.*\)% |$/\1/p' "$METRICS_REPORT")" "80"

# 只有 skipped 的项目：不能把「没跑」报成「0% critical」，必须是「无已完成运行」。
bash "$SCRIPT_DIR/collect-metrics.sh" "$SKIP_ROOT" >/dev/null
SKIP_REPORT="$SKIP_ROOT/.project-knowledge/reports/telemetry-report.md"
assert_eq "collect-metrics 单独统计 Skipped" \
  "$(sed -n 's/^| Skipped (ended before output) | \(.*\) |$/\1/p' "$SKIP_REPORT")" "1"
assert_eq "collect-metrics 无 completed 时不报 0%" \
  "$(sed -n 's/^| Avg confidence | \(.*\) |$/\1/p' "$SKIP_REPORT")" "n/a (no completed runs)"
assert_eq "collect-metrics 不把 skipped 计入可靠性分母" \
  "$(sed -n 's/^- \*\*Reliability\*\*: \(.*\)$/\1/p' "$SKIP_REPORT")" \
  "0/0 completed (0%), excluding 1 skipped run(s) that never produced output"

# ---------------------------------------------------------------------------
echo "=== 8. runtime-run：运行的机械生命周期（start / finish / status） ==="
RUN="$SCRIPT_DIR/runtime-run.sh"

# 8.1 start：解析/创建任务 + 加锁 + 写运行指针
RR_ROOT="$TMP/runtime-run-proj"
mkdir -p "$RR_ROOT"
START_OUT="$(bash "$RUN" start "$RR_ROOT" --skill project-analyzer --goal "分析这个项目" --new-task --session-id s1)"
RR_TASK="$(printf '%s\n' "$START_OUT" | sed -n 's/^TASK_ID=//p')"
RR_RUN="$(printf '%s\n' "$START_OUT" | sed -n 's/^RUN_ID=//p')"
assert_eq "start 输出 TASK_ID" "$(printf '%s' "$RR_TASK" | grep -c '^task-')" "1"
assert_eq "中文 goal 的 task id 仍为 ASCII" "$(printf '%s' "$RR_TASK" | LC_ALL=C grep -c '[^ -~]')" "0"
assert_eq "运行指针已写入" \
  "$([ -f "$RR_ROOT/.project-knowledge/runtime/current-runs/project-analyzer.json" ] && echo yes || echo no)" "yes"
assert_eq "start 后锁为 locked" \
  "$(bash "$LOCK" "$RR_ROOT/.project-knowledge" analyzer status >/dev/null 2>&1; echo $?)" "0"

# 8.2 start 幂等：不产生第二次运行
START2_OUT="$(bash "$RUN" start "$RR_ROOT" --skill project-analyzer --session-id s1)"
assert_eq "重复 start 复用同一 runId" "$(printf '%s\n' "$START2_OUT" | sed -n 's/^RUN_ID=//p')" "$RR_RUN"
assert_eq "重复 start 标记 REUSED=1" "$(printf '%s\n' "$START2_OUT" | sed -n 's/^REUSED=//p')" "1"

# 8.3 finish completed 缺 confidence → 拒绝，且指针保留（可修正后重试）
set +e
bash "$RUN" finish "$RR_ROOT" --skill project-analyzer --session-id s1 --status completed >/dev/null 2>&1; RR_BAD=$?
set -e
assert_eq "completed 缺 confidence 被拒绝（exit 2）" "$RR_BAD" "2"
assert_eq "拒绝后运行指针保留" \
  "$([ -f "$RR_ROOT/.project-knowledge/runtime/current-runs/project-analyzer.json" ] && echo yes || echo no)" "yes"

# 8.4 finish completed：恰好一行终态记录 + 释放锁 + 清指针 + 任务 completed
FIN_OUT="$(bash "$RUN" finish "$RR_ROOT" --skill project-analyzer --session-id s1 --status completed --confidence 91 2>/dev/null)"
RR_TL="$RR_ROOT/.project-knowledge/runtime/metrics/timeline.jsonl"
assert_eq "finish 只写一行终态记录" "$(wc -l < "$RR_TL" | tr -d ' ')" "1"
assert_eq "终态记录 status=completed" \
  "$(node -e 'const fs=require("fs");process.stdout.write(JSON.parse(fs.readFileSync(process.argv[1],"utf8").trim()).status)' "$RR_TL")" "completed"
assert_eq "终态记录 confidence=91" \
  "$(node -e 'const fs=require("fs");process.stdout.write(String(JSON.parse(fs.readFileSync(process.argv[1],"utf8").trim()).quality.confidence))' "$RR_TL")" "91"
assert_eq "finish 后锁已释放" \
  "$(bash "$LOCK" "$RR_ROOT/.project-knowledge" analyzer status >/dev/null 2>&1; echo $?)" "4"
assert_eq "finish 后运行指针已清理" \
  "$([ -f "$RR_ROOT/.project-knowledge/runtime/current-runs/project-analyzer.json" ] && echo yes || echo no)" "no"
assert_eq "任务保持 active（finish 只结束 Run，不关闭长期 Task）" \
  "$(node -e 'const fs=require("fs");process.stdout.write(JSON.parse(fs.readFileSync(process.argv[1],"utf8")).status)' \
     "$RR_ROOT/.project-knowledge/runtime/tasks/$RR_TASK/meta.json")" "active"

# 8.4b Discovery 产物缺失 → context.warnings 告警（不改变 status）
assert_eq "finish 输出 WARNINGS" "$(printf '%s\n' "$FIN_OUT" | sed -n 's/^WARNINGS=//p')" "discovery-artifact-missing"
assert_eq "终态记录 context.warnings 含 discovery-artifact-missing" \
  "$(node -e 'const fs=require("fs");const r=JSON.parse(fs.readFileSync(process.argv[1],"utf8").trim());process.stdout.write(String((r.context&&r.context.warnings||[]).includes("discovery-artifact-missing")))' "$RR_TL")" "true"
assert_eq "告警不改变 status" \
  "$(node -e 'const fs=require("fs");process.stdout.write(JSON.parse(fs.readFileSync(process.argv[1],"utf8").trim()).status)' "$RR_TL")" "completed"

# 8.4c Discovery 产物存在 → 不产生告警
bash "$RUN" start "$RR_ROOT" --skill project-analyzer --goal with-discovery --new-task --session-id s1 >/dev/null
RR_TASK2="$(node -e 'process.stdout.write(require(process.argv[1]).taskId)' "$RR_ROOT/.project-knowledge/runtime/current-runs/project-analyzer.json")"
mkdir -p "$RR_ROOT/.project-knowledge/runtime/tasks/$RR_TASK2"
printf '{"status":"discover","mode":"incremental","scope":["src"]}\n' \
  > "$RR_ROOT/.project-knowledge/runtime/tasks/$RR_TASK2/discovery.json"
FIN3="$(bash "$RUN" finish "$RR_ROOT" --skill project-analyzer --session-id s1 --status completed --confidence 88 2>/dev/null)"
assert_eq "有 discovery.json 时 WARNINGS 为空" "$(printf '%s\n' "$FIN3" | sed -n 's/^WARNINGS=//p')" ""
assert_eq "有 discovery.json 时记录不含 warnings" \
  "$(tail -1 "$RR_TL" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{const r=JSON.parse(s);process.stdout.write(String(!!(r.context&&r.context.warnings)))})')" "false"

# 8.5 finish 幂等：无活动运行 → exit 0（hook 可安全重复调用）
set +e
FIN2="$(bash "$RUN" finish "$RR_ROOT" --skill project-analyzer 2>&1)"; RR_FIN2=$?
set -e
assert_eq "无活动运行 finish 仍 exit 0" "$RR_FIN2" "0"
assert_eq "无活动运行 FINALIZED=0" "$(printf '%s\n' "$FIN2" | sed -n 's/^FINALIZED=//p')" "0"

# 8.6 hook 自动收尾：默认 degraded，原因落在 context（不新增顶层字段）
bash "$RUN" start "$RR_ROOT" --skill project-planner --goal "规划" --new-task --session-id s1 >/dev/null
bash "$RUN" finish "$RR_ROOT" --skill project-planner --session-id s1 --auto-finalized >/dev/null
AUTO_ROW="$(tail -1 "$RR_TL")"
assert_eq "auto-finalize 记为 degraded" \
  "$(printf '%s' "$AUTO_ROW" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>process.stdout.write(JSON.parse(s).status))')" "degraded"
assert_eq "auto-finalize 标记在 context.autoFinalized" \
  "$(printf '%s' "$AUTO_ROW" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>process.stdout.write(String(JSON.parse(s).context.autoFinalized)))')" "true"
assert_eq "auto-finalize 记录仍有 reason" \
  "$(printf '%s' "$AUTO_ROW" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>process.stdout.write(JSON.parse(s).context.reason?"yes":"no"))')" "yes"

# 8.7 start 幂等必须校验身份：不同 session / task 不静默复用
ID_ROOT="$TMP/identity-proj"
mkdir -p "$ID_ROOT"
bash "$RUN" start "$ID_ROOT" --skill project-analyzer --goal identity --new-task --session-id s1 >/dev/null
ID_TASK2="$(bash "$REG" create "另一个任务" --slug other-task --skill project-planner --dir "$ID_ROOT/.project-knowledge")"
set +e
bash "$RUN" start "$ID_ROOT" --skill project-analyzer --session-id s2 >/dev/null 2>&1; ID_S=$?
bash "$RUN" start "$ID_ROOT" --skill project-analyzer --task-id "$ID_TASK2" --session-id s1 >/dev/null 2>&1; ID_T=$?
set -e
assert_eq "不同 session 不静默复用（exit 1）" "$ID_S" "1"
assert_eq "不同 task 不静默复用（exit 1）" "$ID_T" "1"
assert_eq "拒绝后仍是原 run 的指针" \
  "$(node -e 'const fs=require("fs");process.stdout.write(JSON.parse(fs.readFileSync(process.argv[1],"utf8")).sessionId)' \
     "$ID_ROOT/.project-knowledge/runtime/current-runs/project-analyzer.json")" "s1"

# 8.8 renew：续租单写者锁，TTL 从续租时刻重新计算
REN_OUT="$(bash "$RUN" renew "$ID_ROOT" --skill project-analyzer --session-id s1 2>/dev/null)"
assert_eq "renew 成功" "$(printf '%s\n' "$REN_OUT" | sed -n 's/^RENEWED=//p')" "1"
assert_eq "owner.env 写入 renewed_epoch" \
  "$(grep -c '^renewed_epoch=' "$ID_ROOT/.project-knowledge/.locks/analyzer.lock/owner.env")" "1"
set +e
bash "$RUN" renew "$ID_ROOT" --skill project-analyzer --session-id s2 >/dev/null 2>&1; ID_R=$?
set -e
assert_eq "跨 session renew 被拒绝（exit 2）" "$ID_R" "2"

# 8.9 跨 session finish 被拒绝；本 session 收尾后任务仍 active
set +e
bash "$RUN" finish "$ID_ROOT" --skill project-analyzer --session-id s2 --status completed --confidence 80 >/dev/null 2>&1; ID_F=$?
set -e
assert_eq "跨 session finish 被拒绝（exit 2）" "$ID_F" "2"
assert_eq "跨 session finish 后指针保留" \
  "$([ -f "$ID_ROOT/.project-knowledge/runtime/current-runs/project-analyzer.json" ] && echo yes || echo no)" "yes"
bash "$RUN" finish "$ID_ROOT" --skill project-analyzer --session-id s1 --status completed --confidence 80 >/dev/null 2>&1
assert_eq "本 session finish 清理指针" \
  "$([ -f "$ID_ROOT/.project-knowledge/runtime/current-runs/project-analyzer.json" ] && echo yes || echo no)" "no"
assert_eq "finish 不关闭长期任务" \
  "$(node -e 'const fs=require("fs");process.stdout.write(JSON.parse(fs.readFileSync(process.argv[1],"utf8")).status)' \
     "$ID_ROOT/.project-knowledge/runtime/tasks/"*/meta.json)" "active"

# 8.10 task-meta.schema.json 接入写入路径
REG="$SCRIPT_DIR/task-registry.sh"
REG_ROOT="$TMP/reg-proj"
mkdir -p "$REG_ROOT"
REG_ID="$(bash "$REG" create "schema 校验" --slug schema-check --skill project-planner --dir "$REG_ROOT/.project-knowledge")"
assert_eq "create 产出通过 schema 校验" \
  "$(bash "$REG" validate "$REG_ID" --dir "$REG_ROOT/.project-knowledge" 2>/dev/null)" "valid $REG_ID"
node -e '
  const fs=require("fs");const p=process.argv[1];
  const m=JSON.parse(fs.readFileSync(p,"utf8"));m.monitorOnly=true;
  fs.writeFileSync(p,JSON.stringify(m,null,2));
' "$REG_ROOT/.project-knowledge/runtime/tasks/$REG_ID/meta.json"
set +e
bash "$REG" validate "$REG_ID" --dir "$REG_ROOT/.project-knowledge" >/dev/null 2>&1; REG_V=$?
set -e
assert_eq "schema 之外的字段被拒绝（exit 1）" "$REG_V" "1"

# schema 已声明的类型/format/items 也必须执行，不能只查键名
node -e '
  const fs=require("fs");const p=process.argv[1];
  const m=JSON.parse(fs.readFileSync(p,"utf8"));
  delete m.monitorOnly;
  m.skills=[42]; m.artifacts={ "a.md": 7 }; m.created_at="not-a-date";
  fs.writeFileSync(p,JSON.stringify(m,null,2));
' "$REG_ROOT/.project-knowledge/runtime/tasks/$REG_ID/meta.json"
set +e
bash "$REG" validate "$REG_ID" --dir "$REG_ROOT/.project-knowledge" >/dev/null 2>&1; REG_V2=$?
set -e
assert_eq "skills[]/artifacts 值/date-time 类型错误被拒绝（exit 1）" "$REG_V2" "1"

# 8.11 锁丢失后的旧指针：只有原身份能接回，别的 session 不能借尸还魂
STALE_ROOT="$TMP/stale-proj"
mkdir -p "$STALE_ROOT"
bash "$RUN" start "$STALE_ROOT" --skill project-analyzer --goal stale --new-task --session-id s1 >/dev/null
ST_POINTER="$STALE_ROOT/.project-knowledge/runtime/current-runs/project-analyzer.json"
ST_RUN_BEFORE="$(node -e 'const fs=require("fs");process.stdout.write(JSON.parse(fs.readFileSync(process.argv[1],"utf8")).runId)' "$ST_POINTER")"
bash "$SCRIPT_DIR/writer-lock.sh" "$STALE_ROOT/.project-knowledge" analyzer break --force >/dev/null 2>&1
set +e
bash "$RUN" start "$STALE_ROOT" --skill project-analyzer --session-id s2 >/dev/null 2>&1; ST_S=$?
set -e
assert_eq "锁丢失的旧指针：别的 session 不能接管（exit 2）" "$ST_S" "2"
assert_eq "拒绝后指针仍属原 session" \
  "$(node -e 'const fs=require("fs");process.stdout.write(JSON.parse(fs.readFileSync(process.argv[1],"utf8")).sessionId)' "$ST_POINTER")" "s1"
bash "$RUN" start "$STALE_ROOT" --skill project-analyzer --session-id s1 >/dev/null 2>&1
assert_eq "原 session 接回的是同一个 run（runId 不变）" \
  "$(node -e 'const fs=require("fs");process.stdout.write(JSON.parse(fs.readFileSync(process.argv[1],"utf8")).runId)' "$ST_POINTER")" \
  "$ST_RUN_BEFORE"

# 8.12 「没传 session」不能绕过身份检查（fail-closed）
SESS_ROOT="$TMP/session-proj"
mkdir -p "$SESS_ROOT"
bash "$RUN" start "$SESS_ROOT" --skill project-analyzer --goal sess --new-task --session-id s1 >/dev/null
SESS_POINTER="$SESS_ROOT/.project-knowledge/runtime/current-runs/project-analyzer.json"
set +e
bash "$RUN" finish "$SESS_ROOT" --skill project-analyzer --status completed --confidence 50 >/dev/null 2>&1; SESS_F=$?
bash "$RUN" renew "$SESS_ROOT" --skill project-analyzer >/dev/null 2>&1; SESS_R=$?
bash "$RUN" start "$SESS_ROOT" --skill project-analyzer >/dev/null 2>&1; SESS_S=$?
set -e
assert_eq "缺 session 的 finish 被拒绝（exit 2）" "$SESS_F" "2"
assert_eq "缺 session 的 renew 被拒绝（exit 2）" "$SESS_R" "2"
assert_eq "缺 session 的 start 被拒绝（exit 2）" "$SESS_S" "2"
assert_eq "拒绝后指针仍在且属 s1" \
  "$(node -e 'const fs=require("fs");process.stdout.write(JSON.parse(fs.readFileSync(process.argv[1],"utf8")).sessionId)' "$SESS_POINTER")" "s1"
bash "$RUN" finish "$SESS_ROOT" --skill project-analyzer --session-id s1 --status skipped >/dev/null

# 8.13 finish 锁被别人持有：先证明所有权，再写终态 → 不写 completed、保留指针；
#      锁不存在 → 允许收尾并清理指针（不重复记账）
FIN_ROOT="$TMP/finish-race"
mkdir -p "$FIN_ROOT"
bash "$RUN" start "$FIN_ROOT" --skill project-analyzer --goal race --new-task --session-id s1 >/dev/null
FIN_POINTER="$FIN_ROOT/.project-knowledge/runtime/current-runs/project-analyzer.json"
FIN_TL="$FIN_ROOT/.project-knowledge/runtime/metrics/timeline.jsonl"
bash "$SCRIPT_DIR/writer-lock.sh" "$FIN_ROOT/.project-knowledge" analyzer break --force >/dev/null 2>&1
bash "$SCRIPT_DIR/writer-lock.sh" "$FIN_ROOT/.project-knowledge" analyzer acquire --owner-id other@session >/dev/null 2>&1
set +e
bash "$RUN" finish "$FIN_ROOT" --skill project-analyzer --session-id s1 --status completed --confidence 60 >/dev/null 2>&1; FIN_F=$?
set -e
assert_eq "锁被别人持有时 finish 报错（exit 2）" "$FIN_F" "2"
assert_eq "锁被别人持有时保留运行指针" \
  "$([ -f "$FIN_POINTER" ] && echo yes || echo no)" "yes"
assert_eq "锁被别人持有时不写 completed 终态" \
  "$([ -f "$FIN_TL" ] && grep -c '"status":"completed"' "$FIN_TL" || echo 0)" "0"
bash "$SCRIPT_DIR/writer-lock.sh" "$FIN_ROOT/.project-knowledge" analyzer break --force >/dev/null 2>&1
bash "$RUN" finish "$FIN_ROOT" --skill project-analyzer --session-id s1 --status completed --confidence 60 >/dev/null 2>&1
assert_eq "锁已不存在时重试可清理指针" \
  "$([ -f "$FIN_POINTER" ] && echo yes || echo no)" "no"
assert_eq "重试不重复记账（仍是一行）" "$(wc -l < "$FIN_TL" | tr -d ' ')" "1"

# 8.14 协议允许「同一 skill、不同 task」并行，但当前运行指针按 skill 单槽 → 第二个 task 被拒绝
#      这是**已知实现限制**：迁移到 current-runs/<task_id>/<skill>.json 后改为允许。
PAR_ROOT="$TMP/parallel-limit"
mkdir -p "$PAR_ROOT"
PAR_KD="$PAR_ROOT/.project-knowledge"
PAR_T1="$(bash "$SCRIPT_DIR/task-registry.sh" create "task A" --slug task-a --skill project-planner --dir "$PAR_KD")"
PAR_T2="$(bash "$SCRIPT_DIR/task-registry.sh" create "task B" --slug task-b --skill project-planner --dir "$PAR_KD")"
bash "$RUN" start "$PAR_ROOT" --skill project-planner --task-id "$PAR_T1" --goal "task A" --session-id s1 >/dev/null
set +e
PAR_OUT="$(bash "$RUN" start "$PAR_ROOT" --skill project-planner --task-id "$PAR_T2" --goal "task B" --session-id s2 2>&1)"
PAR_RC=$?
set -e
assert_eq "同 skill 不同 task 当前被串行拒绝（exit 1）" "$PAR_RC" "1"
assert_eq "被拒绝时提示 LOCK=occupied" "$(printf '%s\n' "$PAR_OUT" | grep -c 'LOCK=occupied')" "1"
assert_eq "被拒绝后指针仍属于 task A" \
  "$(node -e 'const fs=require("fs");process.stdout.write(JSON.parse(fs.readFileSync(process.argv[1],"utf8")).taskId)' "$PAR_KD/runtime/current-runs/project-planner.json")" "$PAR_T1"
bash "$RUN" finish "$PAR_ROOT" --skill project-planner --session-id s1 --status skipped >/dev/null

# 8.15 Reviewer 与 Analyzer 共用项目级知识锁（二者都写 knowledge.json）
REV_ROOT="$TMP/reviewer-shared-lock"
mkdir -p "$REV_ROOT"
REV_START="$(bash "$RUN" start "$REV_ROOT" --skill project-analyzer --goal "analyze" --new-task --session-id a1)"
REV_TASK="$(printf '%s\n' "$REV_START" | sed -n 's/^TASK_ID=//p')"
set +e
bash "$RUN" start "$REV_ROOT" --skill project-reviewer --task-id "$REV_TASK" --goal "review" --session-id r1 >/dev/null 2>&1
REV_RC=$?
set -e
assert_eq "Analyzer 持锁时 Reviewer 被拒绝（共享 analyzer 锁）" "$REV_RC" "1"
bash "$RUN" finish "$REV_ROOT" --skill project-analyzer --session-id a1 --status completed --confidence 80 >/dev/null
bash "$RUN" start "$REV_ROOT" --skill project-reviewer --task-id "$REV_TASK" --goal "review" --session-id r1 >/dev/null
assert_eq "Analyzer 收尾后 Reviewer 可持同一把锁" \
  "$([ -f "$REV_ROOT/.project-knowledge/.locks/analyzer.lock/owner.env" ] && echo yes || echo no)" "yes"
bash "$RUN" finish "$REV_ROOT" --skill project-reviewer --session-id r1 --status skipped >/dev/null

# 8.16 --new-task：用户明确选择新建时，不把运行挂到唯一 active 任务上
NT_ROOT="$TMP/new-task-flag"
mkdir -p "$NT_ROOT"
bash "$RUN" start "$NT_ROOT" --skill project-planner --goal "old task" --new-task --session-id s1 >/dev/null
NT_POINTER="$NT_ROOT/.project-knowledge/runtime/current-runs/project-planner.json"
NT_T1="$(node -e 'const fs=require("fs");process.stdout.write(JSON.parse(fs.readFileSync(process.argv[1],"utf8")).taskId)' "$NT_POINTER")"
bash "$RUN" finish "$NT_ROOT" --skill project-planner --session-id s1 --status skipped >/dev/null
bash "$RUN" start "$NT_ROOT" --skill project-planner --goal "new task" --new-task --session-id s2 >/dev/null
NT_T2="$(node -e 'const fs=require("fs");process.stdout.write(JSON.parse(fs.readFileSync(process.argv[1],"utf8")).taskId)' "$NT_POINTER")"
assert_eq "--new-task 不复用旧 active 任务" "$([ "$NT_T2" != "$NT_T1" ] && echo diff || echo same)" "diff"
assert_eq "--new-task 保留旧任务并新建第二个任务" \
  "$(find "$NT_ROOT/.project-knowledge/runtime/tasks" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')" "2"
set +e
bash "$RUN" start "$NT_ROOT" --skill project-planner --goal "x" --new-task --task-id "$NT_T2" --session-id s3 >/dev/null 2>&1
NT_RC=$?
set -e
assert_eq "--new-task 与 --task-id 互斥（exit 2）" "$NT_RC" "2"
bash "$RUN" finish "$NT_ROOT" --skill project-planner --session-id s2 --status skipped >/dev/null

# 8.17 start 必须有运行身份：缺 session → 拒绝，且不留下锁 / 指针
NS_ROOT="$TMP/no-session"
mkdir -p "$NS_ROOT"
set +e
env -u CLAUDE_CODE_SESSION_ID -u CLAUDE_SESSION_ID bash "$RUN" start "$NS_ROOT" --skill project-analyzer --goal nosession --new-task >/dev/null 2>&1
NS_RC=$?
set -e
assert_eq "缺 session 的 start 被拒绝（exit 2）" "$NS_RC" "2"
assert_eq "缺 session 时不写运行指针" \
  "$([ -f "$NS_ROOT/.project-knowledge/runtime/current-runs/project-analyzer.json" ] && echo yes || echo no)" "no"
assert_eq "缺 session 时不获取锁" \
  "$([ -d "$NS_ROOT/.project-knowledge/.locks/analyzer.lock" ] && echo yes || echo no)" "no"

# 8.18 显式 --task-id 必须真实存在：不存在的任务不建 Run
TN_ROOT="$TMP/task-nonexistent"
mkdir -p "$TN_ROOT"
set +e
bash "$RUN" start "$TN_ROOT" --skill project-analyzer --task-id task-19990101-missing --session-id s1 >/dev/null 2>&1
TN_RC=$?
set -e
assert_eq "不存在的 task_id 被拒绝（exit 2）" "$TN_RC" "2"
assert_eq "不存在的 task_id 不写运行指针" \
  "$([ -f "$TN_ROOT/.project-knowledge/runtime/current-runs/project-analyzer.json" ] && echo yes || echo no)" "no"
assert_eq "不存在的 task_id 不创建 meta.json" \
  "$([ -f "$TN_ROOT/.project-knowledge/runtime/tasks/task-19990101-missing/meta.json" ] && echo yes || echo no)" "no"

# 8.19 运行指针 owner 与真实锁 owner 不一致 → 不得复用（锁被 break 后他人接管）
LO_ROOT="$TMP/lock-owner"
mkdir -p "$LO_ROOT"
LO_KD="$LO_ROOT/.project-knowledge"
bash "$RUN" start "$LO_ROOT" --skill project-analyzer --goal owner-check --new-task --session-id s1 --owner-id o1 >/dev/null
bash "$LOCK" "$LO_KD" analyzer break --force >/dev/null 2>&1
bash "$LOCK" "$LO_KD" analyzer acquire --owner-id o2 >/dev/null
set +e
LO_OUT="$(bash "$RUN" start "$LO_ROOT" --skill project-analyzer --session-id s1 --owner-id o1 2>&1)"
LO_RC=$?
set -e
assert_eq "指针 owner 与锁 owner 不一致时 start 被拒绝（exit 1）" "$LO_RC" "1"
assert_eq "锁 owner 不一致时不返回 REUSED" "$(printf '%s\n' "$LO_OUT" | grep -c '^REUSED=1')" "0"

# 8.20 锁 owner 不一致时 finish 不得写 completed / 不得删指针
LO_TL="$LO_KD/runtime/metrics/timeline.jsonl"
set +e
bash "$RUN" finish "$LO_ROOT" --skill project-analyzer --session-id s1 --status completed --confidence 80 >/dev/null 2>&1
LO_FIN=$?
set -e
assert_eq "锁 owner 不一致时 finish 被拒绝（exit 2）" "$LO_FIN" "2"
assert_eq "锁 owner 不一致时不写 completed 终态" \
  "$([ -f "$LO_TL" ] && grep -c '"status":"completed"' "$LO_TL" || echo 0)" "0"
assert_eq "锁 owner 不一致时运行指针保留" \
  "$([ -f "$LO_KD/runtime/current-runs/project-analyzer.json" ] && echo yes || echo no)" "yes"
bash "$LOCK" "$LO_KD" analyzer break --force >/dev/null 2>&1 || true

# 8.21 获锁失败的新建任务不能以 active 留下（孤儿 Task 会污染后续 Task Resolution）
OR_ROOT="$TMP/orphan-task"
mkdir -p "$OR_ROOT"
OR_KD="$OR_ROOT/.project-knowledge"
bash "$RUN" start "$OR_ROOT" --skill project-reviewer --goal review --new-task --session-id r1 >/dev/null
bash "$RUN" start "$OR_ROOT" --skill project-analyzer --goal analyze --new-task --session-id a1 >/dev/null 2>&1 || true
assert_eq "获锁失败的新任务被标记 abandoned" \
  "$(bash "$REG" list --status abandoned --dir "$OR_KD" | wc -l | tr -d ' ')" "1"
assert_eq "Reviewer 的任务仍为 active" \
  "$(bash "$REG" list --status active --dir "$OR_KD" | wc -l | tr -d ' ')" "1"
bash "$RUN" finish "$OR_ROOT" --skill project-reviewer --session-id r1 --status skipped >/dev/null 2>&1 || true

# 8.22 paused 任务恢复后转回 active；completed / abandoned 拒绝恢复
PR_ROOT="$TMP/paused-resume"
mkdir -p "$PR_ROOT"
PR_KD="$PR_ROOT/.project-knowledge"
PR_T="$(bash "$REG" create "暂停的任务" --slug paused-resume --skill project-planner --dir "$PR_KD")"
bash "$REG" set-status "$PR_T" paused --dir "$PR_KD"
bash "$RUN" start "$PR_ROOT" --skill project-planner --task-id "$PR_T" --session-id s1 >/dev/null
assert_eq "paused 任务 start 后转回 active" "$(bash "$REG" list --status active --dir "$PR_KD" | wc -l | tr -d ' ')" "1"
bash "$RUN" finish "$PR_ROOT" --skill project-planner --session-id s1 --status skipped >/dev/null
bash "$REG" set-status "$PR_T" completed --dir "$PR_KD"
set +e
bash "$RUN" start "$PR_ROOT" --skill project-planner --task-id "$PR_T" --session-id s1 >/dev/null 2>&1
PR_RC=$?
set -e
assert_eq "completed 任务拒绝普通恢复（exit 2）" "$PR_RC" "2"

# 8.23 PS_TASK_ID 也必须走统一校验：不存在的 task 不得启动（旧实现只校验显式 --task-id）
PSV_ROOT="$TMP/env-task-id"
mkdir -p "$PSV_ROOT"
set +e
PS_TASK_ID=task-19990101-nope bash "$RUN" start "$PSV_ROOT" --skill project-analyzer --session-id s1 >/dev/null 2>&1
PSV_RC=$?
set -e
assert_eq "PS_TASK_ID 指向不存在的 task → 拒绝（exit 2）" "$PSV_RC" "2"
assert_eq "PS_TASK_ID 被拒后不写运行指针" \
  "$([ -f "$PSV_ROOT/.project-knowledge/runtime/current-runs/project-analyzer.json" ] && echo yes || echo no)" "no"
assert_eq "PS_TASK_ID 被拒后不建锁" \
  "$([ -d "$PSV_ROOT/.project-knowledge/.locks/analyzer.lock" ] && echo yes || echo no)" "no"

# 8.24 schema 不合法的 task 不得启动（显式 --task-id 分支同样要 validate）
SCV_ROOT="$TMP/schema-invalid-task"
mkdir -p "$SCV_ROOT"
SCV_KD="$SCV_ROOT/.project-knowledge"
SCV_T="$(bash "$REG" create "坏任务" --slug broken-meta --skill project-planner --dir "$SCV_KD")"
node -e '
const fs=require("fs"),p=process.argv[1];const m=JSON.parse(fs.readFileSync(p));
delete m.goal; m.status="weird-status"; fs.writeFileSync(p,JSON.stringify(m,null,2));
' "$SCV_KD/runtime/tasks/$SCV_T/meta.json"
set +e
bash "$RUN" start "$SCV_ROOT" --skill project-planner --task-id "$SCV_T" --session-id s1 >/dev/null 2>&1
SCV_RC=$?
set -e
assert_eq "schema 不合法的 task 被拒绝（exit 2）" "$SCV_RC" "2"
assert_eq "schema 不合法时不写运行指针" \
  "$([ -f "$SCV_KD/runtime/current-runs/project-planner.json" ] && echo yes || echo no)" "no"

# 8.25 Runtime 不再自动选择唯一 active 任务：无任务身份且未 --new-task → 拒绝
AUTOSEL_ROOT="$TMP/no-auto-resolve"
mkdir -p "$AUTOSEL_ROOT"
AUTOSEL_KD="$AUTOSEL_ROOT/.project-knowledge"
AUTOSEL_T="$(bash "$REG" create "已有任务" --slug existing --skill project-planner --dir "$AUTOSEL_KD")"
set +e
bash "$RUN" start "$AUTOSEL_ROOT" --skill project-planner --goal "另一件事" --session-id s1 >/dev/null 2>&1
AUTOSEL_RC=$?
set -e
assert_eq "未指定任务身份时不自动接管唯一 active 任务（exit 2）" "$AUTOSEL_RC" "2"
assert_eq "拒绝后不写运行指针" \
  "$([ -f "$AUTOSEL_KD/runtime/current-runs/project-planner.json" ] && echo yes || echo no)" "no"
assert_eq "拒绝后不新建任务（仍只有 1 个）" \
  "$(find "$AUTOSEL_KD/runtime/tasks" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')" "1"
assert_eq "已有任务保持 active" \
  "$(node -e 'const fs=require("fs");process.stdout.write(JSON.parse(fs.readFileSync(process.argv[1],"utf8")).status)' "$AUTOSEL_KD/runtime/tasks/$AUTOSEL_T/meta.json")" "active"

# 8.26 --new-task 必须给 --goal（拒绝登记无目标任务）
NG_ROOT="$TMP/new-task-no-goal"
mkdir -p "$NG_ROOT"
set +e
bash "$RUN" start "$NG_ROOT" --skill project-planner --new-task --session-id s1 >/dev/null 2>&1
NG_RC=$?
set -e
assert_eq "--new-task 缺 goal 被拒绝（exit 2）" "$NG_RC" "2"
assert_eq "--new-task 缺 goal 不创建任务" \
  "$([ -d "$NG_ROOT/.project-knowledge/runtime/tasks" ] && find "$NG_ROOT/.project-knowledge/runtime/tasks" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ' || echo 0)" "0"

# 8.27 过期且已被他人接管的锁：旧 Run finish 不得写 completed（owner 判定先于 stale）
SF_ROOT="$TMP/stale-foreign-owner"
mkdir -p "$SF_ROOT"
SF_KD="$SF_ROOT/.project-knowledge"
bash "$RUN" start "$SF_ROOT" --skill project-analyzer --goal stale-foreign --new-task --session-id s1 --owner-id Aowner >/dev/null
SF_TL="$SF_KD/runtime/metrics/timeline.jsonl"
bash "$LOCK" "$SF_KD" analyzer break --force >/dev/null 2>&1
bash "$LOCK" "$SF_KD" analyzer acquire --owner-id Bowner --ttl-seconds 1 >/dev/null
sleep 2
set +e
bash "$LOCK" "$SF_KD" analyzer status --expect-owner Aowner >/dev/null 2>&1; SF_ST=$?
set -e
assert_eq "他人锁过期后 status 仍报 owner mismatch（3，不是 stale 2）" "$SF_ST" "3"
set +e
bash "$RUN" finish "$SF_ROOT" --skill project-analyzer --session-id s1 --status completed --confidence 70 >/dev/null 2>&1; SF_FIN=$?
set -e
assert_eq "过期他人锁下 finish 被拒绝（exit 2）" "$SF_FIN" "2"
assert_eq "过期他人锁下不写 completed 终态" \
  "$([ -f "$SF_TL" ] && grep -c '"status":"completed"' "$SF_TL" || echo 0)" "0"
assert_eq "过期他人锁下保留运行指针" \
  "$([ -f "$SF_KD/runtime/current-runs/project-analyzer.json" ] && echo yes || echo no)" "yes"

# 8.28 自己的锁过期（owner 仍是自己）→ finish 允许；break 缺 --force 被拒绝
SO_ROOT="$TMP/stale-own-owner"
mkdir -p "$SO_ROOT"
SO_KD="$SO_ROOT/.project-knowledge"
bash "$RUN" start "$SO_ROOT" --skill project-analyzer --goal stale-own --new-task --session-id s1 --ttl-seconds 1 >/dev/null
sleep 2
set +e
bash "$LOCK" "$SO_KD" analyzer break >/dev/null 2>&1; SO_BR=$?
set -e
assert_eq "break 缺 --force 被拒绝（exit 3）" "$SO_BR" "3"
assert_eq "拒绝后锁仍在" \
  "$([ -d "$SO_KD/.locks/analyzer.lock" ] && echo yes || echo no)" "yes"
set +e
bash "$RUN" finish "$SO_ROOT" --skill project-analyzer --session-id s1 --status completed --confidence 75 >/dev/null 2>&1; SO_FIN=$?
set -e
assert_eq "自己的锁过期时 finish 仍可收尾（exit 0）" "$SO_FIN" "0"
assert_eq "自己的锁过期时写入 completed" \
  "$(grep -c '"status":"completed"' "$SO_KD/runtime/metrics/timeline.jsonl" || echo 0)" "1"

# 8.29 .meta.lock 真实并发：touch 与 set-status 交错不损坏 meta、不丢必填字段
MC_ROOT="$TMP/meta-concurrency"
mkdir -p "$MC_ROOT"
MC_KD="$MC_ROOT/.project-knowledge"
MC_T="$(bash "$REG" create "并发任务" --slug meta-race --skill project-planner --dir "$MC_KD")"
MC_PIDS=()
for i in $(seq 1 10); do
  bash "$REG" touch "$MC_T" --dir "$MC_KD" >/dev/null 2>&1 &
  MC_PIDS+=($!)
  if [ $((i % 2)) -eq 0 ]; then
    bash "$REG" set-status "$MC_T" paused --dir "$MC_KD" >/dev/null 2>&1 &
  else
    bash "$REG" set-status "$MC_T" active --dir "$MC_KD" >/dev/null 2>&1 &
  fi
  MC_PIDS+=($!)
done
for p in "${MC_PIDS[@]}"; do wait "$p" || true; done
MC_META="$MC_KD/runtime/tasks/$MC_T/meta.json"
assert_eq "并发后 meta.json 仍是合法 JSON" \
  "$(node -e 'try{JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"));process.stdout.write("ok")}catch(e){process.stdout.write("bad")}' "$MC_META")" "ok"
assert_eq "并发后 goal 未丢失" \
  "$(node -e 'process.stdout.write(require(process.argv[1]).goal)' "$MC_META")" "并发任务"
assert_eq "并发后 task_id 未丢失" \
  "$(node -e 'process.stdout.write(require(process.argv[1]).task_id)' "$MC_META")" "$MC_T"
assert_eq "并发后 status 仍为合法枚举" \
  "$(node -e 'const s=require(process.argv[1]).status;process.stdout.write(["active","paused","completed","abandoned"].includes(s)?"ok":"bad")' "$MC_META")" "ok"
assert_eq "并发后无临时文件残留" \
  "$(find "$MC_KD/runtime/tasks/$MC_T" -name '*.tmp.*' | wc -l | tr -d ' ')" "0"
assert_eq "并发后无 .meta.lock 残留" \
  "$([ -d "$MC_KD/runtime/tasks/$MC_T/.meta.lock" ] && echo yes || echo no)" "no"

# ---------------------------------------------------------------------------
echo "=== 9. analysis-config 合并：不抹掉真实项目配置 ==="
MERGE="$SCRIPT_DIR/analysis-config-merge.mjs"
CFG_ROOT="$TMP/config-proj"
mkdir -p "$CFG_ROOT/.project-knowledge"
# 真实形态（取自 afc）：mode=incremental、无 output、带用户维护的扩展字段
cat > "$CFG_ROOT/.project-knowledge/analysis-config.json" <<'EOF'
{
  "mode": "incremental",
  "projectName": "afc-newcore-web-frontend",
  "depth": "standard",
  "scope": ["workspace", "src-framework"],
  "baseCommit": "8d5c36f",
  "headCommit": "a1b9837",
  "commitsInRange": 429,
  "driftedFiles": 667,
  "dimensions": { "directory": true, "framework": true },
  "driftHotspots": [{ "area": "workspace/views/collection", "files": 138 }],
  "vaultSync": false,
  "createdAt": "2026-08-04T10:00:00+08:00",
  "updatedAt": "2026-09-17T00:00:00+08:00"
}
EOF
cat > "$TMP/draft-ok.json" <<'EOF'
{ "projectName": "afc-newcore-web-frontend", "mode": "incremental", "scope": ["workspace"] }
EOF
MERGE_OUT="$(node "$MERGE" "$CFG_ROOT" "$TMP/draft-ok.json" --apply)"
assert_eq "无 output 字段的草稿可合并（exit 0）" "$?" "0"
assert_eq "incremental 是合法 mode" "$(printf '%s\n' "$MERGE_OUT" | grep -c 'mode 非法')" "0"
CONF="$CFG_ROOT/.project-knowledge/analysis-config.json"
assert_eq "扩展字段 depth 未被抹掉" \
  "$(node -e 'process.stdout.write(String(require(process.argv[1]).depth))' "$CONF")" "standard"
assert_eq "扩展字段 driftHotspots 未被抹掉" \
  "$(node -e 'process.stdout.write(String(require(process.argv[1]).driftHotspots.length))' "$CONF")" "1"
assert_eq "扩展字段 commitsInRange 未被抹掉" \
  "$(node -e 'process.stdout.write(String(require(process.argv[1]).commitsInRange))' "$CONF")" "429"
assert_eq "projectName 不被草稿改写" \
  "$(node -e 'process.stdout.write(require(process.argv[1]).projectName)' "$CONF")" "afc-newcore-web-frontend"
assert_eq "createdAt 不被改写" \
  "$(node -e 'process.stdout.write(require(process.argv[1]).createdAt)' "$CONF")" "2026-08-04T10:00:00+08:00"
assert_eq "写入前已备份" "$(ls "$CFG_ROOT/.project-knowledge/runtime/backups/" 2>/dev/null | wc -l | tr -d ' ')" "1"

# 任务级字段仍必须被拒绝进入根配置
cat > "$TMP/draft-task.json" <<'EOF'
{ "projectName": "afc-newcore-web-frontend", "mode": "incremental", "scope": ["workspace"], "monitorOnly": true }
EOF
DROP_OUT="$(node "$MERGE" "$CFG_ROOT" "$TMP/draft-task.json" --apply)"
assert_eq "monitorOnly 被报告为 DROPPED" "$(printf '%s\n' "$DROP_OUT" | sed -n 's/^DROPPED=//p')" "monitorOnly"
assert_eq "monitorOnly 未进入根配置" \
  "$(node -e 'process.stdout.write(String("monitorOnly" in require(process.argv[1])))' "$CONF")" "false"

# ---------------------------------------------------------------------------
echo "=== 10. knowledge-index 检查：两代 capabilities 形态都能计数 ==="
IDX="$SCRIPT_DIR/check-knowledge-index.sh"
IDX_ROOT="$TMP/index-proj"
mkdir -p "$IDX_ROOT/.project-knowledge"
# v1.1 形态：{ group: { description, files: [...] } }
cat > "$IDX_ROOT/.project-knowledge/knowledge-index.json" <<'EOF'
{
  "schemaVersion": "1.1.0",
  "generatedAt": "2026-09-17T10:30:00+08:00",
  "capabilities": {
    "rules": { "description": "规则", "files": [{ "source": "rules/a.md" }, { "source": "rules/b.md" }] },
    "patterns": { "description": "模式", "files": [{ "source": "patterns/c.md" }] }
  }
}
EOF
IDX_OUT="$(bash "$IDX" "$IDX_ROOT")"
assert_eq "对象形态 capabilities 计出 entries=3" "$(printf '%s\n' "$IDX_OUT" | grep -c 'entries=3')" "1"
assert_eq "对象形态不再误报索引为空" "$(printf '%s\n' "$IDX_OUT" | grep -c '索引为空')" "0"
assert_eq "输出 capability 组数" "$(printf '%s\n' "$IDX_OUT" | grep -c 'groups=2 ')" "1"

# 早期形态：capabilities 直接是数组
mkdir -p "$TMP/index-proj-old/.project-knowledge"
cat > "$TMP/index-proj-old/.project-knowledge/knowledge-index.json" <<'EOF'
{ "schemaVersion": "1.0.0", "generatedAt": "2026-01-01T00:00:00Z", "capabilities": { "rules": [{ "source": "a.md" }] } }
EOF
assert_eq "数组形态 capabilities 仍可计数" \
  "$(bash "$IDX" "$TMP/index-proj-old" | grep -c 'entries=1')" "1"

# ---------------------------------------------------------------------------
echo "=== 11. Claude Code hook 分派（合成 payload） ==="
HOOK="$SCRIPT_DIR/claude-code-lifecycle-hook.sh"
HK_ROOT="$TMP/hook-proj"
mkdir -p "$HK_ROOT/.project-knowledge"
hk_payload() { # event tool skill file cwd [session] [goal]
  node -e '
    const [ev,tool,skill,file,cwd,session,goal]=process.argv.slice(1);
    const ti={};
    if(tool==="Skill"){ti.skill=skill;ti.args=goal||"x";}
    if(file)ti.file_path=file;
    const body={hook_event_name:ev,tool_name:tool,tool_input:ti,cwd,session_id:session||"s1"};
    if(ev==="UserPromptExpansion"){body.command_name=skill;body.expansion_type="slash";if(goal)body.command_args=goal;}
    process.stdout.write(JSON.stringify(body));
  ' "$@"
}

# 11.1 没有运行指针 → 人工编辑放行
assert_eq "无指针时写项目知识放行" \
  "$(hk_payload PreToolUse Write '' "$HK_ROOT/.project-knowledge/architecture/a.md" "$HK_ROOT" | bash "$HOOK")" ""

# 11.2 指针在、锁在 → 放行
bash "$SCRIPT_DIR/runtime-run.sh" start "$HK_ROOT" --skill project-analyzer --goal hook --new-task --session-id s1 >/dev/null
assert_eq "持锁期间写项目知识放行" \
  "$(hk_payload PreToolUse Write '' "$HK_ROOT/.project-knowledge/architecture/a.md" "$HK_ROOT" | bash "$HOOK")" ""

# 11.3 锁被 break 但指针还在 → deny（继续写会互相覆盖）
bash "$LOCK" "$HK_ROOT/.project-knowledge" analyzer break --force >/dev/null 2>&1
BLOCK_OUT="$(hk_payload PreToolUse Write '' "$HK_ROOT/.project-knowledge/architecture/a.md" "$HK_ROOT" | bash "$HOOK")"
assert_eq "锁丢失时 permissionDecision=deny" \
  "$(printf '%s' "$BLOCK_OUT" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{process.stdout.write(JSON.parse(s).hookSpecificOutput.permissionDecision)}catch(e){process.stdout.write("none")}})')" "deny"
assert_eq "deny 使用现行 hookSpecificOutput 格式（不是已弃用的顶层 decision）" \
  "$(printf '%s' "$BLOCK_OUT" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{const j=JSON.parse(s);process.stdout.write(j.decision?"legacy":"current")}catch(e){process.stdout.write("none")}})')" "current"

# 11.4 任务级文件不参与项目级锁校验
assert_eq "写 runtime/ 时放行" \
  "$(hk_payload PreToolUse Write '' "$HK_ROOT/.project-knowledge/runtime/tasks/x.json" "$HK_ROOT" | bash "$HOOK")" ""

# 11.5 每轮 Stop 不触发收尾（否则长任务会被中途释放锁）
hk_payload Stop '' '' '' "$HK_ROOT" | bash "$HOOK" >/dev/null
assert_eq "Stop 不写入终态（Stop 是每轮触发）" \
  "$([ -f "$HK_ROOT/.project-knowledge/runtime/metrics/timeline.jsonl" ] && wc -l < "$HK_ROOT/.project-knowledge/runtime/metrics/timeline.jsonl" | tr -d ' ' || echo 0)" "0"
assert_eq "Stop 后指针仍在" \
  "$([ -f "$HK_ROOT/.project-knowledge/runtime/current-runs/project-analyzer.json" ] && echo yes || echo no)" "yes"

# 11.6 SessionEnd → 兜底终态（degraded），且指针清理
hk_payload SessionEnd '' '' '' "$HK_ROOT" | bash "$HOOK" >/dev/null
HK_TL="$HK_ROOT/.project-knowledge/runtime/metrics/timeline.jsonl"
assert_eq "SessionEnd 兜底恰好一行终态" "$(wc -l < "$HK_TL" | tr -d ' ')" "1"
assert_eq "SessionEnd 兜底记为 degraded" \
  "$(node -e 'const fs=require("fs");process.stdout.write(JSON.parse(fs.readFileSync(process.argv[1],"utf8").trim()).status)' "$HK_TL")" "degraded"
assert_eq "SessionEnd 后指针已清理" \
  "$([ -f "$HK_ROOT/.project-knowledge/runtime/current-runs/project-analyzer.json" ] && echo yes || echo no)" "no"

# 11.7 单一入口：UserPromptExpansion 不创建 Task / Run（Start 只属于 Skill Discovery）
NOAUTO_ROOT="$TMP/hook-noauto"
mkdir -p "$NOAUTO_ROOT/.project-knowledge"
hk_payload UserPromptExpansion '' 'project-analyzer' '' "$NOAUTO_ROOT" | bash "$HOOK" >/dev/null
assert_eq "UserPromptExpansion 不写运行指针" \
  "$([ -f "$NOAUTO_ROOT/.project-knowledge/runtime/current-runs/project-analyzer.json" ] && echo yes || echo no)" "no"
assert_eq "UserPromptExpansion 不创建任务" \
  "$([ -d "$NOAUTO_ROOT/.project-knowledge/runtime/tasks" ] && find "$NOAUTO_ROOT/.project-knowledge/runtime/tasks" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ' || echo 0)" "0"

# 11.8 模型调用 Skill 工具也不登记（Discovery 才是唯一 Start Producer）
hk_payload PreToolUse Skill 'projectSettings:project-analyzer' '' "$NOAUTO_ROOT" | bash "$HOOK" >/dev/null
assert_eq "PreToolUse(Skill) 不写运行指针" \
  "$([ -f "$NOAUTO_ROOT/.project-knowledge/runtime/current-runs/project-analyzer.json" ] && echo yes || echo no)" "no"
assert_eq "PreToolUse(Skill) 不创建任务" \
  "$([ -d "$NOAUTO_ROOT/.project-knowledge/runtime/tasks" ] && find "$NOAUTO_ROOT/.project-knowledge/runtime/tasks" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ' || echo 0)" "0"

# 11.9 SessionEnd 只收本 session 的指针：s2 不得代收 s1 的 run
bash "$SCRIPT_DIR/runtime-run.sh" start "$HK_ROOT" --skill project-analyzer --goal "hook session test" --new-task --session-id s1 >/dev/null
hk_payload SessionEnd '' '' '' "$HK_ROOT" s2 | bash "$HOOK" >/dev/null
assert_eq "别的 session 的 SessionEnd 不代收指针" \
  "$([ -f "$HK_ROOT/.project-knowledge/runtime/current-runs/project-analyzer.json" ] && echo yes || echo no)" "yes"
assert_eq "别的 session 的 SessionEnd 不写 timeline" \
  "$(wc -l < "$HK_TL" | tr -d ' ')" "1"
hk_payload SessionEnd '' '' '' "$HK_ROOT" s1 | bash "$HOOK" >/dev/null
assert_eq "本 session 的 SessionEnd 正常收尾" \
  "$([ -f "$HK_ROOT/.project-knowledge/runtime/current-runs/project-analyzer.json" ] && echo yes || echo no)" "no"
assert_eq "本 session 的 SessionEnd 写第二行终态" \
  "$(wc -l < "$HK_TL" | tr -d ' ')" "2"

# 11.10 写项目级知识时，另一个 session 持锁 → deny；本 session → allow
bash "$SCRIPT_DIR/runtime-run.sh" start "$HK_ROOT" --skill project-analyzer --goal "cross session test" --new-task --session-id s1 >/dev/null
CROSS_OUT="$(hk_payload PreToolUse Write '' "$HK_ROOT/.project-knowledge/architecture/b.md" "$HK_ROOT" s2 | bash "$HOOK")"
assert_eq "另一个 session 持锁时写项目知识被 deny" \
  "$(printf '%s' "$CROSS_OUT" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{process.stdout.write(JSON.parse(s).hookSpecificOutput.permissionDecision)}catch(e){process.stdout.write("none")}})')" "deny"
assert_eq "本 session 持锁时写项目知识放行" \
  "$(hk_payload PreToolUse Write '' "$HK_ROOT/.project-knowledge/architecture/b.md" "$HK_ROOT" s1 | bash "$HOOK")" ""
hk_payload SessionEnd '' '' '' "$HK_ROOT" s1 | bash "$HOOK" >/dev/null

# 11.11 身份未知的旧指针：SessionEnd 不自动收尾（保留给人工恢复，不猜归属）
# 新版 start 一定写 sessionId，所以这里手工造一个旧版指针（无 sessionId）。
LEGACY_ROOT="$TMP/hook-legacy"
mkdir -p "$LEGACY_ROOT/.project-knowledge/runtime/current-runs"
cat > "$LEGACY_ROOT/.project-knowledge/runtime/current-runs/project-analyzer.json" <<'EOF'
{"schemaVersion":"1.0.0","taskId":"task-legacy","runId":"task-legacy/project-analyzer/2026-01-01T00:00:00Z","skill":"project-analyzer","project":"legacy","startedAt":"2026-01-01T00:00:00Z","ownerId":"legacy-owner","status":"running"}
EOF
hk_payload SessionEnd '' '' '' "$LEGACY_ROOT" s1 | bash "$HOOK" >/dev/null
assert_eq "无 sessionId 的旧指针不被 SessionEnd 代收" \
  "$([ -f "$LEGACY_ROOT/.project-knowledge/runtime/current-runs/project-analyzer.json" ] && echo yes || echo no)" "yes"
assert_eq "无 sessionId 的旧指针不写 timeline" \
  "$([ -f "$LEGACY_ROOT/.project-knowledge/runtime/metrics/timeline.jsonl" ] && wc -l < "$LEGACY_ROOT/.project-knowledge/runtime/metrics/timeline.jsonl" | tr -d ' ' || echo 0)" "0"
bash "$SCRIPT_DIR/runtime-run.sh" finish "$LEGACY_ROOT" --skill project-analyzer --status skipped >/dev/null 2>&1 || true
bash "$SCRIPT_DIR/writer-lock.sh" "$LEGACY_ROOT/.project-knowledge" analyzer break --force >/dev/null 2>&1 || true

# 11.12 hook payload 缺少 session_id：SessionEnd 不做任何收尾（身份未知）
NOSESS_ROOT="$TMP/hook-nosession"
mkdir -p "$NOSESS_ROOT"
bash "$SCRIPT_DIR/runtime-run.sh" start "$NOSESS_ROOT" --skill project-analyzer --goal nosess --new-task --session-id s1 >/dev/null
printf '%s' '{"hook_event_name":"SessionEnd","cwd":"'"$NOSESS_ROOT"'","tool_input":{}}' | bash "$HOOK" >/dev/null
assert_eq "payload 无 session_id 的 SessionEnd 不代收指针" \
  "$([ -f "$NOSESS_ROOT/.project-knowledge/runtime/current-runs/project-analyzer.json" ] && echo yes || echo no)" "yes"
bash "$SCRIPT_DIR/runtime-run.sh" finish "$NOSESS_ROOT" --skill project-analyzer --session-id s1 --status skipped >/dev/null 2>&1 || true

# 11.13 --require-goal：无任务且无 goal → exit 3，不创建 "Run <skill>" 脏任务
RG_ROOT="$TMP/hook-require-goal"
mkdir -p "$RG_ROOT"
set +e
bash "$SCRIPT_DIR/runtime-run.sh" start "$RG_ROOT" --skill project-analyzer --require-goal --session-id s1 >/dev/null 2>&1
RG_RC=$?
set -e
assert_eq "--require-goal 且无 goal 时 exit 3" "$RG_RC" "3"
assert_eq "--require-goal 不创建任务" \
  "$([ -d "$RG_ROOT/.project-knowledge/runtime/tasks" ] && find "$RG_ROOT/.project-knowledge/runtime/tasks" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ' || echo 0)" "0"
assert_eq "--require-goal 不写运行指针" \
  "$([ -f "$RG_ROOT/.project-knowledge/runtime/current-runs/project-analyzer.json" ] && echo yes || echo no)" "no"

# 11.14 Reviewer 与 Analyzer 共用 analyzer 锁：Reviewer 持锁时同样保护 knowledge.json
REV_HK="$TMP/hook-reviewer"
mkdir -p "$REV_HK"
bash "$SCRIPT_DIR/runtime-run.sh" start "$REV_HK" --skill project-reviewer --goal review --new-task --session-id r1 >/dev/null
REV_HK_OUT="$(hk_payload PreToolUse Write '' "$REV_HK/.project-knowledge/knowledge.json" "$REV_HK" intruder | bash "$HOOK")"
assert_eq "Reviewer 持 analyzer 锁时其他 session 写 knowledge.json 被 deny" \
  "$(printf '%s' "$REV_HK_OUT" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{process.stdout.write(JSON.parse(s).hookSpecificOutput.permissionDecision)}catch(e){process.stdout.write("none")}})')" "deny"
assert_eq "Reviewer 本 session 写 knowledge.json 放行" \
  "$(hk_payload PreToolUse Write '' "$REV_HK/.project-knowledge/knowledge.json" "$REV_HK" r1 | bash "$HOOK")" ""
bash "$SCRIPT_DIR/runtime-run.sh" finish "$REV_HK" --skill project-reviewer --session-id r1 --status skipped >/dev/null 2>&1 || true

# 11.15 共享锁被持有但没有运行指针 → 无法证明归属，拒绝写项目级知识
NOPTR_HK="$TMP/hook-nopointer"
mkdir -p "$NOPTR_HK/.project-knowledge"
bash "$LOCK" "$NOPTR_HK/.project-knowledge" analyzer acquire --owner-id script-owner >/dev/null
assert_eq "共享锁无指针时写项目知识被 deny" \
  "$(hk_payload PreToolUse Write '' "$NOPTR_HK/.project-knowledge/knowledge.json" "$NOPTR_HK" s1 | bash "$HOOK" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{process.stdout.write(JSON.parse(s).hookSpecificOutput.permissionDecision)}catch(e){process.stdout.write("none")}})')" "deny"
bash "$LOCK" "$NOPTR_HK/.project-knowledge" analyzer break --force >/dev/null 2>&1 || true

# 11.16 Hook 只保护 single-writer 列出的共享资源：decisions/ 不属于共享写入面
bash "$SCRIPT_DIR/runtime-run.sh" start "$HK_ROOT" --skill project-analyzer --goal guard-scope --new-task --session-id s1 >/dev/null
assert_eq "持锁期间写 decisions/ 放行（非共享资源）" \
  "$(hk_payload PreToolUse Write '' "$HK_ROOT/.project-knowledge/decisions/ADR-x.md" "$HK_ROOT" s2 | bash "$HOOK")" ""
assert_eq "持锁期间写 patterns/ 被 deny（共享资源）" \
  "$(hk_payload PreToolUse Write '' "$HK_ROOT/.project-knowledge/patterns/p.md" "$HK_ROOT" s2 | bash "$HOOK" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{process.stdout.write(JSON.parse(s).hookSpecificOutput.permissionDecision)}catch(e){process.stdout.write("none")}})')" "deny"
bash "$SCRIPT_DIR/runtime-run.sh" finish "$HK_ROOT" --skill project-analyzer --session-id s1 --status skipped >/dev/null 2>&1 || true

# 11.17 项目路径含空格：PROTECTED 用数组保存，仍能识别运行指针 / 锁
SP_ROOT="$TMP/hook space proj"
mkdir -p "$SP_ROOT"
bash "$SCRIPT_DIR/runtime-run.sh" start "$SP_ROOT" --skill project-analyzer --goal space --new-task --session-id s1 >/dev/null
assert_eq "含空格路径下持锁写共享资源被 deny" \
  "$(hk_payload PreToolUse Write '' "$SP_ROOT/.project-knowledge/architecture/a.md" "$SP_ROOT" s2 | bash "$HOOK" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{process.stdout.write(JSON.parse(s).hookSpecificOutput.permissionDecision)}catch(e){process.stdout.write("none")}})')" "deny"
bash "$SCRIPT_DIR/runtime-run.sh" finish "$SP_ROOT" --skill project-analyzer --session-id s1 --status skipped >/dev/null 2>&1 || true

# ---------------------------------------------------------------------------
echo
if [ "$FAIL" -eq 0 ]; then
  green "TASK ISOLATION: PASS ($PASS checks)"
  exit 0
else
  red "TASK ISOLATION: FAIL ($FAIL failed, $PASS passed)"
  exit 1
fi
