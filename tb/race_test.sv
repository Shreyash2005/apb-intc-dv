// race_test.sv : for every source, line up a rising edge with a W1C on the
// same clock edge. Spec: the edge wins, PEND stays set. Sweeps lead = 0,1,2
// so the rise lands one cycle before, on, and one cycle after the clear.
class race_test extends intc_base_test;
  `uvm_component_utils(race_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    apb_cfg_seq cfg = apb_cfg_seq::type_id::create("cfg");
    phase.raise_objection(this);
    cfg.en   = 8'hFF;                       // all sources enabled
    cfg.mode = 8'hFF;                       // all edge mode (race only matters here)
    cfg.start(env.apb_agt.sqr);
    for (int i = 0; i < 8; i++)
      for (int lead = 0; lead < 3; lead++)
        race_once(i, lead);
    #50;
    phase.drop_objection(this);
  endtask

  task race_once(int i, int lead);
    src_pulse_seq pulse = src_pulse_seq::type_id::create("pulse");
    apb_write_seq w1c   = apb_write_seq::type_id::create("w1c");
    src_race_seq  rise  = src_race_seq::type_id::create("rise");
    apb_write_seq tidy  = apb_write_seq::type_id::create("tidy");

    // 1. make PEND[i] = 1
    pulse.idx = i;
    pulse.start(env.src_agt.sqr);
    #23;                                    // mid cycle: both drivers start on the same negedge

    // 2. W1C on PEND[i] and a new rise on source i, launched together
    w1c.addr  = 12'h00C;
    w1c.data  = 32'h1 << i;
    rise.idx  = i;
    rise.lead = lead;
    fork
      w1c.start(env.apb_agt.sqr);
      rise.start(env.src_agt.sqr);
    join
    #23;

    // 3. clear whatever is left so the next round starts clean
    tidy.addr = 12'h00C;
    tidy.data = 32'h1 << i;
    tidy.start(env.apb_agt.sqr);
  endtask
endclass
