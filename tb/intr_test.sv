// intr_test.sv : configure, fire one interrupt, service it like a CPU
class intr_test extends uvm_test;
  `uvm_component_utils(intr_test)

  apb_agent apb_agt;
  src_agent src_agt;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    apb_agt = apb_agent::type_id::create("apb_agt", this);
    src_agt = src_agent::type_id::create("src_agt", this);
  endfunction

  task run_phase(uvm_phase phase);
    apb_cfg_seq   cfg   = apb_cfg_seq::type_id::create("cfg");
    src_pulse_seq pulse = src_pulse_seq::type_id::create("pulse");
    apb_isr_seq   isr   = apb_isr_seq::type_id::create("isr");

    phase.raise_objection(this);
    cfg.en   = 8'h08;              // 1. CPU: enable source 3, edge mode
    cfg.mode = 8'h08;
    cfg.start(apb_agt.sqr);
    pulse.idx = 3;                 // 2. device: pulse source 3
    pulse.start(src_agt.sqr);
    #30;                           //    let irq rise
    isr.start(apb_agt.sqr);        // 3. CPU: read ID, clear PEND
    #30;                           //    let irq fall
    phase.drop_objection(this);
  endtask
endclass
