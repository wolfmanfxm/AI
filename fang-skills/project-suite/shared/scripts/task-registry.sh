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
#   task-registry.sh touch  <task_id> [--dir <kd>]
#   task-registry.sh set-status <task_id> <status> [--dir <kd>]
#   task-registry.sh validate <task_id> [--dir <kd>]   # 对照 task-meta.schema.json
#
# 约定：
#   - 路径解析优先级：显式参数 → $PS_TASK_ID → 唯一 active 任务
#   - 多 active 任务时 resolve 返回 2，调用方必须让用户选择，禁止猜
#   - 任务目录是审计证据，不自动删除
#   - create/touch/set-status 写盘后自动 validate：schema 是唯一权威，不再另写一份字段清单
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
META_SCHEMA="$SCRIPT_DIR/../schemas/task-meta.schema.json"

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

# meta.json 的读改写互斥。create 用 mkdir 抢任务目录（天然互斥），但 touch / set-status
# 是「读 → 改 → 写」，同一任务下两个不同 Skill 并发执行会丢更新。锁粒度是单个 Task，
# 不引入全局 Task Manager。持有时间只有一次 JSON 重写，30s 未释放视为陈旧锁。
meta_lock() { # <task_id>
  local d="$TASKS_DIR/$1/.meta.lock" i=0 mt age
  while ! mkdir "$d" 2>/dev/null; do
    i=$((i+1))
    if [ "$i" -ge 100 ]; then
      mt="$(stat -f %m "$d" 2>/dev/null || stat -c %Y "$d" 2>/dev/null || echo 0)"
      age=$(( $(date +%s) - ${mt:-0} ))
      if [ "${age:-0}" -gt 30 ]; then rm -rf "$d"; continue; fi
      echo "task-registry: meta.json 正被另一个写者更新（$1）" >&2
      return 1
    fi
    sleep 0.05
  done
}
meta_unlock() { rmdir "$TASKS_DIR/$1/.meta.lock" 2>/dev/null || true; }

meta_field() { # <meta-file> <field>
  node -e 'const fs=require("fs");try{const o=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));const v=o[process.argv[2]];process.stdout.write(v==null?"":String(v))}catch(e){process.stdout.write("")}' "$1" "$2"
}

write_meta() { # <meta-file> <task_id> <goal> <skill>
  node -e '
    const fs=require("fs");
    const [file,id,goal,skill,now]=process.argv.slice(1);
    // 不再写 skills[]：它没有消费者（执行历史以 timeline 为准），只为维护它引入
    // 读改写竞争不值得。schema 保留该字段用于读取历史任务。
    const meta={schemaVersion:"1.0.0",task_id:id,goal:goal,status:"active",
      originating_skill:skill||null,artifacts:{},
      created_at:now,updated_at:now};
    fs.writeFileSync(file, JSON.stringify(meta,null,2)+"\n");
  ' "$1" "$2" "$3" "$4" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}

slugify() { # 中文等非 ASCII → 回退到时间戳，调用方应显式 --slug
  # ⚠️ 必须 `LC_ALL=C`：UTF-8 locale 下 BSD sed 的 [^a-z0-9] 不会匹配多字节字符，
  #    中文 goal 会原样留在 slug 里 → task-20261109-分析 违反 TASK_RE，timeline 拒收。
  # ⚠️ 不能用 `\+`：macOS(BSD) sed 在 C locale 下不展开该扩展 → 整段中文原样保留。
  #    用 `[^a-z0-9][^a-z0-9]*` 表达「一个或多个」才跨平台有效。
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | LC_ALL=C sed 's/[^a-z0-9][^a-z0-9]*/-/g; s/^-//; s/-$//' \
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
  validate_meta "$id" || die "create: meta.json 不符合 task-meta.schema.json"
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
  local id="${1:-}"
  [ -n "$id" ] || die "touch: <task_id> required"
  local f="$TASKS_DIR/$id/meta.json"
  [ -f "$f" ] || die "touch: no such task '$id'"
  meta_lock "$id" || die "touch: $id 的 meta.json 被占用，稍后重试"
  local nrc
  set +e
  node -e '
    const fs=require("fs");
    const [file,now]=process.argv.slice(1);
    const m=JSON.parse(fs.readFileSync(file,"utf8"));
    // skills[] 不再维护（无消费者，执行历史以 timeline 为准）；touch 只刷新活动时间。
    m.updated_at=now;
    const tmp=file+".tmp."+process.pid;
    fs.writeFileSync(tmp, JSON.stringify(m,null,2)+"\n");
    fs.renameSync(tmp,file);
  ' "$f" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  nrc=$?
  set -e
  meta_unlock "$id"
  [ "$nrc" -eq 0 ] || die "touch: 写入 meta.json 失败"
  validate_meta "$id"
}

cmd_set_status() {
  local id="${1:-}" status="${2:-}"
  [ -n "$id" ] && [ -n "$status" ] || die "set-status: <task_id> <status> required"
  case "$status" in active|paused|completed|abandoned) ;; *) die "set-status: invalid status '$status'" ;; esac
  local f="$TASKS_DIR/$id/meta.json"
  [ -f "$f" ] || die "set-status: no such task '$id'"
  meta_lock "$id" || die "set-status: $id 的 meta.json 被占用，稍后重试"
  local nrc
  set +e
  node -e '
    const fs=require("fs");
    const [file,status,now]=process.argv.slice(1);
    const m=JSON.parse(fs.readFileSync(file,"utf8"));
    m.status=status; m.updated_at=now;
    const tmp=file+".tmp."+process.pid;
    fs.writeFileSync(tmp, JSON.stringify(m,null,2)+"\n");
    fs.renameSync(tmp,file);
  ' "$f" "$status" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  nrc=$?
  set -e
  meta_unlock "$id"
  [ "$nrc" -eq 0 ] || die "set-status: 写入 meta.json 失败"
  validate_meta "$id"
}

