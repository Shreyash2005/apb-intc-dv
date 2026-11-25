// intc_scoreboard.sv : checks the DUT against intc_model every clock cycle
class intc_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(intc_scoreboard)

  // mailboxes the monitors write into
  uvm_tlm_analysis_fifo #(apb_item) apb_fifo;
  uvm_tlm_analysis_fifo #(src_item) src_fifo;

  intc_model   model;
  int unsigned n_cycles, n_reads, n_writes, n_errors;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    apb_fifo = new("apb_fifo", this);
    src_fifo = new("src_fifo", this);
    model    = new();
    model.reset();
  endfunction

  // one source sample arrives per clock edge; use it as the cycle tick
  task run_phase(uvm_phase phase);
    src_item   s;
    apb_item   a;
    bit        has_apb;
    forever begin
      src_fifo.get(s);            // wait for this edge's sample
      #1;                         // let an APB item from the same edge arrive
      has_apb = apb_fifo.try_get(a);
      check_cycle(s, has_apb, a);
    end
  endtask

  function void check_cycle(src_item s, bit has_apb, apb_item a);
    bit        wr;
    bit [11:0] addr;
    bit [31:0] data;
    bit [3:0]  strb;
    bit [31:0] exp;

    n_cycles++;

    // 1. CHECK irq against the state BEFORE this edge
    if (s.irq !== model.irq()) begin
      n_errors++;
      `uvm_error("SB_IRQ", $sformatf("cycle %0d: irq=%0b, expected %0b (model pend=%08b en=%08b)",
                 n_cycles, s.irq, model.irq(), model.pend, model.en))
    end

    // 2. CHECK the APB transfer, if one completed at this edge
    wr = 0; addr = '0; data = '0; strb = '0;
    if (has_apb) begin
      if (a.slverr !== !model.addr_ok(a.addr)) begin
        n_errors++;
        `uvm_error("SB_ERR", $sformatf("cycle %0d: addr 0x%03h slverr=%0b, expected %0b",
                   n_cycles, a.addr, a.slverr, !model.addr_ok(a.addr)))
      end
      if (a.write) begin
        n_writes++;
        wr = 1; addr = a.addr; data = a.data; strb = a.strb;
      end else begin
        n_reads++;
        exp = model.read(a.addr);
        if (a.data !== exp) begin
          n_errors++;
          `uvm_error("SB_READ", $sformatf("cycle %0d: read 0x%03h got 0x%08h, expected 0x%08h",
                     n_cycles, a.addr, a.data, exp))
        end else
          `uvm_info("SB_READ", $sformatf("read 0x%03h = 0x%08h ok", a.addr, a.data), UVM_MEDIUM)
      end
    end

    // 3. UPDATE the model with this edge's inputs
    model.step(s.value, wr, addr, data, strb);
  endfunction

  // anything left unprocessed at the end is suspicious
  function void check_phase(uvm_phase phase);
    if (apb_fifo.used() != 0)
      `uvm_error("SB", $sformatf("%0d APB items never checked", apb_fifo.used()))
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("SB", $sformatf("cycles=%0d reads=%0d writes=%0d errors=%0d",
              n_cycles, n_reads, n_writes, n_errors), UVM_LOW)
    if (n_errors == 0 && n_cycles > 0)
      `uvm_info("SB", "SCOREBOARD PASSED", UVM_LOW)
    else
      `uvm_error("SB", "SCOREBOARD FAILED")
  endfunction
endclass
