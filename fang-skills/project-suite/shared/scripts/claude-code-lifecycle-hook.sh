#!/bin/bash
# Claude Code Runtime Lifecycle Hook v2.0
#
# 把 project-suite 的 run_lifecycle 契约接进 Claude Code 的 hook 机制。
# 契约见 runtime/contracts/host-capability.md；挂载方式见 runtime/adapters/claude-code.md。
#
# 职责边界（单一入口原则）：
#   - **Start 的唯一 Producer 是 Skill Discovery**。本 Hook 不创建任务、不写运行指针。
#     Start 需要用户确认后的 task / goal / 范围，只有 Discovery 知道；Hook 抢先登记会落下
#     "Run <skill>" 这类无信息量任务，并与 Discovery 的 Task Resolution 竞争同一份运行状态。
#   - SessionEnd                       → 异常退出兜底：只对**本 session**、身份已知的运行指针
#                                        执行 finish --auto-finalized
#   - PreToolUse(Write|Edit|MultiEdit) → 写项目级真相文件前校验锁归属（辅助检查）
#
# 挂载点（都由本脚本按 hook_event_name / tool_name 自动分派）：
#   SessionEnd                       → 兜底收尾
#   PreToolUse(Write|Edit|MultiEdit) → 项目级写路径锁校验
#   其余事件 / 工具                   → no-op（包括 UserPromptExpansion / Skill）
#
# ⚠️ UserPromptExpansion / PreToolUse(Skill) 仍可挂载用于日志或上下文注入，
#    但**不得用于创建 Task / Run**。本脚本对这两个事件只做 no-op。
#
# ⚠️ 不用 Stop：Stop 在**每一轮助手回复结束**时触发（不是会话结束）。
#    长任务会在两轮之间被误判为「已结束」并释放锁。会话级收尾必须用 SessionEnd
#    （reason: clear/resume/logout/prompt_input_exit/other）。
#
# ⚠️ Hook 是 Host 层辅助检查，不是绝对的写入互斥保证：它只看 Write/Edit/MultiEdit，
#    覆盖不了 Bash/PowerShell/脚本写入。真正的单写者协议依赖 Skill 在写前 renew + 校验。
#
# 设计原则：**永不阻塞正常编辑**。
#   - 没有 .project-knowledge/ 的项目：静默 no-op
#   - 没有活动运行指针、也没有共享锁：不检查、不拦截
#   - 指针属于**另一个 session** 且锁仍在 → deny（单写者约束：另一个会话正在写项目级知识）
#   - 指针存在但锁已不在 → deny（说明锁被 break，继续写会互相抹掉）
#   - 共享锁被持有但指针缺失 / 指针 owner 与锁 owner 不一致 → deny（无法证明现场归属）
#   - 保护对象是「共享写入资源」：analyzer 与 reviewer 都写 knowledge.json，共用 analyzer 锁，
#     因此两者都要检查，不能只认 project-analyzer 指针。
#
# 挂载（项目级，不全局）：
#   .claude/settings.local.json
#   {
#     "hooks": {
#       "PreToolUse": [{ "matcher": "Write|Edit|MultiEdit",
#                        "hooks": [{ "type": "command",
#           "command": "bash <suite>/shared/scripts/claude-code-lifecycle-hook.sh" }] }],
#       "SessionEnd": [{ "hooks": [{ "type": "command", "timeout": 10,
#           "command": "bash <suite>/shared/scripts/claude-code-lifecycle-hook.sh" }] }]
#     }
#   }
#
# Exit: 0 = allow / no-op；deny 通过 stdout JSON 返回（hookSpecificOutput）
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUN="$SCRIPT_DIR/runtime-run.sh"
LOCK="$SCRIPT_DIR/writer-lock.sh"

INPUT="$(cat)"
[ -n "$INPUT" ] || exit 0

