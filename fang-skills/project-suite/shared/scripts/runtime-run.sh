#!/bin/bash
# Runtime Run v1.0
#
# skill 运行的机械生命周期：task 解析/创建 → 单写者锁 → 运行指针 → 终态 timeline。
# 把原先散落在 prose 里的 Step 0 / Step 0.5 / Delivery §8 收敛**一个入口**，
# 让 hook 或调用方能在任何退出路径上补一条终态记录，而不是靠模型记得写。
#
# Usage:
#   runtime-run.sh start  <project-root> --skill <name>
#                                       (--task-id <id> | --new-task --goal <text> | PS_TASK_ID)
#                                       [--slug <slug>] [--mode <mode>] [--owner-id <id>]
#                                       [--session-id <id>] [--require-goal]
#   runtime-run.sh renew  <project-root> --skill <name> [--owner-id <id>] [--session-id <id>]
#                                       [--ttl-seconds <n>]
#   runtime-run.sh finish <project-root> [--skill <name>] [--status <status>]
#                                       [--confidence <0-100>] [--reason <text>] [--notes <text>]
#                                       [--session-id <id>] [--auto-finalized] [--strict]
#   runtime-run.sh status <project-root>
#
# 语义：
#   - **start 必须带运行身份**：`CLAUDE_CODE_SESSION_ID` / `CLAUDE_SESSION_ID` 为空时必须
#     显式传 `--session-id`，否则拒绝（exit 2）。没有 session 的 Run 无法被 SessionEnd、
#     finish、renew 做身份校验，等于留下一个谁都能收尾的孤儿运行。非 Claude 宿主应通过
#     Host Adapter 生成等价且稳定的 session id，而不是省略。
#   - start 的幂等**按身份校验**：指针存在且锁仍被持有时，只有 task / owner / session
#     三者都一致才复用；且必须 `writer-lock.sh status --expect-owner` 证明真实锁 owner
#     仍是该 Run——锁被 break 后别人 acquire，指针不会自动失效，只查指针会借尸还魂。
#   - 任务身份**所有来源统一校验**（格式 → 存在 → schema → active/paused）：
#     显式 `--task-id`、编排方传的 `PS_TASK_ID`、运行指针里的 task，都走同一个入口。
#     不存在 / schema 不合法 / completed / abandoned → 拒绝启动（exit 2），不建锁、不写指针。
#     paused 允许恢复，并在 start 成功后转回 active。
#   - Runtime **不再自动选择任务**：没有 --task-id / PS_TASK_ID 时不会 resolve 唯一 active 任务。
#     恢复必须显式给任务身份；新建必须 `--new-task --goal`。Task Resolution 的唯一权威是
#     Discovery（见 runtime/mechanisms/task-identity.md）。
#   - Session 身份来自 `CLAUDE_CODE_SESSION_ID`（Claude Code 注入 Bash/Hook 子进程的变量；
#     `CLAUDE_SESSION_ID` 仅作旧宿主兼容）。指针已有 sessionId 而调用方未提供 session 时，
#     finish/renew **一律拒绝**（fail-closed）——「没传 session」不能成为绕过身份检查的路径。
#   - `--require-goal`：没有任务身份且没有 --goal 时直接退出（exit 3），不登记空目标任务。
#     正常启动由 Skill Discovery 调用并传入确认后的 goal。
#   - `--new-task`：明确创建新任务，必须同时给 --goal；不能与 --task-id 同时使用。
#     不传它就不会创建任务（旧行为「有 goal 就自动建」已移除）。
#   - 新建的 Task 在获锁失败时标记为 abandoned：否则会留下一个没有运行指针的孤儿任务。
#     已有任务获锁失败保持原状态。
#   - finish 幂等：没有活动运行 → FINALIZED=0, exit 0（hook 自动收尾可安全重复调用）。
#   - finish 只写**一行**终态记录（同一 runId 已记录则跳过，重试不重复记账）；
#     completed 必须显式给 --confidence。
#   - finish 只结束**本次 Run**（timeline + 释放锁 + 清指针），**不修改长期 Task 的 status**。
#     active/paused/completed 由编排方或用户显式 `task-registry.sh set-status` 决定——
#     单次 skill 完成不等于整个任务完成，finish 自动关任务会让同一任务的后续 skill 认不出它。
#   - finish 的顺序固定为：验指针/session → 验锁 owner → **释放自己的锁** → 追加终态 → 删指针。
#     释放必须早于 append：锁可能已过期并被他人接管，release 以 owner 为条件，是更强的
#     所有权证明；失败（owner 不一致）→ 拒绝写终态（exit 2）、保留指针。
#     锁已不存在 → 按恢复规则允许收尾（告警）。删除指针前还会比对 runId，避免误删新运行。
#   - finish 对 project-analyzer 检查任务级 discovery.json；缺失时写入
#     context.warnings=["discovery-artifact-missing"]（status 不变，只做留痕告警）。
#   - renew 续租单写者锁（长任务每个 checkpoint 调用一次）；TTL 从续租时刻重新计算，
#     不引入后台心跳进程。
#   - 运行指针按 skill 落在 runtime/current-runs/<skill>.json，记录 ownerId / sessionId。
#   - 并发协议（见 runtime/mechanisms/task-identity.md）：同一项目下**不同 task_id** 的
#     同一 skill 允许并行；**同一 task_id + skill** 同一时刻只允许一个活动 Run。
#     共享项目级写者（Analyzer / Releaser / knowledge.json 的 Reviewer）受单写者锁约束，
#     不能靠「不同 task」绕过。
#   - 当前实现限制：运行指针仍按 skill 单槽（runtime/current-runs/<skill>.json），锁也按
#     skill 派生，因此「同一 skill、不同 task 并行」**尚未生效**，start 会复用或拒绝。
#     实现迁移方向：current-runs/<task_id>/<skill>.json，finish / renew / status 按
#     task_id + skill 唯一定位 Run；迁移完成前不得把该场景当作已支持。
#
# Exit:
#   start:  0=ready 1=该 skill 已被其它 owner/session/task 占用 2=参数/任务歧义/锁 stale
#           3=--require-goal 且解析不到任务、也没有 goal（未登记）
#   renew:  0=续租成功 2=参数非法/跨 session/调用方缺 session 3=无活动运行或 owner mismatch
#   finish: 0=已完成或无事可做 2=参数非法/跨 session/锁被他人持有（运行指针保留） 3=--strict 且无活动运行
#   status: 0=有活动运行 4=无活动运行 2=参数非法
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REG="$SCRIPT_DIR/task-registry.sh"
LOCK="$SCRIPT_DIR/writer-lock.sh"
APPEND="$SCRIPT_DIR/timeline-append.sh"

