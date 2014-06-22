// Listing A.4
module prio_encoder_case
   (
    input wire [4:1] r,
    output reg [2:0] y1, y2
   );

   // case statement
   //    - each branch can contain multiple statements
   //      with begin ... end delimiters
   always @*
      case(r)
         4'b1000, 4'b1001, 4'b1010, 4'b1011,
         4'b1100, 4'b1101, 4'b1110, 4'b1111:
            y1 = 3'b100;
         4'b0100, 4'b0101, 4'b0110, 4'b0111:
            y1 = 3'b011;
         4'b0010, 4'b0011:
            y1 = 3'b010;
         4'b0001:
            y1 = 3'b001;
         4'b0000:     // default can also be used
            y1 = 3'b000;
     endcase

   // casez statement
   always @*
      casez(r)
         4'b1???: y2 = 3'b100; // use ? for don't-care
         4'b01??: y2 = 3'b011;
         4'b001?: y2 = 3'b010;
         4'b0001: y2 = 3'b001;
         4'b0000: y2 = 3'b000; // default can also be used
      endcase

endmodule
