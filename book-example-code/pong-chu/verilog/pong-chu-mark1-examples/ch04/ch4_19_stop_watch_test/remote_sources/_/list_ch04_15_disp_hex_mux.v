// Listing 4.15
/*******************************************************************
* Mark1 Notes:
* made an, sseg signals active low
********************************************************************/
module disp_hex_mux
   (
    input wire clk, reset,
    input wire [3:0] hex3, hex2, hex1, hex0,  // hex digits
    input wire [3:0] dp_in,             // 4 decimal points
    output reg [3:0] an,  // enable 1-out-of-4 asserted low
    output reg [7:0] sseg // led segments
   );

   // constant declaration
   // refreshing rate around 800 Hz (50 MHz/2^16)
   localparam N = 18;
   // internal signal declaration
   reg [N-1:0] q_reg;
   wire [N-1:0] q_next;
   reg [3:0] hex_in;
   reg dp;

   // N-bit counter
   // register
   always @(posedge clk, posedge reset)
      if (reset)
         q_reg <= 0;
      else
         q_reg <= q_next;

   // next-state logic
   assign q_next = q_reg + 1;

   // 2 MSBs of counter to control 4-to-1 multiplexing
   // and to generate active-low enable signal
   always @*
      case (q_reg[N-1:N-2])
         2'b00:
            begin
               //an =  4'b1110; //active low
					an =  4'b0001; //active high
               hex_in = hex0;
               dp = dp_in[0];
            end
         2'b01:
            begin
               //an =  4'b1101;	//active low
					an =  4'b0010;	//active high
               hex_in = hex1;
               dp = dp_in[1];
            end
         2'b10:
            begin
               //an =  4'b1011;	//active low
					an =  4'b0100;	//active high
               hex_in = hex2;
               dp = dp_in[2];
            end
         default:
            begin
               //an =  4'b0111;	//active low
					an =  4'b1000;	//active high
               hex_in = hex3;	
               dp = dp_in[3];
            end
       endcase

   // hex to seven-segment led display
   always @*
   begin
      case(hex_in)
         4'h0: sseg[6:0] = 7'b1111110;//7'b0000001;
         4'h1: sseg[6:0] = 7'b0110000;//7'b1001111;
         4'h2: sseg[6:0] = 7'b1101101;//7'b0010010;
         4'h3: sseg[6:0] = 7'b1111001;//7'b0000110;
         4'h4: sseg[6:0] = 7'b0110011;//7'b1001100;
         4'h5: sseg[6:0] = 7'b1011011;//7'b0100100;
         4'h6: sseg[6:0] = 7'b1011111;//7'b0100000;
         4'h7: sseg[6:0] = 7'b1110000;//7'b0001111;
         4'h8: sseg[6:0] = 7'b1111111;//7'b0000000;
         4'h9: sseg[6:0] = 7'b1111011;//7'b0000100;
         4'ha: sseg[6:0] = 7'b1110111;//7'b0001000;
         4'hb: sseg[6:0] = 7'b0011111;//7'b1100000;
         4'hc: sseg[6:0] = 7'b1001110;//7'b0110001;
         4'hd: sseg[6:0] = 7'b0111101;//7'b1000010;
         4'he: sseg[6:0] = 7'b1001111;//7'b0110000;
         default: sseg[6:0] = 7'b1000111;//7'b0111000;  //4'hf
     endcase
     sseg[7] = dp;
   end

endmodule