
// apb_pkg.sv : the APB agent and its sequences, in one package
package apb_pkg;
  import uvm_pkg::*;
  `include "apb_item.sv"
  typedef uvm_sequencer #(apb_item) apb_sequencer;   // the outbox, no custom code needed
  `include "apb_driver.sv"
  `include "apb_monitor.sv"
  `include "apb_agent.sv"
  `include "apb_seqs.sv"
endpackage