# 一次 node 解析，输出 | 分隔字段（base64 编码；不能用 tab——IFS 空白会吞掉空字段）
PARSED="$(printf '%s' "$INPUT" | node -e '
  let s="";
  process.stdin.on("data",d=>s+=d).on("end",()=>{
    let e={};try{e=JSON.parse(s)}catch(_){}
    const ti=e.tool_input||{};
    const enc=v=>Buffer.from(String(v==null?"":v),"utf8").toString("base64");
    process.stdout.write([
      e.hook_event_name||"",
      e.tool_name||"",
      ti.file_path||ti.path||"",
      e.cwd||"",
      e.session_id||"",
    ].map(enc).join("|"));
  });
')"
[ -n "$PARSED" ] || exit 0

decode() { printf '%s' "$1" | base64 --decode 2>/dev/null || printf '%s' "$1" | base64 -D 2>/dev/null; }
IFS='|' read -r EV_B64 TOOL_B64 FILE_B64 CWD_B64 SESSION_B64 <<< "$PARSED"
EVENT="$(decode "$EV_B64")"
TOOL="$(decode "$TOOL_B64")"
FILE="$(decode "$FILE_B64")"
CWD="$(decode "$CWD_B64")"
SESSION="$(decode "$SESSION_B64")"

[ -n "$CWD" ] || CWD="$(pwd)"
KD="$CWD/.project-knowledge"
[ -d "$KD" ] || exit 0

block() {
  # PreToolUse 现行的拒绝格式。顶层的 {"decision":"block"} 对 PreToolUse 已弃用，
  # 仍被接受但会在 transcript 里显示成 "hook error"，所以这里用 hookSpecificOutput。
  node -e '
    const reason=process.argv[1];
    process.stdout.write(JSON.stringify({
      hookSpecificOutput:{
        hookEventName:"PreToolUse",
        permissionDecision:"deny",
        permissionDecisionReason:reason,
      },
    })+"\n");
  ' "$1"
}

# ── SessionEnd：会话级兜底收尾（只收本 session 的指针） ──
# 注意：不是 Stop。Stop 每轮都触发，长任务会被中途收尾。
# 运行指针记录 sessionId；另一个 session 的 run 必须由它自己收尾，否则两个并发会话
# 会互相把对方的运行记成 degraded。
pointer_session() { # <pointer.json>
  node -e '
    const fs=require("fs");
    try{process.stdout.write(String(JSON.parse(fs.readFileSync(process.argv[1],"utf8")).sessionId||""));}catch(e){}
  ' "$1"
}

if [ "$EVENT" = "SessionEnd" ]; then
  # 身份未知（hook payload 没有 session_id，或指针是旧版没有 sessionId）时**不自动收尾**：
  # 无法证明是同一个 session，贸然 finish 会把别人的运行记成 degraded。
  # 这类指针保留给人工恢复（finish --session-id / break）。
  [ -n "$SESSION" ] || exit 0
  for f in "$KD/runtime/current-runs"/*.json; do
    [ -f "$f" ] || continue
    skill="$(basename "$f" .json)"
    psession="$(pointer_session "$f")"
    if [ -z "$psession" ] || [ "$psession" != "$SESSION" ]; then
      continue
    fi
    bash "$RUN" finish "$CWD" --skill "$skill" --session-id "$SESSION" --auto-finalized >/dev/null 2>&1 || true
  done
  exit 0
fi

# ── PreToolUse(Write/Edit)：项目级真相文件的锁校验 ──
case "$TOOL" in Write|Edit|MultiEdit) ;; *) exit 0 ;; esac
[ -n "$FILE" ] || exit 0

# 只有 single-writer.md 列出的**共享写入资源**需要项目级锁：
#   根产物 graph/statistics/context/search-index/manifest/index/knowledge.json
#   目录   architecture/ components/ api/ patterns/
# decisions/、experience/、reports/、proposals/ 等按文档/任务独立写入，
# 不因 Analyzer 正在跑就被整体拦住。
REL=""
case "$FILE" in
  "$KD"/*) REL="${FILE#"$KD"/}" ;;
  */.project-knowledge/*) REL="${FILE#*/.project-knowledge/}" ;;
  *) exit 0 ;;
