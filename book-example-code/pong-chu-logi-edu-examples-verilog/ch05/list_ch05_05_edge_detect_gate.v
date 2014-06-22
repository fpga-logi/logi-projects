// Listing 5.5
module edge_detect_gate
   (
    input wire  clk, reset,
    input wire  level,
    output wire tick
   );

   // signal declaration
   reg delay_reg;

   // delay register
    always @(posedge clk, posedge reset)
       if (reset)
          delay_reg <= 1'b0;
       else
          delay_reg <= level;

   // decoding logic
   assign tick = ~delay_reg & level;

endmodule