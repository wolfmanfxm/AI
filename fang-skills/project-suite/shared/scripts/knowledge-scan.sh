#!/bin/bash
# Knowledge Scan v1.0
#
# Verification pipeline for knowledge quality:
#   evidence / broken-links / duplicates / conflicts
#
# Usage: bash shared/scripts/knowledge-scan.sh <project-knowledge-dir>
# Output: knowledge-scan-report.md

set -euo pipefail
KNOWLEDGE_DIR="${1:-.project-knowledge}"
REPORT="${KNOWLEDGE_DIR}/knowledge-scan-report.md"
ISSUES=0

echo "# Knowledge Scan Report" > "$REPORT"
echo "" >> "$REPORT"
echo "> Scanned: $(date -u +%Y-%m-%dT%H:%M:%SZ) | Dir: $KNOWLEDGE_DIR" >> "$REPORT"
echo "" >> "$REPORT"

# 1. Broken Links
echo "## Broken Links" >> "$REPORT"
echo "" >> "$REPORT"
broken=0
for md in $(find "$KNOWLEDGE_DIR" -name "*.md" -not -path "*/candidates/*" 2>/dev/null); do
  for link in $(grep -ohP '\[.*?\]\([^)]*\.md\)' "$md" 2>/dev/null | grep -oP '(?<=\()[^)]*' || true); do
    # Resolve relative link
    target="$(dirname "$md")/$link"
    if [ ! -f "$target" ]; then
      echo "- ❌ \`$(basename "$md")\` → \`$link\` (not found)" >> "$REPORT"
      ((broken++))
    fi
  done
done
[ "$broken" -eq 0 ] && echo "✅ All links resolve" >> "$REPORT"
echo "" >> "$REPORT"

# 2. Duplicate Patterns
echo "## Duplicate Patterns" >> "$REPORT"
echo "" >> "$REPORT"
dups=0
for f1 in $(find "$KNOWLEDGE_DIR/patterns" -name "*.md" 2>/dev/null); do
  for f2 in $(find "$KNOWLEDGE_DIR/patterns" -name "*.md" 2>/dev/null); do
    [ "$f1" = "$f2" ] && continue
    f1name=$(basename "$f1" .md); f2name=$(basename "$f2" .md)
    # Simple similarity: check if >50% of first file's ## headers appear in second
    headers1=$(grep -c "^## " "$f1" 2>/dev/null || echo 0)
    common=$(grep -f <(grep "^## " "$f1" | head -10) "$f2" 2>/dev/null | wc -l | tr -d ' ' || echo 0)
    if [ "$headers1" -gt 0 ] && [ "$common" -gt $((headers1 / 2)) ]; then
      echo "- ⚠️ \`$f1name\` ≈ \`$f2name\` (${common}/${headers1} shared sections)" >> "$REPORT"
      ((dups++))
    fi
  done
done
[ "$dups" -eq 0 ] && echo "✅ No significant duplicates" >> "$REPORT"
echo "" >> "$REPORT"

# 3. Evidence Gaps
echo "## Evidence Gaps" >> "$REPORT"
echo "" >> "$REPORT"
gaps=$(grep -r "\[MISSING EVIDENCE\]\|\[推断\]\|\[待补充\]" "$KNOWLEDGE_DIR" --include="*.md" 2>/dev/null | wc -l | tr -d ' ')
if [ "$gaps" -eq 0 ]; then
  echo "✅ No evidence gaps" >> "$REPORT"
else
  echo "⚠️ ${gaps} evidence gaps found (search for [MISSING EVIDENCE]/[推断]/[待补充])" >> "$REPORT"
fi
echo "" >> "$REPORT"

# Summary
echo "## Summary" >> "$REPORT"
echo "" >> "$REPORT"
echo "| Check | Status |" >> "$REPORT"
echo "|-------|--------|" >> "$REPORT"
echo "| Broken Links | $([ "$broken" -eq 0 ] && echo '✅ 0' || echo "❌ $broken") |" >> "$REPORT"
echo "| Duplicates | $([ "$dups" -eq 0 ] && echo '✅ 0' || echo "⚠️ $dups") |" >> "$REPORT"
echo "| Evidence Gaps | $([ "$gaps" -eq 0 ] && echo '✅ 0' || echo "⚠️ $gaps") |" >> "$REPORT"

echo "Report: $REPORT"
[ "$broken" -gt 0 ] && exit 1 || exit 0