esac
case "$REL" in
  graph.json|statistics.json|context.json|search-index.json|manifest.json|index.md|knowledge.json) ;;
  architecture/*|components/*|api/*|patterns/*) ;;
  *) exit 0 ;;
esac

# ── PreToolUse(Write/Edit)：项目级共享资源的锁校验 ──
# 保护对象是**共享写入资源**，不是某个 skill：analyzer 与 reviewer 都写 knowledge.json，
# 共用 `analyzer` 锁。按 skill 名分挂 hook 会漏掉 reviewer（它有独立的运行指针）。
pointer_field() { # <pointer.json> <field>
  node -e '
    const fs=require("fs");
    try{const v=JSON.parse(fs.readFileSync(process.argv[1],"utf8"))[process.argv[2]];process.stdout.write(String(v==null?"":v));}catch(e){}
  ' "$1" "$2"
}

PROTECTED=()
for p in "$KD/runtime/current-runs/project-analyzer.json" "$KD/runtime/current-runs/project-reviewer.json"; do
  [ -f "$p" ] && PROTECTED+=("$p")
done

if [ "${#PROTECTED[@]}" -gt 0 ]; then
  for p in "${PROTECTED[@]}"; do
    owner_skill="$(basename "$p" .json)"
    PSESSION="$(pointer_session "$p")"
    POWNER="$(pointer_field "$p" ownerId)"
    if [ -n "$PSESSION" ] && [ -z "$SESSION" ]; then
      block "${owner_skill} 的运行指针属于 session=${PSESSION}，但当前 hook 事件没有 session_id；无法证明写入者身份，拒绝写项目级知识。"
      exit 0
    fi
    if [ -n "$PSESSION" ] && [ -n "$SESSION" ] && [ "$PSESSION" != "$SESSION" ]; then
      block "项目级知识的共享锁由 ${owner_skill} 持有（session=$PSESSION）。当前 session（$SESSION）写入会与它互相覆盖；等它 finish，或在原 session 收尾后再写。"
      exit 0
    fi
    set +e
    if [ -n "$POWNER" ]; then
      LOCK_ST="$(bash "$LOCK" "$KD" analyzer status --expect-owner "$POWNER" 2>&1)"
    else
      LOCK_ST="$(bash "$LOCK" "$KD" analyzer status 2>&1)"
    fi
    LOCK_RC=$?
    set -e
    if [ "$LOCK_RC" -eq 3 ]; then
      block "${owner_skill} 的运行指针 owner=${POWNER} 与真实 analyzer 锁 owner 不一致（${LOCK_ST}）；无法确认现场归属，拒绝写项目级知识。"
      exit 0
    fi
    if [ "$LOCK_RC" -ne 0 ]; then
      block "${owner_skill} 的运行指针仍存在，但 analyzer 单写者锁已丢失（可能被 break）。继续写项目级知识会产生互相覆盖；先执行 runtime-run.sh finish 或重新 acquire。"
      exit 0
    fi
  done
else
  # 没有运行指针，但共享锁仍被持有（例如脚本直接 acquire，或指针被手工删除）：
  # 无法证明当前写入者就是锁的 owner，宁可拒绝，也不要在别人的写入窗口里插一刀。
  set +e
  bash "$LOCK" "$KD" analyzer status >/dev/null 2>&1
  LOCK_RC=$?
  set -e
  if [ "$LOCK_RC" -eq 0 ]; then
    block "analyzer 共享锁被持有，但没有对应的运行指针；无法确认写入者身份，拒绝写项目级知识。"
    exit 0
  fi
fi

exit 0
