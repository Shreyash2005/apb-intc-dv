// src_item.sv : "put this value on the source wires and hold it for N cycles"
class src_item extends uvm_sequence_item;
  rand bit [7:0]    value;   // which sources are high
  rand int unsigned hold;    // how many clock cycles to hold it
       bit          irq;     // filled in by the monitor only

  constraint c_hold { hold inside {[1:8]}; }

  `uvm_object_utils(src_item)

  function new(string name = "src_item");
    super.new(name);
  endfunction

  function string convert2string();
    return $sformatf("src=%08b hold=%0d irq=%0b", value, hold, irq);
  endfunction
endclass
