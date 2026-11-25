
// apb_intc.sv : APB4 interrupt controller, N_SRC sources (N_SRC <= 32)
module apb_intc #(
  parameter int N_SRC = 8
) (
  // clock and reset
  input  logic              pclk,
  input  logic              presetn,
  // APB4 completer
  input  logic              psel,
  input  logic              penable,
  input  logic              pwrite,
  input  logic [11:0]       paddr,
  /* verilator lint_off UNUSEDSIGNAL */  // only pwdata[N_SRC-1:0] is used
  input  logic [31:0]       pwdata,
  /* verilator lint_on UNUSEDSIGNAL */
  input  logic [3:0]        pstrb,
  output logic [31:0]       prdata,
  output logic              pready,
  output logic              pslverr,
  // interrupts
  input  logic [N_SRC-1:0]  src_i,
  output logic              irq_o
);

  // ---------------- register addresses ----------------
  localparam logic [11:0] A_RAW  = 12'h000;
  localparam logic [11:0] A_EN   = 12'h004;
  localparam logic [11:0] A_MODE = 12'h008;
  localparam logic [11:0] A_PEND = 12'h00C;
  localparam logic [11:0] A_STAT = 12'h010;
  localparam logic [11:0] A_ID   = 12'h014;

  // ---------------- 1. bus decoder ----------------
  logic acc, wr, rd, addr_ok;
  logic [N_SRC-1:0] wmask;

  assign acc = psel & penable;
  assign wr  = acc &  pwrite;
  assign rd  = acc & ~pwrite;

  always_comb begin
    case (paddr)
      A_RAW, A_EN, A_MODE, A_PEND, A_STAT, A_ID: addr_ok = 1'b1;
      default:                                   addr_ok = 1'b0;
    endcase
  end

  // byte lane mask, cut down to N_SRC bits
  /* verilator lint_off UNUSEDSIGNAL */
  logic [31:0] wmask32;
  /* verilator lint_on UNUSEDSIGNAL */
  assign wmask32 = {{8{pstrb[3]}}, {8{pstrb[2]}}, {8{pstrb[1]}}, {8{pstrb[0]}}};
  assign wmask   = wmask32[N_SRC-1:0];

  // ---------------- state (flops) ----------------
  logic [N_SRC-1:0] src_q, en_q, mode_q, pend_q;

  // ---------------- 3. edge spotter + clear mask ----------------
  logic [N_SRC-1:0] rise, clr;
  assign rise = src_i & ~src_q;
  assign clr  = (wr && paddr == A_PEND) ? (pwdata[N_SRC-1:0] & wmask) : '0;

  // ---------------- 2 + 4. settings and pending list ----------------
  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      src_q  <= '0;
      en_q   <= '0;
      mode_q <= '0;
      pend_q <= '0;
    end else begin
      src_q <= src_i;
      if (wr && paddr == A_EN)
        en_q   <= (en_q   & ~wmask) | (pwdata[N_SRC-1:0] & wmask);
      if (wr && paddr == A_MODE)
        mode_q <= (mode_q & ~wmask) | (pwdata[N_SRC-1:0] & wmask);
      for (int i = 0; i < N_SRC; i++) begin
        if (mode_q[i]) pend_q[i] <= (pend_q[i] & ~clr[i]) | rise[i];  // edge: set wins
        else           pend_q[i] <= src_i[i];                         // level: copy wire
      end
    end
  end

  // ---------------- 5. filter ----------------
  logic [N_SRC-1:0] active;
  assign active = pend_q & en_q;

  // ---------------- 6. alarm ----------------
  assign irq_o = |active;

  // ---------------- 7. picker (lowest index wins) ----------------
  logic       id_valid;
  logic [4:0] id_idx;
  always_comb begin
    id_valid = 1'b0;
    id_idx   = '0;
    for (int i = N_SRC-1; i >= 0; i--) begin   // scan high to low, last hit = lowest
      if (active[i]) begin
        id_valid = 1'b1;
        id_idx   = 5'(i);
      end
    end
  end

  // ---------------- 8. read back ----------------
  always_comb begin
    prdata = '0;
    if (rd) begin
      case (paddr)
        A_RAW:   prdata[N_SRC-1:0] = src_q;
        A_EN:    prdata[N_SRC-1:0] = en_q;
        A_MODE:  prdata[N_SRC-1:0] = mode_q;
        A_PEND:  prdata[N_SRC-1:0] = pend_q;
        A_STAT:  prdata[N_SRC-1:0] = active;
        A_ID:    prdata            = {id_valid, 26'd0, id_idx};
        default: prdata            = '0;
      endcase
    end
  end

  // ---------------- bus response ----------------
  assign pready  = 1'b1;
  assign pslverr = acc & ~addr_ok;


`ifdef FORMAL
  `include "apb_intc_props.svh"
`endif

endmodule
