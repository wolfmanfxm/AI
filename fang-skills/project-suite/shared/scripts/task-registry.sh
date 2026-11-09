#!/bin/bash
# Task Registry v1.0
#
# 任务身份的唯一机械入口。目录即注册表（无中央 index → 并发 create 不抢写锁）。
#
#   .project-knowledge/runtime/tasks/<task_id>/meta.json
#
# Usage:
#   task-registry.sh create "<goal>" [--slug <slug>] [--skill <name>] [--dir <kd>]
#   task-registry.sh list   [--status active|paused|completed|abandoned] [--dir <kd>]
#   task-registry.sh resolve [<task_id>] [--dir <kd>]     # 0=ok 2=ambiguous 3=none
#   task-registry.sh show   <task_id> [--dir <kd>]
#   task-registry.sh touch  <task_id> <skill> [--dir <kd>]
#   task-registry.sh set-status <task_id> <status> [--dir <kd>]
#
# 约定：
#   - 路径解析优先级：显式参数 → $PS_TASK_ID → 唯一 active 任务
#   - 多 active 任务时 resolve 返回 2，调用方必须让用户选择，禁止猜
#   - 任务目录是审计证据，不自动删除
set -euo pipefail

KNOWLEDGE_DIR=".project-knowledge"
ARGS=()
for ((i=1; i<=$#; i++)); do
  if [ "${!i}" = "--dir" ]; then
    j=$((i+1)); KNOWLEDGE_DIR="${!j}"; i=$j
  else
    ARGS+=("${!i}")
  fi
done

set -- ${ARGS[@]+"${ARGS[@]}"}
CMD="${1:-}"
TASKS_DIR="${KNOWLEDGE_DIR}/runtime/tasks"

die() { echo "task-registry: $*" >&2; exit 1; }

meta_field() { # <meta-file> <field>
  node -e 'const fs=require("fs");try{const o=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));const v=o[process.argv[2]];process.stdout.write(v==null?"":String(v))}catch(e){process.stdout.write("")}' "$1" "$2"
}

write_meta() { # <meta-file> <task_id> <goal> <skill>
  node -e '
    const fs=require("fs");
    const [file,id,goal,skill,now]=process.argv.slice(1);
    const meta={schemaVersion:"1.0.0",task_id:id,goal:goal,status:"active",
      originating_skill:skill||null,skills:skill?[skill]:[],artifacts:{},
      created_at:now,updated_at:now};
    fs.writeFileSync(file, JSON.stringify(meta,null,2)+"\n");
  ' "$1" "$2" "$3" "$4" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}

slugify() { # 中文等非 ASCII → 回退到时间戳，调用方应显式 --slug
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed 's/[^a-z0-9]\+/-/g; s/^-//; s/-$//' \
    | cut -c1-40
}

cmd_create() {
  local goal="${1:-}" slug="" skill=""
  shift || true
  while [ $# -gt 0 ]; do
    case "$1" in
      --slug) slug="${2:-}"; shift 2 ;;
      --skill) skill="${2:-}"; shift 2 ;;
      *) die "create: unknown arg '$1'" ;;
    esac
  done
  [ -n "$goal" ] || die "create: goal required"
  mkdir -p "$TASKS_DIR"

  local day; day="$(date +%Y%m%d)"
  [ -n "$slug" ] || slug="$(slugify "$goal")"
  [ -n "$slug" ] || slug="$(date +%H%M%S)"
  local base="task-${day}-${slug}"
  local id="$base"
  local n=2
  while ! mkdir "$TASKS_DIR/$id" 2>/dev/null; do
    id="${base}-${n}"; n=$((n+1))
    [ "$n" -gt 99 ] && die "create: too many collisions for $base"
  done
  write_meta "$TASKS_DIR/$id/meta.json" "$id" "$goal" "$skill"
  printf '%s\n' "$id"
}

cmd_list() {
  local want=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --status) want="${2:-}"; shift 2 ;;
      *) die "list: unknown arg '$1'" ;;
    esac
  done
  [ -d "$TASKS_DIR" ] || exit 0
  local d id status goal updated
  for d in "$TASKS_DIR"/*/; do
    [ -f "${d}meta.json" ] || continue
    id="$(basename "$d")"
    status="$(meta_field "${d}meta.json" status)"
    [ -n "$want" ] && [ "$status" != "$want" ] && continue
    goal="$(meta_field "${d}meta.json" goal)"
    updated="$(meta_field "${d}meta.json" updated_at)"
    printf '%s\t%s\t%s\t%s\n' "$id" "$status" "$updated" "$goal"
  done
}

cmd_resolve() {
  local explicit="${1:-}"
  [ -n "$explicit" ] && { [ -d "$TASKS_DIR/$explicit" ] && { printf '%s\n' "$explicit"; exit 0; } || die "resolve: no such task '$explicit'"; }

  if [ -n "${PS_TASK_ID:-}" ]; then
    [ -d "$TASKS_DIR/$PS_TASK_ID" ] || die "resolve: PS_TASK_ID='$PS_TASK_ID' not found"
    printf '%s\n' "$PS_TASK_ID"; exit 0
  fi

  local active
  active="$(cmd_list --status active | cut -f1)"
  local count; count="$(printf '%s' "$active" | grep -c . || true)"
  if [ "$count" -eq 1 ]; then
    printf '%s\n' "$active"; exit 0
  elif [ "$count" -eq 0 ]; then
    exit 3
  else
    echo "task-registry: ${count} active tasks; user must choose:" >&2
    cmd_list --status active >&2
    exit 2
  fi
}

cmd_show() {
  local id="${1:-}"; [ -n "$id" ] || die "show: task_id required"
  [ -f "$TASKS_DIR/$id/meta.json" ] || die "show: no such task '$id'"
  cat "$TASKS_DIR/$id/meta.json"
}

cmd_touch() {
  local id="${1:-}" skill="${2:-}"
  [ -n "$id" ] && [ -n "$skill" ] || die "touch: <task_id> <skill> required"
  local f="$TASKS_DIR/$id/meta.json"
  [ -f "$f" ] || die "touch: no such task '$id'"
  node -e '
    const fs=require("fs");
    const [file,skill,now]=process.argv.slice(1);
    const m=JSON.parse(fs.readFileSync(file,"utf8"));
    m.skills=Array.isArray(m.skills)?m.skills:[];
    if(!m.skills.includes(skill)) m.skills.push(skill);
    m.updated_at=now;
    const tmp=file+".tmp";
    fs.writeFileSync(tmp, JSON.stringify(m,null,2)+"\n");
    fs.renameSync(tmp,file);
  ' "$f" "$skill" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}

cmd_set_status() {
  local id="${1:-}" status="${2:-}"
  [ -n "$id" ] && [ -n "$status" ] || die "set-status: <task_id> <status> required"
  case "$status" in active|paused|completed|abandoned) ;; *) die "set-status: invalid status '$status'" ;; esac
  local f="$TASKS_DIR/$id/meta.json"
  [ -f "$f" ] || die "set-status: no such task '$id'"
  node -e '
    const fs=require("fs");
    const [file,status,now]=process.argv.slice(1);
    const m=JSON.parse(fs.readFileSync(file,"utf8"));
    m.status=status; m.updated_at=now;
    const tmp=file+".tmp";
    fs.writeFileSync(tmp, JSON.stringify(m,null,2)+"\n");
    fs.renameSync(tmp,file);
  ' "$f" "$status" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}

case "$CMD" in
  create)     shift; cmd_create "$@" ;;
  list)       shift; cmd_list "$@" ;;
  resolve)    shift; cmd_resolve "$@" ;;
  show)       shift; cmd_show "$@" ;;
  touch)      shift; cmd_touch "$@" ;;
  set-status) shift; cmd_set_status "$@" ;;
  ""|-h|--help) sed -n '2,22p' "$0" ;;
  *) die "unknown command '$CMD'" ;;
esac
