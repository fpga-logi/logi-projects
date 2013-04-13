// Listing A.2
module counter_inst
   (
    input wire clk, reset,
    input wire syn_clr16, load16, en16,
    input wire [15:0] d,
    output wire max_tick8, max_tick16,
    output wire [15:0] q
   );

   // body
   // instantiation of 16-bit counter, all ports used
   bin_counter #(.N(16)) counter_16_unit
      (.clk(clk), .reset(reset),
       .syn_clr(syn_clr16), .load(load16), .en(en16),
       .d(d), .max_tick(max_tick16), .q(q));
   // instantiation of free-running 8-bit counter
   // with only the max_tick signal
   bin_counter counter_8_unit
      (.clk(clk), .reset(reset),
       .syn_clr(1'b0), .load(1'b0), .en(1'b1),
       .d(8'h00), .max_tick(max_tick8), .q());

endmodule
