#!/bin/bash
# Run suite arms with bounded concurrency. Usage: batch.sh maxjobs arm:rep ...
set -u
MAX=$1; shift
BASE=/Users/fangxiangming/.cache/ps-eval/round19/results
run() {
  local arm="$1" rep="$2"
  bash "$BASE/run-one.sh" "$arm" "$rep"
}
i=0
for job in "$@"; do
  arm="${job%%:*}"; rep="${job##*:}"
  run "$arm" "$rep" &
  i=$((i+1))
  if [ $((i % MAX)) -eq 0 ]; then wait; fi
done
wait
echo "BATCH DONE"
