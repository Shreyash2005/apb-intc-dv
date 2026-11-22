module hello;
  import uvm_pkg::*;

  class hello_test extends uvm_test;
    `uvm_component_utils(hello_test)
    function new(string name, uvm_component parent = null);
      super.new(name, parent);
    endfunction
    task run_phase(uvm_phase phase);
      phase.raise_objection(this);
      `uvm_info("HELLO", "UVM is alive", UVM_LOW)
      #10;
      phase.drop_objection(this);
    endtask
  endclass

  initial run_test("hello_test");
endmodule
