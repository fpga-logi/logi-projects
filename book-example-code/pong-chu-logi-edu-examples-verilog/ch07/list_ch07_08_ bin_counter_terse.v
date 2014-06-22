// Listing 7.8
module bin_counter_terse
   #(parameter N=8)
   (
    input wire clk, reset,
    output wire max_tick,
    output reg [N-1:0] q
   );

   // body
   always @(posedge clk, posedge reset)
      if (reset)
         q <= 0;
      else
         q <= q + 1;
  // output logic
   assign max_tick = (q==2**N-1) ? 1'b1 : 1'b0;

endmodule