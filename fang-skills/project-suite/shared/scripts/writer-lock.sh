#!/bin/bash
# Writer Lock v1.0
#
# 项目级真相的单写者约束。mkdir 原子创建锁目录，不依赖 flock（跨平台）。
#
# Usage:
#   writer-lock.sh <knowledge-dir> <writer-name> acquire [--owner-id <id>] [--ttl-seconds <n>]
#   writer-lock.sh <knowledge-dir> <writer-name> release --owner-id <id>
#   writer-lock.sh <knowledge-dir> <writer-name> status
#   writer-lock.sh <knowledge-dir> <writer-name> break
#
# Exit codes:
#   acquire: 0=acquired  1=occupied  2=stale(需显式 break)
#   release: 0=released  3=owner mismatch / not locked
#   status:  0=locked    4=unlocked
set -euo pipefail

KD="${1:-}"; WRITER="${2:-}"; CMD="${3:-}"
[ -n "$KD" ] && [ -n "$WRITER" ] && [ -n "$CMD" ] || { sed -n '2,18p' "$0" >&2; exit 64; }
shift 3

OWNER_ID=""
TTL=3600
while [ $# -gt 0 ]; do
  case "$1" in
    --owner-id)   OWNER_ID="${2:-}"; shift 2 ;;
    --ttl-seconds) TTL="${2:-}"; shift 2 ;;
    *) echo "writer-lock: unknown arg '$1'" >&2; exit 64 ;;
  esac
done

LOCK_ROOT="${KD}/.locks"
LOCK_DIR="${LOCK_ROOT}/${WRITER}.lock"
OWNER_FILE="${LOCK_DIR}/owner.env"

default_owner() { printf 'pid-%s-%s' "$$" "$(hostname 2>/dev/null || echo unknown)"; }
[ -n "$OWNER_ID" ] || OWNER_ID="$(default_owner)"

now_epoch() { date +%s; }

read_owner() { # echo "owner_id|pid|host|started_epoch|ttl"
  [ -f "$OWNER_FILE" ] || return 1
  local owner pid host started ttl
  owner="$(sed -n 's/^owner_id=//p' "$OWNER_FILE" | head -1)"
  pid="$(sed -n 's/^pid=//p' "$OWNER_FILE" | head -1)"
  host="$(sed -n 's/^hostname=//p' "$OWNER_FILE" | head -1)"
  started="$(sed -n 's/^started_epoch=//p' "$OWNER_FILE" | head -1)"
  ttl="$(sed -n 's/^ttl_seconds=//p' "$OWNER_FILE" | head -1)"
  printf '%s|%s|%s|%s|%s\n' "$owner" "$pid" "$host" "${started:-0}" "${ttl:-3600}"
}

is_stale() { # <started> <ttl>
  # 只看 TTL：锁的持有者是 Skill 会话，不是拉起本脚本的短命 shell 进程，
  # 因此 pid 存活与否不能作为判据（acquire 脚本退出后 pid 即消失）。
  local started="$1" ttl="$2" age
  age=$(( $(now_epoch) - ${started:-0} ))
  [ "${age}" -gt "${ttl:-3600}" ]
}

case "$CMD" in
  acquire)
    mkdir -p "$LOCK_ROOT"
    if mkdir "$LOCK_DIR" 2>/dev/null; then
      {
        echo "owner_id=${OWNER_ID}"
        echo "pid=$$"
        echo "hostname=$(hostname 2>/dev/null || echo unknown)"
        echo "started_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        echo "started_epoch=$(now_epoch)"
        echo "ttl_seconds=${TTL}"
      } > "$OWNER_FILE"
      echo "acquired writer=${WRITER} owner=${OWNER_ID}"
      exit 0
    fi
    owner_line="$(read_owner || true)"
    if [ -z "${owner_line:-}" ]; then
      echo "occupied writer=${WRITER} (lock dir exists but owner.env unreadable)" >&2
      exit 1
    fi
    IFS='|' read -r o_id o_pid o_host o_started o_ttl <<< "$owner_line"
    if is_stale "$o_started" "$o_ttl"; then
      echo "stale writer=${WRITER} owner=${o_id} pid=${o_pid} started=${o_started} ttl=${o_ttl}" >&2
      echo "run: writer-lock.sh <kd> ${WRITER} break" >&2
      exit 2
    fi
    echo "occupied writer=${WRITER} owner=${o_id} pid=${o_pid} host=${o_host}" >&2
    exit 1
    ;;
  release)
    [ -d "$LOCK_DIR" ] || { echo "not locked writer=${WRITER}" >&2; exit 3; }
    owner_line="$(read_owner || true)"
    IFS='|' read -r o_id _o_pid _o_host _o_started _o_ttl <<< "${owner_line:-|||}"
    if [ "$o_id" != "$OWNER_ID" ]; then
      echo "owner mismatch: lock held by '${o_id}', release requested by '${OWNER_ID}'" >&2
      exit 3
    fi
    rm -rf "$LOCK_DIR"
    echo "released writer=${WRITER} owner=${OWNER_ID}"
    ;;
  status)
    [ -d "$LOCK_DIR" ] || { echo "unlocked writer=${WRITER}"; exit 4; }
    owner_line="$(read_owner || true)"
    IFS='|' read -r o_id o_pid o_host o_started o_ttl <<< "${owner_line:-|||}"
    if is_stale "$o_started" "$o_ttl"; then
      echo "stale writer=${WRITER} owner=${o_id} pid=${o_pid} started=${o_started}"
      exit 2
    fi
    echo "locked writer=${WRITER} owner=${o_id} pid=${o_pid} host=${o_host} started=${o_started}"
    exit 0
    ;;
  break)
    if [ -d "$LOCK_DIR" ]; then
      owner_line="$(read_owner || true)"
      IFS='|' read -r o_id _o_pid _o_host _o_started _o_ttl <<< "${owner_line:-|||}"
      echo "⚠️  forcing release of writer=${WRITER}, previous owner='${o_id}'" >&2
      rm -rf "$LOCK_DIR"
      echo "broken writer=${WRITER}"
    else
      echo "not locked writer=${WRITER}"
    fi
    ;;
  *)
    echo "writer-lock: unknown command '$CMD'" >&2
    exit 64
    ;;
esac