die() { echo "❌ runtime-run: $*" >&2; exit 2; }
usage() { sed -n '/^# Usage:/,/^set -euo pipefail/p' "$0" | sed '$d' >&2; exit 2; }

CMD="${1:-}"
shift || true
ROOT="${1:-}"
shift || true
case "$CMD" in start|finish|status|renew) ;; *) usage ;; esac
[ -n "$ROOT" ] || usage
case "$ROOT" in -*) usage ;; esac
[ -d "$ROOT" ] || die "project-root 不存在: $ROOT"

SKILL=""; TASK_ID=""; GOAL=""; SLUG=""; MODE=""; OWNER=""
SESSION_ID="${CLAUDE_CODE_SESSION_ID:-${CLAUDE_SESSION_ID:-}}"
STATUS=""; CONFIDENCE=""; REASON=""; NOTES=""; TTL=""
AUTO_FINALIZED=0; STRICT=0; REQUIRE_GOAL=0; NEW_TASK=0

while [ $# -gt 0 ]; do
  case "$1" in
    --skill)          SKILL="${2:-}"; shift 2 ;;
    --task-id)        TASK_ID="${2:-}"; shift 2 ;;
    --goal)           GOAL="${2:-}"; shift 2 ;;
    --slug)           SLUG="${2:-}"; shift 2 ;;
    --mode)           MODE="${2:-}"; shift 2 ;;
    --owner-id)       OWNER="${2:-}"; shift 2 ;;
    --session-id)     SESSION_ID="${2:-}"; shift 2 ;;
    --ttl-seconds)    TTL="${2:-}"; shift 2 ;;
    --status)         STATUS="${2:-}"; shift 2 ;;
    --confidence)     CONFIDENCE="${2:-}"; shift 2 ;;
    --reason)         REASON="${2:-}"; shift 2 ;;
    --notes)          NOTES="${2:-}"; shift 2 ;;
    --auto-finalized) AUTO_FINALIZED=1; shift ;;
    --strict)         STRICT=1; shift ;;
    --require-goal)   REQUIRE_GOAL=1; shift ;;
    --new-task)       NEW_TASK=1; shift ;;
    *) echo "runtime-run: unknown arg '$1'" >&2; exit 2 ;;
  esac
done

KD="$ROOT/.project-knowledge"
RUNTIME_DIR="$KD/runtime"
CURRENT_DIR="$RUNTIME_DIR/current-runs"

VALID_SKILLS="project-analyzer project-planner project-architect project-generator project-tester project-reviewer project-refactorer project-documenter project-releaser"
VALID_STATUSES="completed degraded blocked failed skipped"
TASK_RE='^task-[0-9]{8}(-[A-Za-z0-9][A-Za-z0-9._-]*)?$'

valid_skill() { case " $VALID_SKILLS " in *" $1 "*) return 0 ;; *) return 1 ;; esac; }
valid_status() { case " $VALID_STATUSES " in *" $1 "*) return 0 ;; *) return 1 ;; esac; }

