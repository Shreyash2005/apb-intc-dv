
// apb_monitor.sv : watches the APB pins and reports every completed transfer.
// It never drives anything.
class apb_monitor extends uvm_monitor;
  `uvm_component_utils(apb_monitor)

  virtual apb_if vif;                  // handle to the real wires
  uvm_analysis_port #(apb_item) ap;    // broadcast port: scoreboard and coverage plug in here
  int unsigned n_seen;                 // how many transfers we saw

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // build: create the broadcast port and find the wires
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
    if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "apb_monitor: no virtual interface in config_db")
  endfunction

  // run: check the wires on every posedge, forever
  task run_phase(uvm_phase phase);
    apb_item tr;
    forever begin
      @(posedge vif.pclk);
      // a transfer completes on the posedge where PSEL, PENABLE and PREADY are all high
      if (vif.presetn && vif.psel && vif.penable && vif.pready) begin
        tr        = apb_item::type_id::create("tr");
        tr.write  = vif.pwrite;
        tr.addr   = vif.paddr;
        tr.data   = vif.pwrite ? vif.pwdata : vif.prdata;
        tr.strb   = vif.pstrb;
        tr.slverr = vif.pslverr;
        n_seen++;
        `uvm_info("APB_MON", tr.convert2string(), UVM_MEDIUM)
        ap.write(tr);                  // announce it to every listener
      end
    end
  endtask

  // report: print a summary at the end of the sim
  function void report_phase(uvm_phase phase);
    `uvm_info("APB_MON", $sformatf("observed %0d transfers", n_seen), UVM_LOW)
  endfunction
endclass
