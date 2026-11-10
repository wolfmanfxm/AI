#!/bin/bash
# Writer Lock v1.0
#
# 项目级真相的单写者约束。mkdir 原子创建锁目录，不依赖 flock（跨平台）。
#
# Usage:
#   writer-lock.sh <knowledge-dir> <writer-name> acquire [--owner-id <id>] [--ttl-seconds <n>]
#   writer-lock.sh <knowledge-dir> <writer-name> renew   --owner-id <id> [--ttl-seconds <n>]
#   writer-lock.sh <knowledge-dir> <writer-name> release --owner-id <id>
#   writer-lock.sh <knowledge-dir> <writer-name> status [--expect-owner <id>]
#   writer-lock.sh <knowledge-dir> <writer-name> break --force [--expect-owner <id>]
#
# Exit codes:
#   acquire: 0=acquired  1=occupied  2=stale(需显式 break)
#   renew:   0=renewed   3=not locked / owner mismatch
#   release: 0=released  3=owner mismatch / not locked
#   status:  0=locked（带 --expect-owner 时要求 owner 一致）
#            2=stale（owner 一致或未指定 expect）  3=owner mismatch  4=unlocked
#   break:   0=broken    3=refused（缺 --force / owner 与 --expect-owner 不一致）
#
# --expect-owner 用于「这个锁真的还是我的吗」：runtime-run 复用一个已有 Run / 收尾之前，
# 必须同时满足 指针 owner == 真实锁 owner == 当前调用方，否则会把别人的锁当成自己的。
# owner 比对**先于** stale 判定：别人的锁即使已过期，也必须是 mismatch，而不是可接管的 stale。
# break 是强制接管，必须显式 --force；普通恢复路径不要用它。
set -euo pipefail

KD="${1:-}"; WRITER="${2:-}"; CMD="${3:-}"
[ -n "$KD" ] && [ -n "$WRITER" ] && [ -n "$CMD" ] || { sed -n '/^# Usage:/,/^set -euo pipefail/p' "$0" | sed '$d' >&2; exit 64; }
shift 3

OWNER_ID=""
EXPECT_OWNER=""
TTL=""
FORCE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --owner-id)     OWNER_ID="${2:-}"; shift 2 ;;
    --expect-owner) EXPECT_OWNER="${2:-}"; shift 2 ;;
    --ttl-seconds)  TTL="${2:-}"; shift 2 ;;
    --force)        FORCE=1; shift ;;
    *) echo "writer-lock: unknown arg '$1'" >&2; exit 64 ;;
  esac
done

LOCK_ROOT="${KD}/.locks"
LOCK_DIR="${LOCK_ROOT}/${WRITER}.lock"
OWNER_FILE="${LOCK_DIR}/owner.env"

default_owner() { printf 'pid-%s-%s' "$$" "$(hostname 2>/dev/null || echo unknown)"; }
[ -n "$OWNER_ID" ] || OWNER_ID="$(default_owner)"

now_epoch() { date +%s; }

read_owner() { # echo "owner_id|pid|host|started_epoch|ttl|renewed_epoch"
  [ -f "$OWNER_FILE" ] || return 1
  local owner pid host started ttl renewed
  owner="$(sed -n 's/^owner_id=//p' "$OWNER_FILE" | head -1)"
  pid="$(sed -n 's/^pid=//p' "$OWNER_FILE" | head -1)"
  host="$(sed -n 's/^hostname=//p' "$OWNER_FILE" | head -1)"
  started="$(sed -n 's/^started_epoch=//p' "$OWNER_FILE" | head -1)"
  ttl="$(sed -n 's/^ttl_seconds=//p' "$OWNER_FILE" | head -1)"
  renewed="$(sed -n 's/^renewed_epoch=//p' "$OWNER_FILE" | head -1)"
  printf '%s|%s|%s|%s|%s|%s\n' "$owner" "$pid" "$host" "${started:-0}" "${ttl:-3600}" "${renewed:-0}"
}

is_stale() { # <started> <ttl> <renewed>
  # 只看 TTL：锁的持有者是 Skill 会话，不是拉起本脚本的短命 shell 进程，
  # 因此 pid 存活与否不能作为判据（acquire 脚本退出后 pid 即消失）。
  # renew 过则以最近一次续租时刻为租约起点。
  local started="$1" ttl="$2" renewed="${3:-0}" anchor age
  anchor="$started"
  if [ "${renewed:-0}" -gt 0 ] 2>/dev/null; then anchor="$renewed"; fi
  age=$(( $(now_epoch) - ${anchor:-0} ))
  [ "${age}" -gt "${ttl:-3600}" ]
}

