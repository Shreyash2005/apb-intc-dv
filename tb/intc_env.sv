// intc_env.sv : both agents + scoreboard, connected
class intc_env extends uvm_env;
  `uvm_component_utils(intc_env)

  apb_agent       apb_agt;
  src_agent       src_agt;
  intc_scoreboard sb;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    apb_agt = apb_agent::type_id::create("apb_agt", this);
    src_agt = src_agent::type_id::create("src_agt", this);
    sb      = intc_scoreboard::type_id::create("sb", this);
  endfunction

  // plug each monitor's loudspeaker into its scoreboard mailbox
  function void connect_phase(uvm_phase phase);
    apb_agt.ap.connect(sb.apb_fifo.analysis_export);
    src_agt.ap.connect(sb.src_fifo.analysis_export);
  endfunction
endclass
