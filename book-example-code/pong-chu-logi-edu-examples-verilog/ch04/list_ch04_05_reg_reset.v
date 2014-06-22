// Listing 4.5
module reg_reset
   (
    input wire clk, reset,
    input wire [7:0] d,
    output reg [7:0] q
   );

   // body
   always @(posedge clk, posedge reset)
      if (reset)
         q <= 0;
      else
         q <= d;

endmodule