// tb_top.sv : clock, reset, interfaces, DUT, and UVM kickoff
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

  // the two boxes of wires
  apb_if apb  (.pclk(pclk), .presetn(presetn));
  src_if srcs (.pclk(pclk), .presetn(presetn));

  // DUT, each port hooked to a wire in a box
  apb_intc #(.N_SRC(8)) dut (
    .pclk   (pclk),        .presetn(presetn),
    .psel   (apb.psel),    .penable(apb.penable), .pwrite (apb.pwrite),
    .paddr  (apb.paddr),   .pwdata (apb.pwdata),  .pstrb  (apb.pstrb),
    .prdata (apb.prdata),  .pready (apb.pready),  .pslverr(apb.pslverr),
    .src_i  (srcs.src),    .irq_o  (srcs.irq)
  );

  // hand both boxes to UVM, then start the test named on the command line
  initial begin
    uvm_config_db#(virtual apb_if)::set(null, "uvm_test_top.*", "vif",     apb);
    uvm_config_db#(virtual src_if)::set(null, "uvm_test_top.*", "src_vif", srcs);
    run_test();
  end
endmodule
