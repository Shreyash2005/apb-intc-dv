// apb_intc_props.svh : formal properties for apb_intc.
// Included INSIDE the module under `ifdef FORMAL, so it can see internal signals.
// The EN/MODE write property assumes N_SRC <= 8 (only byte 0's strobe matters).

  // ================= setup =================
  reg f_past_valid = 1'b0;                       // false only on the very first cycle
  always @(posedge pclk) f_past_valid <= 1'b1;

  reg f_prev_rstn = 1'b0;                        // presetn one cycle ago
  always @(posedge pclk) f_prev_rstn <= presetn;

  wire f_steady = f_past_valid && f_prev_rstn && presetn;   // out of reset now and last cycle

  // ================= A1: start in reset =================
  always @(*) if (!f_past_valid) assume (!presetn);

  // ================= A2: legal APB requester =================
  always @(*) if (penable) assume (psel);
  always @(posedge pclk) if (f_steady) begin
    if ($past(psel) && !$past(penable)) begin    // setup -> must be access next
      assume (psel && penable);
      assume (paddr  == $past(paddr));
      assume (pwrite == $past(pwrite));
      assume (pwdata == $past(pwdata));
      assume (pstrb  == $past(pstrb));
    end
    if ($past(psel) && $past(penable))           // pready is 1: access lasts one cycle
      assume (!penable);
  end

  // ================= P1: reset clears everything =================
  always @(posedge pclk)
    if (f_past_valid && !$past(presetn))
      assert (src_q == '0 && en_q == '0 && mode_q == '0 && pend_q == '0);

  // ================= P2: irq is exactly "anything pending and enabled" =================
  always @(*) assert (irq_o == |(pend_q & en_q));

  // ================= P3..P7: the PEND rules, for every source =================
  genvar f_i;
  generate for (f_i = 0; f_i < N_SRC; f_i = f_i + 1) begin : g_fsrc
    always @(posedge pclk) if (f_steady) begin
      if ($past(mode_q[f_i])) begin
        // P3 set wins: a rising edge always sets PEND, even with a clear in the same cycle
        if ($past(rise[f_i]))
          assert (pend_q[f_i]);
        // P4 hold: pending and not cleared -> still pending
        if ($past(pend_q[f_i]) && !$past(clr[f_i]))
          assert (pend_q[f_i]);
        // P5 clear: pending, cleared, no new edge -> cleared
        if ($past(pend_q[f_i]) && $past(clr[f_i]) && !$past(rise[f_i]))
          assert (!pend_q[f_i]);
        // P6 no ghost: not pending and no edge -> stays clear
        if (!$past(pend_q[f_i]) && !$past(rise[f_i]))
          assert (!pend_q[f_i]);
      end else begin
        // P7 level mode: PEND follows the wire, one cycle late
        assert (pend_q[f_i] == $past(src_i[f_i]));
      end
    end
  end endgenerate

  // ================= P8: ID names the lowest active source =================
  always @(*) begin
    assert (id_valid == |active);
    if (id_valid) begin
      assert (id_idx < N_SRC);
      assert (active[id_idx]);                               // that source is active
      assert ((active & ((1 << id_idx) - 1)) == '0);         // nothing below it is
    end
  end

  // ================= P9: bus response =================
  always @(*) begin
    assert (pready == 1'b1);
    if (!(psel && penable))
      assert (!pslverr);
    else
      assert (pslverr == !(paddr == A_RAW  || paddr == A_EN   || paddr == A_MODE ||
                           paddr == A_PEND || paddr == A_STAT || paddr == A_ID));
  end

  // ================= P10: EN and MODE change only on their own write =================
  always @(posedge pclk) if (f_steady) begin
    if ($past(wr) && $past(paddr) == A_EN)
      assert (en_q == ($past(pstrb[0]) ? $past(pwdata[N_SRC-1:0]) : $past(en_q)));
    else
      assert (en_q == $past(en_q));

    if ($past(wr) && $past(paddr) == A_MODE)
      assert (mode_q == ($past(pstrb[0]) ? $past(pwdata[N_SRC-1:0]) : $past(mode_q)));
    else
      assert (mode_q == $past(mode_q));
  end

  // ================= P11: read data is 0 when not reading =================
  always @(*) if (!(psel && penable && !pwrite)) assert (prdata == '0);

  // ================= covers: prove the interesting cases are reachable =================
  always @(posedge pclk) if (f_steady) begin
    cover ($past(mode_q[0] && rise[0] && clr[0]) && pend_q[0]);   // C1 race, set won
    cover (irq_o);                                                // C2 interrupt raised
    cover (id_valid && id_idx == N_SRC - 1);                      // C3 only the top source active
    cover (active[0] && active[N_SRC-1]);                         // C4 two sources active
    cover (pslverr);                                              // C5 bad address
    cover ($past(mode_q[2] && pend_q[2]) && !pend_q[2]);          // C6 a real clear
  end
