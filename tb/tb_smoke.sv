
// tb_smoke.sv : plain SystemVerilog smoke test (no UVM)
// Runs the "life of one interrupt" story and the edge vs clear race.
module tb_smoke;

  logic        pclk = 0, presetn = 0;
  logic        psel = 0, penable = 0, pwrite = 0;
  logic [11:0] paddr = 0;
  logic [31:0] pwdata = 0, prdata;
  logic [3:0]  pstrb = 4'hF;
  logic        pready, pslverr;
  logic [7:0]  src_i = 0;
  logic        irq_o;
  int          errors = 0;

  apb_intc #(.N_SRC(8)) dut (.*);

  always #5 pclk = ~pclk;                     // 100 MHz

  // APB write: setup cycle, then access cycle. Drive on negedge.
  task automatic apb_write(input logic [11:0] a, input logic [31:0] d);
    @(negedge pclk); psel = 1; penable = 0; pwrite = 1; paddr = a; pwdata = d;
    @(negedge pclk); penable = 1;
    @(negedge pclk); psel = 0; penable = 0; pwrite = 0;
  endtask

  // APB read: sample prdata at the posedge that ends the access phase
  task automatic apb_read(input logic [11:0] a, output logic [31:0] d);
    @(negedge pclk); psel = 1; penable = 0; pwrite = 0; paddr = a;
    @(negedge pclk); penable = 1;
    @(posedge pclk); d = prdata;
    @(negedge pclk); psel = 0; penable = 0;
  endtask

  task automatic check(input string what, input logic [31:0] got, exp);
    if (got !== exp) begin
      $display("FAIL %-28s got 0x%h exp 0x%h  @%0t", what, got, exp, $time);
      errors++;
    end else
      $display("ok   %-28s 0x%h", what, got);
  endtask

  logic [31:0] rd;

  initial begin
    $dumpfile("tb_smoke.vcd");
    $dumpvars(0, tb_smoke);

    // reset
    repeat (3) @(negedge pclk);
    presetn = 1;

    // 1. configure: source 3 enabled, edge mode
    apb_write(12'h004, 32'h08);             // EN
    apb_write(12'h008, 32'h08);             // MODE
    apb_read (12'h004, rd); check("EN readback", rd, 32'h08);
    check("irq low before event", {31'b0, irq_o}, 0);

    // 2. one cycle pulse on source 3
    @(negedge pclk); src_i[3] = 1;
    @(negedge pclk); src_i[3] = 0;
    @(negedge pclk);
    check("irq high after edge", {31'b0, irq_o}, 1);

    // 3. CPU asks who it was
    apb_read(12'h00C, rd); check("PEND", rd, 32'h08);
    apb_read(12'h014, rd); check("ID valid, id=3", rd, 32'h8000_0003);

    // 4. clear and check irq drops
    apb_write(12'h00C, 32'h08);
    check("irq low after W1C", {31'b0, irq_o}, 0);

    // 5. race: rising edge lands in the same cycle as the clear
    //    first make PEND[3] = 1 again
    @(negedge pclk); src_i[3] = 1;
    @(negedge pclk); src_i[3] = 0;
    //    W1C access phase and a new rising edge on the same cycle
    @(negedge pclk); psel = 1; penable = 0; pwrite = 1; paddr = 12'h00C; pwdata = 32'h08;
    @(negedge pclk); penable = 1; src_i[3] = 1;
    @(negedge pclk); psel = 0; penable = 0; pwrite = 0; src_i[3] = 0;
    check("race: set wins, irq high", {31'b0, irq_o}, 1);
    apb_read(12'h00C, rd); check("race: PEND[3] still set", rd, 32'h08);

    // 6. bad address -> pslverr
    @(negedge pclk); psel = 1; penable = 0; pwrite = 0; paddr = 12'h020;
    @(negedge pclk); penable = 1;
    @(posedge pclk); check("pslverr on bad addr", {31'b0, pslverr}, 1);
    @(negedge pclk); psel = 0; penable = 0;

    repeat (3) @(negedge pclk);
    if (errors == 0) $display("SMOKE TEST PASSED");
    else             $display("SMOKE TEST FAILED: %0d errors", errors);
    $finish;
  end
endmodule