# 对照 task-meta.schema.json 校验：required / additionalProperties:false / const / enum /
# pattern / minLength / type（含 integer）/ format: date-time / items / additionalProperties。
# 这是 schema 在写入路径上的消费者——否则 schema 只是“登记了但没人读”的文档。
# 支持范围即上面这些关键字；新增 schema 关键字时需同步扩展本函数。
validate_meta() { # <task_id>
  local id="${1:-}" f="$TASKS_DIR/$id/meta.json" out rc
  [ -f "$f" ] || { echo "task-registry: validate: no such task '$id'" >&2; return 1; }
  set +e
  out="$(node -e '
    const fs=require("fs");
    const [file,schemaPath]=process.argv.slice(1);
    const m=JSON.parse(fs.readFileSync(file,"utf8"));
    const s=JSON.parse(fs.readFileSync(schemaPath,"utf8"));
    const errs=[];
    const isDateTime=v=>typeof v==="string"&&
      /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})$/.test(v)&&
      !Number.isNaN(Date.parse(v));
    function typeMatches(t,v){
      const ts=Array.isArray(t)?t:[t];
      return ts.some(x=>
        x==="string"?typeof v==="string":
        x==="integer"?Number.isInteger(v):
        x==="number"?typeof v==="number"&&!Number.isNaN(v):
        x==="object"?(v&&typeof v==="object"&&!Array.isArray(v)):
        x==="array"?Array.isArray(v):
        x==="null"?v===null:
        x==="boolean"?typeof v==="boolean":true);
    }
    function check(def,v,at){
      if(!def||typeof def!=="object")return;
      if(def.const!==undefined&&v!==def.const)errs.push(`${at} 必须是 ${JSON.stringify(def.const)}`);
      if(def.enum&&!def.enum.includes(v))errs.push(`${at}=${JSON.stringify(v)} 不在 ${def.enum.join("/")}`);
      if(def.type&&!typeMatches(def.type,v)){errs.push(`${at} 类型应为 ${[].concat(def.type).join("|")}`);return;}
      if(typeof v==="string"){
        if(def.minLength!==undefined&&v.length<def.minLength)errs.push(`${at} 长度必须 >= ${def.minLength}`);
        if(def.pattern&&!new RegExp(def.pattern).test(v))errs.push(`${at} 不匹配 ${def.pattern}`);
        if(def.format==="date-time"&&!isDateTime(v))errs.push(`${at} 不是合法的 date-time（RFC3339）`);
      }
      if(Array.isArray(v)&&def.items)v.forEach((item,i)=>check(def.items,item,`${at}[${i}]`));
      if(v&&typeof v==="object"&&!Array.isArray(v)&&def.additionalProperties&&typeof def.additionalProperties==="object"){
        for(const k of Object.keys(v))check(def.additionalProperties,v[k],`${at}.${k}`);
      }
    }
    for(const k of (s.required||[])) if(!(k in m)) errs.push(`缺失必填字段 ${k}`);
    for(const k of Object.keys(m)) if(!(k in (s.properties||{}))) errs.push(`不允许的字段 ${k}`);
    for(const [k,def] of Object.entries(s.properties||{})) if(m[k]!==undefined) check(def,m[k],k);
    if(errs.length){for(const e of errs) console.error("task-meta: ❌ "+e);process.exit(1);}
  ' "$f" "$META_SCHEMA" 2>&1)"
  rc=$?
  set -e
  [ "$rc" -eq 0 ] && return 0
  echo "$out" >&2
  return 1
}

cmd_validate() {
  local id="${1:-}"
  [ -n "$id" ] || die "validate: task_id required"
  validate_meta "$id" || die "validate: '$id' 不符合 task-meta.schema.json"
  echo "valid $id"
}

case "$CMD" in
  create)     shift; cmd_create "$@" ;;
  list)       shift; cmd_list "$@" ;;
  resolve)    shift; cmd_resolve "$@" ;;
  show)       shift; cmd_show "$@" ;;
  touch)      shift; cmd_touch "$@" ;;
  set-status) shift; cmd_set_status "$@" ;;
  validate)   shift; cmd_validate "$@" ;;
  ""|-h|--help) sed -n '/^# Task Registry/,/^set -euo pipefail/p' "$0" | sed '$d' ;;
  *) die "unknown command '$CMD'" ;;
esac
