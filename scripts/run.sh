#!/usr/bin/env bash
# run.sh <test> [seed] [extra plusargs...] : run one test, log to logs/<test>_<seed>.log
set -e -o pipefail
cd "$(dirname "$0")/.."
test="${1:-intr_test}"
seed="${2:-1}"
shift $(( $# < 2 ? $# : 2 ))
mkdir -p logs
./obj_dir/Vtb_top +UVM_TESTNAME="$test" +verilator+seed+"$seed" +UVM_NO_RELNOTES "$@" \
  | tee "logs/${test}_${seed}.log"
