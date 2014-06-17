// Listing 7.9
module univ_bin_counter_merged
   #(parameter N=8)
   (
    input wire clk, reset,
    input wire syn_clr, load, en, up,
    input wire [N-1:0] d,
    output wire max_tick, min_tick,
    output reg [N-1:0] q
   );

   // body
   // register and next-state logic
   always @(posedge clk, posedge reset)
      if (reset)
         q <= 0;  //
      else if (syn_clr)
         q <= 0;
      else if (load)
         q <= d;
      else if (en & up )
         q <= q + 1;
      else if (en & ~up )
         q <= q - 1;
      // no else branch since q <= q is implicitly implied

   // output logic
   assign max_tick = (q==2**N-1) ? 1'b1 : 1'b0;
   assign min_tick = (q==0) ? 1'b1 : 1'b0;

endmodule
