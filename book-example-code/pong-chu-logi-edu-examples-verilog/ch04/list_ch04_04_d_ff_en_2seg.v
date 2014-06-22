// Listing 4.4
module d_ff_en_2seg
   (
    input wire clk, reset,
    input wire en,
    input wire d,
    output reg q
   );

   // signal declaration
   reg r_reg, r_next;

   // body
   // D FF
   always @(posedge clk, posedge reset)
      if (reset)
         r_reg <= 1'b0;
      else
         r_reg <= r_next;

   // next-state logic
   always @*
      if (en)
         r_next = d;
      else
         r_next = r_reg;

   // output logic
   always @*
      q = r_reg;

endmodule