case "$CMD" in
  acquire)
    [ -n "$TTL" ] || TTL=3600
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
    IFS='|' read -r o_id o_pid o_host o_started o_ttl o_renewed <<< "$owner_line"
    if is_stale "$o_started" "$o_ttl" "$o_renewed"; then
      echo "stale writer=${WRITER} owner=${o_id} pid=${o_pid} started=${o_started} ttl=${o_ttl}" >&2
      echo "run: writer-lock.sh <kd> ${WRITER} break" >&2
      exit 2
    fi
    echo "occupied writer=${WRITER} owner=${o_id} pid=${o_pid} host=${o_host}" >&2
    exit 1
    ;;
  renew)
    [ -d "$LOCK_DIR" ] || { echo "not locked writer=${WRITER}" >&2; exit 3; }
    owner_line="$(read_owner || true)"
    IFS='|' read -r o_id o_pid o_host o_started o_ttl o_renewed <<< "${owner_line:-|||||}"
    if [ "$o_id" != "$OWNER_ID" ]; then
      echo "owner mismatch: lock held by '${o_id}', renew requested by '${OWNER_ID}'" >&2
      exit 3
    fi
    [ -n "$TTL" ] || TTL="${o_ttl:-3600}"
    renewed_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    tmp="${OWNER_FILE}.tmp.$$"
    {
      echo "owner_id=${o_id}"
      echo "pid=${o_pid}"
      echo "hostname=${o_host}"
      echo "started_at=$(sed -n 's/^started_at=//p' "$OWNER_FILE" | head -1)"
      echo "started_epoch=${o_started}"
      echo "ttl_seconds=${TTL}"
      echo "renewed_at=${renewed_at}"
      echo "renewed_epoch=$(now_epoch)"
    } > "$tmp"
    mv "$tmp" "$OWNER_FILE"
    echo "renewed writer=${WRITER} owner=${OWNER_ID} ttl=${TTL}"
    ;;
  release)
    [ -d "$LOCK_DIR" ] || { echo "not locked writer=${WRITER}" >&2; exit 3; }
    owner_line="$(read_owner || true)"
    IFS='|' read -r o_id _o_pid _o_host _o_started _o_ttl _o_renewed <<< "${owner_line:-|||||}"
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
    IFS='|' read -r o_id o_pid o_host o_started o_ttl o_renewed <<< "${owner_line:-|||||}"
    # owner 比对必须先于 stale：别人的锁即使过期，也不能被当成「可接管的 stale」。
    if [ -n "$EXPECT_OWNER" ] && [ "$o_id" != "$EXPECT_OWNER" ]; then
      echo "owner mismatch writer=${WRITER} held_by=${o_id} expected=${EXPECT_OWNER} pid=${o_pid} host=${o_host} stale=$(is_stale "$o_started" "$o_ttl" "$o_renewed" && echo yes || echo no)" >&2
      exit 3
    fi
    if is_stale "$o_started" "$o_ttl" "$o_renewed"; then
      echo "stale writer=${WRITER} owner=${o_id} pid=${o_pid} started=${o_started}"
      exit 2
    fi
    echo "locked writer=${WRITER} owner=${o_id} pid=${o_pid} host=${o_host} started=${o_started}"
    exit 0
    ;;
  break)
    if [ -d "$LOCK_DIR" ]; then
      owner_line="$(read_owner || true)"
      IFS='|' read -r o_id _o_pid _o_host _o_started _o_ttl _o_renewed <<< "${owner_line:-|||||}"
      # break 是强制接管，不是普通恢复：普通释放走 release。
      if [ "$FORCE" -ne 1 ]; then
        echo "refused: break 会强制移除 writer=${WRITER} 的锁（owner='${o_id}'）；确认无人使用时加 --force" >&2
        exit 3
      fi
      if [ -n "$EXPECT_OWNER" ] && [ "$o_id" != "$EXPECT_OWNER" ]; then
        echo "refused: owner mismatch writer=${WRITER} held_by=${o_id} expected=${EXPECT_OWNER}" >&2
        exit 3
      fi
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
