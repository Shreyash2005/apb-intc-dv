// intc_model.sv : reference model of the interrupt controller, written from the spec.
// No UVM, no timing: just state and rules, advanced one clock edge at a time.
class intc_model;
  bit [7:0] src_q, en, mode, pend;    // the same 4 registers as the DUT

  function void reset();
    src_q = '0; en = '0; mode = '0; pend = '0;
  endfunction

  // ---------- outputs, from the CURRENT state ----------
  function bit [7:0] active();
    return pend & en;
  endfunction

  function bit irq();
    return |(pend & en);
  endfunction

  function bit addr_ok(bit [11:0] a);
    return a inside {12'h000, 12'h004, 12'h008, 12'h00C, 12'h010, 12'h014};
  endfunction

  function bit [31:0] id_reg();         // lowest active index wins
    bit [7:0] act;
    act = active();
    for (int i = 0; i < 8; i++)
      if (act[i]) return {1'b1, 26'd0, 5'(i)};
    return 32'h0;
  endfunction

  function bit [31:0] read(bit [11:0] a);
    case (a)
      12'h000: return {24'h0, src_q};
      12'h004: return {24'h0, en};
      12'h008: return {24'h0, mode};
      12'h00C: return {24'h0, pend};
      12'h010: return {24'h0, active()};
      12'h014: return id_reg();
      default: return 32'h0;
    endcase
  endfunction

  // ---------- advance one clock edge ----------
  // src  : source wires the DUT samples at this edge
  // wr.. : APB write completing at this edge (wr = 0 if none)
  function void step(bit [7:0] src, bit wr, bit [11:0] a, bit [31:0] d, bit [3:0] strb);
    bit [7:0] mask, clr, rise;
    mask = strb[0] ? 8'hFF : 8'h00;                         // only byte 0 matters
    clr  = (wr && a == 12'h00C) ? (d[7:0] & mask) : 8'h00;  // W1C bits
    rise = src & ~src_q;                                    // new rising edges

    for (int i = 0; i < 8; i++)                             // uses the OLD mode
      pend[i] = mode[i] ? ((pend[i] & ~clr[i]) | rise[i])   // edge: set wins
                        : src[i];                           // level: copy wire

    if (wr && a == 12'h004) en   = (en   & ~mask) | (d[7:0] & mask);
    if (wr && a == 12'h008) mode = (mode & ~mask) | (d[7:0] & mask);
    src_q = src;
  endfunction
endclass
