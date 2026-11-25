#!/usr/bin/env bash
# regress.sh [verilator args] : build once, run directed tests + rand_test over
# many seeds, report pass/fail and merged coverage.
#   SEEDS=20 ./scripts/regress.sh
#   ./scripts/regress.sh +define+BUG_PRIO        (inject a bug)
set -e
cd "$(dirname "$0")/.."
command -v z3 >/dev/null || { echo "z3 not found: run 'source ~/eda/oss-cad-suite/environment' first"; exit 1; }
SEEDS="${SEEDS:-10}"

./scripts/build.sh "$@"
rm -rf logs && mkdir -p logs
pass=0
fail=0

run_one() {    # $1 = test name, $2 = seed
  local log="logs/$1_$2.log"
  ./obj_dir/Vtb_top +UVM_TESTNAME="$1" +verilator+seed+"$2" \
    +UVM_NO_RELNOTES +UVM_VERBOSITY=UVM_LOW > "$log" 2>&1 || true
  local cyc
  cyc=$(grep -o "cycles=[0-9]*" "$log" | head -1)
  if grep -q "SCOREBOARD PASSED" "$log" \
     && grep -Eq "UVM_ERROR :[[:space:]]+0$" "$log" \
     && grep -Eq "UVM_FATAL :[[:space:]]+0$" "$log"; then
    pass=$((pass + 1))
    printf "PASS  %-10s seed=%-3s %s\n" "$1" "$2" "$cyc"
  else
    fail=$((fail + 1))
    printf "FAIL  %-10s seed=%-3s %s  -> %s\n" "$1" "$2" "$cyc" "$log"
  fi
}

run_one intr_test 1                                  # directed: one seed is enough
run_one race_test 1
for s in $(seq 1 "$SEEDS"); do run_one rand_test "$s"; done

echo "--------------------------------------------"
echo "passed $pass, failed $fail"
python3 scripts/merge_cov.py logs/*.log
[ "$fail" -eq 0 ]
