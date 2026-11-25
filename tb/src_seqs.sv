// src_seqs.sv : interrupt source sequences

// base: one helper to drive a value for some cycles
class src_base_seq extends uvm_sequence #(src_item);
  `uvm_object_utils(src_base_seq)
  function new(string name = "src_base_seq");
    super.new(name);
  endfunction

  task drive(bit [7:0] v, int unsigned h);
    src_item tr = src_item::type_id::create("tr");
    start_item(tr);
    if (!tr.randomize() with { value == v; hold == h; })
      `uvm_fatal("RAND", "src randomize failed")
    finish_item(tr);
  endtask
endclass

// one cycle pulse on one source, then back to 0
class src_pulse_seq extends src_base_seq;
  `uvm_object_utils(src_pulse_seq)
  rand int unsigned idx;
  constraint c_idx { idx < 8; }

  function new(string name = "src_pulse_seq");
    super.new(name);
  endfunction

  task body();
    drive(8'(1 << idx), 1);   // source idx high for 1 cycle
    drive(8'h00, 1);          // back to low
  endtask
endclass
