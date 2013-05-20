// Listing 3.17
/******************************************************************
* Port to Mark1 Notes: 
* - Changed signals to active high.  MJ
* - inverted logic level of btn.  MJ
*******************************************************************/
module sm_add_test
   (
    input wire clk,
    input wire [1:0] btn,
    input wire [7:0] sw,
    output wire [3:0] an,
    output wire [7:0] sseg
   );

   // signal declaration
   wire [3:0] sum, mout, oct;
   wire [7:0] led3, led2, led1, led0;

   // instantiate adder
   sign_mag_add #(.N(4)) sm_adder_unit
     (.a(sw[3:0]), .b(sw[7:4]), .sum(sum));

   //  magnitude displayed on rightmost 7-seg LED
   assign mout = (~btn==2'b00) ? sw[3:0] :
                 (~btn==2'b01) ? sw[7:4] :
                 sum;
   assign oct = {1'b0, mout[2:0]};
   // instantiate hex decoder
   hex_to_sseg sseg_unit
      (.hex(oct), .dp(1'b0), .sseg(led0));

   // sign displayed on 2nd 7-seg LED
   // middle LED bar on for negative number
   //assign led1 = mout[3] ? 8'b11111110 : 8'b11111111;	//active low
	assign led1 = mout[3] ? 8'b00000001 : 8'b00000000;	//active high
   // blank two other LEDs
   //assign led2 = 8'b11111111;	//active low
   //assign led3 = 8'b11111111;//active low
	assign led2 = 8'b00000000;	//active high
   assign led3 = 8'b00000000;//active high

   // instantiate 7-seg LED display time-multiplexing module
   disp_mux disp_unit
      (.clk(clk), .reset(1'b0), .in0(led0), .in1(led1),
       .in2(led2), .in3(led3), .an(an), .sseg(sseg));

endmodule