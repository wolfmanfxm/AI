#!/bin/bash
# Benchmark Runner v1.0
# Validates skill output against structural expectations.
# Does NOT evaluate semantic quality — only structural contract compliance.
#
# Usage: bash shared/scripts/run-benchmark.sh <skill-name> <output-dir>
#   skill-name:  analyzer | generator | planner | architect | reviewer | tester | refactorer | documenter | releaser
#   output-dir:  directory containing the skill's output files

set -euo pipefail
SKILL="${1:-}"
OUTPUT_DIR="${2:-}"

if [ -z "$SKILL" ] || [ -z "$OUTPUT_DIR" ]; then
  echo "Usage: bash run-benchmark.sh <skill-name> <output-dir>"
  echo "  skill-name: analyzer | generator | planner | architect | reviewer | tester | refactorer | documenter | releaser"
  exit 1
fi

red() { echo -e "\033[31m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }

PASS=0; WARN=0; FAIL=0

check_file() { local f="$OUTPUT_DIR/$1"; local min=${2:-1}; if [ -f "$f" ] && [ "$(wc -c < "$f" 2>/dev/null || echo 0)" -ge "$min" ]; then green "  ✅ $1 (≥${min}B)"; ((PASS++)); else red "  ❌ $1 missing or <${min}B"; ((FAIL++)); fi; }
check_glob() { local pattern="$OUTPUT_DIR/$1"; local min=${2:-1}; local count=$(find $pattern -type f 2>/dev/null | wc -l | tr -d ' '); if [ "$count" -ge "$min" ]; then green "  ✅ $1: ${count} file(s)"; ((PASS++)); else yellow "  ⚠️  $1: ${count}/${min} file(s)"; ((WARN++)); fi; }
check_section() { local f="$OUTPUT_DIR/$1"; local section="$2"; if [ -f "$f" ] && grep -q "^## $section" "$f" 2>/dev/null; then green "  ✅ $1: '$section' section exists"; ((PASS++)); else yellow "  ⚠️  $1: '$section' section missing"; ((WARN++)); fi; }

echo "========================================"
echo " Benchmark: $SKILL"
echo " Output:   $OUTPUT_DIR"
echo "========================================"
echo ""

case "$SKILL" in
  analyzer)
    check_file "architecture/overview.md" 500
    check_file "architecture/modules.md" 300
    check_file "architecture/tech-stack.md" 200
    check_file "components/catalog.md" 300
    check_file "api/overview.md" 200
    check_file "patterns/crud.md" 200
    check_file "statistics.json" 10
    check_file "context.json" 10
    check_file "graph.json" 10
    ;;
  generator)
    check_glob "*.vue" 1
    check_glob "*.ts" 1
    # No duplicate components check (requires graph.json context)
    ;;
  planner)
    check_glob "proposals/PLAN-*.md" 1
    check_file "context-package.json" 10
    for sec in "Goal" "Scope" "Context" "Reuse Analysis" "Decision" "Task Breakdown" "Dependency Graph" "Risk Assessment" "Acceptance Criteria"; do
      check_section "proposals/PLAN-"*.md "$sec" 2>/dev/null || yellow "  ⚠️  Section '$sec' check skipped (no PLAN file found)"
    done
    ;;
  architect)
    check_glob "decisions/ARCHITECTURE-*.md" 1
    for sec in "问题" "候选方案" "选择" "理由"; do
      check_section "decisions/ARCHITECTURE-"*.md "$sec" 2>/dev/null || true
    done
    ;;
  reviewer)
    check_glob "reports/REVIEW-*.md" 1
    for axis in "正确性" "安全性" "可读性" "架构" "性能"; do
      check_section "reports/REVIEW-"*.md "$axis" 2>/dev/null || yellow "  ⚠️  Axis '$axis' not found as section"
    done
    ;;
  tester)
    check_glob "*.test.ts" 0  # combined check below
    check_glob "*.spec.ts" 0
    test_count=$(find "$OUTPUT_DIR" -name "*.test.ts" -o -name "*.spec.ts" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$test_count" -ge 1 ]; then green "  ✅ Test files: ${test_count} found"; ((PASS++)); else red "  ❌ No test files found"; ((FAIL++)); fi
    check_glob "reports/TEST-REPORT.md" 1
    ;;
  refactorer)
    check_glob "reports/REFACTOR.md" 1
    # Behavior unchanged check (requires test run, not structural)
    if grep -q "Before" "$OUTPUT_DIR/reports/REFACTOR.md" 2>/dev/null && grep -q "After" "$OUTPUT_DIR/reports/REFACTOR.md" 2>/dev/null; then
      green "  ✅ REFACTOR.md: Before/After comparison present"; ((PASS++))
    else
      yellow "  ⚠️  REFACTOR.md: missing Before/After metrics"; ((WARN++))
    fi
    ;;
  documenter)
    doc_count=$(find "$OUTPUT_DIR" \( -name "api" -o -name "components" -o -name "README.md" \) 2>/dev/null | wc -l | tr -d ' ')
    if [ "$doc_count" -ge 1 ]; then green "  ✅ Documentation: ${doc_count} dirs/files found"; ((PASS++)); else yellow "  ⚠️  No api/, components/, or README.md"; ((WARN++)); fi
    ;;
  releaser)
    check_file "CHANGELOG.md" 100
    check_file "RELEASE-CHECKLIST.md" 50
    if grep -q "BREAKING CHANGE" "$OUTPUT_DIR/CHANGELOG.md" 2>/dev/null; then
      if grep -q "迁移" "$OUTPUT_DIR/CHANGELOG.md" 2>/dev/null; then
        green "  ✅ Breaking change has migration steps"; ((PASS++))
      else
        yellow "  ⚠️  Breaking change without migration steps"; ((WARN++))
      fi
    else
      green "  ✅ No breaking changes — migration not needed"; ((PASS++))
    fi
    ;;
  *)
    red "Unknown skill: $SKILL"
    exit 2
    ;;
esac

echo ""
echo "========================================"
echo " Verdict"
echo "========================================"
echo " Passed:  $PASS"
echo " Warning: $WARN"
echo " Failed:  $FAIL"
echo ""

if [ "$FAIL" -gt 0 ]; then
  red "❌ BENCHMARK FAILED — $FAIL structural contract violation(s)"
  exit 2
elif [ "$WARN" -gt "$PASS" ]; then
  yellow "⚠️  BENCHMARK LOW — more warnings than passes"
  exit 1
else
  green "✅ BENCHMARK PASSED — structural contract satisfied"
  exit 0
fi
