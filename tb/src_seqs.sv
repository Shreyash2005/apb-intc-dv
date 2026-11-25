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

// random device activity: quiet periods, single sources, bursts of several
class src_rand_seq extends src_base_seq;
  `uvm_object_utils(src_rand_seq)
  int unsigned n = 100;            // number of items

  function new(string name = "src_rand_seq");
    super.new(name);
  endfunction

  task body();
    bit [7:0] v;
    repeat (n) begin
      case ($urandom_range(0, 9))
        0, 1, 2, 3: v = 8'h00;                          // 40% quiet
        4, 5, 6, 7: v = 8'(1 << $urandom_range(0, 7));  // 40% one source high
        default:    v = 8'($urandom);                   // 20% several at once
      endcase
      drive(v, $urandom_range(1, 8));                   // hold 1..8 cycles
    end
    drive(8'h00, 1);                                    // end quiet
  endtask
endclass

// 'lead' cycles low, then a 1 cycle rise on source idx, then low
class src_race_seq extends src_base_seq;
  `uvm_object_utils(src_race_seq)
  int unsigned idx;
  int unsigned lead;               // 0, 1 or 2 cycles of low before the rise

  function new(string name = "src_race_seq");
    super.new(name);
  endfunction

  task body();
    if (lead > 0) drive(8'h00, lead);
    drive(8'(1 << idx), 1);
    drive(8'h00, 1);
  endtask
endclass
