// src_pkg.sv : the interrupt source agent, in one package
package src_pkg;
  import uvm_pkg::*;
  `include "src_item.sv"
  typedef uvm_sequencer #(src_item) src_sequencer;
  `include "src_driver.sv"
  `include "src_monitor.sv"
  `include "src_agent.sv"
endpackage
