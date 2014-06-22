// Listing 7.5
module ab_ff_2seg
   (
    input wire clk,
    input wire a, b,
    output reg q
   );

   reg q_next;

   // D FF
   always @(posedge clk)
      q <= q_next;

   // combinational circuit
   always @*
      q_next = a & b;

endmodule
