// intc_base_test.sv : builds the env; every test extends this
class intc_base_test extends uvm_test;
  `uvm_component_utils(intc_base_test)

  intc_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = intc_env::type_id::create("env", this);
  endfunction
endclass
