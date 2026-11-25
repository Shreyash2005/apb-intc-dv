#!/usr/bin/env bash
# build.sh : compile the UVM testbench. Extra args go to verilator (e.g. +define+BUG_X).
set -e
cd "$(dirname "$0")/.."
rm -rf obj_dir
echo "Building... (about 40 s, output goes to build.log)"
verilator --binary --vpi -j 0 -Wno-fatal --timescale 1ns/1ps \
  +incdir+third_party/uvm +incdir+tb \
  third_party/uvm/uvm_pkg_all_v2020_3_1_dpi.svh \
  third_party/uvm/v2020_3_1/dpi/uvm_dpi.cc \
  rtl/apb_intc.sv tb/apb_if.sv tb/src_if.sv tb/apb_pkg.sv tb/src_pkg.sv \
  tb/env_pkg.sv tb/test_pkg.sv tb/tb_top.sv --top-module tb_top "$@" \
  > build.log 2>&1 || { tail -30 build.log; echo "BUILD FAILED (see build.log)"; exit 1; }
echo "BUILD OK"
