//Listing 8.2
module flag_buf
   #(parameter W = 8) // # buffer bits
   (
    input wire clk, reset,
    input wire clr_flag, set_flag,
    input wire [W-1:0] din,
    output wire flag,
    output wire [W-1:0] dout
   );

   // signal declaration
   reg [W-1:0] buf_reg, buf_next;
   reg flag_reg, flag_next;


   // body
   // FF & register
   always @(posedge clk, posedge reset)
      if (reset)
         begin
            buf_reg <= 0;
            flag_reg <= 1'b0;
         end
      else
         begin
            buf_reg <= buf_next;
            flag_reg <= flag_next;
         end

   // next-state logic
   always @*
   begin
      buf_next = buf_reg;
      flag_next = flag_reg;
      if (set_flag)
         begin
            buf_next = din;
            flag_next = 1'b1;
         end
      else if (clr_flag)
         flag_next = 1'b0;
   end
   // output logic
   assign dout = buf_reg;
   assign flag = flag_reg;

endmodule