// intc_coverage.sv : hand rolled functional coverage (59 bins).
// Same bins a covergroup would have; one counter per bin, hit = counter > 0.
// Sampled once per cycle by the scoreboard, using the model state BEFORE the edge.
class intc_coverage;
  int unsigned c1_reg  [2][7];   // C1 [rd/wr][RAW,EN,MODE,PEND,STAT,ID,BAD]    14 bins
  int unsigned c2_rise [8][2];   // C2 [source][level/edge] rising edge seen     16 bins
  int unsigned c3_race [8];      // C3 [source] rise + W1C same cycle (edge)      8 bins
  int unsigned c4_clr  [8];      // C4 [source] W1C cleared a set bit (edge)      8 bins
  int unsigned c5_id   [9];      // C5 ID read value 0..7, 8 = nothing valid      9 bins
  int unsigned c6_multi;         // C6 two or more sources active at once         1 bin
  int unsigned c7_strb0;         // C7 write with pstrb[0] = 0                     1 bin
  int unsigned c8_irq  [2];      // C8 irq [fall, rise]                            2 bins
  bit          last_irq;

  string reg_name [7] = '{"RAW", "EN", "MODE", "PEND", "STAT", "ID", "BAD"};
  int unsigned hit_total, bin_total;

  static function int reg_idx(bit [11:0] a);
    case (a)
      12'h000: return 0;
      12'h004: return 1;
      12'h008: return 2;
      12'h00C: return 3;
      12'h010: return 4;
      12'h014: return 5;
      default: return 6;
    endcase
  endfunction

  // m = model BEFORE this edge, s = this edge's source sample, a = APB item (if has_apb)
  function void sample(intc_model m, src_item s, bit has_apb, apb_item a);
    bit [7:0]  rise, clr;
    bit [31:0] id;
    rise = s.value & ~m.src_q;
    clr  = '0;

    if (has_apb) begin
      c1_reg[a.write][reg_idx(a.addr)]++;
      if (a.write && !a.strb[0])                         c7_strb0++;
      if (a.write && a.addr == 12'h00C && a.strb[0])      clr = a.data[7:0];
      if (!a.write && a.addr == 12'h014) begin
        id = m.id_reg();
        if (id[31]) c5_id[id[4:0]]++;
        else        c5_id[8]++;
      end
    end

    for (int i = 0; i < 8; i++) begin
      if (rise[i])                                   c2_rise[i][m.mode[i]]++;
      if (m.mode[i] && rise[i] && clr[i])            c3_race[i]++;
      if (m.mode[i] && m.pend[i] && clr[i] && !rise[i]) c4_clr[i]++;
    end

    if ($countones(m.active()) >= 2) c6_multi++;

    if ( s.irq && !last_irq) c8_irq[1]++;
    if (!s.irq &&  last_irq) c8_irq[0]++;
    last_irq = s.irq;
  endfunction

  // print one coverpoint: hits / bins and which bins are missing
  function void show(string name, int h, int t, string miss);
    hit_total += h;
    bin_total += t;
    `uvm_info("COV", $sformatf("%-22s %2d/%2d  missing:%s", name, h, t,
              (miss == "") ? " none" : miss), UVM_LOW)
  endfunction

  function void report();
    int    h;
    string miss;
    hit_total = 0;
    bin_total = 0;

    h = 0; miss = "";
    for (int w = 0; w < 2; w++)
      for (int r = 0; r < 7; r++)
        if (c1_reg[w][r] > 0) h++;
        else miss = {miss, " ", (w ? "WR_" : "RD_"), reg_name[r]};
    show("C1 register access", h, 14, miss);

    h = 0; miss = "";
    for (int i = 0; i < 8; i++)
      for (int md = 0; md < 2; md++)
        if (c2_rise[i][md] > 0) h++;
        else miss = {miss, $sformatf(" s%0d%s", i, md ? "E" : "L")};
    show("C2 rise x mode", h, 16, miss);

    h = 0; miss = "";
    for (int i = 0; i < 8; i++)
      if (c3_race[i] > 0) h++; else miss = {miss, $sformatf(" s%0d", i)};
    show("C3 edge/clear race", h, 8, miss);

    h = 0; miss = "";
    for (int i = 0; i < 8; i++)
      if (c4_clr[i] > 0) h++; else miss = {miss, $sformatf(" s%0d", i)};
    show("C4 W1C clears", h, 8, miss);

    h = 0; miss = "";
    for (int i = 0; i < 9; i++)
      if (c5_id[i] > 0) h++;
      else miss = {miss, (i == 8) ? " none" : $sformatf(" id%0d", i)};
    show("C5 ID values", h, 9, miss);

    show("C6 multi active", (c6_multi > 0), 1, (c6_multi > 0) ? "" : " multi");
    show("C7 pstrb0 write", (c7_strb0 > 0), 1, (c7_strb0 > 0) ? "" : " strb0");

    h = 0; miss = "";
    if (c8_irq[0] > 0) h++; else miss = {miss, " fall"};
    if (c8_irq[1] > 0) h++; else miss = {miss, " rise"};
    show("C8 irq toggle", h, 2, miss);

    `uvm_info("COV", $sformatf("TOTAL %0d/%0d bins = %.1f%%",
              hit_total, bin_total, 100.0 * hit_total / bin_total), UVM_LOW)
  endfunction
endclass
