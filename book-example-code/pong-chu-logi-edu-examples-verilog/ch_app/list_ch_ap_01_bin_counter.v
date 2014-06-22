// Listing A.1
module bin_counter
   // optional parameter declaration
   #(parameter N=8)   // default 8
   // port declaration
   (
    input wire clk, reset,         // clock & reset
    input wire syn_clr, load, en,  // input control
    input wire [N-1:0] d,          // input data
    output wire max_tick,          // output status
    output wire [N-1:0] q          // output data
   );

   // constant declaration
   localparam MAX = 2**N - 1;
   // signal declaration
   reg [N-1:0] r_reg, r_next;

   // body
   //===========================================
   // component instantiation
   //===========================================
   // no instantiation in this code

   //===========================================
   // memory elements
   //===========================================
   // register
   always @(posedge clk, posedge reset)
      if (reset)
         r_reg <= 0;
      else
         r_reg <= r_next;

   //===========================================
   // combinational circuits
   //===========================================
   // next-state logic
   always @*
      if (syn_clr)
         r_next = 0;
      else if (load)
         r_next = d;
      else if (en)
         r_next = r_reg + 1;
      else
         r_next = r_reg;
   // output logic
   assign q = r_reg;
   assign max_tick = (r_reg==2**N-1) ? 1'b1 : 1'b0;

endmodule
