
// apb_item.sv : one APB transfer (the "what", with no timing)
class apb_item extends uvm_sequence_item;
  rand bit        write;     // 1 = write, 0 = read
  rand bit [11:0] addr;
  rand bit [31:0] data;      // pwdata on writes, prdata on reads
  rand bit [3:0]  strb;
       bit        slverr;    // response, filled in by driver / monitor

  // default: word aligned, inside the register window, all byte lanes on
  constraint c_aligned { addr[1:0] == 2'b00; }
  constraint c_window  { soft addr <= 12'h01C; }
  constraint c_strb    { soft strb == 4'hF; }

  `uvm_object_utils(apb_item)

  function new(string name = "apb_item");
    super.new(name);
  endfunction

  function string convert2string();
    return $sformatf("%s addr=0x%03h data=0x%08h strb=%b slverr=%0b",
                     write ? "WR" : "RD", addr, data, strb, slverr);
  endfunction
endclass