# 锁名绑定**共享写入资源**，不是 skill 身份（见 single-writer.md）：
#   - `analyzer` 锁保护项目级知识（graph / statistics / index / 6 个根产物 / knowledge.json）。
#     Analyzer 与 Reviewer 共用它——两者都会写 knowledge.json，必须互相串行。
#   - 其余 skill 暂用完整名作为执行串行锁（当前实现，待收敛为资源名；不影响正确性，
#     只会让「同一 skill 不同 task」暂时无法并行）。
# 运行指针仍按 skill 枚举命名，两者不混用。
lock_name() {
  case "$1" in
    project-analyzer|project-reviewer) echo analyzer ;;
    *) echo "$1" ;;
  esac
}

now_iso() { date -u +%Y-%m-%dT%H:%M:%SZ; }

project_name() {
  node -e '
    const fs=require("fs"),path=require("path");
    const root=process.argv[1];
    try{
      const d=JSON.parse(fs.readFileSync(path.join(root,".project-knowledge","analysis-config.json"),"utf8"));
      const n=d.project||d.projectName||d.name;
      if(typeof n==="string"&&n.trim()){process.stdout.write(n.trim());process.exit(0);}
    }catch(_){}
    process.stdout.write(path.basename(path.resolve(root))||"unknown-project");
  ' "$ROOT"
}

json_field() { # <file> <field>
  node -e '
    const fs=require("fs");
    try{const o=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));const v=o[process.argv[2]];process.stdout.write(v==null?"":String(v));}catch(e){}
  ' "$1" "$2"
}

task_status() { # <task_id> → active / paused / completed / abandoned / ""
  node -e '
    const fs=require("fs");
    try{process.stdout.write(String(JSON.parse(fs.readFileSync(process.argv[1],"utf8")).status||""));}catch(e){}
  ' "$KD/runtime/tasks/$1/meta.json"
}

# 暂停的任务重新启动 Run 后必须回到 active，否则下次 Task Resolution 找不到它。
# 只在「锁 + 指针都已建好」之后调用，启动失败不允许提前恢复状态。
reactivate_paused_task() { # <task_id>
  [ -n "${1:-}" ] || return 0
  [ "$(task_status "$1")" = "paused" ] || return 0
  if bash "$REG" set-status "$1" active --dir "$KD" >/dev/null 2>&1; then
    echo "TASK_STATUS=reactivated" >&2
  else
    echo "⚠️  任务 $1 原为 paused，启动后未能转回 active；请手动 set-status" >&2
  fi
}

# ── 任务身份的唯一校验入口 ──
# 所有来源（显式 --task-id / PS_TASK_ID / 运行指针）都必须走这里。
# 只在显式分支校验会留下绕过路径：PS_TASK_ID 曾能带着不存在的 task 启动成功。
#   格式 → 存在 → schema → 可启动状态（active / paused）
validate_task_meta() { # <task_id>；结果写入 TASK_STATUS_OUT
  local id="${1:-}" meta="$KD/runtime/tasks/${1:-}/meta.json" st
  [ -n "$id" ] || die "task id 为空"
  [[ "$id" =~ $TASK_RE ]] || die "task id 格式非法: $id（应为 task-YYYYMMDD[-slug]）"
  [ -f "$meta" ] || die "task 不存在: $id（拒绝创建没有 Task Registry 记录的 Run）"
  if ! bash "$REG" validate "$id" --dir "$KD" >/dev/null 2>&1; then
    die "task $id 的 meta.json 不符合 task-meta.schema.json；先修复或重建任务，拒绝启动"
  fi
  st="$(task_status "$id")"
  case "$st" in
    active|paused) TASK_STATUS_OUT="$st" ;;
    completed|abandoned)
      die "task $id 状态为 $st，拒绝普通恢复；如确需重开，先 task-registry.sh set-status $id active" ;;
    *) die "task $id 状态非法: '${st:-<empty>}'（允许 active / paused）" ;;
  esac
}

