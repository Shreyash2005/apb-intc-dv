
// apb_if.sv : APB4 signal bundle shared by the DUT and the testbench
interface apb_if (input logic pclk, input logic presetn);
  logic        psel;
  logic        penable;
  logic        pwrite;
  logic [11:0] paddr;
  logic [31:0] pwdata;
  logic [3:0]  pstrb;
  logic [31:0] prdata;
  logic        pready;
  logic        pslverr;
endinterface
