#!/bin/bash
# Cross-Run Reliability Checker v1.0
# Compares two .project-knowledge/runtime/ snapshots to measure skill stability.
#
# Usage: bash shared/scripts/check-reliability.sh <snapshot-A> <snapshot-B> [skill-name]
#   snapshot-A/B: directories containing state.json + manifest.json + output files
#   skill-name:    optional, filter to one skill

set -euo pipefail

SNAPSHOT_A="${1:-}"
SNAPSHOT_B="${2:-}"
SKILL_FILTER="${3:-}"

if [ -z "$SNAPSHOT_A" ] || [ -z "$SNAPSHOT_B" ]; then
  echo "Usage: bash check-reliability.sh <snapshot-A-dir> <snapshot-B-dir> [skill-name]"
  echo ""
  echo "Snapshots are directories containing .project-knowledge/runtime/ files from two different runs."
  echo "Create a snapshot: cp -r .project-knowledge/runtime/ snapshots/run-$(date +%Y%m%d-%H%M%S)/"
  exit 1
fi

red() { echo -e "\033[31m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }

STATE_A="$SNAPSHOT_A/state.json"
STATE_B="$SNAPSHOT_B/state.json"
PASS=0; WARN=0; FAIL=0

echo "========================================"
echo " Cross-Run Reliability Report"
echo " Run A: $SNAPSHOT_A"
echo " Run B: $SNAPSHOT_B"
echo "========================================"
echo ""

# ⚠️ 快照可读性前置检查（2026-09-18 加）。此前没有这一步，而 `set -euo pipefail` 下
#    快照不存在时脚本会**在打完表头后静默中止**（exit 1）——与「查出问题」用同一个退出码，
#    调用方无法区分「比较完成但不可靠」和「根本没比较」。
#    同时这也让 FAIL 有了真实含义：此前全文**没有任何 `((FAIL++))`**，
#    「Failed: 0/5」恒为 0、下面的 `exit 2` 是永假分支。
for d in "$SNAPSHOT_A" "$SNAPSHOT_B"; do
  if [ ! -d "$d" ]; then
    red "  ❌ 快照目录不存在或不可读：$d"
    ((FAIL++))
  fi
done
if [ "$FAIL" -gt 0 ]; then
  echo ""
  red "❌ RELIABILITY CHECK FAILED — 快照不可读，**未做任何比较**（不是「稳定」）"
  exit 2
fi

# ═══ Dimension 1: Structural — output file count ═══
count_a=$(find "$SNAPSHOT_A" -type f -name "*.md" -o -name "*.json" 2>/dev/null | wc -l | tr -d ' ')
count_b=$(find "$SNAPSHOT_B" -type f -name "*.md" -o -name "*.json" 2>/dev/null | wc -l | tr -d ' ')
if [ "$count_a" -gt 0 ] && [ "$count_b" -gt 0 ]; then
  delta=$((count_b - count_a))
  pct=$(( delta * 100 / (count_a > 0 ? count_a : 1) ))
  abs_pct=${pct#-}
  if [ "$abs_pct" -le 20 ]; then
    green "  ✅ Structural: ${count_a} → ${count_b} files (Δ${pct}% ≤ 20%)"
    ((PASS++))
  else
    yellow "  ⚠️  Structural: ${count_a} → ${count_b} files (Δ${pct}% > 20%)"
    ((WARN++))
  fi
else
  yellow "  ⚠️  Structural: insufficient data (A:$count_a B:$count_b)"
  ((WARN++))
fi

# ═══ Dimension 2: Confidence stability ═══
# ⚠️ 关键：**「比不了」必须与「比了且稳定」区分开**（2026-09-18 修）。
#    原实现里 `... | head -1 || echo "0"` 的 `|| echo "0"` 是死代码（head 恒成功），
#    取不到 confidence 时两边都是**空串**，`$((conf_a - conf_b))` 把空变量当 0 → Δ0 → ✅「稳定」。
#    实测：state.json 里根本没有 confidence 字段，也照样输出 `✅ Confidence: 0 → 0 (Δ0 ≤ 15)`。
if [ -f "$STATE_A" ] && [ -f "$STATE_B" ]; then
  # 空白容忍：文档样例是 `"confidence": 92`（带空格），但 JSON.stringify 产出的是 `"confidence":92`
  # （无空格）。原正则硬编码一个空格，遇到后者会**完全取不到值**（2026-09-18 放宽）。
  conf_a=$(grep -oE '"confidence"[[:space:]]*:[[:space:]]*[0-9]+' "$STATE_A" 2>/dev/null | grep -oE '[0-9]+' | head -1 || true)
  conf_b=$(grep -oE '"confidence"[[:space:]]*:[[:space:]]*[0-9]+' "$STATE_B" 2>/dev/null | grep -oE '[0-9]+' | head -1 || true)
  if [ -z "$conf_a" ] || [ -z "$conf_b" ]; then
    yellow "  ⚠️  Confidence: 至少一侧没有可读的 confidence 数值（A:'${conf_a}' B:'${conf_b}'）——**无法比较**，不等于稳定"
    ((WARN++))
  else
    delta=$((conf_a - conf_b))
    abs_delta=${delta#-}
    if [ "$abs_delta" -le 15 ]; then
      green "  ✅ Confidence: ${conf_a} → ${conf_b} (Δ${delta} ≤ 15)"
      ((PASS++))
    else
      yellow "  ⚠️  Confidence: ${conf_a} → ${conf_b} (Δ${delta} > 15)"
      ((WARN++))
    fi
  fi
else
  yellow "  ⚠️  Confidence: state.json missing in one snapshot"
  ((WARN++))
fi

# ═══ Dimension 3: Stage completion ═══
if [ -f "$STATE_A" ] && [ -f "$STATE_B" ]; then
  # 不要写 `grep -c X f || echo 0`：零匹配时 grep 已打印 0 且 exit 1，`|| echo 0` 再补一个
  # → 变量成两行 `0\n0` → `[ "$a" -eq "$b" ]` 报错并**恒落 else**，于是「两边都是 0」本应 ✅
  #   的场景永远被判 mismatch（2026-09-18 修）。
  completed_a=$(grep -c '"status": "completed"' "$STATE_A" 2>/dev/null || true); completed_a=${completed_a:-0}
  completed_b=$(grep -c '"status": "completed"' "$STATE_B" 2>/dev/null || true); completed_b=${completed_b:-0}
  if [ "$completed_a" -eq "$completed_b" ]; then
    green "  ✅ Stage: same completed count ($completed_a)"
    ((PASS++))
  else
    yellow "  ⚠️  Stage: ${completed_a} → ${completed_b} completed (mismatch)"
    ((WARN++))
  fi
else
  yellow "  ⚠️  Stage: state.json missing"
  ((WARN++))
fi

# ═══ Dimension 4: Fixture checksums (compare fixture file content stability) ═══
# ⚠️ 原实现两处问题（2026-09-18 修）：
#   1. md5_a / md5_b 算了却**全文零引用**（死代码），真比对在下面的循环里 → 已删
#   2. 摘要用 `md5 -q ... || echo ""`：平台没有 md5（Linux 只有 md5sum）时**两侧都是空串**，
#      `"" = ""` 恒真 → 照样输出「✅ N/N checksums match (inputs stable)」。CI 上会静默全绿。
#      现在先探 md5 是否可用；比对失败时两侧用**不同**哨兵值，确保不会误判相等。
if ! command -v md5 >/dev/null 2>&1 && ! command -v md5sum >/dev/null 2>&1; then
  yellow "  ⚠️  Fixture: 平台既无 md5 也无 md5sum —— **无法校验**，不等于稳定"
  ((WARN++))
else
  md5_of() {   # $1=文件；输出摘要，失败输出唯一哨兵
    if command -v md5 >/dev/null 2>&1; then md5 -q "$1" 2>/dev/null || echo "FAILED:$1"
    else md5sum "$1" 2>/dev/null | cut -d' ' -f1 || echo "FAILED:$1"; fi
  }
  fixture_matches=0; fixture_total=0
  for fixture in "context.json" "graph.json" "PLAN.md" "ARCHITECTURE.md"; do
    fa="$SNAPSHOT_A/$fixture"; fb="$SNAPSHOT_B/$fixture"
    if [ -f "$fa" ] && [ -f "$fb" ]; then
      ((fixture_total++))
      sa=$(md5_of "$fa"); sb=$(md5_of "$fb")
      if [ "$sa" = "$sb" ] && [ "${sa#FAILED:}" = "$sa" ]; then
        ((fixture_matches++))
      fi
    fi
  done
  if [ "$fixture_total" -gt 0 ]; then
    if [ "$fixture_matches" -eq "$fixture_total" ]; then
      green "  ✅ Fixture: ${fixture_matches}/${fixture_total} checksums match (inputs stable)"
      ((PASS++))
    else
      yellow "  ⚠️  Fixture: ${fixture_matches}/${fixture_total} checksums match (inputs changed)"
      ((WARN++))
    fi
  else
    yellow "  ⚠️  Fixture: no fixture files found to compare"
    ((WARN++))
  fi
fi

# ═══ Dimension 5: Output section count stability ═══
sections_a=$(find "$SNAPSHOT_A" -name "*.md" -type f -exec grep -c "^## " {} \; 2>/dev/null | awk '{s+=$1}END{print s+0}')
sections_b=$(find "$SNAPSHOT_B" -name "*.md" -type f -exec grep -c "^## " {} \; 2>/dev/null | awk '{s+=$1}END{print s+0}')
if [ "$sections_a" -gt 0 ] && [ "$sections_b" -gt 0 ]; then
  delta=$((sections_b - sections_a))
  abs_delta=${delta#-}
  if [ "$abs_delta" -le 1 ]; then
    green "  ✅ Output sections: ${sections_a} → ${sections_b} (Δ${delta} ≤ 1)"
    ((PASS++))
  else
    yellow "  ⚠️  Output sections: ${sections_a} → ${sections_b} (Δ${delta} > 1)"
    ((WARN++))
  fi
else
  yellow "  ⚠️  Output sections: insufficient data"
  ((WARN++))
fi

echo ""
echo "========================================"
echo " Verdict"
echo "========================================"
echo " Passed:  $PASS/5"
echo " Warning: $WARN/5"
echo " Failed:  $FAIL/5"
echo ""

if [ "$FAIL" -gt 0 ]; then
  red "❌ RELIABILITY CHECK FAILED"
  exit 2
elif [ "$WARN" -gt 2 ]; then
  yellow "⚠️  RELIABILITY LOW — ${WARN}/5 warnings, investigate"
  exit 1
elif [ "$WARN" -gt 0 ]; then
  yellow "⚠️  RELIABILITY ADEQUATE — ${WARN}/5 minor warnings"
  exit 1
else
  green "✅ RELIABILITY HIGH — all dimensions within threshold"
  exit 0
fi