# ═══════════════════════════════════════════════════════════════════════════
# start
# ═══════════════════════════════════════════════════════════════════════════
cmd_start() {
  [ -n "$SKILL" ] || die "start 需要 --skill"
  valid_skill "$SKILL" || die "未知 skill: $SKILL"
  # 没有 session 的 Run 无法被 finish / renew / SessionEnd 做身份校验，
  # 等于留下一个「谁都能收尾」的孤儿运行。非 Claude 宿主由 Host Adapter 生成等价 id。
  if [ -z "$SESSION_ID" ]; then
    die "start 需要运行身份：设置 CLAUDE_CODE_SESSION_ID（Claude Code 自动注入），或显式传 --session-id。没有 session id 的 Run 无法安全收尾。"
  fi
  if [ "$NEW_TASK" -eq 1 ] && [ -n "$TASK_ID" ]; then
    die "--new-task 不能与 --task-id 同时使用（新建任务不指定已有 id）"
  fi
  mkdir -p "$RUNTIME_DIR" "$CURRENT_DIR"
  local run_file="$CURRENT_DIR/$SKILL.json"

  # ── 任务校验：显式 --task-id 必须先证明任务真实、符合 schema 且可恢复 ──
  if [ -n "$TASK_ID" ]; then
    validate_task_meta "$TASK_ID"
  fi

  # --new-task 不参与幂等复用：已有活动运行时必须先收尾，否则会覆盖别人的运行指针
  if [ "$NEW_TASK" -eq 1 ] && [ -f "$run_file" ]; then
    echo "occupied writer=$(lock_name "$SKILL") run=$(json_field "$run_file" runId)（--new-task 要求先收尾现有运行）" >&2
    echo "LOCK=occupied"
    exit 1
  fi

  # ── 幂等：指针存在且锁被持有 → 校验身份后复用；身份不一致则拒绝 ──
  if [ -f "$run_file" ]; then
    local ex_task ex_run ex_start ex_owner ex_session
    ex_task="$(json_field "$run_file" taskId)"
    ex_run="$(json_field "$run_file" runId)"
    ex_start="$(json_field "$run_file" startedAt)"
    ex_owner="$(json_field "$run_file" ownerId)"
    ex_session="$(json_field "$run_file" sessionId)"
    # 指针里的 task 也必须重新校验：meta 可能已被删除、改坏或被标成 completed。
    [ -n "$ex_task" ] && validate_task_meta "$ex_task"
    set +e
    local lock_st lock_rc
    if [ -n "$ex_owner" ]; then
      lock_st="$(bash "$LOCK" "$KD" "$(lock_name "$SKILL")" status --expect-owner "$ex_owner" 2>&1)"
    else
      lock_st="$(bash "$LOCK" "$KD" "$(lock_name "$SKILL")" status 2>&1)"
    fi
    lock_rc=$?
    set -e
    # 指针在、锁在，不代表这把锁还是这个 Run 的：锁可能被 break 后由别人 acquire。
    # status --expect-owner 直接给出 owner 比对结果（3 = 不一致）。
    if [ "$lock_rc" -eq 3 ]; then
      echo "occupied writer=$(lock_name "$SKILL") $lock_st（指针 owner=$ex_owner 与真实锁 owner 不一致，锁可能被 break 后由他人接管）；拒绝复用" >&2
      echo "LOCK=occupied"
      exit 1
    fi
    if [ "$lock_rc" -eq 0 ] && [ -n "$ex_task" ]; then
      # 同一个 run 的幂等复用必须身份一致：不同 session / owner / task 不是同一个运行。
      # 以前只看「指针在 + 锁在」，导致第二个 session 或第二个 task 的 start 静默拿到别人的 run。
      if [ -n "$ex_session" ] && [ -z "$SESSION_ID" ]; then
        echo "occupied writer=$(lock_name "$SKILL") owner=$ex_owner session=$ex_session（调用方未提供 session id）" >&2
        echo "LOCK=occupied"
        exit 1
      fi
      if [ -n "$SESSION_ID" ] && [ -n "$ex_session" ] && [ "$SESSION_ID" != "$ex_session" ]; then
        echo "occupied writer=$(lock_name "$SKILL") owner=$ex_owner session=$ex_session（请求 session=$SESSION_ID）" >&2
        echo "LOCK=occupied"
        exit 1
      fi
      if [ -n "$OWNER" ] && [ -n "$ex_owner" ] && [ "$OWNER" != "$ex_owner" ]; then
        echo "occupied writer=$(lock_name "$SKILL") owner=$ex_owner（请求 owner=$OWNER）" >&2
        echo "LOCK=occupied"
        exit 1
      fi
      if [ -n "$TASK_ID" ] && [ "$TASK_ID" != "$ex_task" ]; then
        echo "❌ runtime-run: skill=$SKILL 已有活动运行 task=$ex_task；不能同时以 task=$TASK_ID 启动。先 finish 旧运行，或换一个 --skill。" >&2
        echo "LOCK=occupied"
        exit 1
      fi
      reactivate_paused_task "$ex_task"
      echo "TASK_ID=$ex_task"
      echo "RUN_ID=$ex_run"
      echo "STARTED_AT=$ex_start"
      echo "OWNER_ID=$ex_owner"
      echo "SESSION_ID=$ex_session"
      echo "LOCK=reused"
      echo "REUSED=1"
      return 0
    fi
    # 锁已不在 → 用原 run 的身份重新加锁，不新开一次运行。
    # 但调用方明确要求了另一个 task/session/owner 时不能借尸还魂：先收尾旧指针。
    if [ -n "$TASK_ID" ] && [ -n "$ex_task" ] && [ "$TASK_ID" != "$ex_task" ]; then
      die "存在未收尾的旧运行（task=$ex_task，锁已丢失）。先 finish/接管它，再以 task=$TASK_ID 启动。"
    fi
    if [ -n "$ex_session" ] && [ -z "$SESSION_ID" ]; then
      die "存在未收尾的旧运行（session=$ex_session，锁已丢失），调用方未提供 session id。先由原 session 收尾或 break --force，再显式传 --session-id 启动。"
    fi
    if [ -n "$SESSION_ID" ] && [ -n "$ex_session" ] && [ "$SESSION_ID" != "$ex_session" ]; then
      die "存在未收尾的旧运行（session=$ex_session，锁已丢失）。先由原 session 收尾或 break --force，再以 session=$SESSION_ID 启动。"
    fi
    if [ -n "$OWNER" ] && [ -n "$ex_owner" ] && [ "$OWNER" != "$ex_owner" ]; then
      die "存在未收尾的旧运行（owner=$ex_owner，锁已丢失）。先 finish/接管它，再以 owner=$OWNER 启动。"
    fi
    [ -n "$OWNER" ] || OWNER="$ex_owner"
    [ -n "$TASK_ID" ] || TASK_ID="$ex_task"
    [ -n "$ex_start" ] && STARTED_AT_OVERRIDE="$ex_start"
  fi

  # ── Step 0：任务解析（Runtime 不猜任务） ──
  # 任务选择的唯一权威是 Discovery：
  #   恢复 → 必须显式给任务身份（--task-id 或编排方传 PS_TASK_ID）
  #   新建 → 必须 --new-task --goal
  # 不再用 `task-registry resolve` 自动挑唯一 active 任务——那等于把 Task Resolution
  # 从 Discovery 挪回 Runtime，且给了「悄悄启动到错误任务」的路径。
  if [ -z "$TASK_ID" ] && [ "$NEW_TASK" -eq 0 ]; then
    if [ -n "${PS_TASK_ID:-}" ]; then
      TASK_ID="$PS_TASK_ID"
      validate_task_meta "$TASK_ID"
    else
      if [ "$REQUIRE_GOAL" -eq 1 ] && [ -z "$GOAL" ]; then
        echo "NO_TASK_NO_GOAL"
        exit 3
      fi
      die "未指定任务：恢复已有任务请显式 --task-id <id>（或由编排方传 PS_TASK_ID）；新建任务请 --new-task --goal <goal>"
    fi
  fi
  local created_task=0
  if [ "$NEW_TASK" -eq 1 ]; then
    if [ -z "$GOAL" ]; then
      # 没有 goal 的任务是脏数据（历史兜底会写成 "Run <skill>"），拒绝登记。
      if [ "$REQUIRE_GOAL" -eq 1 ]; then
        echo "NO_TASK_NO_GOAL"
        exit 3
      fi
      die "--new-task 需要 --goal（调用方应传用户确认后的 goal）"
    fi
    # 默认 slug 用 skill 名：goal 常是中文，slugify 会退化成时间戳，
    # 而 task id 需要可读、可 grep、且满足 TASK_RE。
    [ -n "$SLUG" ] || SLUG="$SKILL"
    TASK_ID="$(bash "$REG" create "$GOAL" --slug "$SLUG" --skill "$SKILL" --dir "$KD")"
    created_task=1
  fi

  # 获锁失败时，本次新建的 Task 不能以 active 留下：它会变成没有运行指针的孤儿任务，
  # 污染后续 Task Resolution。已有任务失败则保持原状态（不要误关）。
  abandon_created_task() {
    [ "$created_task" -eq 1 ] || return 0
    if bash "$REG" set-status "$TASK_ID" abandoned --dir "$KD" >/dev/null 2>&1; then
      echo "⚠️  获锁失败，新建任务 $TASK_ID 已标记 abandoned" >&2
      echo "TASK_STATUS=abandoned"
    else
      echo "⚠️  获锁失败，但新建任务 $TASK_ID 未能标记 abandoned；请手动 set-status" >&2
    fi
  }

  # ── Step 0.5：单写者锁 ──
  [ -n "$OWNER" ] || OWNER="${TASK_ID}@${SESSION_ID:-session-$$}"
  set +e
  local lock_out
  lock_out="$(bash "$LOCK" "$KD" "$(lock_name "$SKILL")" acquire --owner-id "$OWNER" 2>&1)"
  local lock_rc=$?
  set -e
  case "$lock_rc" in
    0) ;;
    1) echo "$lock_out" >&2; abandon_created_task; echo "LOCK=occupied"; exit 1 ;;
    2) echo "$lock_out" >&2; abandon_created_task; echo "LOCK=stale"; exit 2 ;;
    *) echo "$lock_out" >&2; abandon_created_task; exit 2 ;;
  esac

  local started_at="${STARTED_AT_OVERRIDE:-$(now_iso)}"
  local project run_id
  project="$(project_name)"
  run_id="${TASK_ID}/${SKILL}/${started_at}"

  SKILL="$SKILL" TASK_ID="$TASK_ID" RUN_ID="$run_id" STARTED_AT="$started_at" \
  OWNER="$OWNER" SESSION_ID="$SESSION_ID" PROJECT="$project" MODE="$MODE" GOAL="$GOAL" \
  node -e '
    const fs=require("fs");
    const e=process.env;
    const rec={
      schemaVersion:"1.0.0",
      taskId:e.TASK_ID, runId:e.RUN_ID, skill:e.SKILL, project:e.PROJECT,
      startedAt:e.STARTED_AT, ownerId:e.OWNER, status:"running",
    };
    if(e.SESSION_ID) rec.sessionId=e.SESSION_ID;
    if(e.MODE) rec.mode=e.MODE;
    if(e.GOAL) rec.goal=e.GOAL;
    const out=JSON.stringify(rec)+"\n";
    fs.writeFileSync(process.argv[1],out);
  ' "$run_file"

  if ! bash "$REG" touch "$TASK_ID" --dir "$KD" >/dev/null 2>&1; then
    echo "⚠️  无法更新任务 $TASK_ID 的 meta.json（last activity 未刷新）；运行继续" >&2
  fi
  # 显式恢复一个 paused 任务：锁和指针都建好之后才转回 active。
  [ "$created_task" -eq 1 ] || reactivate_paused_task "$TASK_ID"

  echo "TASK_ID=$TASK_ID"
  echo "RUN_ID=$run_id"
  echo "STARTED_AT=$started_at"
  echo "OWNER_ID=$OWNER"
  echo "SESSION_ID=$SESSION_ID"
  echo "LOCK=acquired"
  echo "REUSED=0"
}

