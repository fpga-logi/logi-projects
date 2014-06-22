// Listing 4.7
module free_run_shift_reg
   #(parameter N=8)
   (
    input wire clk, reset,
    input wire s_in,
    output wire s_out
   );

   //signal declaration
   reg [N-1:0] r_reg;
   wire [N-1:0] r_next;

   // body
   // register
   always @(posedge clk, posedge reset)
      if (reset)
         r_reg <= 0;
      else
         r_reg <= r_next;

   // next-state logic
   assign r_next = {s_in, r_reg[N-1:1]};
   // output logic
   assign s_out = r_reg[0];

endmodule