// src_if.sv : interrupt side wires shared by the DUT and the testbench
interface src_if (input logic pclk, input logic presetn);
  logic [7:0] src;   // driven by the testbench, read by the DUT (src_i)
  logic       irq;   // driven by the DUT (irq_o), read by the testbench
endinterface
