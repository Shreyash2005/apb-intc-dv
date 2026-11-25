// env_pkg.sv : reference model, scoreboard, and environment
package env_pkg;
  import uvm_pkg::*;
  import apb_pkg::*;
  import src_pkg::*;
  `include "intc_model.sv"
  `include "intc_scoreboard.sv"
endpackage
