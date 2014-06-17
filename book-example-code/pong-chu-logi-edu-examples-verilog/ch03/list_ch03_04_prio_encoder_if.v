// Listing 3.4
module prio_encoder_if
   (
    input wire [4:1] r,
    output reg [2:0] y
   );

   always @*
      if (r[4]==1'b1)      // can be written as (r[4])
         y = 3'b100;
      else if (r[3]==1'b1) // can be written as (r[3])
         y = 3'b011;
      else if (r[2]==1'b1) // can be written as (r[2])
         y = 3'b010;
      else if (r[1]==1'b1) // can be written as (r[1])
         y = 3'b001;
      else
         y = 3'b000;

endmodule