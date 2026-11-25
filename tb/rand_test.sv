// rand_test.sv : random CPU traffic and random device activity, in parallel.
// +N=<count> sets the number of operations per side (default 200).
class rand_test extends intc_base_test;
  `uvm_component_utils(rand_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    apb_rand_seq apb_seq = apb_rand_seq::type_id::create("apb_seq");
    src_rand_seq src_seq = src_rand_seq::type_id::create("src_seq");
    int unsigned n = 200;

    void'($value$plusargs("N=%d", n));
    apb_seq.n = n;
    src_seq.n = n;

    phase.raise_objection(this);
    fork                                   // both sides at the same time
      apb_seq.start(env.apb_agt.sqr);
      src_seq.start(env.src_agt.sqr);
    join                                   // wait for both to finish
    #50;
    phase.drop_objection(this);
  endtask
endclass
