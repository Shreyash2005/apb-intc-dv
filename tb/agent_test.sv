
class agent_test extends uvm_test;
  `uvm_component_utils(agent_test)

  apb_agent agt;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agt = apb_agent::type_id::create("agt", this);
  endfunction

  task run_phase(uvm_phase phase);
    apb_smoke_seq seq = apb_smoke_seq::type_id::create("seq");
    phase.raise_objection(this);     // "don't end the sim yet"
    seq.start(agt.sqr);              // run the sequence on the agent's outbox
    #20;
    phase.drop_objection(this);      // "I'm done"
  endtask
endclass
