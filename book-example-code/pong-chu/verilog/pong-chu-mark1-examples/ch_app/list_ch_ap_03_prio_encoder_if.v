// Listing A.3
module prio_encoder_if
   (
    input wire [4:1] r,
    output wire [2:0] y1, 
    output reg [2:0] y2
   );

   // Conditional operator
   assign y1 = (r[4]) ? 3'b100 :  // can also use (r[4]==1'b1)
               (r[3]) ? 3'b011 :
               (r[2]) ? 3'b010 :
               (r[1]) ? 3'b001 :
               3'b000;

   // If statement
   //    - each branch can contain multiple statements
   //      with begin ... end delimiters
   always @*
      if (r[4])
         y2 = 3'b100;
      else if (r[3])
         y2 = 3'b011;
      else if (r[2])
         y2 = 3'b010;
      else if (r[1])
         y2 = 3'b001;
      else
         y2 = 3'b000;

endmodule