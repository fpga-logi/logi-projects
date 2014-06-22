// Listing 12.5
module rom_template
   (
    input wire [3:0] addr,
    output reg [7:0] data
   );

   // body
   always @*
      case (addr)
         4'h0: data = 7'b0000001;
         4'h1: data = 7'b1001111;
         4'h2: data = 7'b0010010;
         4'h3: data = 7'b0000110;
         4'h4: data = 7'b1001100;
         4'h5: data = 7'b0100100;
         4'h6: data = 7'b0100000;
         4'h7: data = 7'b0001111;
         4'h8: data = 7'b0000000;
         4'h9: data = 7'b0000100;
         4'ha: data = 7'b0001000;
         4'hb: data = 7'b1100000;
         4'hc: data = 7'b0110001;
         4'hd: data = 7'b1000010;
         4'he: data = 7'b0110000;
         4'hf: data = 7'b0111000;
      endcase

endmodule