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
bash "$LOCK" "$KD" analyzer break >/dev/null 2>&1
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

# ---------------------------------------------------------------------------
echo
if [ "$FAIL" -eq 0 ]; then
  green "TASK ISOLATION: PASS ($PASS checks)"
  exit 0
else
  red "TASK ISOLATION: FAIL ($FAIL failed, $PASS passed)"
  exit 1
fi
