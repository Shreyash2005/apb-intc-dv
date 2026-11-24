// src_driver.sv : puts each src_item's value on the wires for 'hold' cycles
class src_driver extends uvm_driver #(src_item);
  `uvm_component_utils(src_driver)

  virtual src_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual src_if)::get(this, "", "src_vif", vif))
      `uvm_fatal("NOVIF", "src_driver: no src_vif in config_db")
  endfunction

  task run_phase(uvm_phase phase);
    vif.src <= '0;
    wait (vif.presetn === 1'b1);
    forever begin
      seq_item_port.get_next_item(req);
      @(negedge vif.pclk);
      vif.src <= req.value;                     // change on negedge
      repeat (req.hold - 1) @(negedge vif.pclk); // DUT sees it on 'hold' posedges
      seq_item_port.item_done();
    end
  endtask
endclass
