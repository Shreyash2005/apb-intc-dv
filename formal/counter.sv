
module counter (input logic clk, input logic rst);
  logic [3:0] cnt;
  always_ff @(posedge clk)
    if (rst || cnt == 4'd9) cnt <= '0;
    else                    cnt <= cnt + 1'b1;

`ifdef FORMAL
  logic f_past_valid = 1'b0;
  always @(posedge clk) f_past_valid <= 1'b1;
  always @(*) if (!f_past_valid) assume (rst);
  always @(posedge clk) if (f_past_valid) assert (cnt <= 4'd9);
`endif
endmodule
