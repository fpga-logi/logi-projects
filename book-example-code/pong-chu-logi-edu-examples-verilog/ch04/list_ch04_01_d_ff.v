// Listing 4.1
module d_ff
   (
    input wire clk,
    input wire d,
    output reg q
   );

   // body
   always @(posedge clk)
      q <= d;

endmodule