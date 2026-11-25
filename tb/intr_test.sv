// intr_test.sv : configure, fire one interrupt, service it like a CPU.
// Checking is done by the scoreboard inside the env.
class intr_test extends uvm_test;
  `uvm_component_utils(intr_test)

  intc_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = intc_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    apb_cfg_seq   cfg   = apb_cfg_seq::type_id::create("cfg");
    src_pulse_seq pulse = src_pulse_seq::type_id::create("pulse");
    apb_isr_seq   isr   = apb_isr_seq::type_id::create("isr");

    phase.raise_objection(this);
    cfg.en   = 8'h08;              // 1. CPU: enable source 3, edge mode
    cfg.mode = 8'h08;
    cfg.start(env.apb_agt.sqr);
    pulse.idx = 3;                 // 2. device: pulse source 3
    pulse.start(env.src_agt.sqr);
    #30;                           //    let irq rise
    isr.start(env.apb_agt.sqr);    // 3. CPU: read ID, clear PEND
    #30;                           //    let irq fall
    phase.drop_objection(this);
  endtask
endclass
