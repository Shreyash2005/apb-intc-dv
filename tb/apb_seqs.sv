// apb_seqs.sv : APB sequences

// base sequence: two helper tasks every sequence can use
class apb_base_seq extends uvm_sequence #(apb_item);
  `uvm_object_utils(apb_base_seq)
  function new(string name = "apb_base_seq");
    super.new(name);
  endfunction

  task do_write(bit [11:0] a, bit [31:0] d, bit [3:0] s = 4'hF);
    apb_item tr = apb_item::type_id::create("tr");
    start_item(tr);
    if (!tr.randomize() with { write == 1; addr == a; data == d; strb == s; })
      `uvm_fatal("RAND", "write randomize failed")
    finish_item(tr);
  endtask

  task do_read(bit [11:0] a, output bit [31:0] d, output bit err);
    apb_item tr = apb_item::type_id::create("tr");
    start_item(tr);
    if (!tr.randomize() with { write == 0; addr == a; })
      `uvm_fatal("RAND", "read randomize failed")
    finish_item(tr);            // returns after the driver filled in tr.data
    d   = tr.data;
    err = tr.slverr;
  endtask
endclass

// same steps as the smoke test, now as a UVM sequence
class apb_smoke_seq extends apb_base_seq;
  `uvm_object_utils(apb_smoke_seq)
  function new(string name = "apb_smoke_seq");
    super.new(name);
  endfunction

  task body();
    bit [31:0] d;
    bit        e;
    do_write(12'h004, 32'h08);              // EN   = 0x08
    do_write(12'h008, 32'h08);              // MODE = 0x08
    do_read (12'h004, d, e);
    if (d !== 32'h08) `uvm_error("SEQ", $sformatf("EN read 0x%0h, expected 0x08", d))
    do_write(12'h004, 32'hFF, 4'b0000);     // PSTRB = 0: EN must not change
    do_read (12'h004, d, e);
    if (d !== 32'h08) `uvm_error("SEQ", $sformatf("PSTRB=0 write changed EN to 0x%0h", d))
    do_read (12'h020, d, e);                // bad address
    if (e !== 1'b1) `uvm_error("SEQ", "no PSLVERR on bad address")
  endtask
endclass

// configure: write EN and MODE
class apb_cfg_seq extends apb_base_seq;
  `uvm_object_utils(apb_cfg_seq)
  rand bit [7:0] en;
  rand bit [7:0] mode;

  function new(string name = "apb_cfg_seq");
    super.new(name);
  endfunction

  task body();
    do_write(12'h004, {24'h0, en});
    do_write(12'h008, {24'h0, mode});
  endtask
endclass

// mini interrupt handler: read ID, clear that source's PEND bit
class apb_isr_seq extends apb_base_seq;
  `uvm_object_utils(apb_isr_seq)
  function new(string name = "apb_isr_seq");
    super.new(name);
  endfunction

  task body();
    bit [31:0] d;
    bit        e;
    do_read(12'h014, d, e);                       // who interrupted?
    if (d[31]) begin
      `uvm_info("ISR", $sformatf("servicing source %0d", d[4:0]), UVM_LOW)
      do_write(12'h00C, 32'h1 << d[4:0]);         // W1C that PEND bit
    end else
      `uvm_info("ISR", "no interrupt pending", UVM_LOW)
  endtask
endclass
