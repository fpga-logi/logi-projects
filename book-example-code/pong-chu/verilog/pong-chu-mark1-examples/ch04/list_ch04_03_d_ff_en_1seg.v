// Listing 4.3
module d_ff_en_1seg
   (
    input wire clk, reset,
    input wire en,
    input wire d,
    output reg q
   );

   // body
   always @(posedge clk, posedge reset)
      if (reset)
         q <= 1'b0;
      else if (en)
         q <= d;

endmodule