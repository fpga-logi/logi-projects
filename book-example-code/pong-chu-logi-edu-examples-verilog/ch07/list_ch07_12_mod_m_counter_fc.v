// Listing 7.12
module mod_m_counter_fc
   #(parameter M=10) // mod-M
   (
    input wire clk, reset,
    output wire max_tick,
    output wire [log2(M)-1:0] q
   );

   //signal declaration
   localparam N = log2(M);   // number of bits for M
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
   assign r_next = (r_reg==(M-1)) ? 0 : r_reg + 1;
   // output logic
   assign q = r_reg;
   assign max_tick = (r_reg==(M-1)) ? 1'b1 : 1'b0;

   // log2 constant function
   function integer log2(input integer n);
      integer i;
   begin
      log2 = 1;
      for (i = 0; 2**i < n; i = i + 1)
         log2 = i + 1;
   end
   endfunction

endmodule