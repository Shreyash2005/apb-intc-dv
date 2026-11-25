#!/usr/bin/env bash
# bug_hunt.sh : for each injected bug, run the simulation regression and the
# formal proof, and report which flow caught it. Takes about 3 minutes.
set -e
cd "$(dirname "$0")/.."
command -v z3 >/dev/null || { echo "z3 not found: run 'source ~/eda/oss-cad-suite/environment' first"; exit 1; }
BUGS="BUG_CLR_WINS BUG_PRIO BUG_NO_STRB"
rm -rf bug_logs && mkdir -p bug_logs

for bug in $BUGS; do
  echo "================ $bug ================"

  # ---- simulation: full regression with the bug compiled in ----
  if ./scripts/regress.sh "+define+$bug" > "bug_logs/$bug.sim.txt" 2>&1; then
    echo "SIM    : NOT caught (all runs passed)"
  elif ! grep -q "BUILD OK" "bug_logs/$bug.sim.txt"; then
    echo "SIM    : build failed, see bug_logs/$bug.sim.txt"
  else
    nfail=$(grep -c "^FAIL" "bug_logs/$bug.sim.txt" || true)
    which=$(grep "^FAIL" "bug_logs/$bug.sim.txt" | awk '{print $2"/"$3}' | tr '\n' ' ')
    first=$(grep -h "UVM_ERROR tb/intc_scoreboard" logs/*.log | head -1 | sed 's/.*\[SB/[SB/')
    echo "SIM    : CAUGHT in $nfail run(s): $which"
    echo "         first error: $first"
  fi

  # ---- formal: prove task with the bug ----
  task=$(echo "$bug" | tr 'A-Z' 'a-z')
  (cd formal && sby -f apb_intc.sby "$task" > "../bug_logs/$bug.formal.txt" 2>&1) || true
  if grep -q "DONE (PASS" "bug_logs/$bug.formal.txt"; then
    echo "FORMAL : NOT caught (proof passed)"
  else
    loc=$(grep -m1 "Assert failed" "bug_logs/$bug.formal.txt" | sed 's/.*apb_intc_props.svh:\([0-9]*\).*/\1/')
    if [ -n "$loc" ] && [ "$loc" -eq "$loc" ] 2>/dev/null; then
      echo "FORMAL : CAUGHT by apb_intc_props.svh line $loc:"
      sed -n "$((loc - 1)),${loc}p" formal/apb_intc_props.svh | sed 's/^/           /'
    else
      echo "FORMAL : failed, see bug_logs/$bug.formal.txt"
    fi
  fi
done

echo "================ restoring clean build ================"
./scripts/build.sh