# ═══════════════════════════════════════════════════════════════════════════
# finish
# ═══════════════════════════════════════════════════════════════════════════
cmd_finish() {
  if [ ! -d "$CURRENT_DIR" ]; then
    if [ "$STRICT" -eq 1 ]; then
      echo "❌ runtime-run: 没有活动运行可收尾" >&2
      exit 3
    fi
    echo "FINALIZED=0"
    echo "STATUS=none"
    return 0
  fi

  # ── 定位运行指针 ──
  local run_file=""
  if [ -n "$SKILL" ]; then
    valid_skill "$SKILL" || die "未知 skill: $SKILL"
    [ -f "$CURRENT_DIR/$SKILL.json" ] && run_file="$CURRENT_DIR/$SKILL.json"
  else
    local files=("$CURRENT_DIR"/*.json)
    if [ -e "${files[0]}" ]; then
      if [ "${#files[@]}" -gt 1 ]; then
        local names
        names="$(printf '%s\n' "${files[@]}" | xargs -n1 basename | tr '\n' ' ')"
        die "存在多个活动运行，finish 必须指定 --skill（$names）"
      fi
      run_file="${files[0]}"
      SKILL="$(basename "$run_file" .json)"
    fi
  fi

  if [ -z "$run_file" ] || [ ! -f "$run_file" ]; then
    if [ "$STRICT" -eq 1 ]; then
      echo "❌ runtime-run: 没有活动运行可收尾" >&2
      exit 3
    fi
    echo "FINALIZED=0"
    echo "STATUS=none"
    return 0
  fi

  # ── 跨 session 保护：指针有 sessionId 时，调用方必须能证明自己是同一个 session ──
  # 「没传 session」不是放行理由：否则任意 shell 都能收尾别人的运行。
  local pointer_session
  pointer_session="$(json_field "$run_file" sessionId)"
  if [ -n "$pointer_session" ] && [ -z "$SESSION_ID" ]; then
    die "运行属于 session=$pointer_session，但调用方没有提供 session id。请设置 CLAUDE_CODE_SESSION_ID 或显式传 --session-id；拒绝在身份未知时收尾。"
  fi
  if [ -n "$SESSION_ID" ] && [ -n "$pointer_session" ] && [ "$SESSION_ID" != "$pointer_session" ]; then
    die "运行属于另一个 session（$pointer_session，请求 $SESSION_ID）；拒绝跨 session 收尾。请由原 session 收尾，或先确认后人工 finish。"
  fi

  # ── 终态与 confidence ──
  if [ -z "$STATUS" ]; then
    if [ "$AUTO_FINALIZED" -eq 1 ]; then STATUS="degraded"; else STATUS="skipped"; fi
  fi
  valid_status "$STATUS" || die "status 非法: $STATUS（允许 $VALID_STATUSES）"

  if [ "$STATUS" = "completed" ]; then
    [ -n "$CONFIDENCE" ] || die "completed 必须显式给 --confidence 0-100（0 只用于未评估的运行）"
    case "$CONFIDENCE" in ''|*[!0-9]*) die "--confidence 必须是 0-100 的整数" ;; esac
    [ "$CONFIDENCE" -le 100 ] || die "--confidence 必须是 0-100 的整数"
  else
    [ -n "$CONFIDENCE" ] || CONFIDENCE=0
    case "$CONFIDENCE" in ''|*[!0-9]*) die "--confidence 必须是 0-100 的整数" ;; esac
    [ "$CONFIDENCE" -le 100 ] || die "--confidence 必须是 0-100 的整数"
  fi

  if [ -z "$REASON" ]; then
    case "$STATUS" in
      degraded) [ "$AUTO_FINALIZED" -eq 1 ] && REASON="auto-finalized: run stopped before Delivery" || REASON="degraded run" ;;
      skipped)  REASON="no terminal status supplied" ;;
      blocked)  REASON="blocked" ;;
      failed)   REASON="failed" ;;
      completed) ;;
    esac
  fi

  # ── 组装并追加终态记录（校验失败 → 保留指针，可修正后重试） ──
  local task_id run_id started_at owner_id project finished_at record warnings
  task_id="$(json_field "$run_file" taskId)"
  run_id="$(json_field "$run_file" runId)"
  started_at="$(json_field "$run_file" startedAt)"
  owner_id="$(json_field "$run_file" ownerId)"
  project="$(json_field "$run_file" project)"
  [ -n "$project" ] || project="$(project_name)"
  finished_at="$(now_iso)"

  # ── 产物完整性告警（不进 status：缺产物不等于运行失败，但必须可见） ──
  # Analyzer 的 Discovery 契约要求留任务级 discovery.json（本次范围/深度的决策依据）。
  # 实测出现过「运行成功、根配置未被污染，但任务目录里没有 discovery.json」的情况——
  # 只看 status=completed 会漏掉这条留痕缺口，所以在终态记录里带上 warnings。
  warnings=""
  if [ "$SKILL" = "project-analyzer" ] && [ ! -f "$KD/runtime/tasks/$task_id/discovery.json" ]; then
    warnings="discovery-artifact-missing"
    echo "⚠️  Discovery 产物缺失: $KD/runtime/tasks/$task_id/discovery.json（已记入 context.warnings）" >&2
  fi

  record="$(SKILL="$SKILL" TASK_ID="$task_id" RUN_ID="$run_id" PROJECT="$project" \
    STARTED_AT="$started_at" FINISHED_AT="$finished_at" STATUS="$STATUS" \
    CONFIDENCE="$CONFIDENCE" REASON="$REASON" NOTES="$NOTES" AUTO="$AUTO_FINALIZED" \
    WARNINGS="$warnings" \
    node -e '
      const e=process.env;
      const s=Date.parse(e.STARTED_AT), f=Date.parse(e.FINISHED_AT);
      const rec={
        schemaVersion:"2.0.0",
        project:e.PROJECT,
        taskId:e.TASK_ID,
        runId:e.RUN_ID,
        skill:e.SKILL,
        status:e.STATUS,
        timing:{startedAt:e.STARTED_AT,finishedAt:e.FINISHED_AT,durationMs:(!isNaN(s)&&!isNaN(f)&&f>=s)?f-s:0},
        quality:{confidence:Number(e.CONFIDENCE)},
      };
      const ctx={};
      if(e.REASON) ctx.reason=e.REASON;
      if(e.NOTES) ctx.notes=e.NOTES;
      if(e.AUTO==="1") ctx.autoFinalized=true;
      if(e.WARNINGS) ctx.warnings=e.WARNINGS.split(",");
      if(Object.keys(ctx).length) rec.context=ctx;
      process.stdout.write(JSON.stringify(rec));
    ')"

  # ── 锁所有权：先证明「这把锁还是本次 Run 的」，再释放，最后才写终态 ──
  # 为什么释放必须早于 append：锁可能已经过期并被别人接管（stale + owner mismatch）。
  # 只做一次 status 预检查仍有竞争窗口；release 以 owner 为条件，是更强的所有权证明。
  # 若锁已被他人接管 → release 失败 → 拒绝写 completed。timeline 是 append-only，
  # 假的 completed 事后无法纠正；而「已释放但未记账」可以重试（指针保留、锁已不存在）。
  local pointer_owner pre_lock_st pre_lock_rc
  pointer_owner="$(json_field "$run_file" ownerId)"
  if [ -n "$pointer_owner" ]; then
    set +e
    pre_lock_st="$(bash "$LOCK" "$KD" "$(lock_name "$SKILL")" status --expect-owner "$pointer_owner" 2>&1)"
    pre_lock_rc=$?
    set -e
    case "$pre_lock_rc" in
      3)
        die "单写者锁不属于本次运行 owner=$pointer_owner（$pre_lock_st，锁可能已被 break 并被接管）。拒绝写终态；运行指针保留，请先确认现场。" ;;
      4)
        echo "⚠️  单写者锁已不存在（可能被 break）；按恢复规则继续，终态归本次 run" >&2 ;;
      0|2)
        if ! bash "$LOCK" "$KD" "$(lock_name "$SKILL")" release --owner-id "$pointer_owner" >/dev/null 2>&1; then
          die "单写者锁释放失败（owner=$pointer_owner）。拒绝写终态；运行指针保留，请先确认现场。"
        fi ;;
      *)
        die "无法确认单写者锁状态（$pre_lock_st）" ;;
    esac
  fi

  # ── 追加终态记录（同一 runId 只写一行：重试不重复记账） ──
  local append_out append_rc timeline_file
  timeline_file="$KD/runtime/metrics/timeline.jsonl"
  if [ -f "$timeline_file" ] && grep -F -q "\"runId\":\"$run_id\"" "$timeline_file"; then
    echo "⚠️  timeline 已有 runId=$run_id 的终态记录；跳过重复追加" >&2
    append_out="already-recorded"
  else
    set +e
    append_out="$(printf '%s' "$record" | bash "$APPEND" "$ROOT" -)"
    append_rc=$?
    set -e
    if [ "$append_rc" -ne 0 ]; then
      die "终态写入失败（锁已释放；运行指针保留，可修复后重试 finish）"
    fi
  fi

  # ── 清理指针（只删本次 run 的指针，避免并发下误删刚创建的新运行） ──
  local cur_run_id
  cur_run_id="$(json_field "$run_file" runId)"
  if [ "$cur_run_id" = "$run_id" ]; then
    rm -f "$run_file"
  else
    echo "⚠️  运行指针已被另一个 run 替换（当前 ${cur_run_id:-<empty>}，本次 $run_id）；不删除" >&2
  fi

  # ── 任务状态：不在这里关闭。finish 只结束 Run；长期 Task 的 active/paused/completed
  #    由编排方或用户显式 `task-registry.sh set-status` 决定。这里只刷新 last activity，
  #    保证同一任务的后续 Skill 仍能 resume 到它，而不是新建一个任务。
  if ! bash "$REG" touch "$task_id" --dir "$KD" >/dev/null 2>&1; then
    echo "⚠️  无法刷新任务 $task_id 的 last activity；终态已记录" >&2
  fi

  echo "FINALIZED=1"
  echo "STATUS=$STATUS"
  echo "RUN_ID=$run_id"
  echo "CONFIDENCE=$CONFIDENCE"
  echo "WARNINGS=$warnings"
  echo "TIMELINE=$append_out"
}

# ═══════════════════════════════════════════════════════════════════════════
# renew
# ═══════════════════════════════════════════════════════════════════════════
cmd_renew() {
  [ -n "$SKILL" ] || die "renew 需要 --skill"
  valid_skill "$SKILL" || die "未知 skill: $SKILL"
  local run_file="$CURRENT_DIR/$SKILL.json"
  if [ ! -f "$run_file" ]; then
    echo "NO_ACTIVE_RUN"
    exit 3
  fi

  local owner_id pointer_session
  owner_id="$(json_field "$run_file" ownerId)"
  pointer_session="$(json_field "$run_file" sessionId)"
  if [ -n "$pointer_session" ] && [ -z "$SESSION_ID" ]; then
    die "运行属于 session=$pointer_session，但调用方没有提供 session id。拒绝在身份未知时续租。"
  fi
  if [ -n "$SESSION_ID" ] && [ -n "$pointer_session" ] && [ "$SESSION_ID" != "$pointer_session" ]; then
    die "运行属于另一个 session（$pointer_session，请求 $SESSION_ID）；拒绝续租"
  fi
  [ -n "$OWNER" ] || OWNER="$owner_id"
  [ -n "$OWNER" ] || die "运行指针缺少 ownerId，无法续租"

  local renew_out rc
  set +e
  if [ -n "$TTL" ]; then
    renew_out="$(bash "$LOCK" "$KD" "$(lock_name "$SKILL")" renew --owner-id "$OWNER" --ttl-seconds "$TTL" 2>&1)"
  else
    renew_out="$(bash "$LOCK" "$KD" "$(lock_name "$SKILL")" renew --owner-id "$OWNER" 2>&1)"
  fi
  rc=$?
  set -e
  if [ "$rc" -ne 0 ]; then
    echo "$renew_out" >&2
    exit "$rc"
  fi

  echo "$renew_out"
  echo "RENEWED=1"
}

# ═══════════════════════════════════════════════════════════════════════════
# status
# ═══════════════════════════════════════════════════════════════════════════
cmd_status() {
  if [ ! -d "$CURRENT_DIR" ]; then
    echo "NO_ACTIVE_RUNS"
    exit 4
  fi
  local any=0 f
  for f in "$CURRENT_DIR"/*.json; do
    [ -f "$f" ] || continue
    any=1
    local skill lock_state
    skill="$(basename "$f" .json)"
    set +e
    bash "$LOCK" "$KD" "$(lock_name "$skill")" status >/dev/null 2>&1; local rc=$?
    set -e
    if [ "$rc" -eq 0 ]; then lock_state="locked"; else lock_state="unlocked"; fi
    echo "RUN skill=$skill task=$(json_field "$f" taskId) session=$(json_field "$f" sessionId) startedAt=$(json_field "$f" startedAt) lock=$lock_state"
  done
  if [ "$any" -eq 0 ]; then
    echo "NO_ACTIVE_RUNS"
    exit 4
  fi
}

case "$CMD" in
  start)  cmd_start ;;
  renew)  cmd_renew ;;
  finish) cmd_finish ;;
  status) cmd_status ;;
esac
