
module tb_top;
  import uvm_pkg::*;
  import test_pkg::*;

  // clock and reset
  logic pclk = 0, presetn = 0;
  always #5 pclk = ~pclk;
  initial begin
    repeat (3) @(negedge pclk);
    presetn = 1;
  end

  // the box of wires
  apb_if apb (.pclk(pclk), .presetn(presetn));

  // interrupt side, idle for now
  logic [7:0] src_i = '0;
  logic       irq_o;

  // DUT, each port hooked to a wire in the box
  apb_intc #(.N_SRC(8)) dut (
    .pclk   (pclk),        .presetn(presetn),
    .psel   (apb.psel),    .penable(apb.penable), .pwrite (apb.pwrite),
    .paddr  (apb.paddr),   .pwdata (apb.pwdata),  .pstrb  (apb.pstrb),
    .prdata (apb.prdata),  .pready (apb.pready),  .pslverr(apb.pslverr),
    .src_i  (src_i),       .irq_o  (irq_o)
  );

  // hand the wires to UVM, then start the test named on the command line
  initial begin
    uvm_config_db#(virtual apb_if)::set(null, "uvm_test_top.*", "vif", apb);
    run_test();
  end
endmodule
