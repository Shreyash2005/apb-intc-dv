// src_monitor.sv : samples src and irq on EVERY posedge and broadcasts them.
// Prints only when something changes, to keep the log readable.
class src_monitor extends uvm_monitor;
  `uvm_component_utils(src_monitor)

  virtual src_if vif;
  uvm_analysis_port #(src_item) ap;
  int unsigned n_irq_rise;            // how many times irq went 0 -> 1

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
    if (!uvm_config_db#(virtual src_if)::get(this, "", "src_vif", vif))
      `uvm_fatal("NOVIF", "src_monitor: no src_vif in config_db")
  endfunction

  task run_phase(uvm_phase phase);
    src_item  tr;
    bit [7:0] last_src = '0;
    bit       last_irq = 1'b0;
    forever begin
      @(posedge vif.pclk);
      if (!vif.presetn) continue;     // ignore cycles in reset
      tr       = src_item::type_id::create("tr");
      tr.value = vif.src;
      tr.irq   = vif.irq;
      tr.hold  = 1;                   // one sample = one cycle
      if (tr.value != last_src || tr.irq != last_irq)
        `uvm_info("SRC_MON", $sformatf("src=%08b irq=%0b", tr.value, tr.irq), UVM_MEDIUM)
      if (tr.irq && !last_irq) n_irq_rise++;
      last_src = tr.value;
      last_irq = tr.irq;
      ap.write(tr);                   // broadcast every cycle
    end
  endtask

  function void report_phase(uvm_phase phase);
    `uvm_info("SRC_MON", $sformatf("irq rose %0d time(s)", n_irq_rise), UVM_LOW)
  endfunction
endclass
