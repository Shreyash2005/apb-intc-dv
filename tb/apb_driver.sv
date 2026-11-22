
class apb_driver extends uvm_driver #(apb_item);
  `uvm_component_utils(apb_driver)

  virtual apb_if vif;     // handle to the real wires

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // build: find the wires
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "apb_driver: no virtual interface in config_db")
  endfunction

  // run: idle the bus, wait for reset, then deliver items forever
  task run_phase(uvm_phase phase);
    vif.psel    <= 0;
    vif.penable <= 0;
    vif.pwrite  <= 0;
    vif.paddr   <= 0;
    vif.pwdata  <= 0;
    vif.pstrb   <= 0;
    wait (vif.presetn === 1'b1);
    forever begin
      seq_item_port.get_next_item(req);   // take the next letter from the outbox
      drive(req);                         // deliver it on the wires
      seq_item_port.item_done();          // tell the sequence it's done
    end
  endtask

  // one APB transfer. Inputs change on negedge, DUT samples on posedge.
  task drive(apb_item tr);
    // setup phase
    @(negedge vif.pclk);
    vif.psel    <= 1;
    vif.penable <= 0;
    vif.pwrite  <= tr.write;
    vif.paddr   <= tr.addr;
    vif.pwdata  <= tr.write ? tr.data : 32'h0;
    vif.pstrb   <= tr.write ? tr.strb : 4'h0;
    // access phase
    @(negedge vif.pclk);
    vif.penable <= 1;
    // transfer completes on the posedge where pready is high
    do @(posedge vif.pclk); while (!vif.pready);
    if (!tr.write) tr.data = vif.prdata;  // bring read data back to the sequence
    tr.slverr = vif.pslverr;
    // back to idle
    @(negedge vif.pclk);
    vif.psel    <= 0;
    vif.penable <= 0;
  endtask
endclass
